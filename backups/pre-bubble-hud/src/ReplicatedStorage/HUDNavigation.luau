-- Original vector-style graphics made from GUI primitives; no asset IDs or glyph icons.
-- Factory keeps the navigation independent of menus, remotes and player data.
return function(theme, config, style, presentation)
	local TweenService = game:GetService("TweenService")
	local Nav = {}
	Nav.Items = {
		{id = "Inventory", label = "Inventory", color = Color3.fromRGB(94, 196, 230)},
		{id = "Index", label = "Index", color = Color3.fromRGB(175, 145, 242)},
		{id = "Shop", label = "Shop", color = Color3.fromRGB(94, 210, 161)},
		{id = "Upgrades", label = "Upgrades", color = Color3.fromRGB(245, 186, 100)},
		{id = "Scanner", label = "Scanner", color = Color3.fromRGB(115, 157, 245)},
	}
	local function make(class, properties, parent)
		local value = Instance.new(class)
		for key, property in pairs(properties) do value[key] = property end
		value.Parent = parent
		return value
	end
	function Nav.Icon(parent, name, color)
		local root = make("Frame", {Name = name .. "Icon", BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1)}, parent)
		local function rect(x, y, w, h, radius, tint, rotation)
			local p = make("Frame", {BackgroundColor3 = tint or color, BorderSizePixel = 0,
				Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(w, h), Rotation = rotation or 0}, root)
			if radius then make("UICorner", {CornerRadius = UDim.new(radius, 0)}, p) end
			return p
		end
		local function outline(x, y, w, h, radius)
			local p = rect(x, y, w, h, radius); p.BackgroundTransparency = 1
			make("UIStroke", {Color = color, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, p)
		end
		if name == "Inventory" then
			outline(0.14, 0.23, 0.72, 0.63, 0.1)
			rect(0.13, 0.4, 0.74, 0.065); rect(0.45, 0.25, 0.1, 0.25)
			rect(0.2, 0.66, 0.18, 0.055)
		elseif name == "Index" then
			outline(0.19, 0.13, 0.61, 0.75, 0.1)
			rect(0.3, 0.14, 0.055, 0.73)
			for _, y in ipairs({0.35, 0.5, 0.65}) do rect(0.46, y, 0.22, 0.06, 0.4) end
			rect(0.11, 0.3, 0.14, 0.045); rect(0.11, 0.7, 0.14, 0.045)
		elseif name == "Shop" then
			outline(0.18, 0.44, 0.64, 0.43, 0.06)
			rect(0.12, 0.23, 0.76, 0.19, 0.16)
			for _, x in ipairs({0.24, 0.48, 0.72}) do rect(x, 0.25, 0.06, 0.14, nil, theme.Panel) end
			outline(0.54, 0.59, 0.17, 0.28, 0.04); rect(0.28, 0.58, 0.15, 0.13, 0.05)
		elseif name == "Upgrades" then
			-- Three rising equipment bars and an upward arrow.
			rect(0.14, 0.64, 0.13, 0.23, 0.12); rect(0.35, 0.49, 0.13, 0.38, 0.1)
			rect(0.57, 0.34, 0.13, 0.53, 0.08)
			rect(0.51, 0.16, 0.32, 0.075, 0.4, nil, 45)
			rect(0.33, 0.16, 0.32, 0.075, 0.4, nil, -45)
		elseif name == "Scanner" then
			for _, x in ipairs({0.13, 0.73}) do
				for _, y in ipairs({0.14, 0.77}) do
					rect(x, y, 0.16, 0.06); rect(x == 0.13 and x or 0.83, y == 0.14 and y or 0.65, 0.06, 0.18)
				end
			end
			for index, x in ipairs({0.3, 0.41, 0.53, 0.66}) do rect(x, 0.32, index % 2 == 0 and 0.04 or 0.07, 0.35) end
			rect(0.12, 0.48, 0.77, 0.055, nil, theme.Text)
		elseif name == "Cash" then
			outline(0.1, 0.23, 0.8, 0.54, 0.18)
			outline(0.4, 0.38, 0.2, 0.24, 0.5)
			rect(0.19, 0.4, 0.08, 0.2, 0.3); rect(0.73, 0.4, 0.08, 0.2, 0.3)
		end
		return root
	end
	function Nav.Button(parent, item, callback)
		local button = make("TextButton", {Name = item.id .. "Nav", Text = "", AutoButtonColor = false,
			BackgroundColor3 = theme.Panel, BorderSizePixel = 0, Selectable = true,
			Size = UDim2.new(1, -6, 0, 70)}, parent)
		local border = style.Surface(button, 18)
		local scale = make("UIScale", {Scale = 1}, button)
		local badge = make("Frame", {Name = "IconBadge", AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.fromOffset(34, 34),
			BackgroundColor3 = item.color, BackgroundTransparency = 0.88, BorderSizePixel = 0}, button)
		make("UICorner", {CornerRadius = UDim.new(0, 11)}, badge)
		local art = make("Frame", {BackgroundTransparency = 1, Position = UDim2.fromScale(0.1, 0.1),
			Size = UDim2.fromScale(0.8, 0.8)}, badge)
		Nav.Icon(art, item.id, item.color)
		local label = make("TextLabel", {Name = "Label", Text = item.label, Font = Enum.Font.GothamBold,
			TextSize = 11, TextColor3 = theme.Text, BackgroundTransparency = 1,
			Size = UDim2.new(1, -4, 0, 16), Position = UDim2.new(0, 2, 1, -22)}, button)
		local activeMark = make("Frame", {Name = "ActiveMark", BackgroundColor3 = item.color,
			BorderSizePixel = 0, Position = UDim2.new(0, 1, 0.3, 0), Size = UDim2.new(0, 3, 0.4, 0), Visible = false}, button)
		make("UICorner", {CornerRadius = UDim.new(0.5, 0)}, activeMark)
		local hovering, focused, pressed, selected = false, false, false, false
		local tweens = {}
		local function refresh()
			for _, tween in ipairs(tweens) do tween:Cancel() end
			local highlight = selected or hovering or focused
			local duration = config.ReducedMotion and 0 or 0.14
			tweens = {
				TweenService:Create(scale, TweenInfo.new(duration, Enum.EasingStyle.Quad),
					{Scale = config.ReducedMotion and 1 or (pressed and 0.95 or (hovering or focused) and 1.025 or 1)}),
				TweenService:Create(button, TweenInfo.new(duration), {BackgroundColor3 = highlight and theme.Panel:Lerp(item.color, 0.19) or theme.Panel}),
				TweenService:Create(border, TweenInfo.new(duration), {Color = highlight and item.color or theme.Border,
					Transparency = highlight and 0.06 or 0.35}),
			}
			activeMark.Visible = selected
			for _, tween in ipairs(tweens) do tween:Play() end
		end
		button.MouseEnter:Connect(function() hovering = true; refresh() end)
		button.MouseLeave:Connect(function() hovering = false; pressed = false; refresh() end)
		button.SelectionGained:Connect(function() focused = true; refresh() end)
		button.SelectionLost:Connect(function() focused = false; pressed = false; refresh() end)
		button.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then pressed = true; refresh() end
		end)
		button.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then pressed = false; refresh() end
		end)
		button.Activated:Connect(function()
			if not button.Active then return end
			presentation.Play("Button"); pressed = true; refresh(); callback()
			task.delay(0.12, function() if button.Parent then pressed = false; refresh() end end)
		end)
		button.Destroying:Connect(function() for _, tween in ipairs(tweens) do tween:Cancel() end end)
		local handle = {Button = button}
		function handle.Select(value)
			if selected == value then return end
			selected = value; refresh()
		end
		function handle.Resize(row, compact)
			button.Size = UDim2.new(1, -6, 0, row)
			badge.Size = UDim2.fromOffset(compact and 26 or 34, compact and 26 or 34)
			badge.Position = UDim2.new(0.5, 0, 0, compact and 4 or 8)
			label.Position = UDim2.new(0, 2, 1, compact and -19 or -22)
			label.TextSize = compact and 10 or 11
		end
		return handle
	end
	return Nav
end
