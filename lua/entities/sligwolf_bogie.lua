AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

DEFINE_BASECLASS("sligwolf_phys")

ENT.Spawnable 				= false
ENT.AdminOnly 				= false
ENT.DoNotDuplicate 			= false

ENT.sligwolf_bogieEntity    = true

if not SligWolf_Addons then return end
if not SligWolf_Addons.IsLoaded then return end
if not SligWolf_Addons.IsLoaded() then return end

local LIBRail = SligWolf_Addons.Rail
local LIBPhysgun = SligWolf_Addons.Physgun
local LIBEntities = SligWolf_Addons.Entities

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

function ENT:CanApplyBodySystemMotionFrom(sourceEnt, motion)
	if sourceEnt == self then
		return true
	end

	if srcEnt.sligwolf_bogieEntity then
		return false
	end

	if srcEnt.sligwolf_sliderEntity then
		return false
	end

	-- @todo

	return true
end

function ENT:CanApplyBodySystemMotionFor(targetEnt, motion)
	if targetEnt == self then
		return true
	end

	if targetEnt.sligwolf_sliderEntity then
		return true
	end

	-- @todo

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

function ENT:IsOnRail()
	return LIBRail.IsOnRail(self)
end

function ENT:Think()
	BaseClass.Think(self)

	if not SERVER then
		return
	end

	local nextAutoUpdateCheckForRealign = self.nextAutoUpdateCheckForRealign or 0
	local now = CurTime()

	if nextAutoUpdateCheckForRealign < now then
		self:UpdateCheckForRealign()
	end

	local nextTick = 0.25

	if self.shouldAttemptToRealign then
		self:RealignThink()
	end

	local nextAutoUnlockFromMount = self.nextAutoUnlockFromMount
	if nextAutoUnlockFromMount and nextAutoUnlockFromMount < now then
		self:UnlockFromMount()
	end

	self:NextThink( now + nextTick )
	return true
end

function ENT:UpdateCheckForRealign()
	self.shouldAttemptToRealign = self:CanRealign()
	self.nextAutoUpdateCheckForRealign = CurTime() + 0.10
end

function ENT:CanRealign()
	if not self:IsPhysgunCarried(LIBPhysgun.PHYSGUN_CARRIED_MODE_BODY) then
		return false
	end

	if self:IsPhysgunCarried(LIBPhysgun.PHYSGUN_CARRIED_MODE_DIRECT) then
	 	return false
	end

	return true
end

function ENT:RealignThink()
	if self:IsOnRail() then
		-- @todo fix tracers
		return
	end

	self:LockToMount()
end

function ENT:LockToMount()
	if not self.nextAutoUnlockFromMount then
		LIBEntities.LockEntityToMountPoint(self)
	end

	self.nextAutoUnlockFromMount = CurTime() + 0.5
end

function ENT:UnlockFromMount()
	if self.nextAutoUnlockFromMount then
		LIBEntities.UnlockEntityFromMountPoint(self)
	end

	self.nextAutoUnlockFromMount = nil
end