local catalog = require("../src/ReplicatedStorage/ItemCatalog")
local schema = require("../src/ServerScriptService/ProfileSchema")(catalog)
local transactions = require("../src/ServerScriptService/ProfileTransactions")(schema)
local inventory = require("../src/ServerScriptService/InventoryState")(catalog)
local record = transactions.Acquire(nil, "server-a", 1000, 180)
assert(record.version == 1 and record.data.cash == 0 and record.lock.token == "server-a")
local second, reason = transactions.Acquire(record, "server-b", 1100, 180)
assert(second == nil and reason == "Profile in another server")
assert(record.lock.token == "server-a" and record.lock.expires == 1180, "Denied loads must not mutate records")
local data = schema.New()
data.cash = 4500; data.scanner = true
data.inventory.gold_watch = 2; data.discoveries.gold_watch = 3
local saved = transactions.Commit(record, "server-a", data, 1045, 180, false)
assert(saved.data.cash == 4500 and saved.data.scanner and saved.lock.expires == 1225)
data.inventory.gold_watch = 9
assert(saved.data.inventory.gold_watch == 2, "Saved snapshots must be independent of gameplay mutations")
local release = transactions.Commit(saved, "server-a", saved.data, 1050, 180, true)
assert(release.lock == nil and release.data.cash == 4500)
local reconnect = transactions.Acquire(release, "server-b", 1051, 180)
local loaded = schema.Recover(reconnect.data)
assert(loaded.cash == 4500 and loaded.inventory.gold_watch == 2 and loaded.discoveries.gold_watch == 3 and loaded.scanner)
assert(transactions.Commit(reconnect, "server-a", schema.New(), 1052, 180, false) == nil,
	"Old server cannot overwrite a newer session")
assert(transactions.Acquire(reconnect, "server-c", 1200, 180) == nil)
local crashRecovery = transactions.Acquire(reconnect, "server-c", 1300, 180)
assert(crashRecovery.lock.token == "server-c" and crashRecovery.data.cash == 4500)
assert(transactions.Commit(crashRecovery, "server-b", loaded, 1301, 180, true) == nil,
	"Expired server cannot release the new owner's lock")
assert(transactions.Commit(nil, "server-a", schema.New(), 1400, 180, true) == nil,
	"Missing records cannot turn into successful default-data saves")
local corrupt = {version = 2, data = schema.New()}
assert(transactions.Acquire(corrupt, "server-a", 1400, 180) == nil)
assert(corrupt.version == 2, "Unknown schemas must remain untouched")
local invalid = schema.New(); invalid.cash = -1
assert(schema.Validate(invalid) == nil)
invalid.cash = math.huge
assert(schema.Validate(invalid) == nil)
invalid.cash = 0; invalid.inventory.gold_watch = 1.5
assert(schema.Validate(invalid) == nil)
invalid.inventory.gold_watch = 1; invalid.pending = "forged_item"
assert(schema.Validate(invalid) == nil)
local pending = schema.New()
pending.pending = "gold_watch"; pending.discoveries.gold_watch = 1
local recovered, id = schema.Recover(pending)
assert(id == "gold_watch" and recovered.inventory.gold_watch == 1 and recovered.pending == nil)
local again, recoveredAgain = schema.Recover(recovered)
assert(recoveredAgain == nil and again.inventory.gold_watch == 1, "Unfinished reward recovery must not duplicate grants")
assert(inventory.Resolve(again, "Sell") == nil)
assert(inventory.Sell(again, "gold_watch") == 2500)
assert(inventory.Sell(again, "gold_watch") == nil)
local future = schema.New(); future.inventory.future_item = 7
assert(schema.Validate(future).inventory.future_item == 7, "Valid future catalog IDs must not be erased")
assert(transactions.Commit(crashRecovery, "server-c", invalid, 1310, 180, true) == nil)
assert(crashRecovery.data.cash == 4500, "Invalid writes must not change existing progress")
print("PASS: cash/inventory/index/scanner roundtrip; session leases, conflict/stale-write rejection, schema failures, snapshot isolation and pending reward recovery")
