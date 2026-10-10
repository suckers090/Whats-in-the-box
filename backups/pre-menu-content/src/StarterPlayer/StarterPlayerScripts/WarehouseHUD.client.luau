-- Compact industrial HUD. Inventory/index state and selling remain server-authoritative.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
-- Claim synchronously before any dependency waits: a second HUD script cannot
-- attach duplicate remote listeners or create a second controller on respawn.
if playerGui:GetAttribute("WITB_HUDController") then return end
playerGui:SetAttribute("WITB_HUDController", true)
for _, child in ipairs(playerGui:GetChildren()) do
	if child.Name == "WarehouseHUD" and child:IsA("ScreenGui") then child:Destroy() end
end
local theme = require(RS:WaitForChild("UITheme"))
local style = require(RS:WaitForChild("UIStyle"))
local presentation = require(RS:WaitForChild("Presentation"))
local visualConfig = require(RS:WaitForChild("VisualConfig"))
local layout = require(RS:WaitForChild("HUDLayout"))
local navigation = require(RS:WaitForChild("HUDNavigation"))(theme, visualConfig, style, presentation)
local catalog = require(RS:WaitForChild("ItemCatalog"))
local milestones = require(RS:WaitForChild("CollectionMilestones"))
local inventoryView = require(RS:WaitForChild("InventoryView"))
local event = RS:WaitForChild("WarehouseState")
local boxEvent = RS:WaitForChild("BoxEvent")
local state = {inventory = {}, discoveries = {}, collectionClaims = {}, inventoryLocks = {}, inventoryFavorites = {}, plot = 0, scanner = false}
local currentTab, revealActive, previousSelection = nil, false, nil
local revealToken
local navCollapsed, navGeneration, navTween, navMetrics = false, 0, nil, nil
local sortIndex, filterIndex, sequence = 1, 1, 0
local pendingRequest, saleQuote = nil, nil
local inventoryMessage = "Locks protect every sale. Favorites are excluded from duplicate sales."
local render
local navButtons = {}
local function selectNavigation()
	for id, handle in pairs(navButtons) do handle.Select(id == currentTab) end
end
local function create(class, properties, parent)
	local value = Instance.new(class)
	for key, property in pairs(properties) do value[key] = property end
	value.Parent = parent
	return value
end
local function surface(frame)
	style.Surface(frame)
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
	style.Button(value)
	value.Activated:Connect(callback)
	return value
