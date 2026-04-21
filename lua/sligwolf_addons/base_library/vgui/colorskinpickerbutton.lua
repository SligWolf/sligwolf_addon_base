
if not SligWolf_Addons then
	return
end

if SligWolf_Addons:ReloadAddonSystem() then
	return
end

local PANEL = {}

AccessorFunc( PANEL, "m_ColorSkinName", "ColorSkinName" )

function PANEL:Init()
	self:SetPaintBackground(false)
	self:SetSize(128, 128)
	self:SetText("")
	self:SetCursor("hand")
	self:SetDoubleClickingEnabled(false)

	self.m_Title = ""

	self.Colors = {}
	self.Chart = {}
end

function PANEL:SetTitle(title)
	self:SetTooltip(title)
	self.m_Title = title
end

function PANEL:SetCursor(cursor)
	self.m_InternalCursor = cursor
end

function PANEL:GetCursor()
	return self.m_InternalCursor or "arrow"
end

function PANEL:SetTooltip(tooltip)
	self.m_InternalTooltip = tooltip
end

function PANEL:GetTooltip()
	return self.m_InternalTooltip
end

function PANEL:DoClick()
end

function PANEL:AddColor(color)
	table.insert(self.Colors, color)
	self.isDirty = true
end

function PANEL:AddColors(colors)
	for key, color in ipairs(colors) do
		table.insert(self.Colors, color)
	end

	self.isDirty = true
end

function PANEL:ClearColors()
	table.Empty(self.Colors)
	self.isDirty = true
end

function PANEL:PerformLayout(w, h)
	self.isDirty = true
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
	local chart = self.Chart
	local colors = self.Colors
	local count = #colors

	table.Empty(chart)

	if count <= 1 then
		local color = colors[1]

		if color then
			table.insert(chart, {
				color = color:Copy()
			})
		end

		self.isDirty = false
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

	self.isDirty = false
end

function PANEL:PaintColorChart(x, y, w, h)
	if self.isDirty then
		self:BuildChart(x, y, w, h)
	end

	local chart = self.Chart
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
	draw.NoTexture()

	local border = 2
	local shadow = 2

	local borderBoxW = w - shadow
	local borderBoxH = h - shadow

	local innerBoxW = borderBoxW - border * 2
	local innerBoxH = borderBoxW - border * 2

	local shadowBoxW = borderBoxW
	local shadowBoxH = borderBoxH

	surface.SetDrawColor(0, 0, 0, 120)
	surface.DrawRect(2, 2, shadowBoxW, shadowBoxH)

	surface.SetDrawColor(0, 0, 0, 120)
	surface.DrawRect(1, 1, shadowBoxW, shadowBoxH)

	self:PaintColorChart(border, border, innerBoxW, innerBoxH)

	if self:IsHovered() then
		surface.SetDrawColor(0, 0, 0, 50)
		surface.DrawRect(border, border, innerBoxW, innerBoxH)
	end

	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawOutlinedRect(0, 0, borderBoxW, borderBoxH, border)
end


vgui.Register("SligWolf_ColorSkinPickerButton", PANEL, "DButton")

return true

