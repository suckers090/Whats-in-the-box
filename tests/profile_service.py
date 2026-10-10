"""Exercise actual PlayerProfiles code using a deterministic DataStore/Roblox adapter.
Usage: python tests/profile_service.py /path/to/luau
This does not execute Roblox Studio or contact Roblox DataStore.
"""
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = (root / "src/ServerScriptService/PlayerProfiles.luau").read_text()
with tempfile.TemporaryDirectory(prefix="witb-profiles-") as directory:
    relative = "."
    for dependency in ("src/ServerScriptService/ProfileSchema.luau",
                       "src/ServerScriptService/ProfileTransactions.luau",
                       "src/ReplicatedStorage/ItemCatalog.luau"):
        target = Path(directory) / dependency
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(root / dependency, target)
    prefix = '''
local import = require
local schemaFactory = import("ROOT/src/ServerScriptService/ProfileSchema")
local transactionFactory = import("ROOT/src/ServerScriptService/ProfileTransactions")
local catalog = import("ROOT/src/ReplicatedStorage/ItemCatalog")
local config = {DataStoreName = "Live", StudioDataStoreName = "Test", StudioPersistenceEnabled = false,
    AutosaveSeconds = 45, LeaseSeconds = 180, LeaseSafetySeconds = 30, Attempts = 3}
local now, studio, calls, failures, token = 0, false, 0, 0, 0
local records = {}
local mutateDuringWrite = nil
local Players = {}
local warnings = {}
local store = {}
function store:UpdateAsync(key, transform)
    calls += 1
    if failures > 0 then failures -= 1; error("Injected network failure") end
    if mutateDuringWrite then local callback = mutateDuringWrite; mutateDuringWrite = nil; callback() end
    local result = transform(records[key])
    if result then records[key] = result end
    return result
end
local services = {
    Players = Players,
    DataStoreService = {GetDataStore = function(_, name) assert(name == "Live" or name == "Test"); return store end},
    RunService = {IsStudio = function() return studio end},
    HttpService = {GenerateGUID = function() token += 1; return "token_" .. token end},
    ReplicatedStorage = {WaitForChild = function(_, name) return name end},
}
local game = {GetService = function(_, name) return services[name] end, BindToClose = function() end}
local script = {Parent = {WaitForChild = function(_, name) return name end}}
local function require(name)
    if name == "PersistenceConfig" then return config end
    if name == "ProfileSchema" then return schemaFactory end
    if name == "ProfileTransactions" then return transactionFactory end
    if name == "ItemCatalog" then return catalog end
    error("Unknown dependency " .. name)
end
local os = {clock = function() return now end, time = function() return 1000 + math.floor(now) end}
local task = {spawn = function() end, wait = function(seconds) now += seconds end}
local warn = function(message) table.insert(warnings, message) end
local function loadService()
SOURCE
end
local function player(id)
    return {UserId = id, Parent = Players, attributes = {},
        SetAttribute = function(self, key, value) self.attributes[key] = value end,
        GetAttribute = function(self, key) return self.attributes[key] end,
        Kick = function(self, message) self.kicked = message end}
end
'''.replace("ROOT", relative).replace("SOURCE", source)
    checks = '''
local service = loadService()
local owner = player(1)
failures = 2
local profile = service.Load(owner)
assert(profile and calls == 3 and owner.attributes.DataReady == true, "Load must retry transient failures")
profile.Data.cash = 4000
profile.Data.inventory.gold_watch = 2
profile.Data.discoveries.gold_watch = 2
profile.Data.scanner = true
profile.Snapshot = function() return profile.Data end
mutateDuringWrite = function() profile.Data.cash = 5000; profile.Data.inventory.gold_watch = 3 end
assert(service.Save(owner, false))
assert(records.player_1.data.cash == 4000 and records.player_1.data.inventory.gold_watch == 2,
    "Snapshot must freeze related values before a yielding write")
local beforeFailure = records.player_1
failures = 3
assert(not service.Save(owner, false))
assert(records.player_1 == beforeFailure and owner.attributes.SaveStatus == "Save retry needed",
    "Failed writes must not claim success or replace stored progress")
assert(service.Save(owner, false))
assert(records.player_1.data.cash == 5000 and records.player_1.data.scanner == true)
service.Close(owner)
assert(records.player_1.lock == nil and service.Get(owner) == nil)
local rejoined = service.Load(owner)
assert(rejoined.Data.cash == 5000 and rejoined.Data.inventory.gold_watch == 3 and rejoined.Data.scanner)
rejoined.Data.pending = "gold_watch"
service.Close(owner)
local recovered = service.Load(owner)
assert(recovered.Recovered == "gold_watch" and recovered.Data.inventory.gold_watch == 4)
service.Close(owner)
local recoveredAgain = service.Load(owner)
assert(recoveredAgain.Recovered == nil and recoveredAgain.Data.inventory.gold_watch == 4)
records.player_1.lock = {token = "new_server", expires = 999999}
assert(not service.Save(owner, false))
assert(owner.attributes.DataReady == false and owner.kicked,
    "Lost sessions must stop gameplay and cannot overwrite a new owner")
assert(records.player_1.lock.token == "new_server")
local unlucky = player(2)
failures = 3
assert(service.Load(unlucky) == nil)
assert(service.Get(unlucky) == nil and unlucky.attributes.DataReady == false and records.player_2 == nil,
    "Failed load must not install a blank playable profile")
records.player_3 = {version = 999, data = {cash = 777}}
local corrupt = player(3)
assert(service.Load(corrupt) == nil and records.player_3.data.cash == 777,
    "Unsupported profiles must remain unchanged")
studio = true
local previewService = loadService()
local previewPlayer = player(4)
local priorCalls = calls
local previewProfile = previewService.Load(previewPlayer)
previewProfile.Data.cash = 1234
assert(previewService.Save(previewPlayer, false))
previewService.Close(previewPlayer)
assert(calls == priorCalls and records.player_4 == nil and previewPlayer.attributes.SaveStatus == "Studio preview",
    "Default Studio preview must never touch DataStore")
print("PASS: actual profile service retries/failures, frozen snapshots, save/rejoin/recovery, stale-session shutdown and Studio isolation")
'''
    path = Path(directory) / "profiles-test.luau"
    path.write_text(prefix + checks)
    subprocess.run([sys.argv[1] if len(sys.argv) > 1 else "luau", str(path)], check=True)
