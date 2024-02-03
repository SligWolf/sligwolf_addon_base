AddCSLuaFile()

if !SW_Addons then
	return
end

if !SW_ADDON then
	SW_Addons.AutoLoadAddon(function() end)
	return
end

function SW_ADDON:GetRelativeVelocity(ent)
	if !IsValid(ent) then return end

	local phys = ent:GetPhysicsObject()
	if !IsValid(phys) then return end
	
	local v = phys:GetVelocity()
	return phys:WorldToLocalVector(v)
end

function SW_ADDON:GetForwardVelocity(ent)
	local v = self:GetRelativeVelocity(ent)
	if !v then return 0 end
	
	return v.y or 0
end

local function calcUnitsToMeter(units)
	return units * 0.75 * 2.54 / 100
end

local function calcMeterToUnits(meter)
	return meter * 100 / (0.75 * 2.54)
end

function SW_ADDON:GetKPHSpeed(ups)
	-- Km per hour
	local UnitToKmh = math.Round(calcUnitsToMeter(ups) * 3.6)
	return UnitToKmh
end

function SW_ADDON:GetUPSSpeed(kph)
	-- Units per second
	local KmhToUnits = math.Round(calcMeterToUnits(kph) / 3.6)
	return KmhToUnits
end