end
local gui = create("ScreenGui", {Name = "WarehouseHUD", ResetOnSpawn = false, DisplayOrder = 5,
	ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets, ClipToDeviceSafeArea = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, playerGui)
local safeRoot = create("Frame", {Name = "SafeArea", Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1}, gui)
local hud = create("Frame", {Name = "CashCard", Size = UDim2.fromOffset(216, 84), Position = UDim2.fromOffset(14, 8),
	BackgroundColor3 = theme.Background, BackgroundTransparency = 0.04, BorderSizePixel = 0}, safeRoot)
style.Surface(hud, 18)
local cashBadge = create("Frame", {Name = "CashBadge", Position = UDim2.fromOffset(12, 25), Size = UDim2.fromOffset(32, 32),
	BackgroundColor3 = theme.Success, BackgroundTransparency = 0.88, BorderSizePixel = 0}, hud)
create("UICorner", {CornerRadius = UDim.new(0, 10)}, cashBadge)
navigation.Icon(cashBadge, "Cash", theme.Success)
local cashHeading = text(hud, "WAREHOUSE FUNDS", 9, UDim2.fromOffset(14, 9), UDim2.fromOffset(120, 12), theme.Muted)
local cashLabel = text(hud, "$0", 26, UDim2.fromOffset(52, 25), UDim2.new(1, -64, 0, 32))
cashLabel.TextScaled = true
create("UITextSizeConstraint", {MinTextSize = 13, MaxTextSize = 26}, cashLabel)
local plotLabel = text(hud, "WAREHOUSE / ASSIGNING", 10, UDim2.fromOffset(14, 57), UDim2.new(1, -28, 0, 14), theme.Muted)
cashLabel.TextColor3 = theme.Success
local cashGain = text(hud, "", 10, UDim2.new(1, -96, 0, 7), UDim2.fromOffset(82, 14), theme.Success)
cashGain.TextXAlignment = Enum.TextXAlignment.Right
cashGain.TextScaled = true
create("UITextSizeConstraint", {MinTextSize = 8, MaxTextSize = 10}, cashGain)
cashGain.Visible = false
local cashTween, cashFlash, cashGeneration = nil, nil, 0
local deliveryLabel = text(hud, "DELIVERY / PREPARING", 10, UDim2.fromOffset(14, 75), UDim2.new(1, -28, 0, 14), theme.Accent)
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
local dock = create("ScrollingFrame", {Name = "IconNavigation", Position = UDim2.fromOffset(14, 116),
	Size = UDim2.fromOffset(78, 388), BackgroundTransparency = 1, BorderSizePixel = 0,
	CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y, ScrollBarThickness = 2,
	ScrollBarImageColor3 = theme.Accent, VerticalScrollBarInset = Enum.ScrollBarInset.None}, safeRoot)
create("UIPadding", {PaddingLeft = UDim.new(0, 3), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4)}, dock)
local navList = create("UIListLayout", {FillDirection = Enum.FillDirection.Vertical,
	Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, dock)
local scrollHint = text(safeRoot, "SWIPE", 9, UDim2.fromOffset(14, 504), UDim2.fromOffset(78, 12), theme.Muted)
scrollHint.TextXAlignment = Enum.TextXAlignment.Center; scrollHint.Visible = false
local refreshNavigation
local toggle = navigation.Toggle(safeRoot, function()
	if revealActive then return end
	navCollapsed = not navCollapsed
	refreshNavigation(true)
end)
local function selectedInNavigation()
	local node = GuiService.SelectedObject
	while node do if node == dock then return true end; node = node.Parent end
	return false
end
refreshNavigation = function(animate)
	if not navMetrics then return end
	local m = navMetrics
	navGeneration += 1
	local generation = navGeneration
	if navTween then navTween:Cancel(); navTween = nil end
	local enabled = not navCollapsed and not revealActive
	toggle.Button.Visible = not revealActive
	toggle.Collapsed(navCollapsed)
	for _, handle in pairs(navButtons) do
		handle.Button.Active = enabled; handle.Button.Selectable = enabled
	end
	dock.ScrollingEnabled = enabled
	scrollHint.Visible = enabled and m.scroll
	if not enabled and selectedInNavigation() then
		if revealActive then GuiService.SelectedObject = nil else GuiService.SelectedObject = toggle.Button end
	end
	local destination = UDim2.fromOffset(navCollapsed and -m.navWidth - 8 or m.x, m.navY)
	if revealActive then dock.Visible = false; return end
	if animate and not visualConfig.ReducedMotion then
		dock.Visible = true
		navTween = TweenService:Create(dock, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = destination})
		navTween:Play()
		task.delay(0.2, function()
			if generation == navGeneration and gui.Parent then dock.Visible = not navCollapsed and not revealActive end
		end)
	else dock.Position = destination; dock.Visible = enabled end
end
local function resizeNavigation()
	if safeRoot.AbsoluteSize.X <= 0 or safeRoot.AbsoluteSize.Y <= 0 then return end
	local m = layout.Measure(safeRoot.AbsoluteSize.X, safeRoot.AbsoluteSize.Y, UserInputService.TouchEnabled)
	navMetrics = m
	hud.Position = UDim2.fromOffset(m.x, m.y); hud.Size = UDim2.fromOffset(m.cashWidth, m.cashHeight)
	dock.Size = UDim2.fromOffset(m.navWidth, m.navHeight)
	toggle.Button.Position = UDim2.fromOffset(m.toggleX, m.toggleY)
	navList.Padding = UDim.new(0, m.gap)
	cashHeading.Position = UDim2.fromOffset(14, 4)
	cashLabel.Position = UDim2.fromOffset(52, m.compact and 15 or 18)
	cashLabel.Size = UDim2.new(1, -64, 0, m.compact and 26 or 29)
	cashBadge.Position = UDim2.fromOffset(12, m.compact and 15 or 17)
	cashBadge.Size = UDim2.fromOffset(m.compact and 26 or 32, m.compact and 26 or 32)
	plotLabel.Position = UDim2.fromOffset(14, m.compact and 40 or 48)
	deliveryLabel.Position = UDim2.fromOffset(14, m.compact and 53 or 65)
	plotLabel.Visible = not m.tiny; deliveryLabel.Visible = not m.tiny
	for _, handle in pairs(navButtons) do handle.Resize(m.row, m.compact) end
	scrollHint.Text = UserInputService.TouchEnabled and "SWIPE" or "SCROLL"
	scrollHint.Position = UDim2.fromOffset(m.x, m.navY + m.navHeight + 2)
	scrollHint.Size = UDim2.fromOffset(m.navWidth, 12)
	refreshNavigation(false)
