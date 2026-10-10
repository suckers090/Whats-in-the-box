-- Client browsing only; all claims and discoveries remain server authoritative.
local view = {Filters = {"All", "Undiscovered", "Discovered", "Common", "Uncommon", "Rare", "Epic", "Legendary"}}
function view.Summary(catalog, discoveries, milestones, claims)
	local found, ready, byRarity = 0, 0, {}
	for _, item in ipairs(catalog) do
		local group = byRarity[item.rarity] or {found = 0, total = 0}; byRarity[item.rarity] = group
		group.total += 1
		if (discoveries[item.id] or 0) > 0 then found += 1; group.found += 1 end
	end
	for _, m in ipairs(milestones) do if found >= m.required and not claims[m.id] then ready += 1 end end
	return {found = found, total = #catalog, ready = ready, byRarity = byRarity}
end
function view.List(catalog, discoveries, filter, query)
	local rows = {}; query = string.lower(query or "")
	for _, item in ipairs(catalog) do
		local discovered = (discoveries[item.id] or 0) > 0
		local matches = filter == "All" or filter == item.rarity
			or (filter == "Discovered" and discovered) or (filter == "Undiscovered" and not discovered)
		-- Search uses public catalog metadata; no private package contents are exposed.
		local searchable = string.lower(item.name .. " " .. (item.category or "") .. " " .. item.rarity)
		if matches and (query == "" or string.find(searchable, query, 1, true)) then
			table.insert(rows, {item = item, discovered = discovered})
		end
	end
	return rows
end
return view
