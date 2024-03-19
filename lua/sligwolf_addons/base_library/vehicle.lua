AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Vehicle = SligWolf_Addons.Vehicle or {}
table.Empty(SligWolf_Addons.Vehicle)

local LIB = SligWolf_Addons.Vehicle

local LIBVehicleControl = nil
local LIBEntities = nil
local LIBCamera = nil
local LIBTimer = nil
local LIBHook = nil

function LIB.ToString(vehicle)
	local vehicleStr = LIBEntities.ToString(vehicle)

	if not IsValid(vehicle) then
		return vehicleStr
	end

	if not vehicle:IsVehicle() then
		return vehicleStr
	end

	local vehicleName = tostring(vehicle.VehicleName or "")
	if vehicleName == "" then
		vehicleName = "<unknown>"
	end

	local str = string.format("%s[spawnname: %s]", vehicleStr, vehicleName)
	return str
end

function LIB.GetVehicleTableFromSpawnname(vehicleSpawnname)
	if not vehicleSpawnname then return nil end

	local VehicleList = list.Get("Vehicles") or {}
	local vehicleTable = VehicleList[vehicleSpawnname]

	if not vehicleTable then return nil end
	return vehicleTable
end

function LIB.GetVehicleSpawnnameFromVehicle(vehicle)
	if not IsValid(vehicle) then return nil end
	if not vehicle:IsVehicle() then return nil end

	local vehicleSpawnname = tostring(vehicle.VehicleName or "")
	if vehicleSpawnname == "" then
		if CLIENT then
			return nil
		end

		vehicleSpawnname = LIBEntities.GetKeyValue(vehicle, "sligwolf_spawnname")
		vehicleSpawnname = tostring(vehicleSpawnname or "")
	end

	if vehicleSpawnname == "" then
		return nil
	end

	return vehicleSpawnname
end

function LIB.GetVehicleTableFromVehicle(vehicle)
	local vehicleSpawnname = LIB.GetVehicleSpawnnameFromVehicle(vehicle)
	if not vehicleSpawnname then
		return nil
	end

	local vehicleTable = LIB.GetVehicleTableFromSpawnname(vehicleSpawnname)
	if not vehicleTable then return nil end

	return vehicleTable
end

function LIB.EnableWheels(vehicle, enable)
	local wheels = vehicle:GetWheelCount() or 0

	for i = 1, wheels do
		local phys = vehicle:GetWheel(i)
		if not IsValid(phys) then
			continue
		end

		phys:EnableCollisions(enable)
	end
end

function LIB.WheelsOnGround(vehicle)
		local wheels = vehicle:GetWheelCount() or 0

		for i = 1, wheels do
			local _, _, onGround = vehicle:GetWheelContactPoint(i)

			return onGround
		end

		return false
	end

function LIB.SetDriverMaxHealth(ply, maxHealth, thresholdAsFull)
	if not IsValid(ply) then return end
	if not maxHealth then return end

	if not thresholdAsFull then
		thresholdAsFull = 1
	end

	thresholdAsFull = math.Clamp(thresholdAsFull, 0, 1)

	local oldMaxHealth = ply:GetMaxHealth()
	local curHealth = ply:Health()

	if not ply.__SLIGWOLF_oldMaxHealth then
		ply.__SLIGWOLF_oldMaxHealth = oldMaxHealth
	end

	if not ply.__SLIGWOLF_oldHealth then
		ply.__SLIGWOLF_oldHealth = curHealth
	end

	if curHealth > maxHealth then
		-- shrink HP along max HP
		ply:SetHealth(maxHealth)
	end

	if curHealth >= oldMaxHealth * thresholdAsFull then
		-- grow HP along max HP if it is above certain threshold
		ply:SetHealth(maxHealth)
	end

	ply:SetMaxHealth(maxHealth)
end

function LIB.ResetDriverMaxHealth(ply)
	if not IsValid(ply) then return end

	local maxHP = ply.__SLIGWOLF_oldMaxHealth
	if not maxHP then return end

	local curHealth = ply:Health()

	LIB.SetDriverMaxHealth(ply, maxHP, 1)

	ply.__SLIGWOLF_oldMaxHealth = nil

	local oldHP = ply.__SLIGWOLF_oldHealth
	if not oldHP then return end

	local hp = math.min(curHealth, oldHP, maxHP)
	ply:SetHealth(hp)

	ply.__SLIGWOLF_oldHealth = nil
end

