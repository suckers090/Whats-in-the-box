"""Exercise the actual serialized delivery cycle with lifecycle doubles, without Roblox.
Usage: python tests/delivery_cycle.py /path/to/luau
"""
import re
import subprocess
import sys
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = (root / "src/ServerScriptService/WarehousePrototype.server.luau").read_text()
match = re.search(r"local function deliver\(\).*?\n\tend(?=\n\tlocal function packageCount)", source, re.S)
assert match, "Missing delivery cycle"
prefix = '''
local phases, spawned, movements, visibility, notifications = {}, {}, {}, {}, {}
local ready, active, failWait, failMove, waitCount, moveCount = true, true, 0, 0, 0, 0
local Players = {}
local plot = {Owner = {Parent = Players, GetAttribute = function() return ready end}}
local workspace = {GetServerTimeNow = function() return 1000 end}
local truckStart, truckTarget = "road", "dock"
local truck = {PivotTo = function(_, location) table.insert(movements, "reset:" .. location) end}
local notice = {FireClient = function(_, player, message) assert(player == plot.Owner); table.insert(notifications, message) end}
local function alive() return active end
local function setDeliveryPhase(phase, due) table.insert(phases, {phase, due}) end
local function waitActive(seconds)
    waitCount += 1
    if waitCount == failWait then active = false end
    return active
end
local function moveTruck(target)
    moveCount += 1
    table.insert(movements, target)
    if moveCount == failMove then active = false end
    return active
end
local function truckVisible(value) table.insert(visibility, value) end
local function spawnPackage(index) table.insert(spawned, index) end
'''
checks = '''
local function reset()
    phases, spawned, movements, visibility, notifications = {}, {}, {}, {}, {}
    ready, active, failWait, failMove, waitCount, moveCount = true, true, 0, 0, 0, 0
end
assert(deliver())
assert(#spawned == 3 and spawned[1] == 1 and spawned[3] == 3)
assert(#phases == 5 and phases[1][1] == "Queued" and phases[1][2] == 1003)
assert(phases[2][1] == "Arriving" and phases[3][1] == "Unloading"
    and phases[4][1] == "Departing" and phases[5][1] == "Ready")
assert(movements[1] == "reset:road" and movements[2] == "dock" and movements[3] == "road")
assert(visibility[1] == true and visibility[2] == false and #notifications == 1)
reset()
assert(deliver() and deliver() and #spawned == 6 and #notifications == 2,
    "Subsequent batches must repeat the real truck cycle")
reset(); ready = false
assert(deliver() and #spawned == 0 and #movements == 0 and #visibility == 0,
    "Saving-paused sessions must not launch queued deliveries")
reset(); failWait = 1
assert(not deliver() and #spawned == 0 and #movements == 0,
    "Plot deletion during queue must cancel the batch")
reset(); failMove = 1
assert(not deliver() and #spawned == 0, "Plot deletion during arrival cannot unload")
reset(); failWait = 2
assert(not deliver() and #spawned == 1 and #notifications == 0,
    "Plot deletion mid-unload must stop further package creation")
reset(); failMove = 2
assert(not deliver() and #spawned == 3 and #phases == 4,
    "Cancelled departures must not report a ready controller or create another batch")
print("PASS: serialized arrival/unload/departure, repeated 3-package batches, save pause and lifecycle cancellation")
'''
with tempfile.TemporaryDirectory(prefix="witb-delivery-") as directory:
    path = Path(directory) / "delivery-test.luau"
    path.write_text(prefix + match.group() + checks)
    subprocess.run([sys.argv[1] if len(sys.argv) > 1 else "luau", str(path)], check=True)
