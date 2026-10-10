
-- StarterPlayerScripts > WarehouseNotifications

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local theme = require(RS:WaitForChild("UITheme"))
local style = require(RS:WaitForChild("UIStyle"))
local presentation = require(RS:WaitForChild("Presentation"))
local layout = require(RS:WaitForChild("HUDLayout"))
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local event = RS:WaitForChild("WarehouseNotice")

local gui = Instance.new("ScreenGui")
gui.Name = "WarehouseNotifications"
gui.ResetOnSpawn = false
gui.DisplayOrder = 20
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.ClipToDeviceSafeArea = true
gui.Parent = player:WaitForChild("PlayerGui")

local safeRoot = Instance.new("Frame")
safeRoot.Name = "NotificationSafeArea"
safeRoot.Size = UDim2.fromScale(1, 1)
safeRoot.BackgroundTransparency = 1
safeRoot.Parent = gui

local message = Instance.new("TextLabel")
message.Name = "Notice"
message.AnchorPoint = Vector2.new(0, 0)
message.BackgroundColor3 = theme.Panel
message.TextColor3 = theme.Text
message.Font = Enum.Font.GothamBold
message.TextScaled = true
message.Visible = false
message.Parent = safeRoot

local fontSize = Instance.new("UITextSizeConstraint")
fontSize.MinTextSize = 11; fontSize.MaxTextSize = 16; fontSize.Parent = message
message.TextWrapped = true
local function resizeNotice()
	local width, height = safeRoot.AbsoluteSize.X, safeRoot.AbsoluteSize.Y
	if width <= 0 or height <= 0 then return end
	local m = layout.Measure(width, height, UserInputService.TouchEnabled)
	-- Share safe-area geometry with the HUD; never place a notice over its cash or buttons.
	local x, y
	if width >= 760 then
		x = math.max(m.toggleX + 44 + 12, (width - 430) / 2); y = 8
	else
		x = m.x + m.navWidth + 14; y = m.y + m.cashHeight + 12
	end
	message.Position = UDim2.fromOffset(x, y)
	message.Size = UDim2.fromOffset(math.max(1, math.min(430, width - x - 14)), m.compact and 52 or 64)
end
safeRoot:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeNotice)
UserInputService:GetPropertyChangedSignal("TouchEnabled"):Connect(resizeNotice)
resizeNotice()

local size = Instance.new("UISizeConstraint")
size.MaxSize = Vector2.new(430, 65)
size.Parent = message

local border = style.Surface(message, 10)
border.Color = theme.Accent
border.Transparency = 0.4
border.Parent = message
local notificationId = 0

event.OnClientEvent:Connect(function(text, cue)
	if cue then presentation.Play(cue) end
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
