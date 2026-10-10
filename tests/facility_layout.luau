local layout = require("../src/ServerScriptService/FacilityLayout")
local function overlaps(a, b)
	return math.abs(a.position[1] - b.position[1]) < (a.size[1] + b.size[1]) / 2
		and math.abs(a.position[3] - b.position[3]) < (a.size[3] + b.size[3]) / 2
end
local protected = {
	{position = {0, 0, -25}, size = {12, 10, 52}}, -- Existing truck/cab approach
	{position = {15, 0, 5}, size = {9, 10, 14}}, -- Employee door and owner spawn
	{position = {0.102, 0, 30.151}, size = {51.2, 20, 42.94}}, -- Blender warehouse
	{position = {29, 0, 28}, size = {6, 10, 50}}, -- Existing side walkway
}
local plot = layout.PlotParts()
assert(#plot <= 40, "Per-plot logistics props must stay bounded")
for _, part in ipairs(plot) do
	assert(part.group and not part.collidable)
	for _, size in ipairs(part.size) do assert(size > 0) end
	for _, route in ipairs(protected) do assert(not overlaps(part, route), part.name .. " obstructs a plot route") end
	assert(part.position[1] - part.size[1] / 2 > -45 and part.position[1] + part.size[1] / 2 < 45)
	assert(part.position[3] + part.size[3] / 2 < 80)
end
local parts = layout.RowParts(0)
assert(#parts <= 120, "Shared row logistics props must stay bounded")
for row = -1, 1 do
	local street = {position = {135, 0, -44 + row * 140}, size = {360, 10, 22}}
	local parkWalk = {position = {310, 0, 22 + row * 140}, size = {5, 10, 140}}
	for _, part in ipairs(parts) do
		assert(not part.collidable)
		for _, size in ipairs(part.size) do assert(size > 0) end
		if part.size[2] > 0.1 then
			assert(not overlaps(part, street), part.name .. " clips an active or future road")
			assert(not overlaps(part, parkWalk), part.name .. " obstructs cross-row visitors")
			for column = 0, 3 do
				for _, route in ipairs(protected) do
					local region = {position = {route.position[1] + column * 90, 0, route.position[3] + row * 140}, size = route.size}
					assert(not overlaps(part, region), part.name .. " obstructs a warehouse/route")
				end
			end
		end
	end
end
local nextRow = layout.RowParts(1)
for i, part in ipairs(nextRow) do
	assert(part.position[3] - parts[i].position[3] == 140 and part.position[1] == parts[i].position[1])
end
print(string.format("PASS: %d plot/%d shared row facility parts; clear doors, warehouses, truck lanes, visitor routes and future roads", #plot, #parts))
