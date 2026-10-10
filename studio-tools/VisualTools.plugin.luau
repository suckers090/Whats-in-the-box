-- Dormant in ServerStorage; runs only after installation as a local Studio plugin.
if not plugin then return end
local RS = game:GetService("ReplicatedStorage")
local toolbar = plugin:CreateToolbar("WITB Art")
local bake = toolbar:CreateButton("WITB_Bake", "Generate editable scenery and preserve original art with Undo", "", "Bake visuals")
local clear = toolbar:CreateButton("WITB_Clear", "Remove generated scenery and restore original finishes/lighting", "", "Clear bake")
local polish = toolbar:CreateButton("WITB_Polish", "Add logistics scenery and neutral daylight without clearing your existing bake", "", "Polish facility")
local clearPolish = toolbar:CreateButton("WITB_ClearFacility", "Remove only the added facility layer and restore its previous lighting", "", "Clear facility")
local function operations()
	local theme = RS:FindFirstChild("UITheme")
	local config = RS:FindFirstChild("VisualConfig")
	assert(theme and config, "Connect the current Rojo project first; UITheme/VisualConfig are missing.")
	return require(script.VisualBake)(require(script.WarehouseVisualBuilder), require(script.WarehouseExteriorBuilder),
		require(script.YardLayout), require(theme), require(config), require(script.FacilityPolish), require(script.FacilityLayout))
end
local function invoke(action)
	local ok, success, message = pcall(function() return operations()[action]() end)
	if not ok then warn("WITB Art: " .. tostring(success))
	elseif not success then warn("WITB Art: " .. tostring(message))
	else print("WITB Art: " .. tostring(message)) end
end
bake.Click:Connect(function() invoke("Bake") end)
clear.Click:Connect(function() invoke("Clear") end)
polish.Click:Connect(function() invoke("Polish") end)
clearPolish.Click:Connect(function() invoke("ClearPolish") end)
