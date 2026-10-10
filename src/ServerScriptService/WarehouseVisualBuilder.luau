-- Shared art builder used by runtime and the Studio plugin. No gameplay dependencies.
local Lighting = game:GetService("Lighting")
return function(theme, config)
	local builder = {}
	local bound = setmetatable({}, {__mode = "k"})
	function builder.ApplyLighting()
		if config.LightingEnabled then
			Lighting.ClockTime = 16.2
			Lighting.Brightness = 2.5
			Lighting.Ambient = Color3.fromRGB(91, 102, 118)
			Lighting.OutdoorAmbient = Color3.fromRGB(116, 129, 145)
			Lighting.ExposureCompensation = 0
			Lighting.EnvironmentDiffuseScale = 0.8
			Lighting.EnvironmentSpecularScale = 0.65
			Lighting.GlobalShadows = true
			Lighting.ShadowSoftness = 0.35
			-- Respect an existing artist-authored effect rather than stack another of its class.
			local function effect(class, name, properties)
				if Lighting:FindFirstChildOfClass(class) then return end
				local value = Instance.new(class)
				value.Name = name
				value:SetAttribute("WITB_VisualEffect", 1)
				for key, property in pairs(properties) do value[key] = property end
				value.Parent = Lighting
			end
			effect("Atmosphere", "WITB_Atmosphere", {Density = 0.18, Offset = 0.15,
				Color = Color3.fromRGB(198, 211, 224), Decay = Color3.fromRGB(142, 153, 169), Haze = 0.6, Glare = 0})
			effect("ColorCorrectionEffect", "WITB_Grade", {Brightness = 0.01, Contrast = 0.06,
				Saturation = -0.06, TintColor = Color3.fromRGB(247, 250, 255)})
			effect("BloomEffect", "WITB_Bloom", {Intensity = 0.12, Size = 18, Threshold = 1.8})
		end
	end
	local steel = Color3.fromRGB(54, 68, 82)
	local caution = Color3.fromRGB(215, 174, 74)
	local lampColor = Color3.fromRGB(224, 236, 248)

	function builder.BindPlot(plot, folder, interactive)
		local dockSign = folder:FindFirstChild("DockSign")
		local gui = dockSign and dockSign:FindFirstChildOfClass("SurfaceGui")
		local text = gui and gui:FindFirstChildOfClass("TextLabel")
		if text then text.Text = string.format("BAY %02d  /  WITB", plot.Slot) end
		if interactive == false then return end
		for _, name in ipairs({"EmployeeDoor_panel", "GarageDoor_Panel"}) do
			local door = plot.Model:FindFirstChild(name)
			local indicator = folder:FindFirstChild("DoorStatus_" .. name)
			if door and indicator and not bound[indicator] then
				bound[indicator] = true
				local function refresh()
					indicator.Color = door:GetAttribute("DoorBusy") and caution
						or (door:GetAttribute("DoorOpen") and theme.Success or theme.Accent)
				end
				local busy = door:GetAttributeChangedSignal("DoorBusy"):Connect(refresh)
				local open = door:GetAttributeChangedSignal("DoorOpen"):Connect(refresh)
				indicator.Destroying:Once(function() busy:Disconnect(); open:Disconnect(); bound[indicator] = nil end)
				refresh()
			end
		end
	end

	function builder.Decorate(plot, interactive)
		if not config.WorldEnabled or not plot.Model.Parent then return end
		local existing = plot.Runtime:FindFirstChild("VisualPolish")
		if existing then
			builder.BindPlot(plot, existing, interactive)
			return
		end
		local floor = plot.Model:FindFirstChild("WareHouse_Floor", true)
		local roof = plot.Model:FindFirstChild("Warehouse_Roof", true)
		if not floor or not floor:IsA("BasePart") or not roof or not roof:IsA("BasePart") then
			warn("WarehouseVisuals: floor/roof missing; skipped props for " .. plot.Model.Name)
			return
		end
		local folder = Instance.new("Folder")
		folder.Name = "VisualPolish"
		folder.Parent = plot.Runtime
		local function part(name, size, frame, color, material)
			local value = Instance.new("Part")
			value.Name = name; value.Size = size; value.CFrame = frame
			value.Color = color; value.Material = material or Enum.Material.Metal
			value.Anchored = true; value.CanCollide = false; value.CanTouch = false; value.CanQuery = false
			value.CastShadow = false
			value.Parent = folder
			return value
		end
		local function light(parent, range, brightness)
			local value = Instance.new("PointLight")
			value.Color = lampColor; value.Range = range; value.Brightness = brightness; value.Shadows = false
			value.Parent = parent
		end
		local function label(parent, message, face, color)
			local gui = Instance.new("SurfaceGui")
			gui.Face = face or Enum.NormalId.Front
			-- Uniform pixels per stud prevents square crates and thin floor signs
			-- from stretching the same fixed 600x180 canvas into different shapes.
			gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			gui.PixelsPerStud = 80
			gui.MaxDistance = 90; gui.LightInfluence = 0.3; gui.Parent = parent
			local text = Instance.new("TextLabel")
			text.Size = UDim2.fromScale(0.94, 0.88); text.Position = UDim2.fromScale(0.03, 0.06)
			if gui.Face == Enum.NormalId.Top then
				-- Top-face canvas X follows part Z; rotate the line along the strip's X.
				text.AnchorPoint = Vector2.new(0.5, 0.5)
				text.Position = UDim2.fromScale(0.5, 0.5)
				text.Size = UDim2.fromOffset(parent.Size.X * 80 * 0.94, parent.Size.Z * 80 * 0.8)
				text.Rotation = 90
			end
			text.BackgroundTransparency = 1; text.Text = message; text.TextColor3 = color or theme.Text
			text.Font = Enum.Font.GothamBold; text.TextScaled = true; text.Parent = gui
		end
		local base = floor.CFrame * CFrame.new(0, floor.Size.Y / 2, 0)
		local halfX, halfZ = floor.Size.X / 2, floor.Size.Z / 2
		-- Large removable surface layers make the room cohesive without repainting
		-- imported MeshParts/SurfaceAppearance assets or changing the collision floor.
		-- Set SurfaceFinishEnabled=false in VisualConfig to keep the original textures.
		if config.SurfaceFinishEnabled ~= false then
			part("FloorFinish", Vector3.new(floor.Size.X - 0.5, 0.02, floor.Size.Z - 0.5),
				base * CFrame.new(0, 0.008, 0), Color3.fromRGB(69, 79, 91), Enum.Material.Concrete)
			for _, side in ipairs({-1, 1}) do
				part("LowerWallPanel", Vector3.new(0.06, 5.2, floor.Size.Z - 1),
					base * CFrame.new(side * (halfX - 0.5), 2.8, 0), steel)
				part("WallCapRail", Vector3.new(0.12, 0.12, floor.Size.Z - 1),
					base * CFrame.new(side * (halfX - 0.45), 5.45, 0), theme.Accent)
			end
			part("LowerBackPanel", Vector3.new(floor.Size.X - 1, 5.2, 0.06),
				base * CFrame.new(0, 2.8, halfZ - 0.5), steel)
			part("BackCapRail", Vector3.new(floor.Size.X - 1, 0.12, 0.12),
				base * CFrame.new(0, 5.45, halfZ - 0.45), theme.Accent)
		end
		-- A central route stays clear. Shelves sit at the rear sides, away from all stations.
		if halfX >= 18 and halfZ >= 16 then
			for _, side in ipairs({-1, 1}) do
				local rack = base * CFrame.new(side * (halfX - 5), 0, halfZ - 5)
				for _, x in ipairs({-3.1, 3.1}) do
					for _, z in ipairs({-1.4, 1.4}) do
						part("RackUpright", Vector3.new(0.18, 7, 0.18), rack * CFrame.new(x, 3.5, z), steel)
					end
				end
				for _, y in ipairs({0.3, 3.1, 6}) do
					part("RackShelf", Vector3.new(6.6, 0.16, 3.2), rack * CFrame.new(0, y, 0), steel)
					for _, x in ipairs({-1.6, 1.6}) do
						local crate = part("StorageCrate", Vector3.new(2.5, 1.8, 2.2),
							rack * CFrame.new(x, y + 0.98, 0), Color3.fromRGB(113, 96, 76), Enum.Material.Wood)
						label(crate, "WITB\nSTORAGE", Enum.NormalId.Front, Color3.fromRGB(223, 216, 194))
					end
				end
			end
		end
		-- Four ceiling fixtures. Read roof underside, not the model pivot or door pose.
		for _, x in ipairs({-floor.Size.X * 0.24, floor.Size.X * 0.24}) do
			for _, z in ipairs({-floor.Size.Z * 0.22, floor.Size.Z * 0.22}) do
				local frame = roof.CFrame * CFrame.new(x, -roof.Size.Y / 2 - 0.3, z)
				part("CeilingHousing", Vector3.new(5, 0.35, 1.1), frame, steel)
				local panel = part("CeilingDiffuser", Vector3.new(4.6, 0.06, 0.8), frame * CFrame.new(0, -0.2, 0), lampColor, Enum.Material.Neon)
				light(panel, 28, 1.5)
			end
		end
		-- Add light emitters at existing exterior fixtures without repainting the mesh.
		for _, name in ipairs({"EmployeeLight_Panel", "EmployeeLight_Panel.001"}) do
			local existing = plot.Model:FindFirstChild(name, true)
			if existing and existing:IsA("BasePart") then
				local bulb = part("ExteriorDiffuser", Vector3.new(1.4, 0.06, 0.5),
					existing.CFrame * CFrame.new(0, -existing.Size.Y / 2 - 0.04, 0), lampColor, Enum.Material.Neon)
				light(bulb, 17, 1.1)
			end
		end
		local drop = plot.Markers.PackageDrop
		local dropBase = drop.CFrame * CFrame.new(0, -drop.Size.Y / 2 + 0.02, 0)
		for _, x in ipairs({-8, 8}) do
			part("ReceivingBoundary", Vector3.new(0.12, 0.025, 5), dropBase * CFrame.new(x, 0, 0), caution, Enum.Material.SmoothPlastic)
		end
		for _, z in ipairs({-2.5, 2.5}) do
			part("ReceivingBoundary", Vector3.new(16, 0.025, 0.12), dropBase * CFrame.new(0, 0, z), caution, Enum.Material.SmoothPlastic)
		end
		local receiving = part("ReceivingLabel", Vector3.new(8, 0.025, 1.2), dropBase * CFrame.new(0, 0, 3.5), steel)
		label(receiving, "RECEIVING / KEEP CLEAR", Enum.NormalId.Top, caution)
		local header = plot.Model:FindFirstChild("DoorFrame_Top", true)
		if header and header:IsA("BasePart") then
			local sign = part("DockSign", Vector3.new(7.6, 1.6, 0.1), header.CFrame * CFrame.new(0, 1.2, -header.Size.Z / 2 - 0.08), steel)
			label(sign, string.format("BAY %02d  /  WITB", plot.Slot))
		end
		local wall = plot.Model:FindFirstChild("Warehouse_backwall", true)
		if wall and wall:IsA("BasePart") then
			local sign = part("OperationsSign", Vector3.new(10, 2.3, 0.1), wall.CFrame * CFrame.new(0, 2, -wall.Size.Z / 2 - 0.08), steel)
			label(sign, "WHAT'S IN THE BOX?\nRECEIVE  /  DISCOVER  /  COLLECT")
		end
		-- Fixed indicators are geometry; connections are bound separately after cloning.
		for _, name in ipairs({"EmployeeDoor_panel", "GarageDoor_Panel"}) do
			local door = plot.Model:FindFirstChild(name)
			if door and door:IsA("BasePart") then
				part("DoorStatus_" .. name, Vector3.new(0.25, 0.7, 0.12),
					door.CFrame * CFrame.new(door.Size.X / 2 + 0.6, -door.Size.Y / 2 + 3, -0.85), theme.Accent, Enum.Material.Neon)
			end
		end
		builder.BindPlot(plot, folder, interactive)
	end
	return builder
end
