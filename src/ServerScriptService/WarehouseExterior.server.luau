-- Runtime adapter. Baked shared roads and per-template dressing are reused.
local RS = game:GetService("ReplicatedStorage")
local config = require(RS:WaitForChild("VisualConfig"))
if not config.WorldEnabled then return end
local builder = require(script.Parent:WaitForChild("WarehouseExteriorBuilder"))(config, require(script.Parent:WaitForChild("YardLayout")))
local facility = require(script.Parent:WaitForChild("FacilityPolish"))(config, require(script.Parent:WaitForChild("FacilityLayout")), builder)
local Registry = require(script.Parent:WaitForChild("PlotRegistry"))
local function decorate(plot)
	builder.Decorate(plot)
	facility.Decorate(plot, builder.GetEstate())
end
Registry.Added:Connect(decorate)
for _, plot in ipairs(Registry.GetAll()) do decorate(plot) end
