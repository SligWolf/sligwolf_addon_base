AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

DEFINE_BASECLASS("sligwolf_phys")

ENT.Spawnable 				= false
ENT.AdminOnly 				= false
ENT.DoNotDuplicate 			= false

ENT.sligwolf_bogieEntity    = true
ENT.sligwolf_isBody         = true

if not SligWolf_Addons then return end
if not SligWolf_Addons.IsLoaded then return end
if not SligWolf_Addons.IsLoaded() then return end

local LIBEntities = SligWolf_Addons.Entities
local LIBPhysgun = SligWolf_Addons.Physgun
local LIBRail = SligWolf_Addons.Rail

function ENT:Initialize()
	BaseClass.Initialize(self)

	if not SERVER then
		return
	end

	self.shouldAttemptToRealign = false
end

function ENT:InitializePhysics()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
end

function ENT:GetWagonBodyIndex()
	local wagonBodyIndex = self.wagonBodyIndex

	if wagonBodyIndex then
		return wagonBodyIndex
	end

	local wagon = LIBEntities.GetParentBody(self)
	if not IsValid(wagon) then
		return nil
	end

	local bogies = LIBRail.GetWagonBogies(wagon) or {}
	local wagonEntities = LIBEntities.GetBodyEntities(wagon) or {}

	wagonBodyIndex = {}
	self.wagonBodyIndex = wagonBodyIndex

	for _, bogie in pairs(wagonEntities) do
		wagonBodyIndex[bogie:EntIndex()] = bogie
	end

	for _, bogie in pairs(bogies) do
		local bogieEntities = LIBEntities.GetBodyEntities(bogie)
		if not bogieEntities then
			continue
		end

		for i, child in ipairs(bogieEntities) do
			wagonBodyIndex[child:EntIndex()] = child
		end
	end

	-- @DEBUG: Highlight entities that would trigger realignment when being touched
	-- SligWolf_Addons.Debug.HighlightEntities(wagonBodyIndex)

	return wagonBodyIndex
end

function ENT:IsWagonBodyPhysgunCarried()
	local entities = self:GetPhysgunCarriedEntities()
	if not entities then
		return false
	end

	local wagonBodyIndex = self:GetWagonBodyIndex()
	if not wagonBodyIndex then
		return false
	end

	for thisEntId, _ in pairs(entities) do
		if wagonBodyIndex[thisEntId] then
			return true
		end
	end

	return false
end

function ENT:OnPhysgunPickup(directlyCarried, ply)
	self:UpdateCheckForRealign()

	if self.shouldAttemptToRealign then
		self:RealignThink()
	end
end

function ENT:OnPhysgunDrop(directlyDropped, ply)
	self:UpdateCheckForRealign()

	if self.shouldAttemptToRealign then
		self:RealignThink()
	end
end

function ENT:IsOnRail(bypassCache)
	return LIBRail.IsOnRail(self, bypassCache)
end

function ENT:ThinkInternal()
	BaseClass.ThinkInternal(self)

	if not SERVER then
		return
	end

	local nextAutoUpdateCheckForRealign = self.nextAutoUpdateCheckForRealign or 0
	local now = CurTime()

	if nextAutoUpdateCheckForRealign < now then
		self:UpdateCheckForRealign()
	end

	if self.shouldAttemptToRealign then
		self:RealignThink()
	end

	local nextAutoUnlockFromMount = self.nextAutoUnlockFromMount
	if nextAutoUnlockFromMount and nextAutoUnlockFromMount < now then
		self:UnlockFromMount()
	end

	self:NextThink( now + 0.20 )
	return true
end

function ENT:UpdateCheckForRealign()
	self.shouldAttemptToRealign = self:CanRealign()
	self.nextAutoUpdateCheckForRealign = CurTime() + 0.10
end

function ENT:CanRealign()
	local phys = self:GetPhysicsObject()
	if not IsValid(phys) then
		return false
	end

	if not phys:IsMotionEnabled() then
		-- don't realign frozen bogies
		return false
	end

	if self:IsPhysgunCarried(LIBPhysgun.ENUM_PHYSGUN_CARRIED_MODE_BODY) then
		-- don't bogies being held
		return false
	end

	if not self:IsWagonBodyPhysgunCarried() then
		-- check if the wagon (or one of its sub parts) is held
		return false
	end

	return true
end

function ENT:RealignThink()
	if self:IsOnRail() then
		return
	end

	self:LockToMount()
end

function ENT:LockToMount()
	if not self.nextAutoUnlockFromMount then
		LIBEntities.SetUnsolidToPlayerRecursive(self, true)
		LIBEntities.LockEntityToMountPoint(self)
	end

	self.nextAutoUnlockFromMount = CurTime() + 0.5
end

function ENT:UnlockFromMount()
	if self.nextAutoUnlockFromMount then
		LIBEntities.UnlockEntityFromMountPoint(self)
		LIBEntities.SetUnsolidToPlayerRecursive(self, false)
	end

	self.nextAutoUnlockFromMount = nil
end