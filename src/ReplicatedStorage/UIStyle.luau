-- Shared finishing layer for the existing HUD, reveal and notifications.
local TweenService = game:GetService("TweenService")
local theme = require(script.Parent:WaitForChild("UITheme"))
local config = require(script.Parent:WaitForChild("VisualConfig"))
local Presentation = require(script.Parent:WaitForChild("Presentation"))
local style = {}
function style.Surface(frame, radius)
	local corner = frame:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 12); corner.Parent = frame
	local stroke = frame:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
	stroke.Color = theme.Border; stroke.Thickness = 1; stroke.Transparency = 0.35; stroke.Parent = frame
	if not frame:FindFirstChild("IndustrialGradient") then
		local gradient = Instance.new("UIGradient")
		gradient.Name = "IndustrialGradient"; gradient.Rotation = 90
		gradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(216, 226, 240))
		gradient.Parent = frame
	end
	return stroke
end
function style.Button(button)
	local stroke = style.Surface(button, 8)
	local base = button.BackgroundColor3
	button.AutoButtonColor = false
	local hovering, selected, pressing = false, false, false
	local colorTween, strokeTween
	local function refresh()
		local highlighted = (hovering or selected) and button.Active
		local color = pressing and base:Lerp(Color3.new(), 0.14)
			or (highlighted and base:Lerp(theme.Accent, 0.16) or base)
		if colorTween then colorTween:Cancel() end
		if strokeTween then strokeTween:Cancel() end
		local duration = config.ReducedMotion and 0 or 0.12
		colorTween = TweenService:Create(button, TweenInfo.new(duration), {BackgroundColor3 = color})
		strokeTween = TweenService:Create(stroke, TweenInfo.new(duration), {Transparency = highlighted and 0.05 or 0.35})
		colorTween:Play(); strokeTween:Play()
	end
	button.MouseEnter:Connect(function() hovering = true; refresh() end)
	button.MouseLeave:Connect(function() hovering = false; pressing = false; refresh() end)
	button.SelectionGained:Connect(function() selected = true; refresh() end)
	button.SelectionLost:Connect(function() selected = false; pressing = false; refresh() end)
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			pressing = true; refresh()
		end
	end)
	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			pressing = false; refresh()
		end
	end)
	button.Activated:Connect(function()
		if not button.Active then return end
		Presentation.Play("Button")
		pressing = true; refresh()
		task.delay(0.12, function() if button.Parent then pressing = false; refresh() end end)
	end)
	button.Destroying:Connect(function()
		if colorTween then colorTween:Cancel() end
		if strokeTween then strokeTween:Cancel() end
	end)
end
return style
