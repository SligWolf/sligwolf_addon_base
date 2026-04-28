
if not SligWolf_Addons then
	return
end

if SligWolf_Addons:ReloadAddonSystem() then
	return
end

local PANEL = {}

AccessorFunc(PANEL, "m_ColorSkinName", "ColorSkinName")

local function buildSelectionBoxColors(innerColor, outerColor, steps)
	local result = {}

	for i = 1, steps do
		local color = outerColor:Lerp(innerColor, i / 5)
		table.insert(result, color)
	end

	return result
end

local g_selectionBoxColors = buildSelectionBoxColors(
	Color(85, 160, 200, 180),
	Color(255, 255, 255, 255),
	5
)

function PANEL:Init()
	self:SetPaintBackground(false)
	self:SetSize(128, 128)
	self:SetText("")
	self:SetCursor("hand")
	self:SetDoubleClickingEnabled(false)

	self.m_Title = ""

	self.colors = {}
	self.chart = {}
end

function PANEL:SetTitle(title)
	self:SetTooltip(title)
	self.m_Title = title
end

function PANEL:DoClick()
end

function PANEL:OnDepressionChanged(b)
end

function PANEL:SetSelected(bool)
	self.m_Selected = bool
end

function PANEL:IsSelected()
	return self.m_Selected
end

function PANEL:AddColor(color)
	table.insert(self.colors, color)
	self.needsRebuildChart = true
end

function PANEL:AddColors(colors)
	for key, color in ipairs(colors) do
		table.insert(self.colors, color)
	end

	self.needsRebuildChart = true
end

function PANEL:ClearColors()
	table.Empty(self.colors)
	self.needsRebuildChart = true
end

function PANEL:PerformLayout(w, h)
	self.needsRebuildChart = true
end

local function GetSquareEdgePoint(cx, cy, size, degrees)
	local rad = math.rad(degrees)
	local cos, sin = math.cos(rad), math.sin(rad)
	local absCos, absSin = math.abs(cos), math.abs(sin)
	local half = size / 2

	local scale = (half / absCos < half / absSin) and (half / absCos) or (half / absSin)
	return cx + cos * scale, cy + sin * scale
end


function PANEL:BuildChart(x, y, w, h)
	local chart = self.chart
	local colors = self.colors
	local count = #colors

	table.Empty(chart)

	if count <= 1 then
		local color = colors[1]

		if color then
			table.insert(chart, {
				color = color:Copy()
			})
		end

		self.needsRebuildChart = false
		return
	end

	local cx = x + w / 2
	local cy = y + h / 2

	local size = math.max(w, h)
	local step = 360 / count

	-- -135 degrees ensures a diagonal cut with 2 colors
	local startOffset = (count == 2) and -135 or -90

	-- extented for easy loop handling
	local cornerAngles = { -45, 45, 135, 225, 315, 405 }

	for i = 1, count do
		local startAng = (i - 1) * step + startOffset
		local endAng = i * step + startOffset

		local vertices = {}
		-- start at center
		table.insert(vertices, { x = cx, y = cy })

		-- first start point at the edge
		local sx, sy = GetSquareEdgePoint(cx, cy, size, startAng)
		table.insert(vertices, { x = sx, y = sy })

		-- add corners within the segment angle
		for _, cAng in ipairs(cornerAngles) do
			if cAng > startAng and cAng < endAng then
				local ex, ey = GetSquareEdgePoint(cx, cy, size, cAng)
				table.insert(vertices, { x = ex, y = ey })
			end
		end

		-- end point at the edge
		local ex, ey = GetSquareEdgePoint(cx, cy, size, endAng)
		table.insert(vertices, { x = ex, y = ey })

		local color = colors[i]

		table.insert(chart, {
			vertices = vertices,
			color = color:Copy()
		})
	end

	self.needsRebuildChart = false
end

function PANEL:PaintColorChart(x, y, w, h)
	if self.needsRebuildChart then
		self:BuildChart(x, y, w, h)
	end

	local chart = self.chart
	local count = #chart

	draw.NoTexture()

	-- full color for single or no colors
	if count <= 1 then
		local chartItem = chart[1]

		if chartItem then
			surface.SetDrawColor(chartItem.color)
		else
			surface.SetDrawColor(0, 0, 0, 255)
		end

		surface.DrawRect(x, y, w, h)
		return
	end

	-- render chart
	for _, chartItem in ipairs(chart) do
		surface.SetDrawColor(chartItem.color)
		surface.DrawPoly(chartItem.vertices)
	end
end

function PANEL:Paint(w, h)
	local boxSize = math.min(w, h)

	local isDepressed = self.Depressed and not self.Dragging
	local oldIsDepressed = self.oldIsDepressed

	local isHovered = self:IsHovered() or self:IsChildHovered()
	local oldIsHovered = self.oldIsHovered

	local isSelected = self:IsSelected()

	local depressionBorder = 0
	local hoveredBorder = 0

	if oldIsDepressed ~= isDepressed then
		self.needsRebuildChart = true
		self.oldIsDepressed = isDepressed
		self:OnDepressionChanged(isDepressed)
	end

	if oldIsHovered ~= isHovered then
		self.needsRebuildChart = true
		self.oldIsHovered = isHovered
	end

	local depressionBorderSize = math.min(boxSize / 16, 4)
	depressionBorder = isDepressed and depressionBorderSize or 0

	local hoveredBorderSize = math.min(boxSize / 32, 2)
	hoveredBorder = isHovered and hoveredBorderSize or 0

	draw.NoTexture()

	local outerBorder = math.max(depressionBorder, hoveredBorder)

	local x = outerBorder
	local y = outerBorder

	local innerBorder = 2
	local shadow = 2

	local borderBoxW = w - shadow - 2 * outerBorder
	local borderBoxH = h - shadow - 2 * outerBorder

	local innerBoxW = borderBoxW - innerBorder * 2
	local innerBoxH = borderBoxW - innerBorder * 2

	local innerBoxX = x + innerBorder
	local innerBoxY = y + innerBorder

	local shadowBoxW = borderBoxW
	local shadowBoxH = borderBoxH

	for i = 1, shadow do
		surface.SetDrawColor(0, 0, 0, 120)
		surface.DrawRect(x + i, y + i, shadowBoxW, shadowBoxH)
	end

	self:PaintColorChart(innerBoxX, innerBoxY, innerBoxW, innerBoxH)

	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawOutlinedRect(x, y, borderBoxW, borderBoxH, innerBorder)

	if isSelected then
		for i, color in ipairs(g_selectionBoxColors) do
			local border = 1 + i

			surface.SetDrawColor(color)
			surface.DrawOutlinedRect(x + border, y + border, borderBoxW - border * 2, borderBoxH - border * 2, 1)
		end
	end
end

vgui.Register("SligWolf_ColorSkinPickerButton", PANEL, "DButton")

return true

