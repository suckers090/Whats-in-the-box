-- Compact industrial HUD. Inventory/index state and selling remain server-authoritative.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer
local theme = require(RS:WaitForChild("UITheme"))
local catalog = require(RS:WaitForChild("ItemCatalog"))
local event = RS:WaitForChild("WarehouseState")
local boxEvent = RS:WaitForChild("BoxEvent")
local state = {inventory = {}, discoveries = {}, plot = 0, scanner = false}
local currentTab, revealActive, previousSelection = nil, false, nil
local function create(class, properties, parent)
	local value = Instance.new(class)
	for key, property in pairs(properties) do value[key] = property end
	value.Parent = parent
	return value
end
local function surface(frame)
	create("UICorner", {CornerRadius = UDim.new(0, 12)}, frame)
	create("UIStroke", {Color = theme.Border, Transparency = 0.45, Thickness = 1}, frame)
end
local function text(parent, message, size, position, dimensions, color)
	return create("TextLabel", {Text = message, TextSize = size, Font = Enum.Font.GothamMedium,
		TextColor3 = color or theme.Text, BackgroundTransparency = 1,
		Position = position, Size = dimensions, TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true}, parent)
end
local function button(parent, title, position, size, callback)
	local value = create("TextButton", {Text = title, Font = Enum.Font.GothamBold, TextSize = 14,
		TextColor3 = theme.Text, BackgroundColor3 = theme.Raised, BorderSizePixel = 0,
		Position = position, Size = size, AutoButtonColor = true, Selectable = true}, parent)
	surface(value)
	value.Activated:Connect(callback)
	return value
end
local gui = create("ScreenGui", {Name = "WarehouseHUD", ResetOnSpawn = false, DisplayOrder = 5,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, player:WaitForChild("PlayerGui"))
local hud = create("Frame", {Size = UDim2.fromOffset(205, 88), Position = UDim2.fromOffset(14, 12),
	BackgroundColor3 = theme.Background, BackgroundTransparency = 0.08, BorderSizePixel = 0}, gui)
surface(hud)
local cashLabel = text(hud, "$0", 22, UDim2.fromOffset(14, 8), UDim2.new(1, -28, 0, 28))
local plotLabel = text(hud, "WAREHOUSE / ASSIGNING", 10, UDim2.fromOffset(14, 39), UDim2.new(1, -28, 0, 20), theme.Muted)
cashLabel.TextColor3 = theme.Success
local deliveryLabel = text(hud, "DELIVERY / PREPARING", 10, UDim2.fromOffset(14, 61), UDim2.new(1, -28, 0, 18), theme.Accent)
local function updateDeliveryStatus()
	local phase = player:GetAttribute("DeliveryPhase")
	local count = player:GetAttribute("PackageCount") or 0
	local labels = {Arriving = "TRUCK / ARRIVING", Unloading = "DOCK / UNLOADING",
		Departing = "TRUCK / DEPARTING", Choose = "CHOOSE KEEP OR SELL", Paused = "DELIVERY / SAVE PAUSED"}
	if phase == "Queued" then
		local seconds = math.max(0, math.ceil((player:GetAttribute("NextDeliveryAt") or 0) - workspace:GetServerTimeNow()))
		deliveryLabel.Text = "NEXT DELIVERY / " .. seconds .. "s"
	elseif phase == "Ready" then
		deliveryLabel.Text = "PACKAGES READY / " .. count
	else deliveryLabel.Text = labels[phase] or "DELIVERY / PREPARING" end
end
for _, attribute in ipairs({"DeliveryPhase", "PackageCount", "NextDeliveryAt"}) do
	player:GetAttributeChangedSignal(attribute):Connect(updateDeliveryStatus)
end
updateDeliveryStatus()
task.spawn(function() while gui.Parent do task.wait(1); updateDeliveryStatus() end end)
local dock = create("Frame", {AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -14),
	Size = UDim2.new(0.94, 0, 0, 48), BackgroundColor3 = theme.Background, BorderSizePixel = 0}, gui)
surface(dock)
if UserInputService.TouchEnabled then
	dock.AnchorPoint = Vector2.new(0.5, 0)
	dock.Position = UDim2.new(0.5, 0, 0, 108)
end
create("UISizeConstraint", {MaxSize = Vector2.new(610, 48)}, dock)
create("UIPadding", {PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5)}, dock)
create("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4),
	VerticalAlignment = Enum.VerticalAlignment.Center}, dock)
local shade = create("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(),
	BackgroundTransparency = 0.3, Visible = false, Active = true}, gui)
local panel = create("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.48),
	Size = UDim2.fromScale(0.92, 0.74), BackgroundColor3 = theme.Background, BorderSizePixel = 0}, shade)
