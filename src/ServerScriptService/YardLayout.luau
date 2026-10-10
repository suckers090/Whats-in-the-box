-- Pure placement plan in studs relative to TruckStop's bottom face.
-- Plot allocation is four columns, spaced 90 across and 140 along world Z.
local layout = {ColumnSpacing = 90, RowSpacing = 140, Columns = 4}
function layout.Address(slot)
	local column = (slot - 1) % layout.Columns
	local row = math.floor((slot - 1) / layout.Columns)
	return column, row
end
function layout.PlotParts()
	local parts = {}
	local function add(name, size, position, finish)
		table.insert(parts, {name = name, size = size, position = position, finish = finish})
	end
	-- Route is open from -50 (front of arriving cab) through the bumper at 0.
	for _, x in ipairs({-7.5, 7.5}) do
		add("DeliveryEdge", {0.16, 0.025, 49}, {x, 0.06, -24.5}, "Paint")
	end
	for _, z in ipairs({-35, -22, -9}) do
		add("RouteDash", {0.2, 0.025, 3.2}, {0, 0.06, z}, "Paint")
	end
	add("Walkway", {6, 0.04, 50}, {29, 0.05, 28}, "Concrete")
	add("WalkwayEdge", {0.12, 0.025, 50}, {25.9, 0.07, 28}, "SteelBlue")
	for _, x in ipairs({-39, -31, -23}) do
		add("ParkingLine", {0.13, 0.025, 14}, {x, 0.06, 1}, "Paint")
	end
	add("ParkingEnd", {16, 0.025, 0.13}, {-31, 0.06, 8}, "Paint")
	-- A rear container and side utility cabinet add silhouettes beyond the building.
	add("ContainerBody", {10, 7, 16}, {-17, 3.55, 70}, "Container")
	for _, x in ipairs({-19.5, -14.5}) do
		add("ContainerDoor", {4.8, 6.5, 0.12}, {x, 3.55, 61.93}, "Steel")
		add("ContainerLatch", {0.1, 5.7, 0.16}, {x, 3.55, 61.82}, "SteelBlue")
	end
	for _, x in ipairs({-21, -19, -17, -15, -13}) do
		add("ContainerRib", {0.12, 6.8, 0.1}, {x, 3.55, 78.06}, "Steel")
	end
	add("UtilityCabinet", {3, 4, 2}, {35, 2.05, 42}, "Steel")
	add("UtilityFace", {2.5, 3.4, 0.06}, {35, 2.05, 40.95}, "SteelBlue")
	return parts
end
function layout.RowParts(row)
	local parts = {}
	local function add(name, size, position, finish, collidable)
		table.insert(parts, {name = name, size = size,
			position = {position[1], position[2], position[3] + row * layout.RowSpacing},
			finish = finish, collidable = collidable == true})
	end
	-- Grounds fill empty lots too, so one player's warehouse feels part of a place.
	add("EstateGround", {360, 1, 140}, {135, -0.47, 22}, "Asphalt", true)
	add("ServiceRoad", {360, 1, 22}, {135, -0.46, -44}, "Road", true)
	for column = 0, 3 do
		local x = column * layout.ColumnSpacing
		for _, edge in ipairs({-29, 29}) do
			add("LotBoundary", {0.12, 0.025, 52}, {x + edge, 0.065, 33}, "Concrete")
		end
		for _, edge in ipairs({7, 59}) do
			add("LotBoundary", {58, 0.025, 0.12}, {x, 0.065, edge}, "Concrete")
		end
		add("LotPost", {0.14, 3, 0.14}, {x + 27, 1.55, -20}, "Steel")
		add("LotMarker", {4.5, 1.8, 0.1}, {x + 27, 3.1, -20}, "Steel")
		parts[#parts].text = string.format("WITB LOGISTICS\nLOT %02d", row * 4 + column + 1)
		add("RoadCenterDash", {8, 0.025, 0.18}, {x, 0.065, -44}, "Paint")
		add("StreetPole", {0.25, 13, 0.25}, {x + 38, 6.56, -31}, "Steel")
		add("StreetArm", {3, 0.2, 0.2}, {x + 36.6, 13, -31}, "Steel")
		add("StreetLamp", {1.4, 0.1, 0.7}, {x + 35.8, 12.85, -31}, "Lamp")
		add("RearVerge", {80, 0.1, 4}, {x, 0.08, 81}, "Grass")
		-- Low plant masses on the rear verge, not a wall across visitor routes.
		for _, shrubX in ipairs({-28, 0, 28}) do
			add("Shrub", {3, 1.8, 2}, {x + shrubX, 1, 81}, "Foliage")
		end
	end
	for _, x in ipairs({-42, 312}) do
		add("EstateEdge", {0.15, 0.1, 147}, {x, 0.08, 18.5}, "Concrete")
	end
	-- A cross-row pedestrian link on the outside of all four warehouse columns.
	add("ParkWalk", {5, 0.04, 140}, {310, 0.06, 22}, "Concrete")
	return parts
end
return layout
