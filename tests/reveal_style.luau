local style = require("../src/ReplicatedStorage/RevealStyle")
assert(not style("Common", false).strong)
assert(style("Common", true).title == "NEW DISCOVERY!")
assert(style("Rare", false).strong and not style("Rare", false).special)
for _, rarity in ipairs({"Legendary", "Mythic", "Secret"}) do
	assert(style(rarity, false).special and style(rarity, false).strong)
end
assert(not style("Unknown", false).strong, "Unknown rarity must have safe presentation defaults")
assert(style("Legendary", false).title == "PACKAGE OPENED!", "Rare duplicate is not a new discovery")
print("PASS: common/new/rare/special reveal presentation and unknown rarity fallback")
