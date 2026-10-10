-- Editor-only operations. No DataStore, network calls or gameplay scripts are run.
return function(visualFactory, exteriorFactory, layout, theme, config)
	local RunService = game:GetService("RunService")
	local History = game:GetService("ChangeHistoryService")
	local Lighting = game:GetService("Lighting")
	local Storage = game:GetService("ServerStorage")
	local backupName = "WITB_VisualBakeBackup"
	local api = {}
	local function ref(parent, name, target)
		local value = Instance.new("ObjectValue")
		value.Name = name; value.Value = target; value.Parent = parent
	end
	local function capture(backup, target, properties)
		local entry = Instance.new("Folder")
		entry.Name = "Original_" .. target.Name
		entry.Parent = backup
		ref(entry, "Target", target)
		for _, property in ipairs(properties) do
			local value = target[property]
			if typeof(value) == "EnumItem" then
				entry:SetAttribute(property, value.Name)
				entry:SetAttribute("_Enum_" .. property, true)
			else entry:SetAttribute(property, value) end
		end
	end
	local function restore(backup)
		assert(backup:GetAttribute("WITB_VisualBakeVersion") == 1, "Unsupported visual backup; left untouched")
		for _, entry in ipairs(backup:GetChildren()) do
			local targetRef = entry:IsA("Folder") and entry:FindFirstChild("Target")
			local target = targetRef and targetRef.Value
			if target and (target.Parent or target == Lighting) then
				for property, value in pairs(entry:GetAttributes()) do
					if property:sub(1, 1) ~= "_" then
						if entry:GetAttribute("_Enum_" .. property) then value = Enum.Material[value] end
						target[property] = value
					end
				end
			end
		end
		local existing = {}
		for _, value in ipairs(backup.ExistingLighting:GetChildren()) do existing[value.Value] = true end
		for _, value in ipairs(Lighting:GetChildren()) do
			if not existing[value] and value:GetAttribute("WITB_VisualEffect") == 1 then value:Destroy() end
		end
		for _, value in ipairs(backup.Created:GetChildren()) do
			if value.Value then value.Value:Destroy() end
		end
		Lighting:SetAttribute("WITB_VisualBakeVersion", backup:GetAttribute("PreviousLightingVersion"))
		backup:Destroy()
	end
	local function recording(name, work, rollback)
		if RunService:IsRunning() then return false, "Stop Play before using WITB Art tools." end
		local id = History:TryBeginRecording("WITB_" .. name, name .. " WITB visuals")
		if not id then return false, "Studio is busy recording another edit; try again when it finishes." end
		local ok, message = pcall(work)
		if not ok and rollback then
			local restored, reason = pcall(rollback)
			if not restored then warn("WITB Art rollback: " .. tostring(reason)) end
		end
		History:FinishRecording(id, ok and Enum.FinishRecordingOperation.Commit or Enum.FinishRecordingOperation.Cancel)
		return ok, ok and message or tostring(message)
	end
	function api.Bake()
		local backup
		return recording("Bake", function()
			assert(config.WorldEnabled, "Enable WorldEnabled in VisualConfig before baking.")
			assert(not Storage:FindFirstChild(backupName), "Visuals are already baked. Edits retained; use Clear bake before regenerating.")
			assert(not workspace:FindFirstChild("IndustrialParkRuntime"), "Existing IndustrialParkRuntime left untouched; use Clear bake for a previous bake.")
			local model = workspace:FindFirstChild("WITB_StarterWarehousetest")
			local markers = workspace:FindFirstChild("WarehouseMarkers")
			assert(model and model:IsA("Model"), "Missing WITB_StarterWarehousetest model in Workspace.")
			assert(markers and markers:IsA("Folder"), "Missing WarehouseMarkers folder in Workspace.")
			assert(not model:FindFirstChild("WITB_BakedDecor"), "Existing WITB_BakedDecor left untouched.")
			for _, name in ipairs({"PackageDrop", "ScannerLocation", "TruckStop"}) do
				local value = markers:FindFirstChild(name)
				assert(value and value:IsA("BasePart"), "Missing marker: " .. name)
			end
			for _, name in ipairs({"WareHouse_Floor", "Warehouse_Roof"}) do
				local value = model:FindFirstChild(name, true)
				assert(value and value:IsA("BasePart"), "Missing mesh: " .. name)
			end
			backup = Instance.new("Folder")
			backup.Name = backupName; backup:SetAttribute("WITB_VisualBakeVersion", 1); backup.Parent = Storage
			backup:SetAttribute("PreviousLightingVersion", Lighting:GetAttribute("WITB_VisualBakeVersion"))
			local created = Instance.new("Folder"); created.Name = "Created"; created.Parent = backup
			local existing = Instance.new("Folder"); existing.Name = "ExistingLighting"; existing.Parent = backup
			for _, value in ipairs(Lighting:GetChildren()) do ref(existing, value.Name, value) end
			capture(backup, Lighting, {"ClockTime", "Brightness", "Ambient", "OutdoorAmbient",
				"ExposureCompensation", "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "GlobalShadows", "ShadowSoftness"})
			for _, value in ipairs(model:GetDescendants()) do
				if value:IsA("BasePart") then capture(backup, value, {"Color", "Material"}) end
			end
			for _, name in ipairs({"Baseplate", "SpawnLocation"}) do
				local value = workspace:FindFirstChild(name)
				if value and value:IsA("BasePart") then
					capture(backup, value, {"Color", "Material", "Transparency"})
					for _, child in ipairs(value:GetChildren()) do
						if child:IsA("Texture") or child:IsA("Decal") then capture(backup, child, {"Transparency"}) end
					end
				end
			end
			local decor = Instance.new("Folder")
			decor.Name = "WITB_BakedDecor"; decor:SetAttribute("WITB_VisualBakeVersion", 1); decor.Parent = model
			ref(created, "TemplateDecor", decor)
			local plot = {Model = model, Markers = markers, Runtime = decor, Slot = 1}
			local visual = visualFactory(theme, config)
			local exterior = exteriorFactory(config, layout)
			if config.YardEnabled ~= false then
				local marker = markers.TruckStop
				local origin = (marker.CFrame * CFrame.new(0, -marker.Size.Y / 2, 0)).Position
				local park = Instance.new("Folder")
				park.Name = "IndustrialParkRuntime"; park:SetAttribute("WITB_EstateVersion", 1)
				park:SetAttribute("WITB_EstateOrigin", origin); park.Parent = workspace
				ref(created, "Estate", park)
				exterior.FinishBaseplate()
			end
			visual.ApplyLighting()
			visual.Decorate(plot, false)
			exterior.Decorate(plot)
			Lighting:SetAttribute("WITB_VisualBakeVersion", 1)
			return "Visuals baked. Edit the scenery, then save your place. Clear bake or Studio Undo restores the original art."
		end, function() if backup then restore(backup) end end)
	end
	function api.Clear()
		return recording("Clear", function()
			local backup = Storage:FindFirstChild(backupName)
			assert(backup, "No WITB bake backup found. Nothing was removed.")
			restore(backup)
			return "Bake cleared; original finishes and lighting restored. Studio Undo restores your baked scene."
		end)
	end
	return api
end