end
safeRoot:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeNavigation)
UserInputService:GetPropertyChangedSignal("TouchEnabled"):Connect(resizeNavigation)
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
local confirmLayer
local function close()
	shade.Visible = false
	if confirmLayer then confirmLayer.Visible = false end
	saleQuote = nil
	currentTab = nil
	selectNavigation()
	GuiService.SelectedObject = previousSelection
end
closeButton = button(panel, "X", UDim2.new(1, -54, 0, 12), UDim2.fromOffset(38, 38), close)
local list = create("ScrollingFrame", {Position = UDim2.fromOffset(16, 100), Size = UDim2.new(1, -32, 1, -148),
	BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
	ScrollBarImageColor3 = theme.Accent, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y}, panel)
local grid = create("UIGridLayout", {CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder}, list)
local function resizeGrid()
	local columns = list.AbsoluteSize.X >= 550 and 2 or 1
	grid.CellSize = UDim2.new(1 / columns, -((columns - 1) * 10 / columns + 5), 0, currentTab == "Inventory" and 164 or 124)
end
list:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeGrid)
resizeGrid()
local inventoryTools = create("Frame", {Name = "InventoryTools", Position = UDim2.fromOffset(18, 100),
	Size = UDim2.new(1, -36, 0, 34), BackgroundTransparency = 1, Visible = false}, panel)
local inventoryStatus = text(panel, "", 11, UDim2.fromOffset(18, 138), UDim2.new(1, -36, 0, 30), theme.Muted)
inventoryStatus.Name = "InventoryStatus"; inventoryStatus.Visible = false
local function requestInventory(action, id, options)
	if pendingRequest then return end
	if player:GetAttribute("DataReady") ~= true then
		inventoryMessage = "Saving is paused. Your inventory has not changed."
		render(); return
	end
	sequence += 1
	local requestId = "inventory_" .. sequence
	pendingRequest = {id = requestId, action = action}
	local payload = options or {}; payload.requestId = requestId
	inventoryMessage = "Checking with your warehouse..."
	event:FireServer(action, id, payload)
	render()
	task.delay(4, function()
		if pendingRequest and pendingRequest.id == requestId then
			pendingRequest = nil
			inventoryMessage = "Response delayed. Refreshing inventory; check your counts before retrying."
			event:FireServer("RequestState")
			render()
		end
	end)
end
local sortButton = button(inventoryTools, "", UDim2.new(), UDim2.new(1 / 3, -5, 1, 0), function()
	if pendingRequest then return end
	sortIndex = sortIndex % #inventoryView.Sorts + 1; render()
end)
local filterButton = button(inventoryTools, "", UDim2.new(1 / 3, 2, 0, 0), UDim2.new(1 / 3, -5, 1, 0), function()
	if pendingRequest then return end
	filterIndex = filterIndex % #inventoryView.Filters + 1; render()
end)
local duplicatesButton = button(inventoryTools, "SELL DUPES", UDim2.new(2 / 3, 4, 0, 0), UDim2.new(1 / 3, -5, 1, 0), function()
	requestInventory("QuoteDuplicates")
end)
for _, value in ipairs({sortButton, filterButton, duplicatesButton}) do
	value.TextScaled = true
	create("UITextSizeConstraint", {MinTextSize = 9, MaxTextSize = 12}, value)
