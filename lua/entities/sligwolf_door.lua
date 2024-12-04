AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

DEFINE_BASECLASS("sligwolf_door_phys")

ENT.Spawnable 			= false
ENT.AdminOnly 			= false
ENT.DoNotDuplicate 		= false

ENT.sligwolf_allowAnimation	= true

if not SligWolf_Addons then return end
if not SligWolf_Addons.IsLoaded then return end
if not SligWolf_Addons.IsLoaded() then return end

local CONSTANTS = SligWolf_Addons.Constants

local LIBConstraints = SligWolf_Addons.Constraints
local LIBEntities = SligWolf_Addons.Entities
local LIBModel = SligWolf_Addons.Model

function ENT:Initialize()
	BaseClass.Initialize(self)

	self:TurnOn(true)

	self:SetDoorAutoClose(true)
	self:SetDoorOpenTime(3)
	self:SetDoorOpenSound(CONSTANTS.sndMetaldoorOpen)
	self:SetDoorCloseSound(CONSTANTS.sndMetaldoorClose)

	if SERVER then
		self:SetUseType(SIMPLE_USE)
	end

	self:SetDoorPhysSolid(true)
end

function ENT:InitializePhysics()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
end

function ENT:PostInitialize()
	BaseClass.PostInitialize(self)

	self:UpdateCollisionEntity()

	if self:GetDoorSpawnOpen() then
		self:OpenInternal()
	end

	self:CallStateEvent()
end

function ENT:SetDoorAutoClose(bool)
	if CLIENT then return end
	self._autoClose = bool or false
end

function ENT:GetDoorAutoClose()
	if CLIENT then return end
	return self._autoClose or false
end

function ENT:SetDoorOpenTime(num)
	if CLIENT then return end
	self._openTime = num or 3
end

function ENT:GetDoorOpenTime()
	if CLIENT then return end
	return self._openTime or 3
end

function ENT:SetDoorOpenPhysModel(mdl)
	if CLIENT then return end

	self._openPhysModel = mdl or ""
	self:UpdateCollisionEntity()
end

function ENT:GetDoorOpenPhysModel()
	if CLIENT then return end
	return self._openPhysModel or ""
end

function ENT:SetDoorOpenSound(snd)
	if CLIENT then return end
	self._openSound = snd or CONSTANTS.sndNull
end

function ENT:GetDoorOpenSound()
	if CLIENT then return end
	return self._openSound or CONSTANTS.sndNull
end

function ENT:SetDoorCloseSound(snd)
	if CLIENT then return end
	self._closeSound = snd or CONSTANTS.sndNull
end

function ENT:GetDoorCloseSound()
	if CLIENT then return end
	return self._closeSound or CONSTANTS.sndNull
end

function ENT:SetDoorDisableUse(disableUse)
	if CLIENT then return end
	self._disableUse = disableUse or false
end

function ENT:GetDoorDisableUse()
	if CLIENT then return end
	return self._disableUse or false
end

function ENT:SetDoorSpawnOpen(spawnOpen)
	if CLIENT then return end
	self._spawnOpen = spawnOpen or false
end

function ENT:GetDoorSpawnOpen()
	if CLIENT then return end
	return self._spawnOpen or false
end

function ENT:Use(activator, caller, useType, value)
	if CLIENT then return end
	if self:GetDoorDisableUse() then return end

	self:Toggle()
end

function ENT:UpdateCollisionEntity(force)
	if CLIENT then return end

	local mdl = self:GetDoorOpenPhysModel()

	local oldmdl = self._oldOpenModel or ""
	self._oldOpenModel = mdl

	if force or mdl ~= oldmdl then
		self:SpawnCollisionEntity(mdl)
		self:UpdateDoorPhysSolid()
	end
end

function ENT:GetCollisionEntity()
	if not IsValid(self._collisionProp) then
		return
	end

	return self._collisionProp
end

