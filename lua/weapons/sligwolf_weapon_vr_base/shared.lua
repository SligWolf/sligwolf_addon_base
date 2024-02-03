AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

DEFINE_BASECLASS("sligwolf_weapon_base")

SWEP.Spawnable				= false
SWEP.AdminOnly				= false

SWEP.sligwolf_vrBaseEntity 	= true

if not SligWolf_Addons then return end
if not SligWolf_Addons.IsLoaded then return end
if not SligWolf_Addons.IsLoaded() then return end

local LIBVR = SligWolf_Addons.VR

SWEP.VrViewModelOffset = {
	pos = Vector(0, 0, 0),
	ang = Angle(0, 0, 0),
}

SWEP.VrTraceHandOffset = {
	pos = Vector(0, 0, 0),
	ang = Angle(0, 0, 0),
}

local Vector_Zero = Vector()
local Angle_Zero = Angle()

function SWEP:IsInVR()
	return LIBVR.IsPlayerInVR(self:GetOwner())
end

function SWEP:GetRightHandPose()
	local rhPos, rhAng = vrmod.GetRightHandPose(self:GetOwner())

	if not rhPos or not rhAng then
		return nil, nil
	end

	local VrTraceHandOffset = self.VrTraceHandOffset or {}
	local offsetPos = VrTraceHandOffset.pos or Vector_Zero
	local offsetAng = VrTraceHandOffset.ang or Angle_Zero

	local rhPos, rhAng = LocalToWorld(
		offsetPos,
		offsetAng,
		rhPos,
		rhAng
	)

	rhAng:Normalize()

	debugoverlay.Axis(rhPos, rhAng, 3, 0.05, true)
	debugoverlay.EntityTextAtPosition(rhPos, 0, "SWEP:GetRightHandPose()", 0.1, color_white)

	return rhPos, rhAng
end

function SWEP:GetHMDPose()
	local pos, ang = vrmod.GetHMDPose(self:GetOwner())

	if not pos or not ang then
		return nil, nil
	end

	return pos, ang
end

function SWEP:Initialize()
	BaseClass.Initialize(self)

	self:ApplyVrViewModelOffset()
end

function SWEP:ApplyVrViewModelOffset()
	if not vrmod then return end
	if not isfunction(vrmod.SetViewModelOffsetForWeaponClass) then return end

	vrmod.SetViewModelOffsetForWeaponClass(
		self:GetClass(),
		self.VrViewModelOffset.pos or Vector_Zero,
		self.VrViewModelOffset.ang or Angle_Zero
	)
end

function SWEP:GetRightHandToWorld(localPos, localAng)
	local rhPos, rhAng = self:GetRightHandPose()

	if not rhPos or not rhAng then
		return nil, nil
	end

	localPos = localPos or Vector_Zero
	localAng = localAng or Angle_Zero

	local worldPos, worldAng = LocalToWorld(
		localPos,
		localAng,
		rhPos,
		rhAng
	)

	if not worldPos or not worldAng then
		return nil, nil
	end

	return worldPos, worldAng
end

function SWEP:GetHMDToWorld(localPos, localAng)
	local pos, ang = self:GetHMDPose()

	if not pos or not ang then
		return nil, nil
	end

	localPos = localPos or Vector_Zero
	localAng = localAng or Angle_Zero

	local worldPos, worldAng = LocalToWorld(
		localPos,
		localAng,
		pos,
		ang
	)

	if not worldPos or not worldAng then
		return nil, nil
	end

	return worldPos, worldAng
end

function SWEP:GetVrHMDPos()
	local pos = self:GetHMDToWorld()
	if not pos then return nil end

	return pos
end

function SWEP:VRSwingAttack(tr, velocityAbs)
	-- Override me
end

function SWEP:OnVRExit()
	-- override me
end

function SWEP:OnVRStart()
	-- override me
end

function SWEP:OnVRStateChange(state)
	-- override me
end

function SWEP:OnVRThink()
	-- override me
end

function SWEP:OnDrop()
	BaseClass.OnDrop(self)
	self:CallMethodWithErrorNoHalt("OnVRExit")

	return true
end

function SWEP:OnRemove()
	BaseClass.OnRemove(self)
	self:CallMethodWithErrorNoHalt("OnVRExit")

	return true
end

function SWEP:Holster()
	BaseClass.Holster(self)
	self:CallMethodWithErrorNoHalt("OnVRExit")

	return true
end

function SWEP:VRPollInternal()
	local LastVRState = self.wasVR or false
	local VRState = self:IsInVR()
	self.isVR = VRState

	if VRState ~= LastVRState then
		if VRState then
			self:CallMethodWithErrorNoHalt("OnVRStart")
		else
			self:CallMethodWithErrorNoHalt("OnVRExit")
		end

		self:CallMethodWithErrorNoHalt("OnVRStateChange", VRState)
		self.wasVR = VRState
	end

	if VRState then
		self:CallMethodWithErrorNoHalt("OnVRThink")
	end
end

function SWEP:Think()
	BaseClass.Think(self)

	self:VRPollInternal()
end

