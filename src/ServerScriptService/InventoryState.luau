-- Pure session inventory rules, shared by the server handlers and standalone tests.
return function(catalog)
	local byId = {}
	for _, item in ipairs(catalog) do byId[item.id] = item end
	local rules = {}
	function rules.New()
		return {inventory = {}, discoveries = {}, inventoryLocks = {}, inventoryFavorites = {}, pending = nil, lastRequest = -math.huge}
	end
	local function locked(data, id) return data.inventoryLocks and data.inventoryLocks[id] == true end
	function rules.SetFlag(data, id, flag, enabled)
		if type(id) ~= "string" or not byId[id] or (data.inventory[id] or 0) < 1 then
			return false, "That item is not in your inventory."
		end
		if (flag ~= "Lock" and flag ~= "Favorite") or type(enabled) ~= "boolean" then return false, "Invalid item preference." end
		local key = flag == "Lock" and "inventoryLocks" or "inventoryFavorites"
		data[key] = data[key] or {}
		data[key][id] = enabled and true or nil
		return true
	end
	function rules.Discover(data, id)
		if data.pending or not byId[id] then return false end
		data.pending = id
		data.discoveries[id] = (data.discoveries[id] or 0) + 1
		return true
	end
	function rules.Resolve(data, decision, availableCredit)
		local item = data.pending and byId[data.pending]
		if not item or (decision ~= "Keep" and decision ~= "Sell") then return nil end
		if decision == "Sell" and locked(data, item.id) then return nil, "This item is locked. Choose KEEP to protect your collection." end
		if decision == "Sell" and availableCredit and item.value > availableCredit then return nil, "Cash limit reached. Choose KEEP." end
		if decision == "Keep" and (data.inventory[item.id] or 0) >= 1000000000 then return nil, "Stack limit reached." end
		data.pending = nil
		if decision == "Keep" then
			data.inventory[item.id] = (data.inventory[item.id] or 0) + 1
			return 0
		end
		return item.value
	end
	function rules.Sell(data, id, availableCredit)
		if type(id) ~= "string" or not byId[id] or (data.inventory[id] or 0) < 1 then return nil, "That item is no longer available." end
		if locked(data, id) then return nil, "Unlock this stack before selling." end
		if availableCredit and byId[id].value > availableCredit then return nil, "Cash limit reached; nothing was sold." end
		data.inventory[id] -= 1
		return byId[id].value
	end
	function rules.QuoteDuplicates(data)
		local quantities, value, count = {}, 0, 0
		for _, item in ipairs(catalog) do
			local amount = (data.inventory[item.id] or 0) - 1
			if amount > 0 and not locked(data, item.id) and not (data.inventoryFavorites and data.inventoryFavorites[item.id]) then
				quantities[item.id] = amount
				value += amount * item.value
				count += amount
			end
		end
		return quantities, value, count
	end
	function rules.SellQuotedDuplicates(data, quantities, availableCredit)
		-- The server owns this quote. Validate the entire transaction before changing
		-- any stack; a stale count or newly protected item cancels the whole sale.
		local value, count = 0, 0
		for id, amount in pairs(quantities) do
			local item = byId[id]
			if not item or type(amount) ~= "number" or amount <= 0 or amount % 1 ~= 0
				or (data.inventory[id] or 0) ~= amount + 1 or locked(data, id)
				or (data.inventoryFavorites and data.inventoryFavorites[id]) then
				return nil, "Inventory changed. Review a new duplicates quote."
			end
			value += amount * item.value; count += amount
		end
		if count == 0 then return nil, "No unprotected duplicates to sell." end
		if value > availableCredit then return nil, "Cash limit reached; nothing was sold." end
		for id, amount in pairs(quantities) do data.inventory[id] -= amount end
		return value, count
	end
	return rules
end
