local catalog = require("../src/ReplicatedStorage/ItemCatalog")
local milestones = require("../src/ReplicatedStorage/CollectionMilestones")
local roller = require("../src/ServerScriptService/ItemRoller")(catalog)
local inventory = require("../src/ServerScriptService/InventoryState")(catalog)
local schema = require("../src/ServerScriptService/ProfileSchema")(catalog)
local transactions = require("../src/ServerScriptService/ProfileTransactions")(schema)
local collection = require("../src/ServerScriptService/CollectionProgress")(catalog, milestones)
local view = require("../src/ReplicatedStorage/CollectionView")
local invView = require("../src/ReplicatedStorage/InventoryView")
local ids, categories, weights, hits, mean = {}, {}, {}, {}, 0
assert(#catalog == 60 and roller.Total == 10000)
for _, item in ipairs(catalog) do
	assert(not ids[item.id] and #item.id <= 64 and item.value % 1 == 0 and item.value > 0)
	assert(type(item.category) == "string" and type(item.preview) == "string")
	ids[item.id] = item; categories[item.category] = true
	weights[item.rarity] = (weights[item.rarity] or 0) + item.weight
	mean += item.value * item.weight / roller.Total
end
assert(weights.Common == 7000 and weights.Uncommon == 1700 and weights.Rare == 800 and weights.Epic == 300 and weights.Legendary == 200)
local categoryCount = 0; for _ in pairs(categories) do categoryCount += 1 end; assert(categoryCount == 8)
assert(mean > 650 and mean < 850, "Catalog expansion must not multiply starter earnings")
for id, value in pairs({old_toy = 25, headphones = 100, gaming_console = 650, gold_watch = 2500, mysterious_device = 12000}) do assert(ids[id].value == value) end
-- Exhaust every possible ticket: catches unreachable new rows and boundary bias.
for ticket = 1, roller.Total do
	local item = roller.Roll({NextInteger = function(_, low, high) assert(low == 1 and high == 10000); return ticket end})
	hits[item.id] = (hits[item.id] or 0) + 1
end
for _, item in ipairs(catalog) do assert(hits[item.id] == item.weight, item.id .. " has incorrect roll coverage") end
local data = schema.New(); data.cash = 4321; data.scanner = true
data.collectionClaims = {first_find = true, getting_started = true, original_five = true}
for _, item in ipairs(catalog) do assert(inventory.Discover(data, item.id)); assert(inventory.Resolve(data, "Keep") == 0) end
assert(collection.Count(data.discoveries) == 60)
local totalClaims = 0
for _, m in ipairs(milestones) do
	if m.required <= 5 then assert(collection.Claim(data, m.id) == nil)
	else local reward = collection.Claim(data, m.id); assert(reward == m.reward); data.cash += reward; totalClaims += 1 end
	assert(collection.Claim(data, m.id) == nil, "Reward cannot pay twice")
end
assert(totalClaims == 5 and data.cash == 35821)
local capped = schema.New(); capped.discoveries = data.discoveries
assert(collection.Claim(capped, "warehouse_ten", 999) == nil and not capped.collectionClaims.warehouse_ten,
	"A cash-cap rejection must leave the new reward claim available")
assert(collection.Claim(capped, "warehouse_ten", 1000) == 1000)
assert(inventory.SetFlag(data, "diamond_relic", "Lock", true))
assert(inventory.SetFlag(data, "arcade_board", "Favorite", true))
assert(inventory.Sell(data, "diamond_relic") == nil)
data.pending = "quantum_core"; data.inventory.future_item = 4
local record = transactions.Acquire(nil, "owner", 1000, 180)
local saved = transactions.Commit(record, "owner", data, 1001, 180, true)
assert(saved.version == 1)
local loaded = schema.Recover(transactions.Acquire(saved, "next", 1002, 180).data)
assert(loaded.inventory.quantum_core == 2 and loaded.inventory.future_item == 4)
assert(loaded.cash == 35821 and loaded.scanner and loaded.inventoryLocks.diamond_relic and loaded.inventoryFavorites.arcade_board)
for _, item in ipairs(catalog) do assert(loaded.inventory[item.id] >= 1 and loaded.discoveries[item.id] == 1) end
assert(#view.List(catalog, {}, "Undiscovered", "") == 60)
assert(#view.List(catalog, loaded.discoveries, "Discovered", "") == 60)
assert(#view.List(catalog, loaded.discoveries, "Epic", "") == 8)
assert(#view.List(catalog, {}, "All", "TOOLS") == 8)
assert(#view.List(catalog, {}, "All", "[.*]") == 0, "Search is literal, not a pattern")
local summary = view.Summary(catalog, loaded.discoveries, milestones, loaded.collectionClaims)
assert(summary.found == 60 and summary.ready == 0 and summary.byRarity.Legendary.found == 4)
assert(#invView.List(catalog, loaded.inventory, loaded.inventoryLocks, loaded.inventoryFavorites, "Rarity", "Epic") == 8)
local rows = invView.List(catalog, loaded.inventory, {}, {}, "Rarity", "All")
assert(rows[1].item.rarity == "Legendary" and rows[5].item.rarity == "Epic")
print("PASS: every weighted ticket, 60 reachable IDs/eight themes/five rarities, economy bounds, new item save/pending recovery, expanded claims, literal collection browsing and Epic ordering")
