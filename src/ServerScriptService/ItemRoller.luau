-- Built once on the server. No client-supplied rarity, weight or price.
return function(catalog)
	local total, entries = 0, {}
	for _, item in ipairs(catalog) do
		assert(type(item.weight) == "number" and item.weight > 0 and item.weight % 1 == 0, "Invalid catalog weight")
		total += item.weight
		table.insert(entries, {item = item, upper = total})
	end
	assert(total > 0, "Empty catalog")
	local roller = {Total = total}
	function roller.Roll(rng)
		local ticket = rng:NextInteger(1, total)
		for _, entry in ipairs(entries) do if ticket <= entry.upper then return entry.item end end
		error("RNG returned an out-of-range ticket")
	end
	return roller
end