function ENT:SpawnCollisionEntity(mdl)
	if CLIENT then return end

	mdl = mdl or ""

	LIBEntities.RemoveEntityWithNoCallback(self._collisionProp)
	LIBEntities.RemoveEntityWithNoCallback(self._collisionPropConst)

	self._collisionProp = nil
	self._collisionPropConst = nil

	if mdl == "" then
		return
	end

	local Prop = self:MakeEntEnsured("sligwolf_door_phys", "CollisionProp")
	if not IsValid(Prop) then
		return
	end

	Prop.DoNotDuplicate = true

	LIBModel.SetModel(Prop, mdl)
	Prop:SetPos(self:GetPos())
	Prop:SetAngles(self:GetAngles())

	Prop:Spawn()
	Prop:Activate()

	local doorParent = LIBEntities.GetParent(self)

	local WD = LIBConstraints.Weld(Prop, doorParent, {nocollide = true})
	if not IsValid(WD) then
		self:RemoveFaultyEntities(
			{self, doorParent, Prop},
			"Couldn't create weld constraint 'WD' between %s <===> %s. Removing entities.",
			doorParent,
			Prop
		)

		return
	end

	local respawn = function(thisent, withEffect)
		if withEffect then
			return
		end

		if LIBEntities.IsMarkedForDeletion(self) then
			return
		end

		self:TimerNextFrame("RespawnCollision", function()
			if LIBEntities.IsMarkedForDeletion(self) then
				return
			end

			self:UpdateCollisionEntity(true)
		end)
	end

	LIBEntities.RemoveEntitiesOnDelete(self, Prop)
	LIBEntities.RemoveEntitiesOnDelete(WD, Prop)

	LIBEntities.CallOnRemove(Prop, "RespawnCollision", respawn)

	self._collisionProp = Prop
	self._collisionPropConst = WD

	self:UpdateBodySystemMotion()
	return Prop
end

function ENT:UpdateDoorPhysSolid()
	BaseClass.UpdateDoorPhysSolid(self)

	local collision = self:GetCollisionEntity()
	if not collision then return end

	collision:UpdateDoorPhysSolid()
end

function ENT:SetDoorPhysSolid(solid)
	BaseClass.SetDoorPhysSolid(self, solid)

	local collision = self:GetCollisionEntity()
	if not collision then return end

	collision:SetDoorPhysSolid(not solid)
end

function ENT:DoorIsOpen()
	return self._isOpen or false
end

function ENT:Toggle()
	if CLIENT then return end

	if self:DoorIsOpen() then
		self:DoorClose()
	else
		self:DoorOpen()
	end
end

function ENT:DoorOpen()
	if CLIENT then return end
	if self:DoorIsOpen() then return end
	if not self:IsOn() then return end

	self:OpenInternal()

	if self:GetDoorAutoClose() then
		local opentime = self:GetDoorOpenTime()

		self:TimerOnce("AutoCloseDoor", opentime, function()
			self:DoorClose()
		end)
	end
end

function ENT:DoorClose()
	if CLIENT then return end
	if not self:DoorIsOpen() then return end
	if not self:IsOn() then return end

	self:CloseInternal()
end

function ENT:OpenInternal()
	if CLIENT then return end
	if self:DoorIsOpen() then return end
	if not self:IsOn() then return end

	local osnd = self:GetDoorOpenSound()

	self:TimerRemove("AutoCloseDoor")

	self:SetAnim("open")
	self:EmitSound(osnd)
	self:SetDoorPhysSolid(false)
	self._isOpen = true

	self:CallStateEvent()
end

function ENT:CloseInternal()
	if CLIENT then return end
	if not self:DoorIsOpen() then return end
	if not self:IsOn() then return end

	local csnd = self:GetDoorCloseSound()

	self:TimerRemove("AutoCloseDoor")

	self:SetAnim("close")
	self:EmitSound(csnd)
	self:SetDoorPhysSolid(true)
	self._isOpen = false

	self:CallStateEvent()
end

function ENT:CallStateEvent()
	if CLIENT then return end

	local open = self:DoorIsOpen()
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

