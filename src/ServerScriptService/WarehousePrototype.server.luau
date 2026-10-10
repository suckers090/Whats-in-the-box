
-- What's in the Box? - Existing warehouse integration
-- ServerScriptService > WarehousePrototype

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")

-- The markers describe placement; their bottom faces are the placement surfaces.
local markers = workspace:WaitForChild("WarehouseMarkers", 10)
assert(markers and markers:IsA("Folder"), "Add Workspace.WarehouseMarkers before starting gameplay")

local function marker(name)
	local value = markers:FindFirstChild(name)
	assert(value and value:IsA("BasePart"), "Missing warehouse marker: " .. name)
	return value
end

local packageDrop = marker("PackageDrop")
local truckStop = marker("TruckStop")
marker("ScannerLocation") -- Validate the scanner prerequisite before starting delivery.

for _, value in ipairs(markers:GetChildren()) do
	if value:IsA("BasePart") then
		value.Transparency = 1
		value.CanCollide = false
		value.CanTouch = false
		value.CanQuery = false
	end
end

-- REMOTE EVENT
local boxEvent = RS:FindFirstChild("BoxEvent")

if not boxEvent then
	boxEvent = Instance.new("RemoteEvent")
	boxEvent.Name = "BoxEvent"
	boxEvent.Parent = RS
end

-- RANDOM ITEMS
local rng = Random.new()

local items = {
	{name = "Old Toy", value = 25, rarity = "Common", weight = 45},
	{name = "Headphones", value = 100, rarity = "Common", weight = 25},
	{name = "Gaming Console", value = 650, rarity = "Uncommon", weight = 17},
	{name = "Gold Watch", value = 2500, rarity = "Rare", weight = 10},
	{name = "Mysterious Device", value = 12000, rarity = "Legendary", weight = 3}
}

local pendingItems = {}
local collections = {}

local function randomItem()
	local roll = rng:NextInteger(1, 100)
	local total = 0

	for _, item in ipairs(items) do
		total += item.weight

		if roll <= total then
			return item
		end
	end

	return items[1]
end

-- PLAYER MONEY AND INVENTORY
local function setupPlayer(player)
	collections[player] = {}

	local stats = player:FindFirstChild("leaderstats")

	if not stats then
		stats = Instance.new("Folder")
		stats.Name = "leaderstats"
		stats.Parent = player
	end

	local cash = stats:FindFirstChild("Cash")

	if not cash then
		cash = Instance.new("IntValue")
		cash.Name = "Cash"
		cash.Value = 0
		cash.Parent = stats
	end
end

Players.PlayerAdded:Connect(setupPlayer)

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

Players.PlayerRemoving:Connect(function(player)
	pendingItems[player] = nil
	collections[player] = nil
end)

-- KEEP OR SELL SYSTEM
boxEvent.OnServerEvent:Connect(function(player, decision)
	local item = pendingItems[player]

	if not item then
		return
	end

	if decision == "Sell" then
		local stats = player:FindFirstChild("leaderstats")
		local cash = stats and stats:FindFirstChild("Cash")

		if not cash then
			return
		end

		cash.Value += item.value
		pendingItems[player] = nil

		boxEvent:FireClient(player, "Closed")

		print(player.Name .. " sold " .. item.name .. " for $" .. item.value)

	elseif decision == "Keep" then
		local collection = collections[player]

		if not collection then
			return
		end

		table.insert(collection, item.name)
		pendingItems[player] = nil

		boxEvent:FireClient(player, "Closed")

		print(player.Name .. " kept " .. item.name)
	end
end)

-- Runtime objects only. The imported warehouse and existing spawn stay untouched.
assert(not workspace:FindFirstChild("WarehousePrototype"), "WarehousePrototype runtime folder already exists; stop Play before restarting")
local world = Instance.new("Folder")
world.Name = "WarehousePrototype" -- Retained for ScannerUpgrade's existing dependency.
world.Parent = workspace

local function makePart(name, size, cf, color, parent, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Parent = parent or world
	return p
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
local packages = Instance.new("Folder")
packages.Name = "Packages"
packages.Parent = world

-- SPAWN MYSTERY PACKAGE
local function spawnPackage(index)
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
	box:SetAttribute("PrizeValue", prize.value)
	box:SetAttribute("PrizeRarity", prize.rarity)

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

		if opened or box:GetAttribute("SoldSealed") then
			return
		end

		if pendingItems[player] then
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
		pendingItems[player] = item

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
		truck:PivotTo(cf)
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
		spawnPackage(i)
		task.wait(0.5)
	end

	print("Delivery complete! Three packages arrived.")
end

-- INITIAL DELIVERY
task.wait(3)
deliver()

print("What's in the Box? v0.2 loaded!")

-- AUTOMATIC PACKAGE RESTOCK
task.spawn(function()
	while true do
		task.wait(5)

		if #packages:GetChildren() == 0 then

			print("Preparing next delivery...")
			task.wait(3)

			for i = 1, 3 do
				spawnPackage(i)
				task.wait(0.5)
			end

			print("New packages delivered!")
		end
	end
end)
