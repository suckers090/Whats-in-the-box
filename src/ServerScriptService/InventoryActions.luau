-- Server-only command rules. Quotes are private session state, not saved or client
-- supplied quantities/prices. No yields occur between item validation and removal.
return function(inventory, clock, newToken)
	local actions = {}
	local supported = {SellInventory = true, SetInventoryFlag = true, QuoteDuplicates = true, SellDuplicates = true}
	function actions.Supports(action) return type(action) == "string" and supported[action] == true end
	local function result(success, message, fields)
		local value = fields or {}
		value.success = success; value.message = message
		return value
	end
	function actions.Run(data, cash, action, id, payload)
		if not actions.Supports(action) then return result(false, "Unknown inventory action.") end
		local now = clock()
		if now - (data.lastInventoryRequest or -math.huge) < 0.15 then return result(false, "Please wait a moment and try again.") end
		data.lastInventoryRequest = now
		if type(cash) ~= "number" or cash ~= cash or cash < 0 or cash > 1000000000000 or cash % 1 ~= 0 then
			return result(false, "Inventory sales are temporarily unavailable.")
		end
		if action == "SetInventoryFlag" then
			if type(payload) ~= "table" then return result(false, "Invalid item preference.") end
			local ok, message = inventory.SetFlag(data, id, payload.flag, payload.enabled)
			if ok then data.saleQuote = nil end
			return result(ok, message or (payload.flag == "Lock" and (payload.enabled and "Stack locked." or "Stack unlocked.")
				or (payload.enabled and "Added to favorites." or "Removed from favorites.")))
		elseif action == "SellInventory" then
			local earned, reason = inventory.Sell(data, id, 1000000000000 - cash)
			if not earned then return result(false, reason) end
			data.saleQuote = nil
			return result(true, "Sold one item for $" .. earned .. ".", {cashDelta = earned, soldCount = 1})
		elseif action == "QuoteDuplicates" then
			local quantities, value, count = inventory.QuoteDuplicates(data)
			data.saleQuote = nil
			if count == 0 then return result(false, "No unprotected duplicates to sell. One of each item is kept.") end
			if value > 1000000000000 - cash then return result(false, "Cash limit reached; nothing was sold.") end
			local token = newToken()
			data.saleQuote = {token = token, quantities = quantities, expires = now + 20}
			return result(true, "Keep one of each item; locked and favorite stacks are excluded.",
				{quote = {token = token, value = value, count = count, validFor = 20}})
		end
		local quote = data.saleQuote
		if type(id) ~= "string" or not quote or id ~= quote.token then return result(false, "Review a duplicates quote before confirming.") end
		data.saleQuote = nil -- Single-use receipt, including rejected/expired confirmations.
		if now >= quote.expires then return result(false, "Quote expired. Review a new duplicates quote.") end
		local earned, count = inventory.SellQuotedDuplicates(data, quote.quantities, 1000000000000 - cash)
		if not earned then return result(false, count) end
		return result(true, "Sold " .. count .. " duplicates for $" .. earned .. ".", {cashDelta = earned, soldCount = count})
	end
	return actions
end
