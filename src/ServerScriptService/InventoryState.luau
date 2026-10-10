-- Pure session inventory rules, shared by the server handlers and standalone tests.
return function(catalog)
	local byId = {}
	for _, item in ipairs(catalog) do byId[item.id] = item end
	local rules = {}
	function rules.New()
		return {inventory = {}, discoveries = {}, pending = nil, lastRequest = -math.huge}
	end
	function rules.Discover(data, id)
		if data.pending or not byId[id] then return false end
		data.pending = id
		data.discoveries[id] = (data.discoveries[id] or 0) + 1
		return true
	end
	function rules.Resolve(data, decision)
		local item = data.pending and byId[data.pending]
		if not item or (decision ~= "Keep" and decision ~= "Sell") then return nil end
		data.pending = nil
		if decision == "Keep" then
			data.inventory[item.id] = (data.inventory[item.id] or 0) + 1
			return 0
		end
		return item.value
	end
	function rules.Sell(data, id)
		if type(id) ~= "string" or not byId[id] or (data.inventory[id] or 0) < 1 then return nil end
		data.inventory[id] -= 1
		return byId[id].value
	end
	return rules
end
