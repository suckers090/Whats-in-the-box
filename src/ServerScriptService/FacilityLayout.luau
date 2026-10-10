-- Low-part-count logistics props. Positions are relative to the existing dock/estate
-- origin; the four-column, 90 x 140 plot grid and truck route stay unchanged.
local layout = {}
local function plan()
	local parts = {}
	local function add(group, name, size, position, finish, options)
		local value = {group = group, name = name, size = size, position = position, finish = finish}
		for key, option in pairs(options or {}) do value[key] = option end
		table.insert(parts, value)
	end
	return parts, add
end
local function pallet(add, group, x, z, stack)
	-- Two runners and one deck suggest a pallet without dozens of individual boards.
	for _, dx in ipairs({-1.2, 1.2}) do
		add(group, "PalletRunner", {0.3, 0.35, 3}, {x + dx, 0.23, z}, "Wood")
	end
	add(group, "PalletDeck", {3.5, 0.16, 3}, {x, 0.49, z}, "Wood")
	if stack then
		add(group, "WrappedFreight", {3.2, 2.4, 2.8}, {x, 1.77, z}, "Freight")
		for _, dx in ipairs({-0.95, 0.95}) do
			add(group, "FreightStrap", {0.1, 2.42, 2.82}, {x + dx, 1.77, z}, "Steel")
		end
	end
end
local function container(add, group, x, z)
	add(group, "ShippingContainer", {9, 7, 20}, {x, 3.56, z}, "Container")
	for _, dx in ipairs({-2.2, 2.2}) do
		add(group, "FreightDoor", {4.3, 6.5, 0.1}, {x + dx, 3.56, z - 10.06}, "SteelBlue")
		add(group, "DoorBar", {0.1, 5.8, 0.15}, {x + dx, 3.56, z - 10.15}, "Steel")
	end
	for _, dz in ipairs({-8, -4, 0, 4, 8}) do
		add(group, "ContainerRib", {0.1, 6.8, 0.14}, {x + 4.56, 3.56, z + dz}, "Steel")
	end
end
local function building(add, group, x, z, width, depth, height, number)
	add(group, "IndustrialShell", {width, height, depth}, {x, height / 2 + 0.06, z}, "Facade")
	add(group, "RoofCap", {width + 1.2, 0.7, depth + 1.2}, {x, height + 0.41, z}, "Steel")
	add(group, "Clerestory", {width - 5, 2, 0.1}, {x, height - 4, z - depth / 2 - 0.06}, "Glass")
	add(group, "LoadingShutter", {10, 9, 0.12}, {x - width * 0.2, 4.6, z - depth / 2 - 0.08}, "SteelBlue")
	add(group, "DepotLabel", {15, 2.4, 0.12}, {x + width * 0.2, 9, z - depth / 2 - 0.08}, "Steel",
		{text = "FREIGHT DEPOT " .. number})
	add(group, "RoofVent", {6, 2.5, 5}, {x + 8, height + 1.6, z + 4}, "Concrete")
end
function layout.PlotParts()
	local parts, add = plan()
	-- A parked, anchored van fits the left-hand parking bay; it is scenery, not a
	-- second delivery vehicle. No scripts, constraints, sounds or lights inside it.
	local x = -35
	add("ParkedDeliveryVan", "Chassis", {5.6, 0.55, 11.6}, {x, 1.15, 0}, "Steel")
	add("ParkedDeliveryVan", "CargoBody", {5.4, 3.8, 7.2}, {x, 3.15, 2}, "Vehicle")
	add("ParkedDeliveryVan", "Cab", {5.3, 2.5, 3.7}, {x, 2.5, -3.5}, "Vehicle")
	add("ParkedDeliveryVan", "Windshield", {4.5, 1.2, 0.06}, {x, 3.03, -5.39}, "Glass")
	add("ParkedDeliveryVan", "FrontBumper", {5.7, 0.3, 0.3}, {x, 1.2, -5.85}, "Steel")
	add("ParkedDeliveryVan", "RearBumper", {5.7, 0.3, 0.3}, {x, 1.2, 5.85}, "Steel")
	for _, dx in ipairs({-2.65, 2.65}) do
		for _, z in ipairs({-3.65, 3.7}) do
			add("ParkedDeliveryVan", "Tyre", {0.65, 1.7, 1.7}, {x + dx, 0.91, z}, "Rubber", {shape = "Cylinder"})
		end
	end
	add("ParkedDeliveryVan", "FleetLabel", {0.08, 1.1, 4.5}, {x - 2.75, 3.4, 1.8}, "Steel",
		{text = "WITB\nLOGISTICS", face = "Left"})
	for _, dx in ipairs({-1.85, 1.85}) do
		add("ParkedDeliveryVan", "Headlamp", {0.85, 0.45, 0.08}, {x + dx, 1.9, -5.41}, "VehicleLamp")
	end
	-- Waste collection on the outer left flank; returning freight behind the dock.
	add("WasteStation", "Dumpster", {5, 3, 4}, {-35, 1.56, 47}, "Waste")
	add("WasteStation", "DumpsterLid", {5.3, 0.2, 4.3}, {-35, 3.16, 47}, "Steel")
	add("WasteStation", "RecyclingLabel", {2.7, 0.8, 0.1}, {-35, 2.1, 44.94}, "Steel", {text = "RECYCLE"})
	pallet(add, "FreightStaging", 11, 64, true)
	pallet(add, "FreightStaging", 16, 68, false)
	-- Equipment is next to the existing utility cabinet, outside the side walkway.
	add("UtilityPlant", "HVAC", {4, 3, 4}, {35.5, 1.56, 53}, "Concrete")
	add("UtilityPlant", "VentGrille", {3.4, 2.2, 0.08}, {35.5, 1.7, 50.94}, "Steel")
	for _, y in ipairs({1.1, 1.7, 2.3}) do
		add("UtilityPlant", "VentSlat", {3.1, 0.12, 0.09}, {35.5, y, 50.85}, "SteelBlue")
	end
	return parts