function LIB.Load()
	LIBVehicleControl = SligWolf_Addons.VehicleControl
	LIBEntities = SligWolf_Addons.Entities
	LIBCamera = SligWolf_Addons.Camera
	LIBTimer = SligWolf_Addons.Timer
	LIBHook = SligWolf_Addons.Hook

	local function SpawnVehicleFinished(vehicle, ply)
		if not IsValid(vehicle) then return end

		if not vehicle:IsVehicle() then return end
		if not vehicle:IsValidVehicle() then return end

		if not vehicle.sligwolf_vehicle then return end
		if not vehicle.sligwolf_Addonname then return end

		SligWolf_Addons.CallFunctionOnAddon(vehicle.sligwolf_Addonname, "SpawnVehicleFinished", vehicle, ply)
	end

	LIBHook.Add("SLIGWOLF_SpawnSystemFinished", "Library_Vehicle_SpawnVehicleFinished", SpawnVehicleFinished, 20000)

	local function PlayerEnteredVehicle(ply, vehicle)
		if not IsValid(vehicle) then return end
		if not IsValid(ply) then return end

		if not vehicle:IsValidVehicle() then return end

		if not vehicle.sligwolf_vehicle then return end
		if not vehicle.sligwolf_Addonname then return end

		LIBCamera.ResetCamera(ply)
		SligWolf_Addons.CallFunctionOnAddon(vehicle.sligwolf_Addonname, "EnterVehicle", ply, vehicle)
	end

	LIBHook.Add("PlayerEnteredVehicle", "Library_Vehicle_PlayerEnteredVehicle", PlayerEnteredVehicle, 20000)

	local function PlayerLeaveVehicle(ply, vehicle)
		if not IsValid(vehicle) then return end
		if not IsValid(ply) then return end

		if not vehicle:IsValidVehicle() then return end

		if not vehicle.sligwolf_vehicle then return end
		if not vehicle.sligwolf_Addonname then return end

		SligWolf_Addons.CallFunctionOnAddon(vehicle.sligwolf_Addonname, "LeaveVehicle", ply, vehicle)

		LIB.ResetDriverMaxHealth(ply)
		LIBVehicleControl.ExitSeat(vehicle, ply)
		LIBCamera.ResetCamera(ply)
	end

	LIBHook.Add("PlayerLeaveVehicle", "Library_Vehicle_PlayerLeaveVehicle", PlayerLeaveVehicle, 20000)

	local function OnEntityCreated(ent)
		if not IsValid(ent) then return end

		LIBTimer.SimpleNextFrame(function()
			if not IsValid(ent) then return end

			if not SligWolf_Addons then return end
			SligWolf_Addons.CallFunctionOnAllAddons("HandleVehicleSpawn", ent)
		end)
	end

	LIBHook.Add("OnEntityCreated", "Library_Vehicle_OnEntityCreated", OnEntityCreated, 10000)

	local function PlayerSpawnedVehicle(ply, vehicle)
		if not IsValid(ply) then return end
		if not IsValid(vehicle) then return end

		vehicle.sligwolf_SpawnerPlayer = ply
	end

	LIBHook.Add("PlayerSpawnedVehicle", "Library_Vehicle_PlayerSpawnedVehicle", PlayerSpawnedVehicle, 10000)

	if CLIENT then
		local g_trace = {}
		local g_traceResult = {}

		g_trace.output = g_traceResult

		local function CalcVehicleView(vehicle, ply, view)
			if not vehicle then
				return
			end

			if not vehicle.sligwolf_entity and not vehicle:GetNWBool("sligwolf_entity") then
				return
			end

			if vehicle.GetThirdPersonMode == nil or ply:GetViewEntity() ~= ply then
				return
			end

			if not vehicle:GetThirdPersonMode() then
				return view
			end

			local mn, mx = vehicle:GetRenderBounds()
			local radius = (mn - mx):Length()
			local radius = radius + radius * vehicle:GetCameraDistance()

			local TargetOrigin = view.origin + (view.angles:Forward() * -radius)
			local WallOffset = 4

			local root = LIBEntities.GetSuperParent(vehicle)

			g_trace.start = view.origin
			g_trace.endpos = TargetOrigin

			g_trace.filter = function(ent)
				if not ent.sligwolf_entity and not ent:GetNWBool("sligwolf_entity") then
					return true
				end

				if LIBEntities.GetSuperParent(ent) == root then
					return false
				end

				return true
			end

			g_trace.mins = Vector(-WallOffset, -WallOffset, -WallOffset)
			g_trace.maxs = Vector(WallOffset, WallOffset, WallOffset)

			util.TraceHull(g_trace)

			view.origin = g_traceResult.HitPos
			view.drawviewer = true

			if g_traceResult.Hit and not g_traceResult.StartSolid then
				view.origin = view.origin + g_traceResult.HitNormal * WallOffset
			end

			return view
		end

		LIBHook.Add("CalcVehicleView", "Library_Vehicle_CalcVehicleView", CalcVehicleView, 10000)
	end
end

return true

