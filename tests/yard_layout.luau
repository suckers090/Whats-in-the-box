local layout = require("../src/ServerScriptService/YardLayout")
local function overlap(a, b)
	return math.abs(a.position[1] - b.position[1]) < (a.size[1] + b.size[1]) / 2
		and math.abs(a.position[3] - b.position[3]) < (a.size[3] + b.size[3]) / 2
end
for slot = 1, 20 do
	local column, row = layout.Address(slot)
	assert(column == (slot - 1) % 4 and row == math.floor((slot - 1) / 4))
end
local route = {position = {0, 0, -25}, size = {12, 10, 52}}
local employeeApproach = {position = {15, 0, 5}, size = {9, 10, 14}}
local warehouse = {position = {0.102, 0, 30.151}, size = {51.2, 20, 42.94}}
local nextStreet = {position = {135, 0, 96}, size = {360, 10, 22}}
local count = 0
for _, part in ipairs(layout.PlotParts()) do
	count += 1
	for _, dimension in ipairs(part.size) do assert(dimension > 0) end
	if part.size[2] > 0.2 then
		assert(not overlap(part, route), part.name .. " blocks the truck approach")
		assert(not overlap(part, employeeApproach), part.name .. " blocks employee entrance")
		assert(not overlap(part, warehouse), part.name .. " clips the warehouse")
		assert(not overlap(part, nextStreet), part.name .. " clips the next row's road")
	end
	assert(not part.collidable, "Per-plot props must remain decorative")
end
assert(count == 23)
local street, ground, lights, rowCount
lights, rowCount = 0, 0
for _, part in ipairs(layout.RowParts(0)) do
	rowCount += 1
	if part.name == "ServiceRoad" then street = part end
	if part.name == "EstateGround" then ground = part end
	if part.name == "StreetLamp" then lights += 1 end
	if part.size[2] > 0.2 and not part.collidable then
		assert(not overlap(part, nextStreet), part.name .. " intrudes on next row's road")
	end
	assert(part.collidable == (part.name == "EstateGround" or part.name == "ServiceRoad"))
end
assert(street and ground and lights == 4 and rowCount == 61)
assert(street.position[3] - street.size[3]/2 <= -50, "Arriving cab must be over asphalt")
assert(street.position[1] - street.size[1]/2 == -45 and street.position[1] + street.size[1]/2 == 315)
local second = layout.RowParts(1)
local first = layout.RowParts(0)
for i, part in ipairs(second) do
	assert(part.position[3] - first[i].position[3] == 140)
	assert(part.size[1] == first[i].size[1])
end
print("PASS: plot grid, door/truck/building clearance, cross-row roads, bounded decoration and walkable ground")
