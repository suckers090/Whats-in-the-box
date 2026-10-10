-- Pure server rules. Counts unique known item IDs, never duplicate opens.
return function(catalog, milestones)
	local byId = {}
	for _, milestone in ipairs(milestones) do byId[milestone.id] = milestone end
	local rules = {}
	function rules.Count(discoveries)
		local count = 0
		for _, item in ipairs(catalog) do
			if (discoveries[item.id] or 0) > 0 then count += 1 end
		end
		return count
	end
	function rules.Claim(data, id)
		local milestone = type(id) == "string" and byId[id]
		if not milestone then return nil, "Unknown collection reward." end
		if data.collectionClaims[id] then return nil, "Collection reward already claimed." end
		if rules.Count(data.discoveries) < milestone.required then
			return nil, "Discover more different items to unlock this reward."
		end
		-- No yield: record the claim before the caller adds cash in the same handler.
		data.collectionClaims[id] = true
		return milestone.reward
	end
	return rules
end