end
confirmLayer = create("Frame", {Name = "DuplicateSaleConfirmation", Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = theme.Background, BackgroundTransparency = 0.08, Active = true, Visible = false, ZIndex = 10}, panel)
local confirmPanel = create("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(0.94, 0, 0, 206), BackgroundColor3 = theme.Panel, BorderSizePixel = 0, ZIndex = 11}, confirmLayer)
surface(confirmPanel)
local confirmTitle = text(confirmPanel, "SELL DUPLICATES?", 18, UDim2.fromOffset(16, 12), UDim2.new(1, -32, 0, 28))
confirmTitle.ZIndex = 12
local confirmText = text(confirmPanel, "", 14, UDim2.fromOffset(16, 48), UDim2.new(1, -32, 0, 88), theme.Muted)
confirmText.ZIndex = 12
local cancelSale = button(confirmPanel, "CANCEL", UDim2.new(0, 16, 1, -54), UDim2.new(0.48, -20, 0, 38), function()
	confirmLayer.Visible = false; saleQuote = nil
	inventoryMessage = "Sale cancelled. Nothing was sold."
	GuiService.SelectedObject = closeButton
	render()
end)
local confirmSale = button(confirmPanel, "CONFIRM SALE", UDim2.new(0.48, 4, 1, -54), UDim2.new(0.52, -20, 0, 38), function()
	if not saleQuote or pendingRequest then return end
	local token = saleQuote.token
	confirmLayer.Visible = false; saleQuote = nil
	GuiService.SelectedObject = closeButton
	requestInventory("SellDuplicates", token)
end)
cancelSale.ZIndex = 13; confirmSale.ZIndex = 13
local saveLabel = text(panel, "PROGRESS / LOADING", 10, UDim2.new(0, 18, 1, -36), UDim2.new(1, -36, 0, 24), theme.Muted)
saveLabel.Size = UDim2.new(1, -148, 0, 24)
-- Preserve warehouse travel while keeping the five-button gameplay navigation focused.
button(panel, "HOME", UDim2.new(1, -112, 1, -40), UDim2.fromOffset(94, 30), function()
	close(); event:FireServer("GoHome")
end)
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
render = function()
	selectNavigation()
	for _, child in ipairs(list:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
	local found, owned = 0, 0
	for _, item in ipairs(catalog) do
		if (state.discoveries[item.id] or 0) > 0 then found += 1 end
		owned += state.inventory[item.id] or 0
	end
	progress.Visible = currentTab == "Index"
	local inventoryOpen = currentTab == "Inventory"
	panel.Size = inventoryOpen and UDim2.fromScale(0.94, 0.9) or UDim2.fromScale(0.92, 0.74)
	inventoryTools.Visible = inventoryOpen; inventoryStatus.Visible = inventoryOpen
	list.Position = UDim2.fromOffset(16, inventoryOpen and 176 or 100)
	list.Size = UDim2.new(1, -32, 1, inventoryOpen and -224 or -148)
	resizeGrid()
	TweenService:Create(progressFill, TweenInfo.new(0.25), {Size = UDim2.fromScale(found / #catalog, 1)}):Play()
	plotLabel.Text = "PLOT " .. state.plot .. " / " .. found .. " DISCOVERIES"
	updateSaveStatus()
	if currentTab == "Index" then
		title.Text = "COLLECTION INDEX"
		subtitle.Text = found .. " / " .. #catalog .. " discovered  •  " .. math.floor(found / #catalog * 100) .. "% complete"
		for index, milestone in ipairs(milestones) do
			local claimed = state.collectionClaims[milestone.id] == true
			local eligible = found >= milestone.required
			local frame = card(milestone.name,
				math.min(found, milestone.required) .. " / " .. milestone.required .. " different finds\nReward: $" .. milestone.reward,
				claimed and theme.Muted or theme.Accent, index)
			if eligible and not claimed then
				local claimButton
				claimButton = button(frame, "CLAIM $" .. milestone.reward, UDim2.new(0, 14, 1, -40), UDim2.new(1, -28, 0, 30), function()
					claimButton.Active = false
					claimButton.Text = "CHECKING..."
					event:FireServer("ClaimCollection", milestone.id)
					-- Re-enable if the server is paused or a request was rate limited.
					task.delay(1, function()
						if claimButton.Parent then
							claimButton.Active = true
							claimButton.Text = "CLAIM $" .. milestone.reward
						end
					end)
				end)
			else
				text(frame, claimed and "CLAIMED" or "KEEP DISCOVERING", 10,
					UDim2.new(0, 14, 1, -31), UDim2.new(1, -28, 0, 20), theme.Muted)
			end
		end
		for index, item in ipairs(catalog) do
			local unlocked = (state.discoveries[item.id] or 0) > 0
			local frame = card(unlocked and item.name or "UNDISCOVERED",
				item.rarity:upper() .. (unlocked and ("  •  $" .. item.value .. "\nOpened " .. state.discoveries[item.id] .. " times") or "\nOpen packages to discover this item"),
				unlocked and theme.Rarity[item.rarity] or theme.Muted, #milestones + index)
			text(frame, unlocked and "DISCOVERED" or "LOCKED", 10, UDim2.new(0, 14, 1, -31), UDim2.new(1, -28, 0, 20), theme.Muted)
		end
	elseif currentTab == "Inventory" then
		title.Text = "YOUR INVENTORY"
		subtitle.Text = owned .. " kept items  •  Duplicate sales keep one of each item"
		sortButton.Text = "SORT / " .. inventoryView.Sorts[sortIndex]:upper()
		filterButton.Text = "SHOW / " .. inventoryView.Filters[filterIndex]:upper()
		inventoryStatus.Text = inventoryMessage
		local ready = player:GetAttribute("DataReady") == true and pendingRequest == nil
		duplicatesButton.Active = ready; duplicatesButton.Selectable = ready
		duplicatesButton.Text = pendingRequest and "CHECKING..." or "SELL DUPES"
		local rows = inventoryView.List(catalog, state.inventory, state.inventoryLocks, state.inventoryFavorites,
			inventoryView.Sorts[sortIndex], inventoryView.Filters[filterIndex])
		for index, row in ipairs(rows) do
			local item = row.item
			local frame = card(item.name, item.rarity:upper() .. "  •  OWNED " .. row.count .. "  •  $" .. item.value
				.. (row.locked and "\nLOCKED / protected from selling" or (row.favorite and "\nFAVORITE / kept out of duplicate sales" or "")), theme.Rarity[item.rarity], index)
			local lock = button(frame, row.locked and "UNLOCK" or "LOCK", UDim2.new(0, 14, 1, -78), UDim2.new(0.48, -18, 0, 30), function()
				requestInventory("SetInventoryFlag", item.id, {flag = "Lock", enabled = not row.locked})
			end)
			local favorite = button(frame, row.favorite and "UNFAVORITE" or "FAVORITE", UDim2.new(0.48, 0, 1, -78), UDim2.new(0.52, -14, 0, 30), function()
				requestInventory("SetInventoryFlag", item.id, {flag = "Favorite", enabled = not row.favorite})
			end)
			local sell = button(frame, row.locked and "LOCKED" or ("SELL ONE / $" .. item.value), UDim2.new(0, 14, 1, -40), UDim2.new(1, -28, 0, 30), function()
				if not row.locked then requestInventory("SellInventory", item.id) end
			end)
			for _, value in ipairs({lock, favorite, sell}) do
				value.Active = ready and (value ~= sell or not row.locked); value.Selectable = value.Active
				value.TextColor3 = value.Active and theme.Text or theme.Muted
				value.TextScaled = true
				create("UITextSizeConstraint", {MinTextSize = 9, MaxTextSize = 12}, value)
			end
		end
		if owned == 0 then card("Nothing kept yet", "Open a package and choose KEEP.\nYour finds will appear here.") end
		if owned > 0 and #rows == 0 then card("No matching items", "Change SHOW to view the rest of your inventory.") end
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
	if shade.Visible and not revealActive and not confirmLayer.Visible then
		local selection = GuiService.SelectedObject
		if not selection or not selection.Parent then GuiService.SelectedObject = closeButton end
	end
end
local function open(tab)
	if revealActive then return end
	if shade.Visible and currentTab == tab then close(); return end
	previousSelection = GuiService.SelectedObject
	confirmLayer.Visible = false; saleQuote = nil
	currentTab = tab
	render()
	shade.Visible = true
	scale.Scale = visualConfig.ReducedMotion and 1 or 0.96
	TweenService:Create(scale, TweenInfo.new(visualConfig.ReducedMotion and 0 or 0.18, Enum.EasingStyle.Quad), {Scale = 1}):Play()
	GuiService.SelectedObject = closeButton
end
for order, item in ipairs(navigation.Items) do
	local handle = navigation.Button(dock, item, function() open(item.id) end)
	handle.Button.LayoutOrder = order
	navButtons[item.id] = handle
end
resizeNavigation()
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.I then open("Index")
	elseif input.KeyCode == Enum.KeyCode.B then open("Inventory")
	elseif input.KeyCode == Enum.KeyCode.Escape and shade.Visible then close() end
end)
event.OnClientEvent:Connect(function(snapshot)
	if snapshot.inventoryResponse then
		local response = snapshot.inventoryResponse
		if not pendingRequest or response.requestId ~= pendingRequest.id then return end
		pendingRequest = nil
		inventoryMessage = response.message
		render()
		if response.success and response.quote and currentTab == "Inventory" and shade.Visible then
			saleQuote = response.quote
			confirmText.Text = saleQuote.count .. " duplicate items / $" .. saleQuote.value
				.. "\n\nOne of each item stays. Locked and favorite stacks are excluded. Quote lasts 20 seconds."
			confirmLayer.Visible = true
			GuiService.SelectedObject = cancelSale
			local token = saleQuote.token
			task.delay(20, function()
				if saleQuote and saleQuote.token == token then
					saleQuote = nil; confirmLayer.Visible = false
					inventoryMessage = "Quote expired. Review a new duplicates quote."
					GuiService.SelectedObject = closeButton
					render()
				end
			end)
		end
		return
	end
	if snapshot.inventory or snapshot.inventoryLocks or snapshot.inventoryFavorites then
		if saleQuote then inventoryMessage = "Inventory updated. Review a new duplicates quote." end
		if confirmLayer.Visible then GuiService.SelectedObject = closeButton end
		saleQuote = nil; confirmLayer.Visible = false
	end
	for key, value in pairs(snapshot) do state[key] = value end
	render()
end)
player:GetAttributeChangedSignal("DataReady"):Connect(function()
	if player:GetAttribute("DataReady") ~= true then
		if confirmLayer.Visible then GuiService.SelectedObject = closeButton end
		saleQuote = nil; confirmLayer.Visible = false
		inventoryMessage = "Saving is paused. Your inventory has not changed."
	else inventoryMessage = "Locks protect every sale. Favorites are excluded from duplicate sales." end
	render()
end)
boxEvent.OnClientEvent:Connect(function(action, data)
	if action == "Reveal" then
		revealActive = true
		revealToken = data and data.token
		confirmLayer.Visible = false; saleQuote = nil
		if shade.Visible then shade.Visible = false; currentTab = nil end
		selectNavigation(); refreshNavigation(false)
	elseif action == "Closed" and (not data or data.token == revealToken) then
		revealActive = false; revealToken = nil; resizeNavigation()
	end
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
	local previous = cash.Value
	cash.Changed:Connect(function(value)
		local earned = value - previous
		previous = value
		cashLabel.Text = money(value)
		if earned <= 0 then return end
		presentation.Play("Cash")
		if not visualConfig.EffectsEnabled then return end
		cashGeneration += 1
		local generation = cashGeneration
		if cashTween then cashTween:Cancel() end
		if cashFlash then cashFlash:Cancel() end
		cashGain.Text = "+" .. money(earned)
		cashGain.Position = UDim2.new(1, -96, 0, 7)
		cashGain.TextTransparency = 0; cashGain.Visible = true
		cashLabel.TextColor3 = theme.Success:Lerp(theme.Text, 0.45)
		cashFlash = TweenService:Create(cashLabel, TweenInfo.new(0.4), {TextColor3 = theme.Success})
		cashFlash:Play()
		cashTween = TweenService:Create(cashGain, TweenInfo.new(1.2), {TextTransparency = 1,
			Position = UDim2.new(1, -96, 0, visualConfig.ReducedMotion and 7 or 2)})
		cashTween:Play()
		task.delay(1.2, function() if generation == cashGeneration then cashGain.Visible = false end end)
	end)
end)
event:FireServer("RequestState")

task.delay(2, function() if state.plot == 0 then event:FireServer("RequestState") end end)
