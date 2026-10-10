-- Dimensions use ScreenGui's CoreUISafeInsets area, not the raw camera viewport.
local Layout = {}
function Layout.Measure(width, height, touch)
	local compact = height < 520
	local tiny = height < 280
	local cashHeight = tiny and 48 or compact and 74 or 96
	local row = compact and 52 or 70
	local gap = compact and 6 or 8
	local edge = width < 500 and 10 or 14
	local top = 8
	local navY = top + cashHeight + 12
	-- Short touch screens scroll above the thumbstick instead of covering it.
	local reserve = touch and math.min(150, height * 0.4) or 18
	local contentHeight = row * 5 + gap * 4 + 6
	local navHeight = math.min(contentHeight, math.max(row + 6, height - reserve - navY - 14))
	return {x = edge, y = top, cashWidth = math.min(230, width - edge * 2),
		cashHeight = cashHeight, navY = navY, navWidth = compact and 68 or 78,
		row = row, gap = gap, navHeight = navHeight, compact = compact, tiny = tiny,
		scroll = navHeight < contentHeight}
end
return Layout
