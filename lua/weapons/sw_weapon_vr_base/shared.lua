AddCSLuaFile()
DEFINE_BASECLASS("sw_weapon_base")

SWEP.Spawnable				= false
SWEP.AdminOnly				= false
SWEP.__IsSW_Entity 			= true

SWEP.VrViewModelOffset = {
	pos = Vector(0,0,0),
	ang = Angle(0,0,0),
}

SWEP.VrTraceHandOffset = {
	pos = Vector(0,0,0),
	ang = Angle(0,0,0),
}

local Vector_Zero = Vector()
local Angle_Zero = Angle()

function SWEP:IsInVR()
	local Addon = self:GetAddon()
	if !Addon then return nil, nil end

	return Addon:VRIsPlayerInVR(self.Owner)
end

function SWEP:GetRightHandPose()
	local rhPos, rhAng = vrmod.GetRightHandPose(self.Owner)
	
	if !rhPos or !rhAng then
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
	local pos, ang = vrmod.GetHMDPose(self.Owner)
	
	if !pos or !ang then
		return nil, nil
	end

	return pos, ang
end

function SWEP:Initialize()
	BaseClass.Initialize(self)

	self:ApplyVrViewModelOffset()
end

function SWEP:ApplyVrViewModelOffset()
	if !vrmod then return end
	if !isfunction(vrmod.SetViewModelOffsetForWeaponClass) then return end

	vrmod.SetViewModelOffsetForWeaponClass(
		self:GetClass(),
		self.VrViewModelOffset.pos or Vector_Zero,
		self.VrViewModelOffset.ang or Angle_Zero
	)
end

function SWEP:GetRightHandToWorld(localPos, localAng)
	local rhPos, rhAng = self:GetRightHandPose()
	
	if !rhPos or !rhAng then
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
	
	if !worldPos or !worldAng then
		return nil, nil
	end

	return worldPos, worldAng
end

function SWEP:GetHMDToWorld(localPos, localAng)
	local pos, ang = self:GetHMDPose()
	
	if !pos or !ang then
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
	
	if !worldPos or !worldAng then
		return nil, nil
	end

	return worldPos, worldAng
end

function SWEP:GetVrHMDPos()
	local pos = self:GetHMDToWorld()
	if !pos then return nil end

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

	if VRState != LastVRState then
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