surface(panel)
create("UISizeConstraint", {MaxSize = Vector2.new(760, 560)}, panel)
local scale = create("UIScale", {Scale = 1}, panel)
local title = text(panel, "COLLECTION INDEX", 22, UDim2.fromOffset(18, 14), UDim2.new(1, -82, 0, 32))
title.TextScaled = true
create("UITextSizeConstraint", {MinTextSize = 14, MaxTextSize = 22}, title)
local subtitle = text(panel, "", 13, UDim2.fromOffset(18, 51), UDim2.new(1, -36, 0, 38), theme.Muted)
local progress = create("Frame", {Position = UDim2.fromOffset(18, 92), Size = UDim2.new(1, -36, 0, 3),
	BackgroundColor3 = theme.Raised, BorderSizePixel = 0, Visible = false}, panel)
local progressFill = create("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = theme.Accent, BorderSizePixel = 0}, progress)
local closeButton
local function close()
	shade.Visible = false
	currentTab = nil
	GuiService.SelectedObject = previousSelection
end
closeButton = button(panel, "X", UDim2.new(1, -54, 0, 12), UDim2.fromOffset(38, 38), close)
local list = create("ScrollingFrame", {Position = UDim2.fromOffset(16, 100), Size = UDim2.new(1, -32, 1, -148),
	BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
	ScrollBarImageColor3 = theme.Accent, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y}, panel)
local grid = create("UIGridLayout", {CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder}, list)
local function resizeGrid()
	local columns = list.AbsoluteSize.X >= 550 and 2 or 1
	grid.CellSize = UDim2.new(1 / columns, -((columns - 1) * 10 / columns + 5), 0, 124)
end
list:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeGrid)
resizeGrid()
local saveLabel = text(panel, "PROGRESS / LOADING", 10, UDim2.new(0, 18, 1, -36), UDim2.new(1, -36, 0, 24), theme.Muted)
local function updateSaveStatus()
	local status = player:GetAttribute("SaveStatus") or "Loading"
	saveLabel.Text = status == "Studio preview" and "STUDIO PREVIEW / SAVING OFF" or ("PROGRESS / " .. string.upper(status))
	saveLabel.TextColor3 = (status == "Save retry needed" or status == "Saving paused" or status == "Save failed")
		and theme.Rarity.Legendary or theme.Muted
	plotLabel.TextColor3 = saveLabel.TextColor3
	local found = 0
	for _, item in ipairs(catalog) do if (state.discoveries[item.id] or 0) > 0 then found += 1 end end
	plotLabel.Text = "PLOT " .. state.plot .. " / " .. found .. " DISCOVERIES"
	if status == "Saving paused" then plotLabel.Text = "PLOT " .. state.plot .. " / SAVE PAUSED"
	elseif status == "Save retry needed" or status == "Save failed" then plotLabel.Text = "PLOT " .. state.plot .. " / SAVE RETRY" end
end
player:GetAttributeChangedSignal("SaveStatus"):Connect(updateSaveStatus)
updateSaveStatus()
local function card(name, detail, color, order)
	local frame = create("Frame", {BackgroundColor3 = theme.Panel, BorderSizePixel = 0, LayoutOrder = order or 0}, list)
	surface(frame)
	create("Frame", {BackgroundColor3 = color or theme.Accent, BorderSizePixel = 0,
		Size = UDim2.new(0, 3, 1, -24), Position = UDim2.fromOffset(0, 12)}, frame)
	text(frame, name, 17, UDim2.fromOffset(14, 10), UDim2.new(1, -28, 0, 29), color)
	text(frame, detail, 12, UDim2.fromOffset(14, 42), UDim2.new(1, -28, 0, 33), theme.Muted)
	return frame
end
local function station()
	close()
	event:FireServer("GoScanner")
