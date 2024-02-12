AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

DEFINE_BASECLASS("sligwolf_weapon_vr_base")

SWEP.Spawnable				= false
SWEP.AdminOnly				= false

SWEP.sligwolf_vrMeleeBaseEntity	= true

if not SligWolf_Addons then return end
if not SligWolf_Addons.IsLoaded then return end
if not SligWolf_Addons.IsLoaded() then return end

SWEP.MeleeDistance			= 85

SWEP.VrVelocitySensorPos	= Vector(0, 0, 0)
SWEP.VrMinHitTime			= 0.125

SWEP.VrMinHitVelocityRelativeToAttacker	 = 200
SWEP.VrMinHitVelocityRelativeToTarget    = 200

SWEP.VrTraceChains = {}

local Vector_Zero = Vector()

local LIBTracer = SligWolf_Addons.Tracer

function SWEP:Initialize()
	BaseClass.Initialize(self)

	self:SetHoldType("melee")
end

function SWEP:GetVrVelocitySensorPos()
	local pos = self:GetRightHandToWorld(self.VrVelocitySensorPos)

	if not pos then return nil end

	if self:IsDeveloper() then
		debugoverlay.Cross(pos, 1, 0.1, color_white, true)
		debugoverlay.EntityTextAtPosition(pos, 0, "SWEP:GetVrVelocitySensorPos()", 0.1, color_white)
	end

	return pos
end

function SWEP:GetVrSensorVelocity()
	return self.VrSensorVelocity or Vector_Zero
end

function SWEP:SetVrSensorVelocity(velocity)
	self.VrSensorVelocity = velocity or Vector_Zero
end

function SWEP:GetVrHMDVelocity()
	return self.VrHMDVelocity or Vector_Zero
end

function SWEP:SetVrHMDVelocity(velocity)
	self.VrHMDVelocity = velocity or Vector_Zero
end

function SWEP:GetTargetEntityVelocity(targetEntity, hitPos)
	if not IsValid(targetEntity) then
		return Vector_Zero
	end

	local phys = targetEntity:GetPhysicsObject()
	if IsValid(phys) then
		return phys:GetVelocityAtPoint(hitPos)
	end

	if SERVER and targetEntity:IsNPC() then
		return targetEntity.GetGroundSpeedVelocity()
	end

	return targetEntity:GetVelocity()
end

function SWEP:GetVrSensorVelocityRelativeToTarget(targetEntity, hitPos)
	local sensorVelocity = self:GetVrSensorVelocity()
	local entVelocity = self:GetTargetEntityVelocity(targetEntity, hitPos)

	return sensorVelocity - entVelocity
end

function SWEP:GetVrSensorVelocityRelativeToAttacker()
	local sensorVelocity = self:GetVrSensorVelocity()
	local hmdVelocity = self:GetVrHMDVelocity()

	return sensorVelocity - hmdVelocity
end

local velocityMap = {
	{"GetVrHMDPos", "SetVrHMDVelocity"},
	{"GetVrVelocitySensorPos", "SetVrSensorVelocity"},
}

function SWEP:CalcVrVelocities()
	local currentTime = CurTime()

	local lastTickTime = self.velocityLastTickTime or currentTime
	self.velocityLastTickTime = currentTime

	local timeDelta = currentTime - lastTickTime
	if timeDelta <= 0 then return end

	self.velocityLastPoses = self.velocityLastPoses or {}

	for k, v in ipairs(velocityMap) do
		local posGetterName = velocityMap[1]
		local velSetterName = velocityMap[2]

		if not posGetterName then
			continue
		end

		if not velSetterName then
			continue
		end

		local posGetter = self[posGetterName]
		local velSetter = self[velSetterName]

		if not posGetter then
			continue
		end

		if not velSetter then
			continue
		end

		local pos = posGetter(self)

		local lastPos = self.velocityLastPoses[posGetter] or pos
		self.velocityLastPoses[posGetter] = pos

		local posDelta = pos - lastPos
		local vel = posDelta / timeDelta

		velSetter(self, vel)
	end
end

