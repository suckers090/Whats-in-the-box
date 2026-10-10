-- Additive layer shared by the Studio toolbar and server. Saved groups are reused,
-- including artist edits; the existing roads, template meshes and props are untouched.
return function(config, layout, exterior)
	local builder = {}
	local function add(parent, descriptors, base, created)
		if parent:FindFirstChild("FacilityPolish") then return end
		local folder = Instance.new("Folder")
		folder.Name = "FacilityPolish"
		folder:SetAttribute("WITB_FacilityVersion", 1)
		folder.Parent = parent
		if created then created(folder) end -- Register before construction for failure cleanup.
		exterior.BuildParts(descriptors, base, folder)
	end
	function builder.Decorate(plot, park, created)
		if not config.WorldEnabled or config.YardEnabled == false or config.FacilityDetailsEnabled == false then return end
		if not plot.Model.Parent or not park or park:GetAttribute("WITB_EstateVersion") ~= 1 then return end
		local origin = park:GetAttribute("WITB_EstateOrigin")
		if typeof(origin) ~= "Vector3" then return end
		local marker = plot.Markers.TruckStop
		local dock = marker.CFrame * CFrame.new(0, -marker.Size.Y / 2, 0)
		add(plot.Runtime, layout.PlotParts(), dock, created)
		for _, section in ipairs(park:GetChildren()) do
			local row = section.Name:match("^EstateRow_(%d+)$")
			if row and section:IsA("Folder") then
				add(section, layout.RowParts(tonumber(row)), CFrame.new(origin), created)
			end
		end
	end
	return builder
end