end
local function render()
	for _, child in ipairs(list:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
	local found, owned = 0, 0
	for _, item in ipairs(catalog) do
		if (state.discoveries[item.id] or 0) > 0 then found += 1 end
		owned += state.inventory[item.id] or 0
	end
	progress.Visible = currentTab == "Index"
	TweenService:Create(progressFill, TweenInfo.new(0.25), {Size = UDim2.fromScale(found / #catalog, 1)}):Play()
	plotLabel.Text = "PLOT " .. state.plot .. " / " .. found .. " DISCOVERIES"
	updateSaveStatus()
	if currentTab == "Index" then
		title.Text = "COLLECTION INDEX"
		subtitle.Text = found .. " / " .. #catalog .. " discovered  •  " .. math.floor(found / #catalog * 100) .. "% complete"
		for index, item in ipairs(catalog) do
			local unlocked = (state.discoveries[item.id] or 0) > 0
			local frame = card(unlocked and item.name or "UNDISCOVERED",
				item.rarity:upper() .. (unlocked and ("  •  $" .. item.value .. "\nOpened " .. state.discoveries[item.id] .. " times") or "\nOpen packages to discover this item"),
				unlocked and theme.Rarity[item.rarity] or theme.Muted, index)
			text(frame, unlocked and "DISCOVERED" or "LOCKED", 10, UDim2.new(0, 14, 1, -31), UDim2.new(1, -28, 0, 20), theme.Muted)
		end
	elseif currentTab == "Inventory" then
		title.Text = "YOUR INVENTORY"
		subtitle.Text = owned .. " kept items  •  Sell one at a time at its shown value"
		for index, item in ipairs(catalog) do
			local count = state.inventory[item.id] or 0
			if count > 0 then
				local frame = card(item.name, item.rarity:upper() .. "  •  OWNED " .. count, theme.Rarity[item.rarity], index)
				button(frame, "SELL ONE / $" .. item.value, UDim2.new(0, 14, 1, -40), UDim2.new(1, -28, 0, 30), function()
					event:FireServer("SellInventory", item.id)
				end)
			end
		end
		if owned == 0 then card("Nothing kept yet", "Open a package and choose KEEP.\nYour finds will appear here.") end
	elseif currentTab == "Scanner" or currentTab == "Upgrades" then
		title.Text = currentTab == "Scanner" and "PACKAGE SCANNER" or "WAREHOUSE UPGRADES"
		subtitle.Text = "Equipment belongs to your warehouse"
		local frame = card(state.scanner and "Scanner online" or "Unlock the scanner",
			state.scanner and "Scan your sealed packages with R for a value clue." or "Reveal value clues before opening.\nUnlock at your station for $2,000.", theme.Accent)
		button(frame, "GO TO STATION", UDim2.new(0, 14, 1, -40), UDim2.new(0.52, -18, 0, 30), station)
		if not state.scanner then
			button(frame, "BUY $2,000", UDim2.new(0.52, 0, 1, -40), UDim2.new(0.48, -14, 0, 30), function() event:FireServer("BuyScanner") end)
		end
	elseif currentTab == "Shop" then
		title.Text = "SELLING DESK"
		subtitle.Text = "Turn discoveries into your next upgrade"
		local frame = card("Sell your kept finds", "Items sell for their listed value.\nSelling does not erase index discoveries.")
		button(frame, "OPEN INVENTORY", UDim2.new(0, 14, 1, -40), UDim2.new(1, -28, 0, 30), function() currentTab = "Inventory"; render() end)
		card("Sealed packages / $120", "Use F beside your own unopened package.\nYou decide whether to reveal or sell.", theme.Muted, 2)
	end
end
local function open(tab)
	if revealActive then return end
	if shade.Visible and currentTab == tab then close(); return end
	previousSelection = GuiService.SelectedObject
	currentTab = tab
	render()
	shade.Visible = true
	scale.Scale = 0.96
	TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {Scale = 1}):Play()
	GuiService.SelectedObject = closeButton
end
for _, name in ipairs({"Index", "Inventory", "Scanner", "Shop", "Upgrades", "Home"}) do
	local b = button(dock, name, UDim2.new(), UDim2.new(1 / 6, -5, 0, 38), function()
		if name == "Home" then close(); event:FireServer("GoHome") else open(name) end
	end)
	b.TextSize = 11
	b.TextScaled = true
	create("UITextSizeConstraint", {MinTextSize = 8, MaxTextSize = 11}, b)
end
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.I then open("Index")
	elseif input.KeyCode == Enum.KeyCode.B then open("Inventory")
	elseif input.KeyCode == Enum.KeyCode.Escape and shade.Visible then close() end
end)
event.OnClientEvent:Connect(function(snapshot)
	for key, value in pairs(snapshot) do state[key] = value end
	render()
end)
boxEvent.OnClientEvent:Connect(function(action)
	if action == "Reveal" then
		revealActive = true
		if shade.Visible then shade.Visible = false; currentTab = nil end
	elseif action == "Closed" then revealActive = false end
end)
local function money(value)
	local result = tostring(value)
	while true do
		local nextValue, count = result:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		result = nextValue
		if count == 0 then break end
	end
	return "$" .. result
end
task.spawn(function()
	local cash = player:WaitForChild("leaderstats"):WaitForChild("Cash")
	cashLabel.Text = money(cash.Value)
	cash.Changed:Connect(function(value) cashLabel.Text = money(value) end)
end)
event:FireServer("RequestState")

task.delay(2, function() if state.plot == 0 then event:FireServer("RequestState") end end)
