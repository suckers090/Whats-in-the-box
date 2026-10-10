local catalog = require("../src/ReplicatedStorage/ItemCatalog")
local milestones = require("../src/ReplicatedStorage/CollectionMilestones")
local rules = require("../src/ServerScriptService/CollectionProgress")(catalog, milestones)
local schema = require("../src/ServerScriptService/ProfileSchema")(catalog)
local transactions = require("../src/ServerScriptService/ProfileTransactions")(schema)
local inventory = require("../src/ServerScriptService/InventoryState")(catalog)

-- Pre-feature v1 record: no reset, every original field and unknown item survives.
local legacy = {cash = 2300, inventory = {gold_watch = 2, future_item = 7},
	discoveries = {old_toy = 20, headphones = 4, gaming_console = 1}, scanner = true, pending = "gold_watch"}
local record = transactions.Acquire({version = 1, data = legacy}, "owner", 1000, 180)
assert(record and record.data.cash == 2300 and record.data.scanner)
assert(record.data.inventory.future_item == 7 and next(record.data.collectionClaims) == nil)
assert(legacy.collectionClaims == nil, "Migration must not mutate input")
local data = schema.Recover(record.data)
assert(data.inventory.gold_watch == 3 and data.pending == nil)
assert(rules.Count(data.discoveries) == 3)
data.discoveries.future_item = 999
assert(rules.Count(data.discoveries) == 3, "Unknown IDs must not unlock milestones")
assert(rules.Claim(data, {}) == nil and rules.Claim(data, "forged") == nil)
assert(rules.Claim(data, "original_five") == nil)
assert(next(data.collectionClaims) == nil, "Failed claims must not consume anything")
local reward = rules.Claim(data, "first_find")
assert(reward == 100)
data.cash += reward
assert(rules.Claim(data, "first_find") == nil, "Replay cannot pay twice")
assert(rules.Claim(data, "getting_started") == 500, "Existing players can claim earned rewards")
data.cash += 500
local other = schema.New()
assert(rules.Claim(other, "first_find") == nil and next(other.collectionClaims) == nil)
assert(inventory.Sell(data, "gold_watch") == 2500)
assert(rules.Count(data.discoveries) == 3, "Selling does not erase collection progress")
data.discoveries.gold_watch = 1
data.discoveries.mysterious_device = 1
assert(rules.Claim(data, "original_five") == 1500)
data.cash += 1500
assert(data.cash == 4400, "Total milestone bonus is $2100")
data.collectionClaims.future_milestone = true
local saved = transactions.Commit(record, "owner", data, 1045, 180, true)
assert(saved and saved.data.collectionClaims.original_five and saved.data.collectionClaims.future_milestone)
data.collectionClaims.original_five = nil
assert(saved.data.collectionClaims.original_five, "Snapshot claim map must be independent")
local reconnect = transactions.Acquire(saved, "next-owner", 1050, 180)
local loaded = schema.Recover(reconnect.data)
for _, milestone in ipairs(milestones) do
	assert(rules.Claim(loaded, milestone.id) == nil, "Rejoining cannot pay a claimed reward again")
end
assert(loaded.cash == 4400 and loaded.scanner and loaded.inventory.gold_watch == 2)
for _, invalid in ipairs({false, 1, "yes", {}}) do
	local bad = schema.New()
	bad.collectionClaims = {first_find = invalid}
	assert(schema.Validate(bad) == nil, "Reject malformed persisted claim flags")
end
local bad = schema.New(); bad.collectionClaims = "bad"
assert(schema.Validate(bad) == nil)
print("PASS: legacy migration, distinct finds, eligibility, replay/forgery rejection, isolation and claim/cash save roundtrip")
