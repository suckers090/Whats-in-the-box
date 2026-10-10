-- Menu-only finishing: deliberately leaves HUDNavigation, HUDLayout and UIStyle untouched.
return function(theme, config, style)
	local TweenService = game:GetService("TweenService")
	local menu = {}
	function menu.Surface(frame, accent, radius)
		local border = style.Surface(frame, radius or 20)
		border.Color = accent or theme.Border; border.Transparency = 0.48
		local gradient = frame:FindFirstChild("IndustrialGradient")
		if gradient then gradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(191, 207, 228)) end
		return border
	end
	function menu.Button(button)
		style.Button(button)
		local corner = button:FindFirstChildOfClass("UICorner")
		if corner then corner.CornerRadius = UDim.new(0, 14) end
		local scale = Instance.new("UIScale"); scale.Scale = 1; scale.Parent = button
		local hovering, focused, pressing, tween = false, false, false, nil
		local function refresh()
			if tween then tween:Cancel() end
			local value = config.ReducedMotion and 1 or (pressing and 0.97 or (hovering or focused) and 1.015 or 1)
			tween = TweenService:Create(scale, TweenInfo.new(config.ReducedMotion and 0 or 0.12), {Scale = button.Active and value or 1})
			tween:Play()
		end
		button.MouseEnter:Connect(function() hovering = true; refresh() end)
		button.MouseLeave:Connect(function() hovering = false; pressing = false; refresh() end)
		button.SelectionGained:Connect(function() focused = true; refresh() end)
		button.SelectionLost:Connect(function() focused = false; pressing = false; refresh() end)
		button.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then pressing = true; refresh() end
		end)
		button.InputEnded:Connect(function() pressing = false; refresh() end)
		button:GetPropertyChangedSignal("Active"):Connect(refresh)
		button.Destroying:Connect(function() if tween then tween:Cancel() end end)
	end
	function menu.Measure(width, height, tab)
		local w, h = math.min(900, math.floor(width * 0.94)), math.min(720, math.floor(height * 0.94))
		local short = height < 400
		local header, tools, status, footer = short and 54 or 90, short and 38 or 44, 0, 52
		if tab == "Inventory" then status = short and 24 or 30 end
		if tab ~= "Inventory" and tab ~= "Index" then tools = 0 end
		local inline = short and w >= 500 and tools > 0
		local reservedTools = inline and 0 or tools
		local toolsX = inline and math.floor(w * 0.4) or 16
		local listY = header + reservedTools + status + 8
		return {width = w, height = h, short = short, header = header, tools = tools, status = status,
			inline = inline, reservedTools = reservedTools, toolsX = toolsX, toolsY = inline and 8 or header,
			toolsWidth = inline and w - toolsX - 72 or w - 32, statusY = header + reservedTools + 2,
			footer = footer, listY = listY, listHeight = math.max(1, h - listY - footer),
			columns = w >= 660 and 2 or 1}
	end
	return menu
end