function SWEP:VRTrace()
	local ply = self:GetOwner()

	local filterFunc = function(sp, ent)
		if ent == ply then return false end
		return true
	end

	for _, traceChain in ipairs(self.VrTraceChains) do
		local tracePoses = {}

		for _, tracePos in ipairs(traceChain) do
			tracePos = self:GetRightHandToWorld(tracePos)
			tracePoses[#tracePoses + 1] = tracePos
		end

		local tr = LIBTracer.TracerChain(self, tracePoses, filterFunc)

		if not tr then	continue end
		if not tr.Hit then	continue end

		return tr
	end

	return nil
end

function SWEP:CreateHitEffect(tr)
	if not tr then return nil end

	local ED = EffectData()

	ED:SetStart(self:GetOwner():GetShootPos())
	ED:SetOrigin(tr.HitPos)
	ED:SetNormal(tr.Normal)
	ED:SetSurfaceProp(tr.SurfaceProps)
	ED:SetEntity(tr.Entity)

	return ED
end

function SWEP:MeleeTrace()
	local Owner = self:GetOwner()
	local Start = Owner:GetShootPos()
	local End = Start + Owner:GetAimVector() * self.MeleeDistance

	local Filter = function(ent, ...)
		if not IsValid(Owner) then return false end
		if ent == Owner then return false end

		return true
	end

	local tr = util.TraceLine({
		start = Start,
		endpos = End,
		filter = Filter,
		mask = MASK_SHOT_HULL
	})

	return tr
end

function SWEP:DealMeleeScaledDamage(ent, scale)
	if not IsValid(ent) then return end

	local Damage = self.Damage * scale
	local DamageType = self.DamageType
	local DamageForce = self.DamageForce * scale

	self:DealMeleeDamage(ent, Damage, DamageType, DamageForce)
end

function SWEP:DealMeleeDamage(entTarget, damage, damageType, force)
	local Owner = self:GetOwner()
	local Dist = self.MeleeDistance
	local AimVec = Owner:GetAimVector()

	if SERVER then
		if entTarget:IsNPC() or entTarget:IsPlayer() then
			local Dmgi = DamageInfo()
			Dmgi:SetDamage(damage)
			Dmgi:SetDamageForce(AimVec * force)
			Dmgi:SetAttacker(Owner)
			Dmgi:SetInflictor(self)
			Dmgi:SetDamageType(damageType)
			entTarget:TakeDamageInfo(Dmgi)
		else
			local bulletInfo = {
				Attacker	= Owner,
				Damage		= damage,
				Force 		= 5,
				Distance	= Dist,
				Tracer		= 0,
				Src 		= Owner:GetShootPos(),
				Dir 		= AimVec,
			}
			self:FireBullets(bulletInfo)
		end
	end
end

function SWEP:OnVRExit()
	BaseClass.OnVRExit(self)

	self:SetVrSensorVelocity(Vector_Zero)
	self:SetVrHMDVelocity(Vector_Zero)

	self.nextHitTime = nil
	self.hasHit = nil
	self.velocityLastTickTime = nil
	self.velocityLastPoses = nil
end

function SWEP:OnVRThink()
	BaseClass.OnVRThink(self)

	self:CalcVrVelocities()

	local tr = self:VRTrace()
	if not tr then
		self.hasHit = false
		return
	end

	local hit = tr.Hit or false
	local hitEntity = tr.Entity
	local hitPos = tr.HitPos
	local hasHit = self.hasHit or false
	self.hasHit = hit

	if hasHit == hit then return end
	if not hit then return	end

	local nextHitTime = self.nextHitTime or 0
	local now = CurTime()

	if nextHitTime > now then return end

	local velocityRelativeToTarget = self:GetVrSensorVelocityRelativeToTarget(hitEntity, hitPos)
	local velocityRelativeToAttacker = self:GetVrSensorVelocityRelativeToAttacker()

	local velocityRelativeToTargetAbs = velocityRelativeToTarget:Length()
	local velocityRelativeToAttackerAbs = velocityRelativeToAttacker:Length()

	if velocityRelativeToTargetAbs < self.VrMinHitVelocityRelativeToTarget then
		return
	end

	if velocityRelativeToAttackerAbs < self.VrMinHitVelocityRelativeToAttacker then
		return
	end

	self:VRSwingAttack(tr, velocityAbs)
	self.nextHitTime = now + self.VrMinHitTime
end

function SWEP:VRSwingAttack(tr, velocityAbs)
	-- Override me
end

