AddCSLuaFile()

local PANEL = {}
AccessorFunc(PANEL, "m_ConVar", "ConVar")

function PANEL:Init()
	self.Label = vgui.Create("DLabel", self)
	self.NumPad = vgui.Create("DBinder", self)

	self.Label:SetDark(true)
	self:SetPaintBackground(false)
	
	self:SetHeight(50)
	self.NumPad:SetSize(200, 25)
end

function PANEL:SetLabel(txt)
	if (!txt) then return end

	self.Label:SetText(txt)
	self.Label:SizeToContents()
end

function PANEL:SetConVar(cvar)
	self.NumPad:SetConVar(cvar)
	self.m_ConVar = cvar
end

function PANEL:PerformLayout()
	self.NumPad:InvalidateLayout(true)

	self.Label:SizeToContents()
	self.Label:CenterHorizontal()
	self.Label:AlignTop(0)
	self.NumPad:CenterHorizontal()
	self.NumPad:AlignTop(20)
end

vgui.Register("SligWolf_Custom_CtrlNumPad", PANEL, "DPanel")