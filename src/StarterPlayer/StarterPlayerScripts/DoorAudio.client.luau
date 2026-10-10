-- Optional local spatial audio from existing replicated door attributes.
-- Only nearby clients play a cue. No change to movement, collision or permissions.
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local presentation = require(RS:WaitForChild("Presentation"))
local plots = workspace:WaitForChild("WarehousePlots")
local tracked = setmetatable({}, {__mode = "k"})
local function watch(value)
	if not value:IsA("BasePart") or (value.Name ~= "EmployeeDoor_panel" and value.Name ~= "GarageDoor_Panel") or tracked[value] then return end
	tracked[value] = true
	local connection = value:GetAttributeChangedSignal("DoorBusy"):Connect(function()
		if value:GetAttribute("DoorBusy") ~= true then return end
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and (root.Position - value.Position).Magnitude <= 45 then presentation.Play("Door", value) end
	end)
	value.Destroying:Once(function() connection:Disconnect(); tracked[value] = nil end)
end
plots.DescendantAdded:Connect(watch)
for _, value in ipairs(plots:GetDescendants()) do watch(value) end
