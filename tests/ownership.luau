local allowed = require("../src/ServerScriptService/InteractionRules")
local function position(x)
	return setmetatable({x = x}, {__sub = function(a, b) return {Magnitude = math.abs(a.x - b.x)} end})
end
local health = {Health = 100}
local root = {Position = position(0), IsA = function(_, name) return name == "BasePart" end}
local owner = {Character = {
	FindFirstChild = function() return root end,
	FindFirstChildOfClass = function() return health end,
}}
local visitor = {Character = owner.Character}
local plot = {Owner = owner, Model = {}}
local object = {Position = position(8), IsDescendantOf = function(_, model) return model == plot.Model end}
assert(allowed(plot, owner, plot, object, 10))
assert(not allowed(plot, visitor, plot, object, 10), "A visitor cannot open, scan, sell or upgrade")
assert(not allowed(plot, owner, nil, object, 10), "Released plots cannot authorize interactions")
assert(not allowed(plot, owner, {}, object, 10), "Stale plot allocation cannot authorize interactions")
object.Position = position(11)
assert(not allowed(plot, owner, plot, object, 10), "Forged distant prompt requests are rejected")
object.Position = position(5)
health.Health = 0
assert(not allowed(plot, owner, plot, object, 10), "Dead characters cannot interact")
health.Health = 100
object.IsDescendantOf = function() return false end
assert(not allowed(plot, owner, plot, object, 10), "Objects outside the owner's plot are rejected")
print("PASS: owner/visitor, stale allocation, distance, health and object ancestry checks")
