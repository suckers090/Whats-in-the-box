-- Bounded procedural reveal props, ready to replace with Blender assets later.
-- No physics, sounds, external meshes or live Workspace objects.
local preview = {}
function preview.Build(parent, item, color)
	local model = Instance.new("Model"); model.Name = "Prize"; model.Parent = parent
	local dark, steel = Color3.fromRGB(28, 38, 54), Color3.fromRGB(172, 188, 205)
	local function part(x, y, z, px, py, pz, tint, ball)
		local p = Instance.new("Part")
		p.Anchored = true; p.CanCollide = false; p.CanTouch = false; p.CanQuery = false
		p.Size = Vector3.new(x, y, z); p.Position = Vector3.new(px, py, pz)
		p.Color = tint or color; p.Material = Enum.Material.SmoothPlastic
		if ball then p.Shape = Enum.PartType.Ball end
		p.Parent = model; return p
	end
	local key = item.preview
	local function is(keys) return string.find("|" .. keys .. "|", "|" .. key .. "|", 1, true) ~= nil end
	if is("crystal|core|device|meteor|pendant") then
		part(2, 0.35, 1.8, 0, -1.2, 0, dark)
		local gem = part(1.4, 1.9, 1.4, 0, 0.1, 0, color, key ~= "crystal")
		gem.Material = key == "meteor" and Enum.Material.Slate or Enum.Material.Neon
		for _, x in ipairs({-0.95, 0.95}) do part(0.25, 1.8, 0.3, x, -0.1, 0, steel) end
	elseif is("clock|watch|compass") then
		part(2, 2, 0.4, 0, 0, 0, color, true); part(1.65, 1.65, 0.25, 0, 0, 0.3, dark, true)
		part(0.09, 0.65, 0.08, 0, 0.25, 0.48, steel); part(0.6, 0.09, 0.08, 0.25, 0, 0.48, steel)
	elseif is("camera|projector") then
		part(2.5, 1.6, 1, 0, 0, 0, dark); part(1.1, 1.1, 0.8, 0, 0, 0.7, color, true)
		part(0.65, 0.65, 0.4, 0, 0, 1.1, steel, true); part(0.55, 0.3, 0.5, -0.6, 0.95, 0, color)
	elseif is("book|cards") then
		part(1.8, 2.4, 0.6, 0, 0, 0, color); part(1.4, 2, 0.12, 0.12, 0, 0.36, steel)
		for _, y in ipairs({-0.5, 0, 0.5}) do part(0.8, 0.08, 0.05, 0.15, y, 0.46, dark) end
	elseif is("ingot|coins") then
		for _, y in ipairs({-0.6, 0, 0.6}) do part(2, 0.45, 1.1, 0, y, 0, color) end
	elseif is("toolbox|case|console") then
		part(2.5, 1.6, 1.1, 0, 0, 0, color); part(2.6, 0.16, 1.2, 0, 0.4, 0, dark)
		part(1, 0.25, 0.3, 0, 1.1, 0, steel)
		for _, x in ipairs({-0.8, 0.8}) do part(0.18, 0.45, 0.1, x, 0.35, 0.62, steel) end
	elseif is("robot|bear|duck") then
		part(1.3, 1.4, 0.9, 0, -0.2, 0, color, key ~= "robot")
		part(1.1, 1, 1, 0, 0.95, 0, color, true)
		for _, x in ipairs({-0.3, 0.3}) do part(0.17, 0.17, 0.15, x, 1.1, 0.5, dark, true) end
		for _, x in ipairs({-0.7, 0.7}) do part(0.4, 0.9, 0.5, x, -0.3, 0, steel, true) end
		if key == "duck" then part(0.65, 0.18, 0.5, 0, 0.7, 0.65, steel) end
	elseif is("car|train|skates") then
		part(2.5, 0.65, 1.3, 0, -0.2, 0, color); part(1.4, 0.85, 1.1, 0.2, 0.55, 0, dark)
		for _, x in ipairs({-0.8, 0.8}) do for _, z in ipairs({-0.65, 0.65}) do part(0.65, 0.65, 0.35, x, -0.65, z, steel, true) end end
	elseif is("lamp|fan") then
		part(1.6, 0.25, 1.2, 0, -1.1, 0, dark); part(0.2, 1.5, 0.2, 0, -0.3, 0, steel)
		part(1.8, 1.2, 0.8, 0, 0.85, 0, color, key == "fan")
		if key == "fan" then part(1.4, 0.15, 0.1, 0, 0.85, 0.5, steel); part(0.15, 0.95, 0.1, 0, 0.85, 0.5, steel) end
	elseif is("mug|kettle|vase") then
		part(1.4, 1.8, 1.4, 0, 0, 0, color); part(1.1, 0.15, 1.1, 0, 0.95, 0, dark)
		part(0.25, 1, 0.3, 1, 0, 0, steel); part(0.55, 0.2, 0.3, 0.8, 0.5, 0, steel)
	elseif is("speaker|radio|remote|handheld|meter") then
		part(1.9, 2.4, 0.75, 0, 0, 0, dark); part(1.45, 1.1, 0.1, 0, 0.4, 0.43, color)
		for _, x in ipairs({-0.45, 0.45}) do part(0.35, 0.35, 0.12, x, -0.7, 0.46, steel, true) end
	elseif is("laptop|keyboard|typewriter|circuit|turntable|record|chess") then
		part(2.7, 0.3, 1.9, 0, -0.6, 0, dark)
		if is("record|turntable") then
			part(1.7, 0.15, 1.7, 0, -0.35, 0, color, true); part(0.25, 0.12, 0.25, 0, -0.23, 0, steel)
		else for _, x in ipairs({-0.85, 0, 0.85}) do part(0.6, 0.2, 1.3, x, -0.34, 0, color) end end
		if key == "laptop" or key == "typewriter" then part(2.5, 1.6, 0.18, 0, 0.3, -0.8, color); part(2, 1.2, 0.1, 0, 0.3, -0.66, steel) end
	elseif is("trophy|globe|ball") then
		part(1.5, 0.3, 1.2, 0, -1.05, 0, dark); part(0.3, 0.65, 0.3, 0, -0.6, 0, steel)
		part(1.65, 1.65, 1.65, 0, 0.55, 0, color, true)
	else
		-- Tools/junk: key-specific detail, always bounded to a handful of parts.
		if key == "cone" then
			part(2, 0.2, 1.8, 0, -1, 0, dark); part(1, 1.8, 1, 0, 0, 0, color); part(1.1, 0.2, 1.1, 0, 0.2, 0, steel)
		elseif key == "spool" then
			part(1.5, 1.5, 1.5, 0, 0, 0, color, true); part(0.55, 0.55, 1.7, 0, 0, 0, dark)
			for _, z in ipairs({-0.8, 0.8}) do part(1.7, 1.7, 0.15, 0, 0, z, steel) end
		else
			part(0.45, 2.1, 0.5, 0, -0.25, 0, dark)
			part(key == "drill" and 1.8 or 1.1, 0.65, 0.8, key == "drill" and 0.35 or 0, 0.8, 0, color)
			part(0.35, 0.35, 0.9, 0, 0.8, 0.65, steel)
		end
	end
	return model
end
return preview
