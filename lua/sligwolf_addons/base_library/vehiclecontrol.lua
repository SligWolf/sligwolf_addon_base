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

function LIB.Load()
	LIBEntities = SligWolf_Addons.Entities
end

function LIB.GetControlledVehicle(ply)
	local vehicle = ply:GetVehicle()

	local remoteVehicle = ply.sligwolf_remoteControlledVehicle
	local remoteState = ply.sligwolf_remoteControllerState

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

function LIB.TrainDoorButtonToggle(button, mainvehicle, ply)
	if not IsValid(button) then return end
	if not IsValid(ply) then return end

	-- @TODO: Create entity links between button and door (triggered entity)

	local name = LIBEntities.GetName(button)
	local id = string.Right(name, 1)

	local door = LIBEntities.GetChild(mainvehicle, "Door_D" .. id)
	if not IsValid(door) then return end

	door.sligwolf_doorState = not door.sligwolf_doorState

	if door.sligwolf_doorState then
		door:SetAutoClose(false)
		door:Open()
		return
	else
		door:SetAutoClose(true)
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

	if not vehicle.sligwolf_vehicleEngine then return end

	if ply:KeyDown(IN_FORWARD) then
		vehicle.sligwolf_speed = vehicle.sligwolf_speed + acceleration
	end
	if ply:KeyDown(IN_BACK) then
		vehicle.sligwolf_speed = vehicle.sligwolf_speed - acceleration
	end

	if ply:KeyDown(IN_JUMP) then
		if vehicle.sligwolf_speed >= breakUntil then
			vehicle.sligwolf_speed = vehicle.sligwolf_speed - emergencyBrake
			if vehicle.sligwolf_speed <= stopBreakingAt then
				vehicle.sligwolf_speed = setSpeedTo
			end
		end
		if vehicle.sligwolf_speed <= -breakUntil then
			vehicle.sligwolf_speed = vehicle.sligwolf_speed + emergencyBrake
			if vehicle.sligwolf_speed >= -stopBreakingAt then
				vehicle.sligwolf_speed = setSpeedTo
			end
		end
	end
end

return true

