
-- What's in the Box? v0.4
-- ServerScriptService > ScannerUpgrade

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local theme = require(RS:WaitForChild("UITheme"))

local noticeEvent = RS:FindFirstChild("WarehouseNotice")
if not noticeEvent then
	noticeEvent = Instance.new("RemoteEvent")
	noticeEvent.Name = "WarehouseNotice"
	noticeEvent.Parent = RS
end

local Registry = require(script.Parent:WaitForChild("PlotRegistry"))
local stateEvent = RS:WaitForChild("WarehouseState")
local function setupPlot(plot)
	local markers = plot.Markers
	local scannerLocation = markers.ScannerLocation
	local scannerFrame = scannerLocation.CFrame * CFrame.new(0, -scannerLocation.Size.Y / 2, 0)
	local world = plot.Runtime
	local packages = plot.Packages
	local SCANNER_PRICE = 2000
	local SEALED_PRICE = 120
	local scannerUnlocked = false

	local function notify(player, message)
		noticeEvent:FireClient(player, message)
	end

	local function part(name, size, position, color, parent)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = scannerFrame * CFrame.new(position)
		p.Color = color
		p.Anchored = true
		p.Material = Enum.Material.SmoothPlastic
		p.Parent = parent
		return p
	end

	local function addPrompt(parent, action, object)
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = action
		prompt.ObjectText = object
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = parent
		return prompt
	end

	-- Upgrade purchase station
	local purchasePad = part(
		"ScannerPurchase",
		Vector3.new(5, 0.6, 5),
		Vector3.new(5, 0.3, 0),
		theme.Accent,
		world
	)

	local purchasePrompt = addPrompt(
		purchasePad, "Buy Scanner - $2000", "Warehouse Upgrade"
	)

	local sign = Instance.new("BillboardGui")
	sign.Size = UDim2.fromOffset(210, 55)
	sign.StudsOffset = Vector3.new(0, 3, 0)
	sign.AlwaysOnTop = true
	sign.Parent = purchasePad

	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.fromScale(1, 1)
	signText.BackgroundTransparency = 1
	signText.Font = Enum.Font.GothamBlack
	signText.TextScaled = true
	signText.TextColor3 = theme.Text
	signText.TextStrokeTransparency = 0
	signText.Text = "PACKAGE SCANNER\n$2,000"
	signText.Parent = sign

	local function buildScanner()
		local scanner = Instance.new("Model")
		scanner.Name = "PackageScanner"
		scanner.Parent = world

		part(
			"ScannerBase",
			Vector3.new(3, 0.5, 2.5),
			Vector3.new(0, 0.25, 0),
			Color3.fromRGB(40, 50, 65),
			scanner
		)

		local screen = part(
			"ScannerScreen",
			Vector3.new(2.6, 2, 0.35),
			Vector3.new(0, 1.45, -0.7),
			Color3.fromRGB(35, 180, 255),
			scanner
		)
		screen.Material = Enum.Material.Neon

		part(
			"ScannerSensor",
			Vector3.new(1.8, 0.3, 1),
			Vector3.new(0, 0.65, 0.3),
			Color3.fromRGB(90, 105, 125),
			scanner
		)

		local glow = Instance.new("PointLight")
		glow.Color = Color3.fromRGB(30, 170, 255)
		glow.Range = 8
		glow.Brightness = 1
		glow.Parent = screen
	end

	local function getClue(value)
		if value < 150 then
			return "SCAN: Low value (under $150)"
		elseif value < 1000 then
			return "SCAN: Medium value ($150 - $999)"
		elseif value < 10000 then
			return "SCAN: High value ($1,000 - $9,999)"
		else
			return "SCAN: Exceptional value ($10,000+)"
		end
	end

	local function setupBox(box)
		if not box:IsA("BasePart") then return end
		if box:GetAttribute("UpgradeReady") then return end
		box:SetAttribute("UpgradeReady", true)

		local sealed = addPrompt(
			box,
			"Sell 120",
			"Package"
		)

		sealed.Name = "SealedSellPrompt"
		sealed.KeyboardKeyCode = Enum.KeyCode.F
		sealed.GamepadKeyCode = Enum.KeyCode.ButtonY
		sealed.Triggered:Connect(function(player)
			if not Registry.CanInteract(plot, player, box, 10) then return end
			if not box.Parent then return end
			if box:GetAttribute("SoldSealed") then return end

			local openPrompt = box:FindFirstChild("ProximityPrompt")

			if not openPrompt or not openPrompt.Enabled then
				return
			end

			local stats = player:FindFirstChild("leaderstats")
			local cash = stats and stats:FindFirstChild("Cash")
			if not cash then return end

			box:SetAttribute("SoldSealed", true)
			openPrompt.Enabled = false
			sealed.Enabled = false

			cash.Value += SEALED_PRICE
			notify(player, "Sold sealed package for $120!")
			box:Destroy()
		end)



		-- Create the scan interaction
		local scan = addPrompt(
			box,
			"Scan",
			"Package"
		)

		scan.Name = "ScanPrompt"
		scan.KeyboardKeyCode = Enum.KeyCode.R
		scan.GamepadKeyCode = Enum.KeyCode.ButtonB
		scan.Enabled = scannerUnlocked

		scan.Triggered:Connect(function(player)
			if not Registry.CanInteract(plot, player, box, 10) then return end
			if not scannerUnlocked then return end
			if not box.Parent then return end
			if box:GetAttribute("SoldSealed") then return end

			local prize = plot.Prizes[box]
			local value = prize and prize.value
			if type(value) ~= "number" then
				notify(player, "This package cannot be scanned!")
				return
			end

			notify(player, getClue(value))
		end)

	end

	for _, box in ipairs(packages:GetChildren()) do
		setupBox(box)
	end

	packages.ChildAdded:Connect(setupBox)

	local function buyScanner(player)
		if not Registry.CanInteract(plot, player, purchasePad, 10) then
			notify(player, "Visit your scanner station before purchasing.")
			return
		end
		if scannerUnlocked then
			notify(player, "Scanner already unlocked!")
			return
		end

		local stats = player:FindFirstChild("leaderstats")
		local cash = stats and stats:FindFirstChild("Cash")

		if not cash or cash.Value < SCANNER_PRICE then
			notify(player, "You need $2,000 to unlock the scanner!")
			return
		end

		cash.Value -= SCANNER_PRICE
		scannerUnlocked = true
		plot.ScannerUnlocked = true
		stateEvent:FireClient(player, {scanner = true})

		buildScanner()
		purchasePad.Color = Color3.fromRGB(70, 85, 105)
		purchasePrompt.Enabled = false
		signText.Text = "SCANNER UNLOCKED!"

		for _, box in ipairs(packages:GetChildren()) do
			local scan = box:FindFirstChild("ScanPrompt")
			if scan then
				scan.Enabled = true
			end
		end

		notify(player, "Package Scanner unlocked!")
		print(player.Name .. " unlocked the Package Scanner!")
	end
	plot.PurchaseScanner = buyScanner
	purchasePrompt.Triggered:Connect(buyScanner)

	print("Warehouse Upgrade v0.4 loaded!")

end
Registry.Added:Connect(setupPlot)
for _, plot in ipairs(Registry.GetAll()) do setupPlot(plot) end
