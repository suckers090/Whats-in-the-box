-- Runtime adapter for the same art builder used by the editor tool.
local RS = game:GetService("ReplicatedStorage")
local config = require(RS:WaitForChild("VisualConfig"))
local builder = require(script.Parent:WaitForChild("WarehouseVisualBuilder"))(require(RS:WaitForChild("UITheme")), config)
-- Saved, edited lighting is authoritative after baking.
if game:GetService("Lighting"):GetAttribute("WITB_VisualBakeVersion") ~= 1 then builder.ApplyLighting() end
if not config.WorldEnabled then return end
local Registry = require(script.Parent:WaitForChild("PlotRegistry"))
Registry.Added:Connect(function(plot) builder.Decorate(plot) end)
for _, plot in ipairs(Registry.GetAll()) do builder.Decorate(plot) end
