-- Session plot allocation. The original Studio model/markers become runtime templates only.
local ServerStorage = game:GetService("ServerStorage")
local canInteract = require(script.Parent:WaitForChild("InteractionRules"))
local model = workspace:WaitForChild("WITB_StarterWarehousetest", 15)
local markers = workspace:WaitForChild("WarehouseMarkers", 15)
assert(model and model:IsA("Model"), "PlotRegistry: missing imported warehouse model")
assert(markers and markers:IsA("Folder"), "PlotRegistry: missing WarehouseMarkers")
for _, name in ipairs({"PackageDrop", "TruckStop", "ScannerLocation"}) do
	assert(markers:FindFirstChild(name) and markers[name]:IsA("BasePart"), "Missing marker: " .. name)
end
local templates = Instance.new("Folder")
templates.Name = "WarehouseTemplates"
templates.Parent = ServerStorage
model.Parent = templates
markers.Parent = templates
local plotsFolder = Instance.new("Folder")
plotsFolder.Name = "WarehousePlots"
plotsFolder.Parent = workspace
local added = Instance.new("BindableEvent")
local plots, slots = {}, {}
local registry = {Added = {}}
-- BindableEvents copy Lua tables. Send an Instance and resolve the canonical
-- plot here so subscribers share its identity, prizes and upgrade callbacks.
function registry.Added:Connect(callback)
	return added.Event:Connect(function(owner)
		local plot = plots[owner]
		if plot then callback(plot) end
	end)
end

function registry.GetAll()
	local list = {}
	for _, plot in pairs(plots) do table.insert(list, plot) end
	return list
end
function registry.Get(player) return plots[player] end
function registry.Assign(player, scannerUnlocked)
	if plots[player] then return plots[player] end
	local slot = 1
	while slots[slot] do slot += 1 end
	local shift = Vector3.new(((slot - 1) % 4) * 90, 0, math.floor((slot - 1) / 4) * 140)
	local building = model:Clone()
	building.Name = "Warehouse_" .. player.UserId
	building:PivotTo(CFrame.new(shift) * model:GetPivot())
	building:SetAttribute("OwnerUserId", player.UserId)
	building:SetAttribute("OwnerName", player.DisplayName)
	local localMarkers = markers:Clone()
	localMarkers.Parent = building
	for _, part in ipairs(localMarkers:GetChildren()) do
		if part:IsA("BasePart") then
			part.CFrame = part.CFrame + shift
			part.Transparency = 1
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
		end
	end
	local runtime = Instance.new("Folder")
	runtime.Name = "WarehousePrototype"
	runtime.Parent = building
	-- Baked art is already shifted by PivotTo. Reuse it inside the normal runtime
	-- folder, preserving edits and avoiding a second set of fixtures/yard props.
	local baked = building:FindFirstChild("WITB_BakedDecor")
	if baked and baked:IsA("Folder") and baked:GetAttribute("WITB_VisualBakeVersion") == 1 then
		for _, child in ipairs(baked:GetChildren()) do child.Parent = runtime end
		baked:Destroy()
	end
	local packages = Instance.new("Folder")
	packages.Name = "Packages"
	packages.Parent = runtime
	local ground = Instance.new("Part")
	ground.Name = "PlotGround"
	ground.Size = Vector3.new(90, 1, 140)
	ground.CFrame = localMarkers.TruckStop.CFrame * CFrame.new(0, -localMarkers.TruckStop.Size.Y / 2 - 0.5, 22)
	ground.Anchored = true
	ground.Color = Color3.fromRGB(54, 62, 77)
	ground.Material = Enum.Material.Concrete
	ground.Parent = runtime
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "OwnerSpawn"
	spawn.Size = Vector3.new(5, 1, 5)
	spawn.CFrame = localMarkers.TruckStop.CFrame * CFrame.new(15, -localMarkers.TruckStop.Size.Y / 2 + 0.5, -3)
	spawn.Anchored = true
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = runtime
	local tag = Instance.new("BillboardGui")
	tag.Name = "OwnerSign"
	tag.Size = UDim2.fromOffset(260, 58)
	tag.StudsOffset = Vector3.new(0, 6, 0)
	tag.MaxDistance = 100
	tag.Parent = spawn
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(20, 26, 40)
	label.BackgroundTransparency = 0.15
	label.TextColor3 = Color3.fromRGB(240, 245, 255)
	label.TextSize = 18
	label.Font = Enum.Font.GothamBold
	label.Text = player.DisplayName .. "'s Warehouse\nPLOT " .. slot
	label.Parent = tag
	Instance.new("UICorner", label).CornerRadius = UDim.new(0, 10)
	local plot = {Owner = player, Slot = slot, Model = building, Markers = localMarkers,
		Runtime = runtime, Packages = packages, Spawn = spawn, Prizes = {}, ScannerUnlocked = scannerUnlocked == true}
	plots[player] = plot
	slots[slot] = player
	building.Parent = plotsFolder
	player.RespawnLocation = spawn
	added:Fire(player)
	return plot
end
function registry.CanInteract(plot, player, object, distance)
	return player:GetAttribute("DataReady") == true and canInteract(plot, player, plots[player], object, distance)
end
function registry.Release(player)
	local plot = plots[player]
	if not plot then return end
	plots[player] = nil
	slots[plot.Slot] = nil
	player.RespawnLocation = nil
	plot.Model:Destroy()
	table.clear(plot.Prizes)
end
return registry
