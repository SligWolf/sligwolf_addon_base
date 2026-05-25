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

function ENT:InitializePhysicsInternal()
	BaseClass.InitializePhysicsInternal(self)

	self:EnforceStatic()
	self._physicsInitialized = true
end

function ENT:InitializePhysics()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
end

function ENT:SetupDataTables()
	BaseClass.SetupDataTables(self)
	self:AddNetworkRVar("Bool", "staticPhysics")
end

function ENT:OnKeyValueSet(key, value)
	BaseClass.OnKeyValueSet(self, key, value)

	if key ~= "sligwolf_static" then
		return
	end

	if tobool(value) then
		self:ApplyStatic()
	end
end

function ENT:PhysicsCollide(colData, collider)
	-- override me
end

function ENT:ApplyStatic()
	if CLIENT then
		return
	end

	if self._physicsInitialized then
		-- This property has to be set before Spawn()/Activate() is called.
		return
	end

	self:SetNetworkRVar("staticPhysics", true)
end

function ENT:GetStatic()
	local isStatic = self:GetNetworkRVar("staticPhysics", false)
	if not isStatic then
		return false
	end

	local entTable = self:SligWolf_GetTable()

	local spawnerPlayer = entTable.spawnerPlayer
	if IsValid(spawnerPlayer) then
		-- Lose static property: Never allow players to create static entities.
		self:RemoveStatic()
		return false
	end

	if self._staticEnforced and self:IsMotionEnabled() then
		-- Lose static property: Motion has been enabled by external means, e.g. by nukes or admin mods.
		self:RemoveStatic()
		return false
	end

	return true
end

function ENT:EnforceStatic()
	if CLIENT then
		return
	end

	local isStatic = self:GetStatic()
	if not isStatic then
		return
	end

	self:EnableMotion(false)

	self.sligwolf_noBodySystemApplyMotion = true
	self._staticEnforced = true
end

function ENT:RemoveStatic()
	if not self._staticEnforced then
		return false
	end

	self._staticEnforced = nil

	self:EnableMotion(true)
	self.sligwolf_noBodySystemApplyMotion = false
	self:SetNetworkRVar("staticPhysics", false)
end

function ENT:DeleteSpawnSolidState()
	local entTable = self:SligWolf_GetTable()

	local spawnState = entTable.spawnState
	if not spawnState then
		return
	end

	spawnState.solid = nil
end

function ENT:CopySpawnPhysState(otherEnt)
	if not IsValid(otherEnt) then
		return
	end

	local entTableA = self:SligWolf_GetTable()
	local entTableB = otherEnt:SligWolf_GetTable()

	local spawnStateA = entTableA.spawnState
	if not spawnStateA then
		return
	end

	local spawnStateB = entTableB.spawnState
	if spawnStateB then
		return
	end

	entTableB.spawnState = table.Copy(spawnStateA)
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

function ENT:OnPhysgunPickup(ent, ply)
	-- override me
end

function ENT:OnPhysgunDrop(ent, ply)
	-- override me
end
