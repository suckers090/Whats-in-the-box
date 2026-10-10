-- Data validation and recovery are pure so failures can be regression-tested outside Roblox.
return function(catalog)
	local known = {}
	for _, item in ipairs(catalog) do known[item.id] = true end
	local schema = {}
	function schema.New()
		return {cash = 0, inventory = {}, discoveries = {}, scanner = false, pending = nil, collectionClaims = {}}
	end
	local function integer(value, limit)
		return type(value) == "number" and value == value and value >= 0 and value <= limit and value % 1 == 0
	end
	local function counts(source)
		if type(source) ~= "table" then return nil end
		local copy, size = {}, 0
		for id, count in pairs(source) do
			size += 1
			if size > 256 or type(id) ~= "string" or #id < 1 or #id > 64 or not integer(count, 1000000000) then return nil end
			copy[id] = count -- Preserve valid unknown IDs for future catalog changes.
		end
		return copy
	end
	function schema.Validate(data)
		if type(data) ~= "table" or not integer(data.cash, 1000000000000) or type(data.scanner) ~= "boolean" then
			return nil, "Invalid cash or upgrade data"
		end
		local inventory, discoveries = counts(data.inventory), counts(data.discoveries)
		if not inventory or not discoveries then return nil, "Invalid inventory or discoveries" end
		if data.pending ~= nil and (type(data.pending) ~= "string" or not known[data.pending]) then
			return nil, "Unknown pending reward"
		end
		-- Old v1 saves have no claims field. Preserve valid future milestone IDs.
		local claims = {}
		if data.collectionClaims ~= nil then
			if type(data.collectionClaims) ~= "table" then return nil, "Invalid collection claims" end
			local size = 0
			for id, claimed in pairs(data.collectionClaims) do
				size += 1
				if size > 256 or type(id) ~= "string" or #id < 1 or #id > 64 or claimed ~= true then
					return nil, "Invalid collection claims"
				end
				claims[id] = true
			end
		end
		return {cash = data.cash, inventory = inventory, discoveries = discoveries,
			scanner = data.scanner, pending = data.pending, collectionClaims = claims}
	end
	function schema.Recover(data)
		local copy, reason = schema.Validate(data)
		if not copy then return nil, reason end
		local recovered = copy.pending
		if recovered then
			if (copy.inventory[recovered] or 0) >= 1000000000 then return nil, "Inventory limit exceeded" end
			copy.inventory[recovered] = (copy.inventory[recovered] or 0) + 1
			copy.pending = nil
		end
		return copy, recovered
	end
	return schema
end
