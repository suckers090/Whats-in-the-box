
-- What's in the Box? - Prototype v0.2
-- ServerScriptService > WarehousePrototype

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")

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

-- CREATE WAREHOUSE
local old = workspace:FindFirstChild("WarehousePrototype")

if old then
	old:Destroy()
end

local world = Instance.new("Folder")
world.Name = "WarehousePrototype"
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

-- WAREHOUSE STRUCTURE
local concrete = Color3.fromRGB(110, 115, 125)
local wallColor = Color3.fromRGB(195, 200, 205)
local dark = Color3.fromRGB(40, 48, 60)

makePart(
	"WarehouseFloor",
	Vector3.new(54, 1, 48),
	CFrame.new(0, 0, 0),
	concrete
)

makePart(
	"BackWall",
	Vector3.new(54, 16, 1),
	CFrame.new(0, 8, 24),
	wallColor
)

makePart(
	"LeftWall",
	Vector3.new(1, 16, 48),
	CFrame.new(-27, 8, 0),
	wallColor
)

makePart(
	"RightWall",
	Vector3.new(1, 16, 48),
	CFrame.new(27, 8, 0),
	wallColor
)

-- FRONT WALL AND LOADING ENTRANCE
makePart(
	"FrontLeft",
	Vector3.new(17, 16, 1),
	CFrame.new(-18.5, 8, -24),
	wallColor
)

makePart(
	"FrontRight",
	Vector3.new(17, 16, 1),
	CFrame.new(18.5, 8, -24),
	wallColor
)

makePart(
	"FrontTop",
	Vector3.new(20, 5, 1),
	CFrame.new(0, 13.5, -24),
	wallColor
)

-- LOADING DOCK AND DRIVEWAY
makePart(
	"Driveway",
	Vector3.new(22, 0.3, 45),
	CFrame.new(0, -0.3, -47),
	dark
)

makePart(
	"LoadingPlatform",
	Vector3.new(16, 0.4, 8),
	CFrame.new(0, 0.45, -20),
	Color3.fromRGB(150, 150, 155)
)

-- INSPECTION TABLE
makePart(
	"InspectionTable",
	Vector3.new(8, 1, 5),
	CFrame.new(-12, 2.5, 5),
	Color3.fromRGB(140, 90, 55)
)

for _, offset in ipairs({
	Vector3.new(-3, -1.25, -2),
	Vector3.new(3, -1.25, -2),
	Vector3.new(-3, -1.25, 2),
	Vector3.new(3, -1.25, 2)
	}) do

	makePart(
		"TableLeg",
		Vector3.new(0.6, 2.5, 0.6),
		CFrame.new(-12, 2.5, 5) * CFrame.new(offset),
		dark
	)

end

-- DELIVERY TRUCK
local truck = Instance.new("Model")
truck.Name = "DeliveryTruck"
truck.Parent = world

makePart(
	"TruckBody",
	Vector3.new(9, 6, 13),
	CFrame.new(0, 4, -65),
	Color3.fromRGB(45, 145, 240),
	truck
)

makePart(
	"Cab",
	Vector3.new(9, 5, 5),
	CFrame.new(0, 3.5, -76),
	Color3.fromRGB(35, 110, 200),
	truck
)

-- TRUCK WHEELS
for _, x in ipairs({-4, 4}) do
	for _, z in ipairs({-61, -75}) do

		local wheel = makePart(
			"Wheel",
			Vector3.new(2.5, 1, 2.5),
			CFrame.new(x, 1.5, z)
				* CFrame.Angles(0, 0, math.rad(90)),
			Color3.fromRGB(25, 25, 30),
			truck
		)

		wheel.Shape = Enum.PartType.Cylinder

	end
end

-- PACKAGE FOLDER
local packages = Instance.new("Folder")
packages.Name = "Packages"
packages.Parent = world

-- SPAWN MYSTERY PACKAGE
local function spawnPackage(index)
	local x = -5 + (index - 1) * 5

	local box = makePart(
		"MysteryBox",
		Vector3.new(3, 3, 3),
		CFrame.new(x, 2, -13),
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
	local targetPivot = startPivot + Vector3.new(0, 0, 29)

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

-- PLAYER SPAWN
local spawn = Instance.new("SpawnLocation")
spawn.Name = "WarehouseSpawn"
spawn.Size = Vector3.new(6, 1, 6)
spawn.Position = Vector3.new(0, 1, 12)
spawn.Anchored = true
spawn.Neutral = true
spawn.Parent = world

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
