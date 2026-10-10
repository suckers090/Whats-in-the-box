-- Runtime adapter. Baked shared roads and per-template dressing are reused.
local RS = game:GetService("ReplicatedStorage")
local config = require(RS:WaitForChild("VisualConfig"))
if not config.WorldEnabled then return end
local builder = require(script.Parent:WaitForChild("WarehouseExteriorBuilder"))(config, require(script.Parent:WaitForChild("YardLayout")))
local Registry = require(script.Parent:WaitForChild("PlotRegistry"))
Registry.Added:Connect(function(plot) builder.Decorate(plot) end)
for _, plot in ipairs(Registry.GetAll()) do builder.Decorate(plot) end
