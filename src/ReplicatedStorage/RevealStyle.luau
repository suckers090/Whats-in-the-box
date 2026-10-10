-- Pure display rules. This never rolls an item or changes its rarity/value.
local strong = {Rare = true, Epic = true, Legendary = true, Mythic = true, Secret = true}
local special = {Legendary = true, Mythic = true, Secret = true}
return function(rarity, isNew)
	return {
		strong = strong[rarity] == true,
		special = special[rarity] == true,
		title = isNew == true and "NEW DISCOVERY!" or "PACKAGE OPENED!",
		duration = special[rarity] and 0.5 or 0.3,
	}
end
