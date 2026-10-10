-- Pure display ordering. This module never grants/sells items or decides a price.
local view = {Sorts = {"Rarity", "Value", "Name", "Count"},
	Filters = {"All", "Favorites", "Unlocked", "Common", "Uncommon", "Rare", "Legendary"}}
local ranks = {Common = 1, Uncommon = 2, Rare = 3, Legendary = 4, Secret = 5}
function view.List(catalog, inventory, locks, favorites, sort, filter)
	local rows = {}
	for _, item in ipairs(catalog) do
		local count = inventory[item.id] or 0
		local favorite, locked = favorites[item.id] == true, locks[item.id] == true
		local matches = filter == "All" or (filter == "Favorites" and favorite)
			or (filter == "Unlocked" and not locked) or filter == item.rarity
		if count > 0 and matches then table.insert(rows, {item = item, count = count, favorite = favorite, locked = locked}) end
	end
	table.sort(rows, function(a, b)
		if a.favorite ~= b.favorite then return a.favorite end
		if sort == "Rarity" then
			local ar, br = ranks[a.item.rarity] or 0, ranks[b.item.rarity] or 0
			if ar ~= br then return ar > br end
		elseif sort == "Value" and a.item.value ~= b.item.value then return a.item.value > b.item.value
		elseif sort == "Count" and a.count ~= b.count then return a.count > b.count end
		if a.item.name ~= b.item.name then return a.item.name < b.item.name end
		return a.item.id < b.item.id
	end)
	return rows
end
return view
