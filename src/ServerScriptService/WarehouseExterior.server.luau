-- Industrial estate presentation. No save, purchase, reward or door logic here.
local RS = game:GetService("ReplicatedStorage")
local config = require(RS:WaitForChild("VisualConfig"))
if not config.WorldEnabled then return end
local Registry = require(script.Parent:WaitForChild("PlotRegistry"))
local layout = require(script.Parent:WaitForChild("YardLayout"))
local palette = {
	Asphalt = {Color3.fromRGB(46, 52, 60), Enum.Material.Asphalt},
	Road = {Color3.fromRGB(33, 39, 47), Enum.Material.Asphalt},
	Concrete = {Color3.fromRGB(101, 110, 119), Enum.Material.Concrete},
	Steel = {Color3.fromRGB(49, 62, 77), Enum.Material.Metal},
	SteelBlue = {Color3.fromRGB(88, 116, 140), Enum.Material.Metal},
	Paint = {Color3.fromRGB(210, 194, 137), Enum.Material.SmoothPlastic},
	Container = {Color3.fromRGB(57, 83, 91), Enum.Material.Metal},
	Lamp = {Color3.fromRGB(227, 234, 244), Enum.Material.Neon},
	Grass = {Color3.fromRGB(81, 98, 80), Enum.Material.Grass},
	Foliage = {Color3.fromRGB(58, 83, 70), Enum.Material.Grass},
}
local park, origin
local rows = {}
local function make(descriptor, base, parent)
	local finish = palette[descriptor.finish]
	local value = Instance.new("Part")
	value.Name = descriptor.name
	value.Size = Vector3.new(table.unpack(descriptor.size))
	value.CFrame = base * CFrame.new(table.unpack(descriptor.position))
	value.Color = finish[1]; value.Material = finish[2]
	value.Anchored = true; value.CanCollide = descriptor.collidable == true
	value.CanTouch = false; value.CanQuery = descriptor.collidable == true
	value.CastShadow = false; value.Parent = parent
	if descriptor.name == "Shrub" then value.Shape = Enum.PartType.Ball end
	if descriptor.text then
		local sign = Instance.new("SurfaceGui")
		sign.Face = Enum.NormalId.Front
		sign.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sign.PixelsPerStud = 80
		sign.MaxDistance = 85; sign.LightInfluence = 0.3; sign.Parent = value
		local text = Instance.new("TextLabel")
		text.Size = UDim2.fromScale(0.9, 0.86); text.Position = UDim2.fromScale(0.05, 0.07)
		text.BackgroundTransparency = 1; text.TextScaled = true
		text.Font = Enum.Font.GothamBold; text.TextColor3 = Color3.fromRGB(223, 232, 242)
		text.Text = descriptor.text; text.Parent = sign
	end
	if descriptor.name == "StreetLamp" then
		local light = Instance.new("PointLight")
		light.Color = finish[1]; light.Range = 24; light.Brightness = 0.8; light.Shadows = false
		light.Parent = value
	end
	return value
end
local function finishBaseplate()
	if config.BaseplateFinishEnabled == false then return end
	local plate = workspace:FindFirstChild("Baseplate")
	if plate and plate:IsA("BasePart") then
		plate.Color = palette.Grass[1]; plate.Material = palette.Grass[2]
		-- Hide only the grid on the named baseplate; all warehouse textures stay.
		for _, texture in ipairs(plate:GetChildren()) do
			if texture:IsA("Texture") then texture.Transparency = 1 end
		end
	end
	local spawn = workspace:FindFirstChild("SpawnLocation")
	if spawn and spawn:IsA("SpawnLocation") then
		-- PlotRegistry already gives each player an owner spawn. Hide the legacy visual.
		spawn.Transparency = 1
		for _, child in ipairs(spawn:GetChildren()) do
			if child:IsA("Decal") or child:IsA("Texture") then child.Transparency = 1 end
		end
	end
end
local roofColor = Color3.fromRGB(39, 50, 65)
local frameColor = Color3.fromRGB(76, 98, 119)
local shutterColor = Color3.fromRGB(68, 84, 100)
local function recolor(building)
	if config.ExteriorColorsEnabled == false then return end
	for _, value in ipairs(building:GetDescendants()) do
		if not value:IsA("BasePart") then continue end
		local name = value.Name
		if name == "Warehouse_Roof" or name == "LoadingBay_Canopy" or name == "WareHouse_CompanySign" or name:match("^RoofTrim_") then
			value.Color = roofColor; value.Material = Enum.Material.Metal
		elseif name:match("^Column_") or name:match("^CanopySupport_")
			or name:match("^DoorFrame_") or name:match("^EmployeeFrame_") or name:match("^EmployeeLight_Housing") then
			value.Color = frameColor; value.Material = Enum.Material.Metal
		elseif name == "GarageDoor_Panel" or name == "EmployeeDoor_panel" then
			value.Color = shutterColor; value.Material = Enum.Material.Metal
		elseif name:match("^GarageDoor_Slat") or name == "Dock_MetalEdge" or name == "Employee_DoorHandle" then
			value.Color = frameColor; value.Material = Enum.Material.Metal
		elseif name == "LoadingDock_Platform" then
			value.Color = palette.Concrete[1]; value.Material = Enum.Material.Concrete
		elseif name:match("^Dock_Bumper") then
			value.Color = Color3.fromRGB(28, 32, 37); value.Material = Enum.Material.SmoothPlastic
		end
	end
end
local function decorate(plot)
	if not plot.Model.Parent or plot.Runtime:FindFirstChild("ExteriorPolish") then return end
	local folder = Instance.new("Folder")
	folder.Name = "ExteriorPolish"; folder.Parent = plot.Runtime
	recolor(plot.Model)
	if config.YardEnabled == false then return end
	local marker = plot.Markers.TruckStop
	local dock = marker.CFrame * CFrame.new(0, -marker.Size.Y / 2, 0)
	local column, row = layout.Address(plot.Slot)
	if not park then
		-- Registry shifts plots on world X/Z. The estate uses that same grid,
		-- while each delivery approach still follows its own TruckStop orientation.
		local location = dock.Position - Vector3.new(column * 90, 0, row * 140)
		origin = CFrame.new(location)
		park = Instance.new("Folder"); park.Name = "IndustrialParkRuntime"; park.Parent = workspace
		finishBaseplate()
	end
	-- Fill intervening rows if players reach a later row; each row is built once.
	for index = 0, row do
		if not rows[index] then
			local section = Instance.new("Folder")
			section.Name = "EstateRow_" .. index; section.Parent = park
			for _, descriptor in ipairs(layout.RowParts(index)) do make(descriptor, origin, section) end
			rows[index] = section
		end
	end
	for _, descriptor in ipairs(layout.PlotParts()) do make(descriptor, dock, folder) end
end
Registry.Added:Connect(decorate)
for _, plot in ipairs(Registry.GetAll()) do decorate(plot) end
