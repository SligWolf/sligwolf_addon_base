AddCSLuaFile()
DEFINE_BASECLASS("gmod_sw_base")

ENT.Spawnable			= false
ENT.RenderGroup 		= RENDERGROUP_BOTH
ENT.DoNotDuplicate 		= true

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
	if !CLIENT then return end
	
	local addon = self:GetAddon()
	if !addon then return end
	
	local entfuncs = addon.EntityFunctions
	if !entfuncs then return end
	
	local entfuncs = entfuncs[self:GetClass()]
	if !entfuncs then return end
	
	local name = self:GetDisplayFunctionName()
	local func = entfuncs[name]
	if !isfunction(func) then
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
	if !id then return pos, ang end
	
	local attachment = self:GetAttachment(id)
	if !attachment then return pos, ang end

	return attachment.Pos or pos, attachment.Ang or ang
end

function ENT:Initialize()	
	BaseClass.Initialize(self)
	self:TurnOn(false)
	
	self.attachmentname = nil
	self.displayname = nil
end

function ENT:OnRemove()
	BaseClass.OnRemove(self)
end

function ENT:Think()
	local isON = self:IsOn()

	if !isON then
		return
	end
	
	self:Debug(10)
end

function ENT:DrawTranslucent()
	if !CLIENT then return end
	self.BaseClass.DrawTranslucent(self)
	
	local isON = self:IsOn()
	if !isON then return end

	local func = self:GetDisplayFunction()
	if !func then return end

	local pos, ang = self:GetDisplayPos()
	local scale = self:Get_Scale()
	
	cam.Start3D2D(pos, ang, scale)
		func(self, scale)
	cam.End3D2D()
end

function ENT:Debug(Size, Col, Time, ...)
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