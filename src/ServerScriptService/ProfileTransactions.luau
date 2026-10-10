-- UpdateAsync transforms. Returning nil cancels writes on lock/schema failure.
return function(schema)
	local rules = {}
	local function inspect(record)
		if record == nil then return {version = 1, data = schema.New()} end
		if type(record) ~= "table" or record.version ~= 1 then return nil, "Unsupported profile version" end
		local data, reason = schema.Validate(record.data)
		if not data then return nil, reason end
		local lock = record.lock
		if lock ~= nil and (type(lock) ~= "table" or type(lock.token) ~= "string" or type(lock.expires) ~= "number"
			or lock.expires ~= lock.expires or lock.expires <= 0 or lock.expires == math.huge) then
			return nil, "Invalid session lock"
		end
		return {version = 1, data = data, lock = lock}
	end
	function rules.Acquire(record, token, now, lease)
		local valid, reason = inspect(record)
		if not valid then return nil, reason end
		if valid.lock and valid.lock.token ~= token and valid.lock.expires > now then return nil, "Profile in another server" end
		valid.lock = {token = token, expires = now + lease}
		return valid
	end
	function rules.Commit(record, token, snapshot, now, lease, release)
		-- A missing record is never treated as a successful ownership check on save.
		if record == nil then return nil, "Profile disappeared" end
		local valid, reason = inspect(record)
		if not valid then return nil, reason end
		if not valid.lock or valid.lock.token ~= token then return nil, "Session ownership lost" end
		local copy, errorMessage = schema.Validate(snapshot)
		if not copy then return nil, errorMessage end
		return {version = 1, data = copy, lock = not release and {token = token, expires = now + lease} or nil}
	end
	return rules
end
