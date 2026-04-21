
if not SligWolf_Addons then
	return
end

if SligWolf_Addons:ReloadAddonSystem() then
	return
end

local PANEL = {}

AccessorFunc( PANEL, "m_ColorSkinName", "ColorSkinName" )

function PANEL:Init()
	self.SetCursorInternal = self.BaseClass.SetCursor
	self.SetTooltipInternal = self.BaseClass.SetTooltip

	self:SetPaintBackground(false)
	self:SetSize(128, 128)
	self:SetText("")
	self:SetCursor("hand")
	self:SetDoubleClickingEnabled(false)

	self.Image = self:Add("DImage")
	self.Image:SetPos(0, 0)
	self.Image:SetSize(128, 128)
	self.Image:SetVisible(false)

	self.Border = 0
	self.m_Title = ""

	self:BuildCircle()
end

function PANEL:SetTitle(title)
	self:SetTooltip(title)
	self.m_Title = title
end

function PANEL:SetMaterial(name)
	self.m_MaterialName = name
	local mat = Material(name)

	if not mat or mat:IsError() then
		return
	end

	self.Image:SetMaterial(mat)
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

local function CirclePoly(poly, centerX, centerY, radius)
	table.Empty(poly)

	if radius <= 0 then
		return
	end

	local segments = 32

	for i = 0, segments - 1 do
		local angle = math.rad((i / segments) * -360)
		local x = centerX + math.sin(angle) * radius
		local y = centerY + math.cos(angle) * radius

		table.insert(poly, { x = x, y = y })
	end
end

function PANEL:BuildCircle()
	local w, h = self:GetSize()

	local radius = math.min(w, h) / 2
	local radiusInner = radius - 4

	local centerX, centerY = w / 2, h / 2

	local circlePolyBorder = self.circlePolyBorder or {}
	self.circlePolyBorder = circlePolyBorder

	local circlePoly = self.circlePoly or {}
	self.circlePoly = circlePoly

	CirclePoly(circlePolyBorder, centerX, centerY, radius)
	CirclePoly(circlePoly, centerX, centerY, radiusInner)

	self.circlePolyCenterX = centerX
	self.circlePolyCenterY = centerY
	self.circlePolyRadius = radius
end

function PANEL:PerformLayout(w, h)
	self.Image:SetPos(0, 0)
	self.Image:SetSize(w, h)

	self:BuildCircle()
end

function PANEL:IsHovered(...)
	if not self.BaseClass.IsHovered(self, ...) then
		return false
	end

	local mouseX, mouseY = self:CursorPos()
	return self:IsInCircle(mouseX, mouseY)
end

function PANEL:IsChildHovered(...)
	if not self.BaseClass.IsChildHovered(self, ...) then
		return false
	end

	local mouseX, mouseY = self:CursorPos()
	return self:IsInCircle(mouseX, mouseY)
end

function PANEL:IsInCircle(x, y)
	local radiusSqr = self.circlePolyRadius ^ 2
	local dist = math.DistanceSqr(x, y, self.circlePolyCenterX, self.circlePolyCenterY)

	return dist <= radiusSqr
end

function PANEL:OnMousePressed(...)
	if not self:IsHovered() then return end
	self.BaseClass.OnMousePressed(self, ...)
end

function PANEL:OnMouseReleased(...)
	if not self:IsHovered() then return end
	self.BaseClass.OnMouseReleased(self, ...)
end

function PANEL:OnCursorMoved(x, y)
	if not self:IsInCircle(x, y) then
		return true
	end

	return false
end

function PANEL:OnCursorMoved(x, y)
	if not self:IsInCircle(x, y) then
		return true
	end

	return false
end


function PANEL:Think()
	local hovered = self:IsHovered()
	local oldhovered = self.oldHovered
	self.oldHovered = hovered

	if hovered == oldhovered then
		return
	end

	if hovered then
		self:SetCursorInternal(self:GetCursor())
		self:SetTooltipInternal(self:GetTooltip())
	else
		self:SetCursorInternal("arrow")
		self:SetTooltipInternal()
	end

	ChangeTooltip(self)
end

function PANEL:Paint(w, h)
	draw.NoTexture()

	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawPoly(self.circlePolyBorder)

	render.ClearStencil()
	render.SetStencilEnable(true)

	render.SetStencilWriteMask(1)
	render.SetStencilTestMask(1)
	render.SetStencilFailOperation(STENCILOPERATION_KEEP)
	render.SetStencilZFailOperation(STENCILOPERATION_KEEP)
	render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
	render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
	render.SetStencilReferenceValue(1)

	surface.SetDrawColor(255, 255, 255, 255)
	surface.DrawPoly(self.circlePoly)

	render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
	render.SetStencilPassOperation(STENCILOPERATION_KEEP)

	render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	render.PushFilterMin(TEXFILTER.ANISOTROPIC)

	self.Image:PaintAt(0, 0, w, h)

	render.PopFilterMin()
	render.PopFilterMag()

	if self:IsHovered() then
		surface.SetDrawColor(0, 0, 0, 50)
		surface.DrawRect(0, 0, w, h)
	end

	render.SetStencilEnable(false)
end

vgui.Register("SligWolf_ColorSkinPickerButton", PANEL, "DButton")

return true

