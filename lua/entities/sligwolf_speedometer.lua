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

	self:SetSpeedoMinSpeed(0)
	self:SetSpeedoMaxSpeed(1312)
	self:SetSpeedoMinPoseValue(0)
	self:SetSpeedoMaxPoseValue(1)

	self:SetSpeedoMessureEntity(self)
	self:SetSpeedoPoseName("vehicle_guage")
end

function ENT:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:AddNetworkRVar("Entity", "MessureEntity")
	self:AddNetworkRVar("String", "PoseName")

	self:AddNetworkRVar("Float", "MinSpeed")
	self:AddNetworkRVar("Float", "MaxSpeed")
	self:AddNetworkRVar("Float", "MinPoseValue")
	self:AddNetworkRVar("Float", "MaxPoseValue")
end

function ENT:SetSpeedoMinSpeed(speed)
	if CLIENT then return end

	speed = tonumber(speed or 0) or 0

	if speed < 0 then
		speed = 0
	end

	self:SetNetworkRVar("MinSpeed", speed)
end

function ENT:GetSpeedoMinSpeed()
	return self:GetNetworkRVarNumber("MinSpeed", 0)
end

function ENT:SetSpeedoMaxSpeed(speed)
	if CLIENT then return end

	speed = tonumber(speed or 0) or 0

	if speed < 0 then
		speed = 0
	end

	self:SetNetworkRVar("MaxSpeed", speed)
end

function ENT:GetSpeedoMaxSpeed()
	return self:GetNetworkRVarNumber("MaxSpeed", 0)
end

function ENT:SetSpeedoMinPoseValue(poseValue)
	if CLIENT then return end

	poseValue = tonumber(poseValue or 0) or 0

	self:SetNetworkRVar("MinPoseValue", poseValue)
end

function ENT:GetSpeedoMinPoseValue()
	return self:GetNetworkRVarNumber("MinPoseValue", 0)
end

function ENT:SetSpeedoMaxPoseValue(poseValue)
	if CLIENT then return end

	poseValue = tonumber(poseValue or 0) or 0

	self:SetNetworkRVar("MaxPoseValue", poseValue)
end

function ENT:GetSpeedoMaxPoseValue()
	return self:GetNetworkRVarNumber("MaxPoseValue", 0)
end

function ENT:SetSpeedoPoseName(poseName)
	if CLIENT then return end

	poseName = tostring(poseName or "")
	self:SetNetworkRVar("PoseName", poseName)
end

function ENT:GetSpeedoPoseName()
	return self:GetNetworkRVarString("PoseName", "vehicle_guage")
end

function ENT:SetSpeedoMessureEntity(ent)
	if CLIENT then return end

	if not IsValid(ent) then
		return
	end

	self:SetNetworkRVar("MessureEntity", ent)
end

function ENT:GetSpeedoMessureEntity()
	local ent = self:GetNetworkRVar("MessureEntity")

	if not IsValid(ent) then
		return nil
	end

	return ent
end

function ENT:GetRelativeVelocity()
	local vent = self:GetSpeedoMessureEntity()

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

function ENT:GetSpeed()
	local v = self:GetRelativeVelocity()
	v = math.abs(v.y or 0)

	return v
end

function ENT:GuagePose()
	local speed = self:GetSpeed()

	local minSpeed = self:GetSpeedoMinSpeed()
	local maxSpeed = self:GetSpeedoMaxSpeed()

	if minSpeed >= maxSpeed then
		return nil
	end

	local minPoseValue = self:GetSpeedoMinPoseValue()
	local maxPoseValue = self:GetSpeedoMaxPoseValue()

	local pose = math.Remap(speed, minSpeed, maxSpeed, minPoseValue, maxPoseValue)
	return pose
end

function ENT:UpdateGuagePose()
	local pose = self:GuagePose()
	if not pose then
		return
	end

	local poseName = self:GetSpeedoPoseName()

	self:SetPoseParameter(poseName, pose)
	self:InvalidateBoneCache()
end

function ENT:ThinkInternal()
	BaseClass.ThinkInternal(self)

	if SERVER then return end
	self:UpdateGuagePose()
end

