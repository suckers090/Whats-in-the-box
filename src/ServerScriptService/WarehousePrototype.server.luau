-- Existing package gameplay, now scoped to each player's warehouse plot.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local Registry = require(script.Parent:WaitForChild("PlotRegistry"))
local items = require(RS:WaitForChild("ItemCatalog"))
local function remote(name)
	local event = RS:FindFirstChild(name)
	if not event then event = Instance.new("RemoteEvent"); event.Name = name; event.Parent = RS end
	return event
end
local boxEvent = remote("BoxEvent")
local stateEvent = remote("WarehouseState")
local notice = remote("WarehouseNotice")
local rng = Random.new()
local sessions, loading = {}, {}
local Profiles = require(script.Parent:WaitForChild("PlayerProfiles"))
local Inventory = require(script.Parent:WaitForChild("InventoryState"))(items)
local Collection = require(script.Parent:WaitForChild("CollectionProgress"))(items,
	require(RS:WaitForChild("CollectionMilestones")))
local function pushState(player)
	local data = sessions[player]
	if not data or player.Parent ~= Players then return end
	local plot = Registry.Get(player)
	stateEvent:FireClient(player, {
		inventory = data.inventory, discoveries = data.discoveries,
		collectionClaims = data.collectionClaims,
		plot = plot and plot.Slot or 0, scanner = plot and plot.ScannerUnlocked or false,
	})
end
local function randomItem()
	local roll, total = rng:NextInteger(1, 100), 0
	for _, item in ipairs(items) do
		total += item.weight
		if roll <= total then return item end
	end
	return items[1]
