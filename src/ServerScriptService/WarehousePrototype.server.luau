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
local sessions = {}
local Inventory = require(script.Parent:WaitForChild("InventoryState"))(items)
local function pushState(player)
	local data = sessions[player]
	if not data or player.Parent ~= Players then return end
	local plot = Registry.Get(player)
	stateEvent:FireClient(player, {
		inventory = data.inventory, discoveries = data.discoveries,
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
	if not data then return end
	local earned = Inventory.Resolve(data, decision)
	if earned == nil then return end
	player.leaderstats.Cash.Value += earned
	boxEvent:FireClient(player, "Closed")
	pushState(player)
end)
stateEvent.OnServerEvent:Connect(function(player, action, id)
	local data = sessions[player]
	if not data then return end
	local now = os.clock()
	if now - data.lastRequest < 0.2 then return end
	data.lastRequest = now
	if action == "RequestState" then
		pushState(player)
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
			local target = action == "GoScanner" and plot.Markers.ScannerLocation.CFrame * CFrame.new(5, 3, 3) or plot.Spawn.CFrame + Vector3.new(0, 4, 0)
			character:PivotTo(target)
		end
	end
end)
local function runPlot(plot)
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
	-- Keep the original simple truck; it reverses into the dock on the initial delivery.
	local truckTarget = truckStop.CFrame * CFrame.new(0, -truckStop.Size.Y / 2, -6.5)
	local truckStart = truckTarget * CFrame.new(0, 0, -29)
	local truck = Instance.new("Model")
	truck.Name = "DeliveryTruck"
	truck.Parent = world

	makePart("TruckBody", Vector3.new(9, 6, 13), truckStart * CFrame.new(0, 4, 0),
		Color3.fromRGB(45, 145, 240), truck)
	makePart("Cab", Vector3.new(9, 5, 5), truckStart * CFrame.new(0, 3.5, -11),
		Color3.fromRGB(35, 110, 200), truck)
	for _, x in ipairs({-4, 4}) do
		for _, z in ipairs({4, -10}) do
			local wheel = makePart("Wheel", Vector3.new(1, 2.5, 2.5),
				truckStart * CFrame.new(x, 1.25, z), Color3.fromRGB(25, 25, 30), truck)
			wheel.Shape = Enum.PartType.Cylinder
		end
	end
	truck.WorldPivot = truckStart

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
					rarity = item.rarity
				})
			end

			box:Destroy()

		end)
	end

	-- DELIVERY ANIMATION
	local function deliver()
		print("Delivery truck arriving!")

		local startPivot = truck:GetPivot()
		local targetPivot = truckTarget

		local driver = Instance.new("CFrameValue")
		driver.Value = startPivot

		local connection = driver.Changed:Connect(function(cf)
			if truck.Parent then truck:PivotTo(cf) end
		end)

		local tween = TweenService:Create(
			driver,
			TweenInfo.new(5, Enum.EasingStyle.Linear),
			{Value = targetPivot}
		)

		tween:Play()
		tween.Completed:Wait()

		connection:Disconnect()
		driver:Destroy()

		task.wait(1)

		-- FIRST THREE PACKAGES
		for i = 1, 3 do
			if not plot.Model.Parent then return end
			spawnPackage(i)
			task.wait(0.5)
		end

		print("Delivery complete! Three packages arrived.")
	end

	task.wait(3)
	if not plot.Model.Parent then return end
	deliver()
	-- AUTOMATIC PACKAGE RESTOCK
	task.spawn(function()
		while plot.Model.Parent do
			task.wait(5)

			if plot.Model.Parent and #packages:GetChildren() == 0 then

				print("Preparing next delivery...")
				task.wait(3)

				for i = 1, 3 do
					if not plot.Model.Parent then return end
					spawnPackage(i)
					task.wait(0.5)
				end

				print("New packages delivered!")
			end
		end
	end)

end
local function setupPlayer(player)
	if sessions[player] then return end
	sessions[player] = Inventory.New()
	local stats = player:FindFirstChild("leaderstats") or Instance.new("Folder")
	stats.Name = "leaderstats"; stats.Parent = player
	local cash = stats:FindFirstChild("Cash") or Instance.new("IntValue")
	cash.Name = "Cash"; cash.Parent = stats
	local plot = Registry.Assign(player)
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
	sessions[player] = nil
	Registry.Release(player)
end)
for _, player in ipairs(Players:GetPlayers()) do setupPlayer(player) end
