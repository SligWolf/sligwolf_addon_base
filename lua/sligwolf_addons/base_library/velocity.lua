AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Velocity = SligWolf_Addons.Velocity or {}
table.Empty(SligWolf_Addons.Velocity)

local LIB = SligWolf_Addons.Velocity

local LIBPhysics = SligWolf_Addons.Physics

function LIB.GetRelativeVelocity(ent)
	if not IsValid(ent) then return end

	local phys = ent:GetPhysicsObject()
	if not LIBPhysics.IsValidPhysObject(phys) then return end

	local v = phys:GetVelocity()
	return phys:WorldToLocalVector(v)
end

function LIB.GetForwardVelocity(ent)
	local v = LIB.GetRelativeVelocity(ent)
	if not v then return 0 end

	return v.y or 0
end

local function calcUnitsToMeter(units)
	return units * 0.75 * 2.54 / 100
end

local function calcMeterToUnits(meter)
	return meter * 100 / (0.75 * 2.54)
end

function LIB.GetKPHSpeed(ups)
	-- Km per hour
	local UnitToKmh = math.Round(calcUnitsToMeter(ups) * 3.6)
	return UnitToKmh
end

function LIB.GetUPSSpeed(kph)
	-- Units per second
	local KmhToUnits = math.Round(calcMeterToUnits(kph) / 3.6)
	return KmhToUnits
end

function LIB.IsMoving(ent, velocityThreshold)
	velocityThreshold = tonumber(velocityThreshold or 0)

	if velocityThreshold <= 0 then
		velocityThreshold = 5
	end

	local velocity = LIB.GetRelativeVelocity(ent)
	if not velocity then
		return false
	end

	local velocityThresholdSqr = velocityThreshold * velocityThreshold
	local velocity = velocity:LengthSqr()

	if velocity < velocityThresholdSqr then
		return false
	end

	return true
end

return true

