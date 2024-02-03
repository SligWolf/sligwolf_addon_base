AddCSLuaFile()
DEFINE_BASECLASS("gmod_sw_base")

ENT.Spawnable 				= false
ENT.AdminOnly 				= false
ENT.DoNotDuplicate 			= false

function ENT:Set_AutoClose(bool)
	if CLIENT then return end
	self.AutoClose = bool or false
end

function ENT:Get_AutoClose()
	if CLIENT then return end
	return self.AutoClose or false
end

function ENT:Set_OpenTime(num)
	if CLIENT then return end
	self.OpenTime = num or 3
end

function ENT:Get_OpenTime()
	if CLIENT then return end
	return self.OpenTime or 3
end

function ENT:Set_OpenSound(snd)
	if CLIENT then return end
	self.OpenSound = snd or "common/null.wav"
end

function ENT:Get_OpenSound()
	if CLIENT then return end
	return self.OpenSound or "common/null.wav"
end

function ENT:Set_CloseSound(snd)
	if CLIENT then return end
	self.CloseSound = snd or "common/null.wav"
end

function ENT:Get_CloseSound()
	if CLIENT then return end
	return self.CloseSound or "common/null.wav"
end

function ENT:KeyValue(key, value)
	if key == "model" then
		value = tostring(value or "")
		
		if value == "" then
			value = self:GetModel()
		end

		self:SetModel(value)
		return
	end
	
	if key == "skin" then
		value = tonumber(value) or self:GetSkin()
		self:SetSkin(value)
		return
	end

	if key == "addonname" then
		value = tostring(value or "")
		self:SetAddonID(value)
		return
	end
end

function ENT:Initialize()	
	self:TurnOn(true)
	
	self:Set_AutoClose(true)
	self:Set_OpenTime(3)
	self:Set_OpenSound("doors/door_metal_medium_open1.wav")
	self:Set_CloseSound("doors/door_metal_medium_close1.wav")
	
	if SERVER then
		self:SetUseType(SIMPLE_USE)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetCollisionGroup(COLLISION_GROUP_NONE)
	end
end

function ENT:Use(activator, caller, useType, value)
	if CLIENT then return end
	if self.denyuse then return end
	
	self:Open()
end

function ENT:IsOpen()
	return self.isopen or false
end

function ENT:Open()
	if CLIENT then return end
	if self:IsOpen() then return end
	if !self:IsOn() then return end
	
	local id = self:GetAddonID()
	local addon = SW_Addons.Addondata[id]
	if !addon then return end
	
	local osnd = self:Get_OpenSound()
	local atc = self:Get_AutoClose()
	local opt = self:Get_OpenTime()
	
	self:SetAnim("open")
	self:SetNotSolid(true)
	self:EmitSound(osnd, 70, 100)
	self.isopen = true
	
	if atc then
		addon:CreateUTimerOnEnt(self, "CloseDoor", opt, function(f_ent)
			if !IsValid(f_ent) then return end
			if !f_ent:IsOn() then return end
			f_ent:Close()
		end)
	end
end

function ENT:Close()	
	if CLIENT then return end
	if !self:IsOpen() then return end

	if !self:IsOn() then return end
	local csnd = self:Get_CloseSound()
	
	self:SetAnim("close")
	self:SetNotSolid(false)
	self:EmitSound(csnd, 70, 100)
	self.isopen = false
end