end
boxEvent.OnServerEvent:Connect(function(player, decision)
	local data = sessions[player]
	if not data or player:GetAttribute("DataReady") ~= true then return end
	local earned = Inventory.Resolve(data, decision)
	if earned == nil then return end
	player.leaderstats.Cash.Value += earned
	boxEvent:FireClient(player, "Closed")
	pushState(player)
end)
stateEvent.OnServerEvent:Connect(function(player, action, id)
	local data = sessions[player]
	if not data then return end
	if action ~= "RequestState" and player:GetAttribute("DataReady") ~= true then return end
	local now = os.clock()
	if now - data.lastRequest < 0.2 then return end
	data.lastRequest = now
	if action == "RequestState" then
		pushState(player)
	elseif action == "ClaimCollection" then
		local earned, reason = Collection.Claim(data, id)
		if earned == nil then notice:FireClient(player, reason); return end
		player.leaderstats.Cash.Value += earned
		pushState(player)
		notice:FireClient(player, "Collection milestone / +$" .. earned)
	elseif action == "SellInventory" then
		local earned = Inventory.Sell(data, id)
		if earned == nil then return end
		player.leaderstats.Cash.Value += earned
		pushState(player)
		notice:FireClient(player, "Item sold for $" .. earned)
	elseif action == "BuyScanner" then
		local plot = Registry.Get(player)
		if plot and plot.PurchaseScanner then plot.PurchaseScanner(player) end
	elseif action == "GoHome" or action == "GoScanner" then
		local plot = Registry.Get(player)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if plot and character and humanoid and humanoid.Health > 0 then
			local target = plot.Spawn.CFrame + Vector3.new(0, 4, 0)
			if action == "GoScanner" then
				local pad = plot.ScannerPurchasePad
				if not pad or not pad:IsDescendantOf(plot.Model) then return end
				-- Stand beside the pad at its actual height, even when the marker is resized.
				target = pad.CFrame * CFrame.new(0, pad.Size.Y / 2 + 3, pad.Size.Z / 2 + 2)
			end
			character:PivotTo(target)
		end
	end
end)
local function runPlot(plot)
	if not plot.Model.Parent or Registry.Get(plot.Owner) ~= plot or plot.Owner.Parent ~= Players then return end
	local world = plot.Runtime
	local packageDrop = plot.Markers.PackageDrop
	local truckStop = plot.Markers.TruckStop
	local function makePart(name, size, cf, color, parent, material)
		local part = Instance.new("Part")
		part.Name = name; part.Size = size; part.CFrame = cf; part.Anchored = true
		part.Color = color; part.Material = material or Enum.Material.SmoothPlastic
		part.Parent = parent or world
		return part
	end
	-- TruckStop marks the rear bumper at dock level. Local +Z points toward the dock.
	-- The existing simple truck reverses into the dock, unloads, then drives back out.
	local truckTarget = truckStop.CFrame * CFrame.new(0, -truckStop.Size.Y / 2, -6.5)
	local truckStart = truckTarget * CFrame.new(0, 0, -29)
	local truck = Instance.new("Model")
	truck.Name = "DeliveryTruck"
	truck.Parent = world

	makePart("TruckBody", Vector3.new(9, 6, 13), truckStart * CFrame.new(0, 4, 0),
		Color3.fromRGB(52, 79, 98), truck)
	makePart("Cab", Vector3.new(9, 5, 5), truckStart * CFrame.new(0, 3.5, -11),
		Color3.fromRGB(37, 48, 65), truck)
	for _, x in ipairs({-4, 4}) do
		for _, z in ipairs({4, -10}) do
			local wheel = makePart("Wheel", Vector3.new(1, 2.5, 2.5),
				truckStart * CFrame.new(x, 1.25, z), Color3.fromRGB(25, 25, 30), truck)
			wheel.Shape = Enum.PartType.Cylinder
		end
	end
	-- Lightweight detailing without external assets or changes to the warehouse model.
	local glass = makePart("Windshield", Vector3.new(7.8, 2, 0.12),
		truckStart * CFrame.new(0, 4.2, -13.56), Color3.fromRGB(123, 168, 185), truck, Enum.Material.Glass)
	glass.Transparency = 0.3
	makePart("FrontBumper", Vector3.new(9.4, 0.6, 0.7),
		truckStart * CFrame.new(0, 1.6, -13.7), Color3.fromRGB(79, 88, 99), truck, Enum.Material.Metal)
	makePart("RearBumper", Vector3.new(9.4, 0.5, 0.5),
		truckStart * CFrame.new(0, 1.5, 6.7), Color3.fromRGB(79, 88, 99), truck, Enum.Material.Metal)
	for _, x in ipairs({-3.2, 3.2}) do
		makePart("Headlight", Vector3.new(1.1, 0.6, 0.12),
			truckStart * CFrame.new(x, 2.5, -13.56), Color3.fromRGB(224, 236, 247), truck, Enum.Material.Neon)
		makePart("RearLight", Vector3.new(0.8, 0.35, 0.12),
			truckStart * CFrame.new(x, 2.4, 6.56), Color3.fromRGB(211, 72, 66), truck, Enum.Material.Neon)
	end
	local body = truck:FindFirstChild("TruckBody")
	for _, face in ipairs({Enum.NormalId.Left, Enum.NormalId.Right}) do
		local sign = Instance.new("SurfaceGui")
		sign.Face = face
		sign.CanvasSize = Vector2.new(520, 240)
		sign.Parent = body
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextColor3 = Color3.fromRGB(229, 238, 247)
		label.TextSize = 38
		label.Text = "WHAT'S IN THE BOX?\nWAREHOUSE DELIVERY"
		label.Parent = sign
	end
	truck.WorldPivot = truckStart
	local truckAppearance = {}
	for _, part in ipairs(truck:GetDescendants()) do
		if part:IsA("BasePart") then
			truckAppearance[part] = part.Transparency
			-- This is an animated delivery prop, not a drivable physics vehicle.
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
		end
	end
	local function truckVisible(visible)
		for part, transparency in pairs(truckAppearance) do
			part.Transparency = visible and transparency or 1
		end
		for _, object in ipairs(truck:GetDescendants()) do
			if object:IsA("SurfaceGui") then object.Enabled = visible end
		end
	end
	truckVisible(false)

	-- PACKAGE FOLDER
	local packages = plot.Packages

	-- SPAWN MYSTERY PACKAGE
	local function spawnPackage(index)
		if not plot.Model.Parent then return end
		local x = (index - 2) * 5

		local box = makePart(
			"MysteryBox",
			Vector3.new(3, 3, 3),
			packageDrop.CFrame * CFrame.new(x, -packageDrop.Size.Y / 2 + 1.5, 0),
			Color3.fromRGB(185, 125, 65),
			packages
		)

		-- Decide the contents when the package arrives
		local prize = randomItem()
		plot.Prizes[box] = prize
		box.Destroying:Connect(function() plot.Prizes[box] = nil end)

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Open Box"
		prompt.ObjectText = "Mystery Package"
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = box

		local opened = false

		prompt.Triggered:Connect(function(player)
			if not Registry.CanInteract(plot, player, box, 10) then return end

			if opened or box:GetAttribute("SoldSealed") then
				return
			end

			if sessions[player].pending then
				boxEvent:FireClient(
					player,
					"Message",
					"Choose KEEP or SELL first!"
				)
				return
			end

			if not box.Parent then
				return
			end

			opened = true
			prompt.Enabled = false

			local item = prize
			local isNew = (sessions[player].discoveries[item.id] or 0) == 0
			Inventory.Discover(sessions[player], item.id)
			pushState(player)

			-- BOX REVEAL EFFECT
			box.Color = Color3.fromRGB(255, 220, 110)
			box.Material = Enum.Material.Neon

			local tween = TweenService:Create(
				box,
				TweenInfo.new(0.25),
				{
					Transparency = 1,
					Size = Vector3.new(0.5, 0.5, 0.5)
				}
			)

			tween:Play()
			tween.Completed:Wait()

			-- SEND ITEM TO PLAYER
			if player.Parent == Players then
				boxEvent:FireClient(player, "Reveal", {
					name = item.name,
					value = item.value,
					rarity = item.rarity,
					isNew = isNew,
				})
			end

			box:Destroy()

		end)
	end

	-- One controller per plot serializes arrival, unloading and departure.
	local destroyed = false
	local activeTween = nil
	local destroyedConnection = plot.Model.Destroying:Connect(function()
		destroyed = true
		if activeTween then activeTween:Cancel() end
	end)
	local function alive()
		return not destroyed and plot.Model.Parent ~= nil and Registry.Get(plot.Owner) == plot and plot.Owner.Parent == Players
	end
	local function setDeliveryPhase(phase, due)
		if not alive() then return end
		plot.Owner:SetAttribute("DeliveryPhase", phase)
		plot.Owner:SetAttribute("NextDeliveryAt", due or 0)
	end
	local function waitActive(seconds)
		local deadline = os.clock() + seconds
		while alive() and os.clock() < deadline do task.wait(math.min(0.1, deadline - os.clock())) end
		return alive()
	end
	local function moveTruck(target)
		if not alive() then return false end
		local driver = Instance.new("CFrameValue")
		driver.Value = truck:GetPivot()
		local connection = driver.Changed:Connect(function(frame)
			if alive() then truck:PivotTo(frame) end
		end)
		activeTween = TweenService:Create(driver,
			TweenInfo.new(5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Value = target})
		activeTween:Play()
		activeTween.Completed:Wait()
		connection:Disconnect()
		driver:Destroy()
		activeTween = nil
		if alive() then truck:PivotTo(target) end
		return alive()
	end
	-- DELIVERY CYCLE (also exercised by the standalone lifecycle regression test).
	local function deliver()
		setDeliveryPhase("Queued", workspace:GetServerTimeNow() + 3)
		if not waitActive(3) then return false end
		if plot.Owner:GetAttribute("DataReady") ~= true then return true end
		truck:PivotTo(truckStart)
		truckVisible(true)
		setDeliveryPhase("Arriving")
		if not moveTruck(truckTarget) then return false end
		setDeliveryPhase("Unloading")
		for index = 1, 3 do
			if not alive() then return false end
			spawnPackage(index)
			if not waitActive(0.5) then return false end
		end
		if plot.Owner.Parent == Players then notice:FireClient(plot.Owner, "Delivery complete / 3 mystery packages arrived.") end
		setDeliveryPhase("Departing")
		if not moveTruck(truckStart) then return false end
		truckVisible(false)
		setDeliveryPhase("Ready")
		return true
	end
	local function packageCount()
		if alive() then plot.Owner:SetAttribute("PackageCount", #packages:GetChildren()) end
	end
	local addedConnection = packages.ChildAdded:Connect(packageCount)
	local removedConnection = packages.ChildRemoved:Connect(packageCount)
	packageCount()
	while alive() do
		local data = sessions[plot.Owner]
		if not data then break end
		if plot.Owner:GetAttribute("DataReady") ~= true then
			setDeliveryPhase("Paused")
		elseif data.pending then
			setDeliveryPhase("Choose")
		elseif #packages:GetChildren() > 0 then
			setDeliveryPhase("Ready")
		elseif not deliver() then break end
		if not waitActive(0.25) then break end
	end
	addedConnection:Disconnect()
	removedConnection:Disconnect()
	destroyedConnection:Disconnect()

end
local function setupPlayer(player)
	if sessions[player] or loading[player] then return end
	loading[player] = true
	local profile, reason = Profiles.Load(player)
	loading[player] = nil
	if not profile then
		warn("WarehousePrototype: could not load profile for " .. player.UserId .. ": " .. tostring(reason))
		if player.Parent == Players then
			player:Kick("Your progress could not be loaded safely. Please try again shortly.")
		end
		return
	end
	if player.Parent ~= Players then Profiles.Close(player); return end
	sessions[player] = profile.Data
	sessions[player].lastRequest = -math.huge
	local stats = player:FindFirstChild("leaderstats") or Instance.new("Folder")
	stats.Name = "leaderstats"; stats.Parent = player
	local cash = stats:FindFirstChild("Cash") or Instance.new("IntValue")
	cash.Name = "Cash"; cash.Parent = stats
	cash.Value = profile.Data.cash
	local data = sessions[player]
	profile.Snapshot = function()
		local currentPlot = Registry.Get(player)
		return {cash = cash.Value, inventory = data.inventory, discoveries = data.discoveries,
			scanner = currentPlot and currentPlot.ScannerUnlocked or data.scanner, pending = data.pending,
			collectionClaims = data.collectionClaims}
	end
	local plot = Registry.Assign(player, profile.Data.scanner)
	if profile.Recovered then
		task.delay(3, function()
			if player.Parent == Players then notice:FireClient(player, "Your unfinished package reward was added to Inventory.") end
		end)
	end
	local function spawnAtHome(character)
		local root = character:WaitForChild("HumanoidRootPart", 10)
		if root and Registry.Get(player) == plot and character.Parent then
			character:PivotTo(plot.Spawn.CFrame + Vector3.new(0, 4, 0))
		end
	end
	player.CharacterAdded:Connect(spawnAtHome)
	if player.Character then task.spawn(spawnAtHome, player.Character) end
	pushState(player)
	task.spawn(runPlot, plot)
end
Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(player)
	Profiles.Close(player)
	sessions[player] = nil
	Registry.Release(player)
end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(setupPlayer, player) end
