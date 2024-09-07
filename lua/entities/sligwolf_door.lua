AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

DEFINE_BASECLASS("sligwolf_phys")

ENT.Spawnable 				= false
ENT.AdminOnly 				= false
ENT.DoNotDuplicate 			= false

ENT.sligwolf_allowAnimation	= true

if not SligWolf_Addons then return end
if not SligWolf_Addons.IsLoaded then return end
if not SligWolf_Addons.IsLoaded() then return end

local CONSTANTS = SligWolf_Addons.Constants

function ENT:Initialize()
	BaseClass.Initialize(self)

	self:TurnOn(true)

	self:SetAutoClose(true)
	self:SetOpenTime(3)
	self:SetOpenSound(CONSTANTS.sndMetaldoorOpen)
	self:SetCloseSound(CONSTANTS.sndMetaldoorClose)

	if SERVER then
		self:SetUseType(SIMPLE_USE)
	end
end

function ENT:InitializePhysics()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
end

function ENT:PostInitialize()
	BaseClass.PostInitialize(self)

	if self:GetSpawnOpen() then
		self:OpenInternal()
	end

	self:CallStateEvent()
end

function ENT:ReinitializeModel()
	self:InitializePhysics()

	self:TimerNextFrame("ReinitializeModelRemount", function()
		self:OnModelReinitialized()
	end)
end

function ENT:OnModelReinitialized()
	-- Override me
end

function ENT:SetAutoClose(bool)
	if CLIENT then return end
	self._autoClose = bool or false
end

function ENT:GetAutoClose()
	if CLIENT then return end
	return self._autoClose or false
end

function ENT:SetOpenTime(num)
	if CLIENT then return end
	self._openTime = num or 3
end

function ENT:GetOpenTime()
	if CLIENT then return end
	return self._openTime or 3
end

function ENT:SetOpenModel(mdl)
	if CLIENT then return end
	self._openModel = mdl or ""
end

function ENT:GetOpenModel()
	if CLIENT then return end
	return self._openModel or ""
end

function ENT:SetCloseModel(mdl)
	if CLIENT then return end
	self._closeModel = mdl or ""
end

function ENT:GetCloseModel()
	if CLIENT then return end
	return self._closeModel or ""
end

function ENT:SetOpenSound(snd)
	if CLIENT then return end
	self._openSound = snd or CONSTANTS.sndNull
end

function ENT:GetOpenSound()
	if CLIENT then return end
	return self._openSound or CONSTANTS.sndNull
end

function ENT:SetCloseSound(snd)
	if CLIENT then return end
	self._closeSound = snd or CONSTANTS.sndNull
end

function ENT:GetCloseSound()
	if CLIENT then return end
	return self._closeSound or CONSTANTS.sndNull
end

function ENT:SetDisableUse(disableUse)
	if CLIENT then return end
	self._disableUse = disableUse or false
end

function ENT:GetDisableUse()
	if CLIENT then return end
	return self._disableUse or false
end

function ENT:SetSpawnOpen(spawnOpen)
	if CLIENT then return end
	self._spawnOpen = spawnOpen or false
end

function ENT:GetSpawnOpen()
	if CLIENT then return end
	return self._spawnOpen or false
end

function ENT:SetDoorModel(mdl)
	mdl = tostring(mdl or "")

	if mdl == "" then
		return
	end

	if self._oldDoorModel and mdl == self._oldDoorModel then
		return
	end

	self:SetModel(mdl)
	self:ReinitializeModel()

	self._oldDoorModel = mdl
end

function ENT:Use(activator, caller, useType, value)
	if CLIENT then return end
	if self:GetDisableUse() then return end

	self:Toggle()
end

function ENT:IsOpen()
	return self._isOpen or false
end

function ENT:Toggle()
	if CLIENT then return end

	if self:IsOpen() then
		self:Close()
	else
		self:Open()
	end
end

function ENT:Open()
	if CLIENT then return end
	if self:IsOpen() then return end
	if not self:IsOn() then return end

	self:OpenInternal()

	if self:GetAutoClose() then
		local opentime = self:GetOpenTime()

		self:TimerOnce("AutoCloseDoor", opentime, function()
			self:Close()
		end)
	end
end

function ENT:Close()
	if CLIENT then return end
	if not self:IsOpen() then return end
	if not self:IsOn() then return end

	self:CloseInternal()
end

function ENT:OpenInternal()
	if CLIENT then return end
	if self:IsOpen() then return end
	if not self:IsOn() then return end

	local osnd = self:GetOpenSound()
	local omdl = self:GetOpenModel()

	self:TimerRemove("AutoCloseDoor")
	self:TimerRemove("ReinitializeModelRemount")

	self:SetDoorModel(omdl)

	self:SetAnim("open")
	self:EmitSound(osnd)
	self._isOpen = true

	if omdl == "" then
		self:SetNotSolid(true)
	else
		self:SetNotSolid(false)
	end

	self:CallStateEvent()
end

function ENT:CloseInternal()
	if CLIENT then return end
	if not self:IsOpen() then return end
	if not self:IsOn() then return end

	local csnd = self:GetCloseSound()
	local cmdl = self:GetCloseModel()

	self:TimerRemove("AutoCloseDoor")
	self:TimerRemove("ReinitializeModelRemount")

	self:SetDoorModel(cmdl)

	self:SetAnim("close")
	self:EmitSound(csnd)
	self._isOpen = false

	self:SetNotSolid(false)

	self:CallStateEvent()
end

function ENT:CallStateEvent()
	if CLIENT then return end

	local open = self:IsOpen()
	local lastOpen = self._lastIsOpen
	self._lastIsOpen = open

	if lastOpen ~= nil and open == lastOpen then
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

