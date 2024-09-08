AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

DEFINE_BASECLASS("sligwolf_animatable")

ENT.Spawnable			= false
ENT.RenderGroup 		= RENDERGROUP_OPAQUE
ENT.DoNotDuplicate 		= true

if not SligWolf_Addons then return end
if not SligWolf_Addons.IsLoaded then return end
if not SligWolf_Addons.IsLoaded() then return end

function ENT:Initialize()
	BaseClass.Initialize(self)

	self:TurnOn(false)
end

function ENT:InitializePhysics()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetCollisionGroup(COLLISION_GROUP_WORLD)
end

function ENT:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:AddNetworkRVar("Entity", "MessureEntity")
	self:AddNetworkRVar("String", "PoseName")

	self:AddNetworkRVar("Bool", "Braking")
	self:AddNetworkRVar("Float", "Size")
	self:AddNetworkRVar("Float", "RestRate")
end

function ENT:WheelBrake(set)
	if CLIENT then return end

	self:SetNetworkRVar("Braking", set)
end

function ENT:WheelIsBraking()
	return self:GetNetworkRVar("Braking", false)
end

function ENT:SetWheelSize(num)
	if CLIENT then return end

	self:SetNetworkRVar("Size", num)
end

function ENT:GetWheelSize()
	return self:GetNetworkRVarNumber("Size", 0)
end

function ENT:SetWheelRestRate(num)
	if CLIENT then return end

	self:SetNetworkRVar("RestRate", num)
end

function ENT:GetWheelRestRate()
	return self:GetNetworkRVarNumber("RestRate", 0)
end

function ENT:SetWheelPoseName(name)
	if CLIENT then return end

	self:SetNetworkRVar("PoseName", name)
end

function ENT:GetWheelPoseName()
	return self:GetNetworkRVarString("PoseName", "spinloop")
end

function ENT:SetWheelMessureEntity(ent)
	if CLIENT then return end

	if not IsValid(ent) then
		return
	end

	self:SetNetworkRVar("MessureEntity", ent)
end

function ENT:GetWheelMessureEntity()
	local ent = self:GetNetworkRVar("MessureEntity")

	if not IsValid(ent) then
		return nil
	end

	return ent
end

function ENT:GetRelativeVelocity()
	local vent = self:GetWheelMessureEntity()

	if not IsValid(vent) then
		return Vector()
	end

	local v = vent:GetVelocity()
	local a = v:Angle()
	local len = v:Length()

	a = vent:WorldToLocalAngles(a)
	v = a:Forward() * len

	return v
end

function ENT:GetForwardVelocity()
	local v = self:GetRelativeVelocity()
	v = v.y or 0

	local now = CurTime()

	if self:WheelIsBraking() then
		self.LastForwardSpeedTime = now
		self.LastForwardSpeed = v

		return 0
	end

	if not self:IsOn() then
		local lasttime = self.LastForwardSpeedTime or now
		local diff = now - lasttime

		local oldv = self.LastForwardSpeed or 0
		if oldv ~= 0 then
			local factor = 1 - ((diff * self:GetWheelRestRate()) / math.abs(oldv))

			if factor <= 0.0001 then
				factor = 0
			end

			v = oldv * factor
		else
			v = 0
		end
	end

	self.LastForwardSpeedTime = now
	self.LastForwardSpeed = v

	return v
end

function ENT:GetRotationSpeed()
	local r = self:GetWheelSize()
	local v = self:GetForwardVelocity()

	if r <= 0 then return 0 end

	local u = r * 2 * math.pi
	local rot = v / u

	return rot
end

function ENT:UpdateRotation()
	local now = CurTime()
	local lastrot = self.LastRot or now
	local diff = now - lastrot

	local rot = self:GetRotationSpeed()

	self.Rot = (self.Rot or 0) + rot * diff * 360
	self.Rot = (self.Rot % 360)
	self.LastRot = now

	self:SetPoseParameter(self:GetWheelPoseName(), self.Rot)
	self:InvalidateBoneCache()
end

function ENT:ThinkInternal()
	BaseClass.ThinkInternal(self)

	if SERVER then return end
	self:UpdateRotation()
end

