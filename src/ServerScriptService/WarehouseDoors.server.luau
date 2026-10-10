-- Door interactions for the existing Blender warehouse. All movement runs on the server.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local INTERACTION_DISTANCE = 12
local EMPLOYEE_OPEN_ANGLE = math.rad(90)
local EMPLOYEE_DURATION = 0.8
local GARAGE_DURATION = 2

local Registry = require(script.Parent:WaitForChild("PlotRegistry"))

local function notify(player, message)
	local event = ReplicatedStorage:FindFirstChild("WarehouseNotice")
	if event and event:IsA("RemoteEvent") then
		event:FireClient(player, message)
	end
end

local function configureDoor(warehouse, panelName, title, duration, garage)
	local panel = warehouse:FindFirstChild(panelName)
	if not panel or not panel:IsA("BasePart") then
		warn("WarehouseDoors: missing panel " .. panelName)
		return
	end

	-- Parenting MeshParts does not make them follow their parent. Move every captured part.
	local closed = panel.CFrame
	local parts = {panel}
	for _, child in ipairs(panel:GetDescendants()) do
		if child:IsA("BasePart") then
			table.insert(parts, child)
		end
	end
	local offsets = {}
	for _, part in ipairs(parts) do
		offsets[part] = closed:ToObjectSpace(part.CFrame)
		part.Anchored = true
	end

	-- Right hinge as viewed from outside is local -X, nearest the garage in this model.
	-- Local +Z points into the warehouse. Positive yaw swings this panel outward.
	local hinge = closed * CFrame.new(-panel.Size.X / 2, 0, 0)
	local hingeOffset = hinge:ToObjectSpace(closed)
	local lift = panel.Size.Y + 0.5
	local function pose(alpha)
		if garage then
			return closed * CFrame.new(0, lift * alpha, 0)
		end
		return hinge * CFrame.Angles(0, EMPLOYEE_OPEN_ANGLE * alpha, 0) * hingeOffset
	end

	-- A stationary control stays reachable when the garage panel lifts above the player.
	local control = Instance.new("Part")
	control.Name = panelName .. "Control"
	control.Size = Vector3.new(0.2, 0.2, 0.2)
	control.Transparency = 1
	control.Anchored = true
	control.CanCollide = false
	control.CanTouch = false
	control.CanQuery = false
	local controlX = garage and (panel.Size.X / 2 + 0.6) or 0
	control.CFrame = closed * CFrame.new(controlX, -panel.Size.Y / 2 + 3, -0.8)
	control.Parent = warehouse

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "DoorPrompt"
	prompt.ActionText = "Open"
	prompt.ObjectText = title
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.MaxActivationDistance = INTERACTION_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.Parent = control

	local open = false
	local busy = false
	panel:SetAttribute("DoorOpen", false)
	panel:SetAttribute("DoorBusy", false)
	local function setCollision(enabled)
		-- Door panels block the closed opening. Decorative handles/slats remain noncolliding.
		panel.CanCollide = enabled
		for _, part in ipairs(parts) do
			if part ~= panel then
				part.CanCollide = false
			end
		end
	end
	setCollision(true)

	local function doorwayOccupied()
		local characters = {}
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character then
				table.insert(characters, player.Character)
			end
		end
		if #characters == 0 then return false end
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = characters
		local hits = workspace:GetPartBoundsInBox(closed,
			panel.Size + Vector3.new(1, 0.5, 2), params)
		return #hits > 0
	end

	local function animate(from, to)
		local driver = Instance.new("NumberValue")
		driver.Value = from
		local function move(alpha)
			local frame = pose(alpha)
			for _, part in ipairs(parts) do
				part.CFrame = frame * offsets[part]
			end
		end
		local connection = driver.Changed:Connect(move)
		local tween = TweenService:Create(driver,
			TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{Value = to})
		tween:Play()
		tween.Completed:Wait()
		move(to)
		connection:Disconnect()
		driver:Destroy()
	end

	prompt.Triggered:Connect(function(player)
		if busy or not prompt.Enabled or player.Parent ~= Players then return end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then return end
		-- Check server-side distance as well as the prompt's client display range.
		if (root.Position - control.Position).Magnitude > INTERACTION_DISTANCE then return end
		if open and doorwayOccupied() then
			notify(player, "Move out of the doorway before closing it!")
			return
		end

		busy = true
		prompt.Enabled = false
		panel:SetAttribute("DoorBusy", true)
		setCollision(false)
		local nextOpen = not open
		animate(open and 1 or 0, nextOpen and 1 or 0)
		-- If someone enters during closing, reopen before restoring collision.
		if not nextOpen and doorwayOccupied() then
			animate(0, 1)
			nextOpen = true
			notify(player, "Door reopened: someone is in the doorway.")
		end
		open = nextOpen
		setCollision(not open)
		panel:SetAttribute("DoorOpen", open)
		panel:SetAttribute("DoorBusy", false)
		prompt.ActionText = open and "Close" or "Open"
		busy = false
		prompt.Enabled = true
	end)
end

local function setupPlot(plot)
	configureDoor(plot.Model, "EmployeeDoor_panel", "Employee Door", EMPLOYEE_DURATION, false)
	configureDoor(plot.Model, "GarageDoor_Panel", "Garage Door", GARAGE_DURATION, true)
end
Registry.Added:Connect(setupPlot)
for _, plot in ipairs(Registry.GetAll()) do setupPlot(plot) end