end
function layout.RowParts(row)
	local parts, rawAdd = plan()
	local function add(group, name, size, position, finish, options)
		rawAdd(group, name, size, {position[1], position[2], position[3] + row * 140}, finish, options)
	end
	for column = 0, 3 do
		local x = column * 90
		-- Kerbs stay off the 22-stud road and the 12-stud delivery approach. A front
		-- pedestrian connection joins the existing six-stud warehouse-side walkway.
		add("PedestrianLinks", "FrontSidewalk", {5, 0.08, 36}, {x + 29, 0.07, -15}, "Concrete")
		add("PedestrianLinks", "SideCurb", {0.25, 0.3, 36}, {x + 32, 0.18, -15}, "Concrete")
		add("PedestrianLinks", "ParkingCurb", {17, 0.3, 0.25}, {x - 33.5, 0.18, -32}, "Concrete")
		-- Short open fence runs suggest the boundary, leaving rear exits/gaps clear.
		for _, dx in ipairs({-31, 31}) do
			local span = dx > 0 and 12 or 20 -- Keep the outside cross-row walk clear.
			add("SecurityFence", "RearFencePanel", {span, 4.5, 0.12}, {x + dx, 2.31, 82}, "Fence", {transparency = 0.9})
			for _, post in ipairs({-span / 2, span / 2}) do
				add("SecurityFence", "FencePost", {0.15, 5, 0.15}, {x + dx + post, 2.56, 82}, "Steel")
			end
			add("SecurityFence", "FenceRail", {span, 0.12, 0.12}, {x + dx, 4.55, 82}, "Steel")
			for _, offset in ipairs(span == 20 and {-5, 0, 5} or {0}) do
				add("SecurityFence", "FenceWire", {0.06, 4.5, 0.06}, {x + dx + offset, 2.31, 82}, "Steel")
			end
		end
	end
	-- Site edges extend behind the warehouse, not across the road or visitor link.
	for _, x in ipairs({-51, 322}) do
		add("SecurityFence", "SideFencePanel", {0.12, 4.5, 96}, {x, 2.31, 23}, "Fence", {transparency = 0.9})
		for _, z in ipairs({-25, 7, 39, 71}) do
			add("SecurityFence", "FencePost", {0.15, 5, 0.15}, {x, 2.56, z}, "Steel")
		end
		add("SecurityFence", "FenceRail", {0.12, 0.12, 96}, {x, 4.55, 23}, "Steel")
		for _, z in ipairs({-13, 3, 19, 35, 51}) do
			add("SecurityFence", "FenceWire", {0.06, 4.5, 0.06}, {x, 2.31, z}, "Steel")
		end
	end
	add("Wayfinding", "SignPost", {0.18, 5.5, 0.18}, {-58, 2.81, -42}, "Steel")
	add("Wayfinding", "DirectionSign", {9, 2.5, 0.12}, {-58, 4.75, -42}, "Steel",
		{text = "LOADING BAYS  →\nVISITOR WALKWAYS  →"})
	-- Repeated warehouses beyond the perimeter form an industrial skyline. Their
	-- bounds stay outside *every* player column and future road row.
	building(add, "WestFreightDepot", -115, 26, 70, 54, 19, "A")
	building(add, "EastWorkshop", 395, 35, 88, 62, 24, "B")
	container(add, "ContainerHolding", -72, 54)
	pallet(add, "ContainerHolding", -72, 38, true)
	return parts
end
return layout
