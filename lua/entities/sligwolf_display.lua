AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

DEFINE_BASECLASS("sligwolf_base")

ENT.Spawnable			= false
ENT.RenderGroup 		= RENDERGROUP_BOTH
ENT.DoNotDuplicate 		= true

if not SligWolf_Addons then return end
if not SligWolf_Addons.IsLoaded then return end
if not SligWolf_Addons.IsLoaded() then return end

function ENT:Initialize()
	BaseClass.Initialize(self)
	self:TurnOn(false)

	self.attachmentname = nil
	self.displayname = nil
end

function ENT:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:AddNetworkRVar("String", "DisplayFunctionName")
	self:AddNetworkRVar("String", "DisplayOriginName")
	self:AddNetworkRVar("Float", "Scale")
end

function ENT:Set_Scale(num)
	if CLIENT then return end
	self:SetNetworkRVar("Scale", num)
end

function ENT:Get_Scale()
	return self:GetNetworkRVarNumber("Scale", 1)
end

function ENT:SetDisplayFunctionName(name)
	if CLIENT then return end

	name = tostring(name or "")
	return self:SetNetworkRVar("DisplayFunctionName", name)
end

function ENT:GetDisplayFunctionName()
	return self:GetNetworkRVarString("DisplayFunctionName", "")
end

function ENT:SetDisplayOriginName(name)
	if CLIENT then return end

	name = tostring(name or "")
	return self:SetNetworkRVar("DisplayOriginName", name)
end

function ENT:GetDisplayOriginName()
	return self:GetNetworkRVarString("DisplayOriginName", "")
end

function ENT:GetDisplayFunction()
	if not CLIENT then return end

	local addon = self:GetAddon()
	if not addon then return end

	local entfuncs = addon.EntityFunctions
	if not entfuncs then return end

	local entfuncs = entfuncs[self:GetClass()]
	if not entfuncs then return end

	local name = self:GetDisplayFunctionName()
	local func = entfuncs[name]
	if not isfunction(func) then
		return nil
	end

	return func
end

function ENT:GetDisplayPos()
	local pos = self:GetPos()
	local ang = self:GetAngles()

	local name = self:GetDisplayOriginName()
	if name == "" then return pos, ang end

	local id = self:LookupAttachment(name)
	if not id then return pos, ang end

	local attachment = self:GetAttachment(id)
	if not attachment then return pos, ang end

	return attachment.Pos or pos, attachment.Ang or ang
end

function ENT:OnRemove()
	BaseClass.OnRemove(self)
end

function ENT:Think()
	local isON = self:IsOn()

	if not isON then
		return
	end

	self:Debug(10)
end

function ENT:DrawTranslucent(...)
	if not CLIENT then return end
	self.BaseClass.DrawTranslucent(self, ...)

	local isON = self:IsOn()
	if not isON then return end

	local func = self:GetDisplayFunction()
	if not func then return end

	local pos, ang = self:GetDisplayPos()
	local scale = self:Get_Scale()

	cam.Start3D2D(pos, ang, scale)
		func(self, scale)
	cam.End3D2D()
end

function ENT:Debug(Size, Col, Time, ...)
	if not self:IsDeveloper() then
		return
	end

	Size = Size or 10
	Col = Col or color_white
	Time = Time or FrameTime()

	local dpos, dang = self:GetDisplayPos()
	local originname = self:GetDisplayOriginName()
	local debugtext = tostring(self) .. " 2d3dpos ('" .. originname .. "')"

	debugoverlay.EntityTextAtPosition(dpos, 0, debugtext, Time, color_white)
	debugoverlay.Axis(dpos, dang, Size, Time, true)
	debugoverlay.Cross(dpos, Size / 10, Time, Col, true)
end

