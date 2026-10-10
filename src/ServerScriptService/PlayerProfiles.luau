local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local config = require(script.Parent:WaitForChild("PersistenceConfig"))
local schema = require(script.Parent:WaitForChild("ProfileSchema"))(require(RS:WaitForChild("ItemCatalog")))
local transactions = require(script.Parent:WaitForChild("ProfileTransactions"))(schema)
local preview = RunService:IsStudio() and not config.StudioPersistenceEnabled
local store = not preview and DataStoreService:GetDataStore(RunService:IsStudio() and config.StudioDataStoreName or config.DataStoreName) or nil
local profiles = {}
local shuttingDown = false
local pendingLoads = 0
local service = {}

local function status(player, value)
	player:SetAttribute("SaveStatus", value)
end
local function update(key, transform)
	local reason
	for attempt = 1, config.Attempts do
		local ok, record = pcall(function()
			return store:UpdateAsync(key, function(current)
				local nextRecord, message = transform(current)
				reason = message
				return nextRecord
			end)
		end)
		if ok then return record, reason end
		reason = "DataStore request failed"
		warn("PlayerProfiles: request attempt " .. attempt .. " failed: " .. tostring(record))
		if attempt < config.Attempts then task.wait(2 ^ (attempt - 1)) end
	end
	return nil, reason
end
function service.Load(player)
	if shuttingDown then return nil, "Server shutting down" end
	pendingLoads += 1
	status(player, "Loading")
	player:SetAttribute("DataReady", false)
	local profile = {Key = "player_" .. player.UserId, Token = HttpService:GenerateGUID(false), LastConfirmed = os.clock()}
	if preview then
		profile.Data = schema.New()
		profile.Preview = true
	else
		local record, reason = update(profile.Key, function(current)
			return transactions.Acquire(current, profile.Token, os.time(), config.LeaseSeconds)
		end)
		if not record or not record.lock or record.lock.token ~= profile.Token then
			status(player, "Load failed")
			pendingLoads -= 1
			return nil, reason or "Unable to acquire profile"
		end
		local data, recovered = schema.Recover(record.data)
		if not data then
			-- Release the acquired lock without rewriting unusable progress.
			update(profile.Key, function(current)
				return transactions.Commit(current, profile.Token, record.data, os.time(), config.LeaseSeconds, true)
			end)
			pendingLoads -= 1
			return nil, "Unable to recover profile"
		end
		profile.Data = data
		profile.Recovered = recovered
	end
	profile.LastConfirmed = os.clock()
	profiles[player] = profile
	status(player, preview and "Studio preview" or "Loaded")
	player:SetAttribute("DataReady", true)
	pendingLoads -= 1
	if shuttingDown or player.Parent ~= Players then
		service.Close(player)
		return nil, "Player session ended while loading"
	end
	return profile
end
function service.Get(player) return profiles[player] end
function service.Save(player, release)
	local profile = profiles[player]
	if not profile or profile.Busy then return false end
	profile.Busy = true
	if profile.Preview then
		profile.Busy = false
		status(player, "Studio preview")
		return true
	end
	local ok, snapshot = pcall(function() return profile.FinalSnapshot or (profile.Snapshot and profile.Snapshot() or profile.Data) end)
	if not ok then
		profile.Busy = false
		status(player, "Save failed")
		warn("PlayerProfiles: snapshot failed for " .. player.UserId)
		return false
	end
	local valid, validationError = schema.Validate(snapshot)
	if not valid then
		profile.Busy = false
		status(player, "Save failed")
		warn("PlayerProfiles: invalid snapshot: " .. tostring(validationError))
		return false
	end
	snapshot = valid -- Freeze cash/counts together before UpdateAsync can yield or retry.
	status(player, "Saving")
	local committed, reason = update(profile.Key, function(current)
		return transactions.Commit(current, profile.Token, snapshot, os.time(), config.LeaseSeconds, release)
	end)
	profile.Busy = false
	if committed then
		profile.LastConfirmed = os.clock()
		status(player, "Saved")
		if not profile.Closing then player:SetAttribute("DataReady", true) end
		return true
	end
	status(player, "Save retry needed")
	if reason == "Session ownership lost" then
		player:SetAttribute("DataReady", false)
		if player.Parent == Players then player:Kick("Your save session moved to another server. Please reconnect.") end
	end
	warn("PlayerProfiles: save not confirmed for " .. player.UserId .. ": " .. tostring(reason))
	return false
end
function service.Close(player)
	local profile = profiles[player]
	if not profile then return end
	if profile.Closing then
		local deadline = os.clock() + 20
		while profiles[player] == profile and os.clock() < deadline do task.wait(0.1) end
		return
	end
	profile.Closing = true
	player:SetAttribute("DataReady", false)
	local captured, snapshot = pcall(function() return profile.Snapshot and profile.Snapshot() or profile.Data end)
	if captured then profile.FinalSnapshot = schema.Validate(snapshot) end
	local deadline = os.clock() + 20
	while profile.Busy and os.clock() < deadline do task.wait(0.1) end
	if not profile.Busy then service.Save(player, true) end
	profiles[player] = nil
end
-- Separate tasks avoid one slow player's request delaying everybody's renewal.
task.spawn(function()
	while true do
		task.wait(config.AutosaveSeconds)
		for player, profile in pairs(profiles) do
			if not profile.Closing then task.spawn(service.Save, player, false) end
		end
	end
end)
task.spawn(function()
	while true do
		task.wait(1)
		for player, profile in pairs(profiles) do
			if not profile.Preview and os.clock() - profile.LastConfirmed >= config.LeaseSeconds - config.LeaseSafetySeconds then
				player:SetAttribute("DataReady", false)
				status(player, "Saving paused")
			end
		end
	end
end)
game:BindToClose(function()
	shuttingDown = true
	for player in pairs(profiles) do task.spawn(service.Close, player) end
	local deadline = os.clock() + 25
	while (next(profiles) or pendingLoads > 0) and os.clock() < deadline do task.wait(0.1) end
end)
return service
