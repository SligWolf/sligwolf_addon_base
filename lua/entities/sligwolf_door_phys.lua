AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

DEFINE_BASECLASS("sligwolf_phys")

ENT.Spawnable 				= false
ENT.AdminOnly 				= false
ENT.DoNotDuplicate 			= true

if not SligWolf_Addons then return end
if not SligWolf_Addons.IsLoaded then return end
if not SligWolf_Addons.IsLoaded() then return end

local LIBEntities = SligWolf_Addons.Entities

local g_massInNotActiveState = 1

function ENT:Initialize()
	BaseClass.Initialize(self)

	if SERVER then
		self:SetUseType(SIMPLE_USE)
	end

	self:SetDoorPhysSolid(false)
end

function ENT:InitializePhysics()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
end

function ENT:Use(...)
	local parent = LIBEntities.GetParent(self)
	if not IsValid(parent) then return end

	parent:Use(...)
end

function ENT:UpdateDoorPhysSolid()
	self:SetDoorPhysSolid(self._isSolid or false)
end

function ENT:SetDoorPhysSolid(solid)
	local phys = self:GetPhysicsObject()
	if not IsValid(phys) then return end

	local oldSolid = self._isSolid
	self._isSolid = solid

	if oldSolid == solid then
		return
	end

	self:SetNotSolid(not solid)

	if solid then
		phys:SetMass(self._oldMass or g_massInNotActiveState)
		self._oldMass = nil
	else
		self._oldMass = phys:GetMass()
		phys:SetMass(g_massInNotActiveState)
	end
end

