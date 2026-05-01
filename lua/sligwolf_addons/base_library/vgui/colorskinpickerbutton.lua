
if not SligWolf_Addons then
	return
end

if SligWolf_Addons:ReloadAddonSystem() then
	return
end

local CONSTANTS = SligWolf_Addons.Constants

local LIBUtil = SligWolf_Addons.Util

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

	self.pieces = {}
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

local function NormalizeMaterial(mat)
	if not mat then
		return nil
	end

	if istable(mat) then
		-- don't pass colors
		return nil
	end

	if type(mat) == "IMaterial" then
		if mat:IsError() then
			mat = LIBUtil.LoadPngMaterial("", "nocull noclamp")
		end

		return mat
	end

	mat = tostring(mat)
	mat = LIBUtil.LoadPngMaterial(mat, "nocull noclamp")

	return mat
end

local function NormalizeColor(color)
	if IsColor(color) then
		return Color(
			color.r or 0,
			color.g or 0,
			color.b or 0,
			255
		)
	end

	return CONSTANTS.colorNone
end

function PANEL:AddPiece(piece)
	local tmp = {}

	if istable(piece) and not IsColor(piece) then
		tmp.color = NormalizeColor(piece.color)
		tmp.materialOverlay = NormalizeMaterial(piece.materialOverlay)
		tmp.material = NormalizeMaterial(piece.material)
	else
		tmp.color = NormalizeColor(piece)
		tmp.material = NormalizeMaterial(piece)
	end

	table.insert(self.pieces, tmp)
	self.needsRebuildChart = true
end

function PANEL:AddPieces(pieces)
	for key, piece in ipairs(pieces) do
		self:AddPiece(piece)
	end
end

function PANEL:ClearPieces()
	table.Empty(self.pieces)
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
	local pieces = self.pieces
	local count = #pieces

	table.Empty(chart)

	if count <= 1 then
		local piece = pieces[1] or {}

		local chartItem = {}

		chartItem.color = piece.color
		chartItem.material = piece.material
		chartItem.materialOverlay = piece.materialOverlay

		table.insert(chart, chartItem)

		self.needsRebuildChart = false
		return
	end

	local addVertex = function(vertices, vx, vy)
		table.insert(vertices, {
			x = vx,
			y = vy,
			u = (vx - x) / w,
			v = (vy - y) / h,
		})
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
		addVertex(vertices, cx, cy)

		-- first start point at the edge
		local sx, sy = GetSquareEdgePoint(cx, cy, size, startAng)
		addVertex(vertices, sx, sy)

		-- add corners within the segment angle
		for _, cAng in ipairs(cornerAngles) do
			if cAng > startAng and cAng < endAng then
				local ex, ey = GetSquareEdgePoint(cx, cy, size, cAng)
				addVertex(vertices, ex, ey)
			end
		end

		-- end point at the edge
		local ex, ey = GetSquareEdgePoint(cx, cy, size, endAng)
		addVertex(vertices, ex, ey)

		local piece = pieces[i] or {}

		local chartItem = {}

		chartItem.vertices = vertices
		chartItem.color = piece.color
		chartItem.material = piece.material
		chartItem.materialOverlay = piece.materialOverlay

		table.insert(chart, chartItem)
	end

	self.needsRebuildChart = false
end

function PANEL:PaintColorChart(x, y, w, h)
	if self.needsRebuildChart then
		self:BuildChart(x, y, w, h)
	end

	local chart = self.chart
	local count = #chart

	-- full color for single or no colors
	if count <= 1 then
		local chartItem = chart[1]
		if not chartItem then
			return
		end

		if chartItem.material then
			surface.SetDrawColor(CONSTANTS.colorNone)
			surface.SetMaterial(chartItem.material)
			surface.DrawTexturedRectUV(x, y, w, h, 0, 0, 1, 1)
		else
			draw.NoTexture()
			surface.SetDrawColor(chartItem.color)
			surface.DrawRect(x, y, w, h)
		end

		if chartItem.materialOverlay then
			surface.SetDrawColor(CONSTANTS.colorNone)
			surface.SetMaterial(chartItem.materialOverlay)
			surface.DrawTexturedRectUV(x, y, w, h, 0, 0, 1, 1)
		end

		return
	end

	-- render chart
	for _, chartItem in ipairs(chart) do
		if chartItem.material then
			surface.SetMaterial(chartItem.material)
			surface.SetDrawColor(CONSTANTS.colorNone)
			surface.DrawPoly(chartItem.vertices)
		else
			draw.NoTexture()
			surface.SetDrawColor(chartItem.color)
			surface.DrawPoly(chartItem.vertices)
		end

		if chartItem.materialOverlay then
			surface.SetMaterial(chartItem.materialOverlay)
			surface.SetDrawColor(CONSTANTS.colorNone)
			surface.DrawPoly(chartItem.vertices)
		end
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

	render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	render.PushFilterMin(TEXFILTER.ANISOTROPIC)

	self:PaintColorChart(innerBoxX, innerBoxY, innerBoxW, innerBoxH)

	render.PopFilterMin()
	render.PopFilterMag()

	draw.NoTexture()

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

