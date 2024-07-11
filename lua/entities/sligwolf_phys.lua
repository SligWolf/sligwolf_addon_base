AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

DEFINE_BASECLASS("sligwolf_base")

ENT.Spawnable 				= false
ENT.AdminOnly 				= false
ENT.PhysicsSounds			= true
ENT.DoNotDuplicate 			= false

ENT.sligwolf_physEntity     = true
ENT.sligwolf_physBaseEntity = true

if not SligWolf_Addons then return end
if not SligWolf_Addons.IsLoaded then return end
if not SligWolf_Addons.IsLoaded() then return end

local LIBEntities = SligWolf_Addons.Entities
local LIBPhysgun = SligWolf_Addons.Physgun
local LIBPhysics = SligWolf_Addons.Physics

function ENT:Initialize()
	BaseClass.Initialize(self)
	LIBPhysics.InitializeAsPhysEntity(self)
end

function ENT:InitializePhysics()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
end

function ENT:PhysicsCollide(colData, collider)
	-- override me
end

function ENT:UpdateBodySystemMotion(delayed)
	LIBEntities.UpdateBodySystemMotion(self, delayed)
end

function ENT:IsPhysgunCarried(checkMode)
	return LIBPhysgun.IsPhysgunCarried(self, checkMode)
end

function ENT:GetPhysgunCarringPlayers()
	return LIBPhysgun.GetPhysgunCarringPlayers(self)
end

function ENT:GetPhysgunCarriedEntities()
	return LIBPhysgun.GetPhysgunCarriedEntities(self)
end

function ENT:OnPhysgunPickup(directlyCarried, ply)
	-- override me
end

function ENT:OnPhysgunDrop(directlyDropped, ply)
	-- override me
end
