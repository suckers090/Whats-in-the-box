-- Lightweight category illustrations for menu cards; avoids dozens of ViewportFrames.
return function(theme)
	local art = {}
	function art.Draw(parent, category, color, locked)
		local root = Instance.new("Frame"); root.Name = "ItemIllustration"
		root.BackgroundTransparency = 1; root.Size = UDim2.fromScale(1, 1); root.Parent = parent
		local function rect(x, y, w, h, tint, radius)
			local p = Instance.new("Frame"); p.BackgroundColor3 = tint or color; p.BorderSizePixel = 0
			p.Position = UDim2.fromScale(x, y); p.Size = UDim2.fromScale(w, h); p.Parent = root
			if radius then local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(radius, 0); c.Parent = p end
		end
		if locked then
			rect(0.3, 0.2, 0.4, 0.4, theme.Muted, 0.5); rect(0.39, 0.29, 0.22, 0.28, theme.Panel, 0.5)
			rect(0.22, 0.48, 0.56, 0.36, theme.Muted, 0.2); rect(0.47, 0.6, 0.06, 0.14, theme.Panel, 0.4)
		elseif category == "Electronics" then
			rect(0.12, 0.18, 0.76, 0.54, nil, 0.1); rect(0.22, 0.28, 0.56, 0.33, theme.Panel, 0.05)
			rect(0.44, 0.72, 0.12, 0.12); rect(0.3, 0.84, 0.4, 0.05)
		elseif category == "Toys" then
			rect(0.3, 0.12, 0.4, 0.29, nil, 0.2); rect(0.2, 0.46, 0.6, 0.32, nil, 0.15)
			for _, x in ipairs({0.35, 0.59}) do rect(x, 0.24, 0.06, 0.06, theme.Panel, 0.5); rect(x, 0.8, 0.13, 0.12) end
		elseif category == "Tools" then
			rect(0.42, 0.35, 0.16, 0.55, nil, 0.2); rect(0.2, 0.15, 0.6, 0.3, nil, 0.15)
			rect(0.37, 0.12, 0.26, 0.17, theme.Panel)
		elseif category == "Collectibles" then
			rect(0.22, 0.15, 0.56, 0.42, nil, 0.25); rect(0.44, 0.5, 0.12, 0.25)
			rect(0.29, 0.79, 0.42, 0.1, nil, 0.1)
		elseif category == "Household" then
			rect(0.17, 0.32, 0.53, 0.49, nil, 0.15); rect(0.69, 0.4, 0.18, 0.31, nil, 0.3)
			rect(0.19, 0.3, 0.49, 0.08, theme.Text, 0.4)
		elseif category == "Office" then
			rect(0.22, 0.16, 0.56, 0.71, nil, 0.1)
			for _, y in ipairs({0.32, 0.5, 0.68}) do rect(0.33, y, 0.32, 0.055, theme.Panel, 0.4) end
		elseif category == "Warehouse Junk" then
			rect(0.14, 0.3, 0.72, 0.56, nil, 0.08); rect(0.43, 0.3, 0.14, 0.56, theme.Panel)
			rect(0.15, 0.4, 0.7, 0.05, theme.Text)
		else
			rect(0.28, 0.19, 0.44, 0.58, nil, 0.4); rect(0.45, 0.28, 0.1, 0.27, theme.Text, 0.4)
			rect(0.2, 0.83, 0.6, 0.05)
		end
		return root
	end
	return art
end
