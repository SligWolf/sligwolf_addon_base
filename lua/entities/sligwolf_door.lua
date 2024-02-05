AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

DEFINE_BASECLASS("sligwolf_phys")

ENT.Spawnable 				= false
ENT.AdminOnly 				= false
ENT.DoNotDuplicate 			= false

if not SligWolf_Addons then return end
if not SligWolf_Addons.IsLoaded then return end
if not SligWolf_Addons.IsLoaded() then return end

local CONSTANTS = SligWolf_Addons.Constants

function ENT:Initialize()
	BaseClass.Initialize(self)

	self:TurnOn(true)

	self:Set_AutoClose(true)
	self:Set_OpenTime(3)
	self:Set_OpenSound(CONSTANTS.sndMetaldoorOpen)
	self:Set_CloseSound(CONSTANTS.sndMetaldoorClose)

	if SERVER then
		self:SetUseType(SIMPLE_USE)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetCollisionGroup(COLLISION_GROUP_NONE)
	end
end

function ENT:PostInitialize()
	BaseClass.PostInitialize(self)

	if self:Get_SpawnOpen() then
		self:OpenInternal()
	end

	self:CallStateEvent()
end

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
	self.OpenSound = snd or CONSTANTS.sndNull
end

function ENT:Get_OpenSound()
	if CLIENT then return end
	return self.OpenSound or CONSTANTS.sndNull
end

function ENT:Set_CloseSound(snd)
	if CLIENT then return end
	self.CloseSound = snd or CONSTANTS.sndNull
end

function ENT:Get_CloseSound()
	if CLIENT then return end
	return self.CloseSound or CONSTANTS.sndNull
end

function ENT:Set_DisableUse(disableUse)
	if CLIENT then return end
	self.DisableUse = disableUse or false
end

function ENT:Get_DisableUse()
	if CLIENT then return end
	return self.DisableUse or false
end

function ENT:Set_SpawnOpen(spawnOpen)
	if CLIENT then return end
	self.SpawnOpen = spawnOpen or false
end

function ENT:Get_SpawnOpen()
	if CLIENT then return end
	return self.SpawnOpen or false
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

function ENT:Use(activator, caller, useType, value)
	if CLIENT then return end
	if self:Get_DisableUse() then return end

	self:Open()
end

function ENT:IsOpen()
	return self.isOpen or false
end

function ENT:Open()
	if CLIENT then return end
	if self:IsOpen() then return end
	if not self:IsOn() then return end

	self:OpenInternal()

	if self:Get_AutoClose() then
		local opentime = self:Get_OpenTime()

		self:TimerOnce("CloseDoor", opentime, function()
			self:Close()
		end)
	end
end

function ENT:OpenInternal()
	if CLIENT then return end
	if self:IsOpen() then return end
	if not self:IsOn() then return end

	local osnd = self:Get_OpenSound()

	self:TimerRemove("CloseDoor")

	self:SetAnim("open")
	self:SetNotSolid(true)
	self:EmitSound(osnd)
	self.isOpen = true

	self:CallStateEvent()
end

function ENT:Close()
	if CLIENT then return end
	if not self:IsOpen() then return end
	if not self:IsOn() then return end

	local csnd = self:Get_CloseSound()

	self:TimerRemove("CloseDoor")

	self:SetAnim("close")
	self:SetNotSolid(false)
	self:EmitSound(csnd)
	self.isOpen = false

	self:CallStateEvent()
end

function ENT:CallStateEvent()
	if CLIENT then return end

	local open = self:IsOpen()
	local lastOpen = self.lastIsOpen
	self.lastIsOpen = open

	if open == lastOpen then
		return
	end

	if open then
		self:OnOpen()
	else
		self:OnClose()
	end
end

function ENT:OnClose()
	-- override me
end

function ENT:OnOpen()
	-- override me
end

