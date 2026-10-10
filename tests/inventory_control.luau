local catalog = require("../src/ReplicatedStorage/ItemCatalog")
local inventory = require("../src/ServerScriptService/InventoryState")(catalog)
local factory = require("../src/ServerScriptService/InventoryActions")
local view = require("../src/ReplicatedStorage/InventoryView")
local schema = require("../src/ServerScriptService/ProfileSchema")(catalog)
local transactions = require("../src/ServerScriptService/ProfileTransactions")(schema)
local now, serial = 0, 0
local actions = factory(inventory, function() return now end, function() serial += 1; return "quote-" .. serial end)
local data = schema.New()
data.inventory = {old_toy = 5, headphones = 3, gold_watch = 2, future_item = 10}
data.discoveries = {old_toy = 5, gold_watch = 2}
local function run(action, id, payload, cash)
	now += 0.2
	return actions.Run(data, cash or 0, action, id, payload)
end
assert(run("SetInventoryFlag", "gold_watch", {flag = "Lock", enabled = true}).success)
assert(not run("SellInventory", "gold_watch").success and data.inventory.gold_watch == 2)
assert(run("SetInventoryFlag", "headphones", {flag = "Favorite", enabled = true}).success)
assert(not run("SetInventoryFlag", "old_toy", {flag = "Lock", enabled = "true"}).success)
assert(not run("SetInventoryFlag", {}, {flag = "Lock", enabled = true}).success)
assert(not run("SetInventoryFlag", "forged", {flag = "Lock", enabled = true}).success)
local quote = run("QuoteDuplicates").quote
assert(quote.count == 4 and quote.value == 100, "Exclude protected and unknown stacks; keep one of each")
assert(not run("SellDuplicates", "forged", {price = 1000000000000, count = 999}).success)
local sold = run("SellDuplicates", quote.token, {price = 1, quantities = {gold_watch = 99}})
assert(sold.success and sold.cashDelta == 100 and sold.soldCount == 4)
assert(data.inventory.old_toy == 1 and data.inventory.gold_watch == 2 and data.inventory.headphones == 3 and data.inventory.future_item == 10)
assert(not run("SellDuplicates", quote.token).success, "Receipt cannot be replayed")
assert(data.discoveries.old_toy == 5, "Selling must not erase collection history")
assert(inventory.Discover(data, "gold_watch"))
assert(inventory.Resolve(data, "Sell") == nil and data.pending == "gold_watch", "Locked types protect a new duplicate too")
assert(inventory.Resolve(data, "Keep") == 0 and data.inventory.gold_watch == 3)
assert(run("SellInventory", "headphones").success, "Favorites exclude bulk; explicit sell-one is still allowed")
data.inventory.old_toy = 4
quote = run("QuoteDuplicates").quote
data.inventory.old_toy = 5 -- Changed during confirmation: entire quoted sale must fail.
assert(not run("SellDuplicates", quote.token).success and data.inventory.old_toy == 5)
quote = run("QuoteDuplicates").quote
now += 21
assert(not run("SellDuplicates", quote.token).success and data.inventory.old_toy == 5)
quote = run("QuoteDuplicates").quote
assert(run("SetInventoryFlag", "old_toy", {flag = "Lock", enabled = true}).success)
assert(not run("SellDuplicates", quote.token).success)
assert(not run("QuoteDuplicates").success, "All duplicate stacks are now protected")
assert(run("SetInventoryFlag", "old_toy", {flag = "Lock", enabled = false}).success)
assert(not run("SellInventory", "old_toy", nil, 1000000000000).success and data.inventory.old_toy == 5)
quote = run("QuoteDuplicates").quote
assert(not run("SellDuplicates", quote.token, nil, 1000000000000 - 99).success and data.inventory.old_toy == 5)
local result = run("QuoteDuplicates")
assert(not actions.Run(data, 0, "SellDuplicates", result.quote.token).success, "Rate limit independent of a receipt")
local visitor = schema.New(); visitor.inventory.old_toy = 8
now += 0.2
assert(not actions.Run(visitor, 0, "SellDuplicates", result.quote.token).success and visitor.inventory.old_toy == 8)
local legacy = {cash = 1500, scanner = true, inventory = {gold_watch = 2, future_item = 3},
	discoveries = {gold_watch = 2}, pending = "gold_watch", collectionClaims = {first_find = true}}
local migrated = schema.Recover(legacy)
assert(migrated.inventory.gold_watch == 3 and migrated.cash == 1500 and migrated.scanner and migrated.collectionClaims.first_find)
assert(next(migrated.inventoryLocks) == nil and next(migrated.inventoryFavorites) == nil and legacy.inventoryLocks == nil)
data.cash = 6000; data.scanner = true; data.inventoryLocks.future_item = true
data.inventoryFavorites.future_item = true; data.collectionClaims.first_find = true
local record = transactions.Acquire(nil, "a", 1000, 180)
local saved = transactions.Commit(record, "a", data, 1001, 180, true)
assert(saved.version == 1 and saved.data.inventoryLocks.gold_watch and saved.data.inventoryLocks.future_item)
assert(saved.data.inventoryFavorites.headphones and saved.data.inventoryFavorites.future_item and saved.data.saleQuote == nil)
data.inventoryLocks.gold_watch = nil; data.inventoryFavorites.headphones = nil
assert(saved.data.inventoryLocks.gold_watch and saved.data.inventoryFavorites.headphones, "Save freezes preference maps")
local rejoin = schema.Recover(transactions.Acquire(saved, "b", 1002, 180).data)
assert(rejoin.inventoryLocks.gold_watch and rejoin.inventoryFavorites.headphones and rejoin.inventory.future_item == 10)
local invalid = schema.New(); invalid.inventoryLocks.old_toy = false
assert(schema.Validate(invalid) == nil, "Malformed preference maps must not become playable defaults")
invalid.inventoryLocks = {}; invalid.inventoryFavorites = "forged"
assert(schema.Validate(invalid) == nil)
local rows = view.List(catalog, data.inventory, saved.data.inventoryLocks, saved.data.inventoryFavorites, "Rarity", "All")
assert(rows[1].item.id == "headphones" and rows[2].item.id == "gold_watch", "Favorites first, then rarity")
rows = view.List(catalog, data.inventory, {}, {}, "Value", "All")
assert(rows[1].item.id == "gold_watch")
rows = view.List(catalog, data.inventory, {}, {}, "Count", "All")
assert(rows[1].item.id == "old_toy")
assert(#view.List(catalog, data.inventory, {}, saved.data.inventoryFavorites, "Name", "Favorites") == 1)
assert(#view.List(catalog, data.inventory, saved.data.inventoryLocks, {}, "Name", "Unlocked") == 2)
assert(#view.List(catalog, data.inventory, {}, {}, "Name", "Legendary") == 0)
assert(data.inventory.gold_watch == 3, "Display sorting never mutates counts")
print("PASS: locks/favorites, atomic duplicate sales, stale/expired/replayed/foreign receipts, limits/rate control, v1 migration/save isolation and sorting/filtering")
