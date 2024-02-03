AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.VehicleControl = SligWolf_Addons.VehicleControl or {}
table.Empty(SligWolf_Addons.VehicleControl)

local LIB = SligWolf_Addons.VehicleControl

local LIBEntities = nil
local LIBTracer = nil

function LIB.Load()
	LIBEntities = SligWolf_Addons.Entities
	LIBTracer = SligWolf_Addons.Tracer
end

function LIB.GetControlledVehicle(ply)
	local vehicle = ply:GetVehicle()

	local remoteVehicle = ply.SLIGWOLF_RemoteControlledVehicle
	local remoteState = ply.SLIGWOLF_RemoteControllerState

	if not IsValid(vehicle) and remoteState then
		vehicle = remoteVehicle
	end

	if not IsValid(vehicle) then
		return nil, remoteState
	end

	return vehicle, remoteState
end

function LIB.IsControllingVehicle(ply)
	local vehicle = LIB.GetControlledVehicle(ply)

	if not IsValid(vehicle) then
		return false
	end

	return true
end

local checkForEmptySpaceVectors = {
	V1 = { VecA = Vector(0, 0, 0), VecB = Vector(0, 0, 70) },
	V2 = { VecA = Vector(15, 0, 0), VecB = Vector(15, 0, 70) },
	V3 = { VecA = Vector(0, 15, 0), VecB = Vector(0, 15, 70) },
	V4 = { VecA = Vector(-15, 0, 0), VecB = Vector(-15, 0, 70) },
	V5 = { VecA = Vector(0, -15, 0), VecB = Vector(0, -15, 70) },
	V6 = { VecA = Vector(15, 15, 0), VecB = Vector(15, 15, 70) },
	V7 = { VecA = Vector(-15, 15, 0), VecB = Vector(-15, 15, 70) },
	V8 = { VecA = Vector(-15, -15, 0), VecB = Vector(-15, -15, 70) },
	V9 = { VecA = Vector(15, -15, 0), VecB = Vector(15, -15, 70) },
}

function LIB.ExitSeat(ent, ply)
	--@TODO: Recode and clean up

	if not IsValid(ent) then return false end
	if not IsValid(ply) then return false end

	local tb = ent.sligwolf_ExitVectors or {}
	local exitPlyVector = tb[1]
	local exitEyeVector = tb[2]

	if not isvector(exitPlyVector) then return false end
	if not isvector(exitEyeVector) then return false end

	local Filter = function(veh, f_ent)
		if not IsValid(f_ent) then return false end
		if not IsValid(ply) then return false end
		if f_ent == veh then return false end
		if f_ent == ply then return false end
		if f_ent:GetModel() == "models/sligwolf/unique_props/seat.mdl" then return false end

		return true
	end

	local seatPos 	= ent:GetPos()
	local seatAng 	= ent:GetAngles()
	local forward 	= seatAng:Forward()
	local right 	= seatAng:Right()
	local up 		= seatAng:Up()

	local exitPos = seatPos + forward * exitPlyVector.x + right * exitPlyVector.y + up * exitPlyVector.z
	local eyePos  = seatPos - (seatPos + forward * exitEyeVector.x + right * exitEyeVector.y + up * exitEyeVector.z)

	for k, v in pairs(checkForEmptySpaceVectors) do
		local tr = LIBTracer.Tracer(ent, exitPos + v.VecA, exitPos + v.VecB, Filter)
		if tr.Hit then return true end
	end

	ply:SetPos(exitPos)
	ply:SetEyeAngles(eyePos:Angle())

	return false
end

function LIB.TrainDoorButtonToggle(button, mainvehicle, ply)
	if not IsValid(button) then return end
	if not IsValid(ply) then return end

	-- @TODO: Create entity links between button and door (triggered entity)

	local name = LIBEntities.GetName(button)
	local id = string.Right(name, 1)

	local door = LIBEntities.GetChild(mainvehicle, "Door_D" .. id)
	if not IsValid(door) then return end

	door.SLIGWOLF_Door_State = not door.SLIGWOLF_Door_State

	if door.SLIGWOLF_Door_State then
		door:Set_AutoClose(false)
		door:Open()
		return
	else
		door:Set_AutoClose(true)
		door:Close()
		return
	end
end

local breakUntil = 5
local stopBreakingAt = 4
local setSpeedTo = 0

function LIB.TrainSpeedOrder(vehicle, ply, acceleration, emergencyBrake)
	if not IsValid(vehicle) then return end
	if not IsValid(ply) then return end
	acceleration = tonumber(acceleration or 2.25)
	emergencyBrake = tonumber(emergencyBrake or 6.75)

	-- @TODO: Create new speed control logic for trains and vehicles for upcomming remote controller update

	if not vehicle.SLIGWOLF_VehicleEngine then return end

	if ply:KeyDown(IN_FORWARD) then
		vehicle.SLIGWOLF_Speed = vehicle.SLIGWOLF_Speed + acceleration
	end
	if ply:KeyDown(IN_BACK) then
		vehicle.SLIGWOLF_Speed = vehicle.SLIGWOLF_Speed - acceleration
	end

	if ply:KeyDown(IN_JUMP) then
		if vehicle.SLIGWOLF_Speed >= breakUntil then
			vehicle.SLIGWOLF_Speed = vehicle.SLIGWOLF_Speed - emergencyBrake
			if vehicle.SLIGWOLF_Speed <= stopBreakingAt then
				vehicle.SLIGWOLF_Speed = setSpeedTo
			end
		end
		if vehicle.SLIGWOLF_Speed <= -breakUntil then
			vehicle.SLIGWOLF_Speed = vehicle.SLIGWOLF_Speed + emergencyBrake
			if vehicle.SLIGWOLF_Speed >= -stopBreakingAt then
				vehicle.SLIGWOLF_Speed = setSpeedTo
			end
		end
	end
end

return true

