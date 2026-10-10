
-- What's in the Box? v0.3 - 3D Item Reveals
-- StarterPlayer > StarterPlayerScripts > BoxClient

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local event = RS:WaitForChild("BoxEvent")

local theme = require(RS:WaitForChild("UITheme"))
local colors = theme.Rarity

local gui = Instance.new("ScreenGui")
gui.Name = "BoxRevealUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.Parent = player:WaitForChild("PlayerGui")

local backdrop = Instance.new("Frame")
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
backdrop.BackgroundTransparency = 0.4
backdrop.Visible = false
backdrop.Parent = gui

local frame = Instance.new("Frame")
frame.Name = "RevealPanel"
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.fromScale(0.5, 0.5)
frame.Size = UDim2.fromScale(0.88, 0.75)
frame.BackgroundColor3 = theme.Background
frame.Parent = backdrop

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)

local constraint = Instance.new("UISizeConstraint")
constraint.MinSize = Vector2.new(250, 300)
constraint.MaxSize = Vector2.new(440, 500)
constraint.Parent = frame

local scale = Instance.new("UIScale")
scale.Scale = 1
scale.Parent = frame

local function label(name, text, y, height)
	local t = Instance.new("TextLabel")
	t.Name = name
	t.Size = UDim2.fromScale(0.9, height)
	t.Position = UDim2.fromScale(0.05, y)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBold
	t.Text = text
	t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1)
	t.Parent = frame
	return t
end

label("Title", "PACKAGE OPENED!", 0.03, 0.09)
local rarityLabel = label("Rarity", "", 0.13, 0.09)
local revealStroke = Instance.new("UIStroke")
revealStroke.Thickness = 2
revealStroke.Transparency = 0.35
revealStroke.Parent = frame

-- 3D item display
local viewport = Instance.new("ViewportFrame")
viewport.Name = "ItemPreview"
viewport.Size = UDim2.fromScale(0.86, 0.43)
viewport.Position = UDim2.fromScale(0.07, 0.24)
viewport.BackgroundColor3 = theme.Panel
viewport.BorderSizePixel = 0
viewport.Ambient = Color3.fromRGB(190, 190, 190)
viewport.LightColor = Color3.new(1, 1, 1)
viewport.LightDirection = Vector3.new(-1, -1, -1)
viewport.Parent = frame
Instance.new("UICorner", viewport).CornerRadius = UDim.new(0, 12)

local camera = Instance.new("Camera")
camera.FieldOfView = 45
camera.CFrame = CFrame.lookAt(
	Vector3.new(6, 4, 9),
	Vector3.new(0, 0, 0)
)
camera.Parent = viewport
viewport.CurrentCamera = camera

local world = Instance.new("WorldModel")
world.Parent = viewport

local itemName = label("ItemName", "", 0.68, 0.085)
local valueLabel = label("Value", "", 0.77, 0.07)

local function button(name, title, x, color)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Size = UDim2.fromScale(0.42, 0.1)
	b.Position = UDim2.fromScale(x, 0.88)
	b.BackgroundColor3 = color
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Text = title
	b.TextScaled = true
	b.Font = Enum.Font.GothamBlack
	b.Selectable = true
	b.Parent = frame
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
	return b
end

local keepButton = button(
	"Keep", "KEEP", 0.05,
	theme.Accent
)

local sellButton = button(
	"Sell", "SELL", 0.53,
	theme.Success
)

local currentModel = nil
local rotation = 0
local waiting = false
local previousSelection = nil

