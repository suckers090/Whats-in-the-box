
-- StarterPlayerScripts > WarehouseNotifications

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local theme = require(RS:WaitForChild("UITheme"))
local style = require(RS:WaitForChild("UIStyle"))
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local event = RS:WaitForChild("WarehouseNotice")

local gui = Instance.new("ScreenGui")
gui.Name = "WarehouseNotifications"
gui.ResetOnSpawn = false
gui.DisplayOrder = 20
gui.Parent = player:WaitForChild("PlayerGui")

local message = Instance.new("TextLabel")
message.AnchorPoint = Vector2.new(0.5, 0)
message.Position = UDim2.fromScale(0.5, 0.08)
message.Size = UDim2.fromScale(0.75, 0.09)
message.BackgroundColor3 = theme.Panel
message.TextColor3 = theme.Text
message.Font = Enum.Font.GothamBold
message.TextScaled = true
message.Visible = false
message.Parent = gui

local size = Instance.new("UISizeConstraint")
size.MaxSize = Vector2.new(430, 65)
size.Parent = message

local border = style.Surface(message, 10)
border.Color = theme.Accent
border.Transparency = 0.4
border.Parent = message
local notificationId = 0

event.OnClientEvent:Connect(function(text)
	notificationId += 1
	local thisId = notificationId

	message.Text = text
	message.Visible = true
	message.BackgroundTransparency = 1
	message.TextTransparency = 1
	border.Transparency = 0.05
	TweenService:Create(message, TweenInfo.new(0.18), {BackgroundTransparency = 0.08, TextTransparency = 0}):Play()
	TweenService:Create(border, TweenInfo.new(0.65), {Transparency = 0.4}):Play()

	task.delay(3, function()
		if notificationId == thisId then
			TweenService:Create(message, TweenInfo.new(0.2), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
			task.delay(0.2, function()
				if notificationId == thisId then message.Visible = false end
			end)
		end
	end)
end)
