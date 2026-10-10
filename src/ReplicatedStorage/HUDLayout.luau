-- Dimensions use ScreenGui's CoreUISafeInsets area, not the raw camera viewport.
local Layout = {}
function Layout.Measure(width, height, touch)
	local compact = height < 520 or width < 420
	local tiny = height < 280
	local cashHeight = tiny and 46 or compact and 68 or 84
	local row = compact and 54 or 70
	local gap = compact and 7 or 9
	local edge = width < 500 and 10 or 14
	local top = 8
	local navY = top + cashHeight + 10
	-- Short touch screens scroll above the thumbstick instead of covering it.
	local reserve = touch and math.min(150, height * 0.4) or 18
	local contentHeight = row * 5 + gap * 4 + 8
	local navHeight = math.min(contentHeight, math.max(row + 8, height - reserve - navY - 14))
	local cashWidth = math.max(1, math.min(216, width - edge * 2 - 48))
	return {x = edge, y = top, cashWidth = cashWidth,
		cashHeight = cashHeight, navY = navY, navWidth = compact and 68 or 78,
		toggleX = edge + cashWidth + 4, toggleY = top + math.floor((cashHeight - 44) / 2),
		row = row, gap = gap, navHeight = navHeight, compact = compact, tiny = tiny,
		scroll = navHeight < contentHeight}
end
return Layout