-- Build simple 3D item models
local function buildItem(name)
	world:ClearAllChildren()

	local model = Instance.new("Model")
	model.Name = "Prize"
	model.Parent = world

	local function part(size, position, color, shape)
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.Size = size
		p.Position = position
		p.Color = color
		p.Material = Enum.Material.SmoothPlastic
		if shape then
			p.Shape = shape
		end
		p.Parent = model
		return p
	end

	if name == "Old Toy" then
		-- Small toy robot
		part(Vector3.new(1.5, 1.5, 0.9),
			Vector3.new(0, -0.1, 0),
			Color3.fromRGB(230, 75, 70))
		part(Vector3.new(1.2, 1, 1),
			Vector3.new(0, 1.2, 0),
			Color3.fromRGB(250, 205, 70))
		for _, x in ipairs({-0.35, 0.35}) do
			part(Vector3.new(0.2, 0.2, 0.15),
				Vector3.new(x, 1.3, 0.55),
				Color3.fromRGB(25, 35, 50))
			part(Vector3.new(0.4, 0.9, 0.5),
				Vector3.new(x * 1.2, -1.3, 0),
				Color3.fromRGB(65, 120, 235))
		end

	elseif name == "Headphones" then
		part(Vector3.new(2.4, 0.4, 0.6),
			Vector3.new(0, 1.2, 0),
			Color3.fromRGB(45, 50, 65))
		for _, x in ipairs({-1.1, 1.1}) do
			part(Vector3.new(0.5, 1.6, 0.8),
				Vector3.new(x, 0.4, 0),
				Color3.fromRGB(55, 150, 245))
		end

	elseif name == "Gaming Console" then
		part(Vector3.new(2.4, 2.8, 0.65),
			Vector3.new(0, 0, 0),
			Color3.fromRGB(230, 235, 245))
		part(Vector3.new(1.35, 2.5, 0.75),
			Vector3.new(0, 0, 0.15),
			Color3.fromRGB(25, 30, 45))
		part(Vector3.new(1.2, 0.55, 0.3),
			Vector3.new(0, -1.65, 0.7),
			Color3.fromRGB(220, 225, 235))

	elseif name == "Gold Watch" then
		part(Vector3.new(0.75, 3.3, 0.25),
			Vector3.new(0, 0, 0),
			Color3.fromRGB(210, 155, 35))
		part(Vector3.new(1.65, 1.65, 0.45),
			Vector3.new(0, 0, 0.25),
			Color3.fromRGB(250, 195, 55),
			Enum.PartType.Ball)
		part(Vector3.new(1.1, 1.1, 0.25),
			Vector3.new(0, 0, 0.58),
			Color3.fromRGB(30, 40, 60),
			Enum.PartType.Ball)

	else
		-- Legendary mysterious device
		local core = part(
			Vector3.new(1.8, 1.8, 1.8),
			Vector3.new(0, 0, 0),
			Color3.fromRGB(170, 65, 255),
			Enum.PartType.Ball
		)
		core.Material = Enum.Material.Neon

		for _, x in ipairs({-1.3, 1.3}) do
			part(Vector3.new(0.5, 2.5, 0.5),
				Vector3.new(x, 0, 0),
				Color3.fromRGB(60, 65, 85))
		end

		part(Vector3.new(3.2, 0.35, 2),
			Vector3.new(0, -1.55, 0),
			Color3.fromRGB(45, 50, 75))
	end

	currentModel = model
	rotation = 0
	return model
end

RunService.RenderStepped:Connect(function(dt)
	if backdrop.Visible and currentModel then
		rotation += dt * 0.65
		currentModel:PivotTo(CFrame.Angles(0, rotation, 0))
	end
end)

local function choose(decision)
	if not backdrop.Visible or waiting then return end
	waiting = true
	event:FireServer(decision)
end

keepButton.Activated:Connect(function()
	choose("Keep")
end)

sellButton.Activated:Connect(function()
	choose("Sell")
end)

event.OnClientEvent:Connect(function(action, data)
	if action == "Reveal" then
		waiting = false

		local color = colors[data.rarity]
			or Color3.new(1, 1, 1)

		revealStroke.Color = color
		revealStroke.Transparency = 0.05
		TweenService:Create(revealStroke, TweenInfo.new(0.6), {Transparency = 0.4}):Play()
		rarityLabel.Text = string.upper(data.rarity)
		rarityLabel.TextColor3 = color
		itemName.Text = data.name
		valueLabel.Text = "VALUE: $" .. data.value
		valueLabel.TextColor3 = color
		viewport.BackgroundColor3 =
			theme.Panel

		buildItem(data.name)

		backdrop.Visible = true

		scale.Scale = 0.8
		TweenService:Create(
			scale,
			TweenInfo.new(data.rarity == "Legendary" and 0.6 or 0.3, Enum.EasingStyle.Back),
			{Scale = 1}
		):Play()

		previousSelection = GuiService.SelectedObject
		GuiService.SelectedObject = keepButton

	elseif action == "Closed" then
		backdrop.Visible = false
		waiting = false
		currentModel = nil
		world:ClearAllChildren()

		if GuiService.SelectedObject == keepButton
			or GuiService.SelectedObject == sellButton then
			GuiService.SelectedObject = previousSelection
		end

	elseif action == "Message" then
		warn(data)
	end
end)

print("3D Box Reveal v0.3 loaded!")
