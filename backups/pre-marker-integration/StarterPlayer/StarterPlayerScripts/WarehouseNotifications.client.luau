
-- StarterPlayerScripts > WarehouseNotifications

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local event = RS:WaitForChild("WarehouseNotice")

local gui = Instance.new("ScreenGui")
gui.Name = "WarehouseNotifications"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local message = Instance.new("TextLabel")
message.AnchorPoint = Vector2.new(0.5, 0)
message.Position = UDim2.fromScale(0.5, 0.08)
message.Size = UDim2.fromScale(0.75, 0.09)
message.BackgroundColor3 = Color3.fromRGB(25, 35, 55)
message.TextColor3 = Color3.new(1, 1, 1)
message.Font = Enum.Font.GothamBold
message.TextScaled = true
message.Visible = false
message.Parent = gui

local size = Instance.new("UISizeConstraint")
size.MaxSize = Vector2.new(430, 65)
size.Parent = message

Instance.new("UICorner", message).CornerRadius = UDim.new(0, 10)

local notificationId = 0

event.OnClientEvent:Connect(function(text)
	notificationId += 1
	local thisId = notificationId

	message.Text = text
	message.Visible = true

	task.delay(3, function()
		if notificationId == thisId then
			message.Visible = false
		end
	end)
end)
