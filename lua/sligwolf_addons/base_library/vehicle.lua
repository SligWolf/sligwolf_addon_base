local SligWolf_Addons = _G.SligWolf_Addons
if not SligWolf_Addons then
	return
end

local LIB = SligWolf_Addons:NewLib("Vehicle")

local LIBConstraints = nil
local LIBCoupling = nil
local LIBEntities = nil
local LIBSourceIO = nil
local LIBPosition = nil
local LIBPhysics = nil
local LIBCamera = nil
local LIBTimer = nil
local LIBModel = nil
local LIBHook = nil
local LIBUtil = nil

function LIB.MakeVehicle(spawnname, plyOwner, parent, name, addonname)
	if not SERVER then return end

	if not spawnname then
		ErrorNoHaltWithStack(
			string.format(
				"Vehicle spawnname is not set. Couldn't create vehicle!",
				spawnname
			)
		)

		return
	end

	local vehicleTable = LIB.GetVehicleTableFromSpawnname(spawnname)
	if not vehicleTable then
		ErrorNoHaltWithStack(
			string.format(
				"Invalid vehicle spawnname '%s'. Couldn't create vehicle!",
				spawnname
			)
		)

		return
	end

	local mdl = vehicleTable.Model
	local keyValues = vehicleTable.KeyValues
	local class = vehicleTable.Class
	local members = vehicleTable.Members

	local vehicle = LIBEntities.MakeEnt(class, plyOwner, parent, name, addonname)
	if not IsValid(vehicle) then return end

	LIBModel.SetModel(vehicle, mdl)

	LIB.SetupVehicleKeyValues(vehicle, keyValues)

	vehicle.VehicleName = spawnname
	vehicle.VehicleTable = vehicleTable

	if vehicle.SetVehicleClass and vehicle.SetDTString then
		vehicle:SetVehicleClass(spawnname)
	end

	vehicle.ClassOverride = class

	if members then
		table.Merge(vehicle, members)
		duplicator.StoreEntityModifier(vehicle, "VehicleMemDupe", members)
	end

	return vehicle
end

local g_allowedVehicleKeyValues = {
	vehiclescript = true,
	limitview = true,
	vehiclelocked = true,
	cargovisible = true,
	enablegun = true,
}

function LIB.SetupVehicleKeyValues(vehicle, keyValues)
	if not SERVER then return end

	if not IsValid(vehicle) then return end
	if not vehicle:IsVehicle() then return end
	if not keyValues then return end

	for k, v in pairs(keyValues) do
		k = string.lower(k)

		if not g_allowedVehicleKeyValues[k] then
			continue
		end

		LIBSourceIO.SetKeyValue(vehicle, k, v)
	end
end

function LIB.SetupVehicleKeyValuesOverride(vehicle, keyValues)
	if not SERVER then return end

	if not IsValid(vehicle) then return end
	if not vehicle:IsVehicle() then return end
	if not keyValues then return end

	local entTable = vehicle:SligWolf_GetTable()

	local keyValuesOverride = entTable.keyValuesOverride or {}
	entTable.keyValuesOverride = keyValuesOverride

	for k, v in pairs(keyValues) do
		k = string.lower(k)

		if not g_allowedVehicleKeyValues[k] then
			continue
		end

		keyValuesOverride[k] = v
	end
end

function LIB.GetVehicleTableFromSpawnname(vehicleSpawnname)
	if not vehicleSpawnname then return nil end

	local vehicleList = LIBUtil.GetList("Vehicles")
	local vehicleTable = vehicleList[vehicleSpawnname]

	if not vehicleTable then return nil end
	return vehicleTable
end

function LIB.GetVehicleSpawnnameFromVehicle(vehicle)
	if not IsValid(vehicle) then return nil end
	if not vehicle:IsVehicle() then return nil end

	local vehicleSpawnname = ""

	if vehicle.GetVehicleClass and vehicle.GetDTString then
		vehicleSpawnname = vehicle:GetVehicleClass()
		vehicleSpawnname = tostring(vehicleSpawnname or "")

		if vehicleSpawnname ~= "" then
			return vehicleSpawnname
		end
	end

	vehicleSpawnname = tostring(vehicle.VehicleName or "")
	if vehicleSpawnname ~= "" then
		return vehicleSpawnname
	end

	if CLIENT then
		return nil
	end

	vehicleSpawnname = LIBSourceIO.GetKeyValue(vehicle, "sligwolf_spawnname")
	vehicleSpawnname = tostring(vehicleSpawnname or "")

	if vehicleSpawnname ~= "" then
		return vehicleSpawnname
	end

	return nil
end

function LIB.IsSpawnedByEngine(vehicle)
	if not IsValid(vehicle) then return false end
	if not vehicle:IsVehicle() then return false end

	local entTable = vehicle:SligWolf_GetTable()
	if entTable.isSpawnedByEngine ~= nil then
		return entTable.isSpawnedByEngine
	end

	entTable.isSpawnedByEngine = true

	if LIBSourceIO.IsCreatedByMap(vehicle, true) then
		return true
	end

	local vehicleSpawnname = tostring(vehicle.VehicleName or "")
	if vehicleSpawnname == "" then
		return true
	end

	entTable.isSpawnedByEngine = false
	return false
end

function LIB.EnableWheels(vehicle, enable)
	local wheels = vehicle:GetWheelCount() or 0

	for i = 1, wheels do
		local phys = vehicle:GetWheel(i - 1)

		if not LIBPhysics.IsValidPhysObject(phys, true) then
			continue
		end

		phys:EnableDrag(enable)
		phys:EnableGravity(enable)
		phys:EnableCollisions(enable)
	end
end

function LIB.WheelsOnGround(vehicle)
	local wheels = vehicle:GetWheelCount() or 0

	for i = 1, wheels do
		local _, _, onGround = vehicle:GetWheelContactPoint(i - 1)

		if onGround then
			return true
		end
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
	local plyTable = ply:SligWolf_GetTable()

	if not plyTable.driverOldMaxHealth then
		plyTable.driverOldMaxHealth = oldMaxHealth
	end

	if not plyTable.driverOldHealth then
		plyTable.driverOldHealth = curHealth
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

	local plyTable = ply:SligWolf_GetTable()

	local maxHP = plyTable.driverOldMaxHealth
	if not maxHP then return end

	local curHealth = ply:Health()

	LIB.SetDriverMaxHealth(ply, maxHP, 1)

	plyTable.driverOldMaxHealth = nil

	local oldHP = plyTable.driverOldHealth
	if not oldHP then return end

	local hp = math.min(curHealth, oldHP, maxHP)
	ply:SetHealth(hp)

	plyTable.driverOldHealth = nil
end

function LIB.VehicleSupportsNPCPassenger(vehicle)
	if not IsValid(vehicle) then return false end
	if not vehicle:IsVehicle() then return false end

	local enterVehicleAttachment = LIBPosition.GetAttachmentId(vehicle, "vehicle_feet_passenger1")
	if not enterVehicleAttachment then return false end

	return true
end

function LIB.NpcSupportsVehicleMounting(npc)
	if not IsValid(npc) then return false end
	if not npc:IsNPC() then return false end

	local enterVehicleSequence = npc:LookupSequence("buggy_enter1") or -1
	if enterVehicleSequence == -1 then return false end

	local exitVehicleSequence = npc:LookupSequence("buggy_exit1") or -1
	if exitVehicleSequence == -1 then return false end

	return true
end

function LIB.NpcCanEnterVehicle(vehicle, npc)
	if not IsValid(vehicle) then return false end
	if not IsValid(npc) then return false end

	if not LIB.VehicleSupportsNPCPassenger(vehicle) then return false end
	if not LIB.NpcSupportsVehicleMounting(npc) then return false end

	local npcTable = npc:SligWolf_GetTable()
	local vehicleTable = vehicle:SligWolf_GetTable()

	local npcSeatPlayerOccupied = vehicleTable.npcSeatPlayerOccupied
	if npcSeatPlayerOccupied then return false end

	if npcTable.passengerLock then return false end
	if vehicleTable.passengerLock then return false end

	local currentPassengerNpc = vehicleTable.currentPassengerNpc
	if IsValid(currentPassengerNpc) then return false end

	local currentPassengerVehicle = npcTable.currentPassengerVehicle
	if IsValid(currentPassengerVehicle) then return false end

	return true
end

function LIB.NpcCanExitVehicle(vehicle, npc)
	if not IsValid(vehicle) then return false end
	if not IsValid(npc) then return false end

	if not LIB.VehicleSupportsNPCPassenger(vehicle) then return false end
	if not LIB.NpcSupportsVehicleMounting(npc) then return false end

	local npcTable = npc:SligWolf_GetTable()
	local vehicleTable = vehicle:SligWolf_GetTable()

	local npcSeatPlayerOccupied = vehicleTable.npcSeatPlayerOccupied
	if npcSeatPlayerOccupied then return false end

	local currentPassengerNpc = vehicleTable.currentPassengerNpc
	if IsValid(currentPassengerNpc) and npc ~= currentPassengerNpc then return false end

	local currentPassengerVehicle = npcTable.currentPassengerVehicle
	if IsValid(currentPassengerVehicle) and vehicle ~= currentPassengerVehicle then return false end

	return true
end

function LIB.GetNpcPassenger(vehicle)
	if not IsValid(vehicle) then return nil end

	local vehicleTable = vehicle:SligWolf_GetTable()

	local npcSeatPlayerOccupied = vehicleTable.npcSeatPlayerOccupied
	if npcSeatPlayerOccupied then return nil end

	local currentPassengerNpc = vehicleTable.currentPassengerNpc
	if not IsValid(currentPassengerNpc) then return nil end

	return currentPassengerNpc
end

function LIB.GetNpcPassengerVehicle(npc)
	if not IsValid(npc) then return nil end

	local npcTable = npc:SligWolf_GetTable()

	local currentPassengerVehicle = npcTable.currentPassengerVehicle
	if not IsValid(currentPassengerVehicle) then return nil end

	return currentPassengerVehicle
end

function LIB.NPCPassengerIsInVehicle(npc, vehicle)
	if not IsValid(npc) then return false end
	if not npc:IsNPC() then return false end
	if not npc:Alive() then return false end

	if not IsValid(vehicle) then return false end
	if not vehicle:IsVehicle() then return false end

	if npc:GetParent() ~= vehicle then
		return false
	end

	return true
end

local g_passengerHandlingTimer = "NpcPassengerHandling"
local g_passengerHandlingTimeout = 60

local g_passengerRevertTmpVehicleName = "NpcPassengerHandling_RevertTmpVehicleName"

local function isUniqueVehicleName(vehicleName)
	if vehicleName == "" then
		return false
	end

	local vehicles = ents.FindByName(vehicleName)

	local found = false

	for k, v in ipairs(vehicles) do
		if not LIB.VehicleSupportsNPCPassenger(v) then continue end

		if found then
			return false
		end

		found = true
	end

	return true
end

local function revertTmpVehicleName(vehicle, vehicleTable)
	local tmpVehicleName = vehicleTable.currentPassengerVehicleTmpName or ""
	if tmpVehicleName == "" then
		return
	end

	local currentName = vehicle:GetName()
	local oldVehicleName = vehicleTable.currentPassengerVehicleOldName or ""

	if currentName == oldVehicleName then
		return
	end

	vehicle:SetName(oldVehicleName)
end

local function npcEnterVehicleInternal(vehicle, vehicleTable, npc, immediately)
	local vehicleName = vehicle:GetName()

	local isUnique = isUniqueVehicleName(vehicleName)
	if isUnique then
		if immediately then
			npc:Fire("EnterVehicleImmediately", vehicleName)
		else
			npc:Fire("EnterVehicle", vehicleName)
		end

		return
	end

	local oldVehicleName = vehicleTable.currentPassengerVehicleOldName or vehicleName
	local tmpVehicleName = vehicleTable.currentPassengerVehicleTmpName or ""

	if tmpVehicleName == "" then
		local tmpPrefix = oldVehicleName ~= "" and oldVehicleName or "Vehicle"
		tmpPrefix = "SligWolf_" .. tmpPrefix .. "_UniqueId"

		tmpVehicleName = LIBUtil.UniqueString(tmpPrefix)
	end

	vehicleTable.currentPassengerVehicleOldName = oldVehicleName
	vehicleTable.currentPassengerVehicleTmpName = tmpVehicleName

	vehicle:SetName(tmpVehicleName)

	if immediately then
		npc:Fire("EnterVehicleImmediately", tmpVehicleName)
	else
		npc:Fire("EnterVehicle", tmpVehicleName)
	end

	local timerName = LIBTimer.GetEntityTimerName(vehicle, g_passengerRevertTmpVehicleName)
	LIBTimer.Remove(timerName)

	-- The temporary name has to be reverted after the next 2 frames.
	LIBTimer.NextFrame(timerName, function()
		LIBTimer.NextFrame(timerName, function()
			if not IsValid(vehicle) then
				return
			end

			revertTmpVehicleName(vehicle, vehicleTable)
		end)
	end)
end

function LIB.NpcEnterVehicle(vehicle, npc, immediately, callback)
	callback = callback or function() end

	if not LIB.NpcCanEnterVehicle(vehicle, npc) then
		callback(vehicle, npc, false)
		return
	end

	local npcTable = npc:SligWolf_GetTable()
	local vehicleTable = vehicle:SligWolf_GetTable()

	npcEnterVehicleInternal(vehicle, vehicleTable, npc, immediately, vehicleName)

	npcTable.passengerLock = true
	npcTable.currentPassengerVehicle = vehicle

	vehicleTable.passengerLock = true
	vehicleTable.currentPassengerNpc = npc
	vehicleTable.passengerEnterAbort = nil

	local timerName = LIBTimer.GetEntityTimerName(vehicle, g_passengerHandlingTimer)
	LIBTimer.Remove(timerName)

	if immediately then
		npcTable.passengerLock = nil
		vehicleTable.passengerLock = nil
		vehicleTable.passengerEnterAbort = nil

		callback(vehicle, npc, true)
		return
	end

	LIBTimer.Until(timerName, 0.25, function(running, ...)
		local validNpc = IsValid(npc)

		if not IsValid(vehicle) then
			if validNpc then
				npcTable.passengerLock = nil
				npcTable.currentPassengerVehicle = nil
			end

			return true
		end

		if not validNpc or not npc:Alive() then
			vehicleTable.passengerLock = nil
			vehicleTable.currentPassengerNpc = nil

			if validNpc then
				npcTable.passengerLock = nil
				npcTable.currentPassengerVehicle = nil

				callback(vehicle, npc, false)
			end

			return true
		end

		local isInVehicle = LIB.NPCPassengerIsInVehicle(npc, vehicle)

		if not isInVehicle then
			if not running then
				-- failed after timeout, force npc to stay out
				npcTable.passengerLock = nil
				npcTable.currentPassengerVehicle = nil

				vehicleTable.passengerLock = nil
				vehicleTable.currentPassengerNpc = nil

				vehicleTable.passengerEnterAbort = true
				LIB.NpcExitVehicle(vehicle, npc, false, function()
					vehicleTable.passengerEnterAbort = nil

					callback(vehicle, npc, false)
				end)

				return true
			end

			-- try again if not timed out
			return false
		end

		npcTable.passengerLock = nil
		vehicleTable.passengerLock = nil

		callback(vehicle, npc, true)

		return true
	end, 0, g_passengerHandlingTimeout)
end

function LIB.NpcExitVehicle(npcOrVehicle, npc, immediately, callback)
	if not IsValid(npcOrVehicle) then return end

	local vehicle = nil

	if npcOrVehicle:IsNPC() then
		npc = npcOrVehicle
		vehicle = LIB.GetNpcPassengerVehicle(npc)
	elseif npcOrVehicle:IsVehicle() then
		vehicle = npcOrVehicle

		if not IsValid(npc) then
			npc = LIB.GetNpcPassenger(vehicle)
		end
	end

	callback = callback or function() end

	if not LIB.NpcCanExitVehicle(vehicle, npc) then
		callback(vehicle, npc, false)
		return
	end

	local npcTable = npc:SligWolf_GetTable()
	local vehicleTable = vehicle:SligWolf_GetTable()

	npcTable.passengerLock = true
	vehicleTable.passengerLock = true

	SafeRemoveEntity(vehicleTable.passengerNoCollide)
	vehicleTable.passengerNoCollide = LIBConstraints.NoCollide(vehicle, npc)

	local passengerNoCollide = vehicleTable.passengerNoCollide

	npc:Fire("ExitVehicle")

	if immediately then
		npc:SetParent()
	end

	local timerName = LIBTimer.GetEntityTimerName(vehicle, g_passengerHandlingTimer)
	LIBTimer.Remove(timerName)

	if immediately then
		npcTable.passengerLock = nil
		npcTable.currentPassengerVehicle = nil

		vehicleTable.passengerLock = nil
		vehicleTable.currentPassengerNpc = nil

		SafeRemoveEntity(vehicleTable.passengerNoCollide)
		vehicleTable.passengerNoCollide = nil

		vehicleTable.passengerEnterAbort = nil

		callback(vehicle, npc, true)
		return
	end

	LIBTimer.Until(timerName, 0.25, function(running)
		local validNpc = IsValid(npc)

		if not IsValid(vehicle) then
			if validNpc then
				npcTable.passengerLock = nil
				npcTable.currentPassengerVehicle = nil
			end

			SafeRemoveEntity(passengerNoCollide)
			return true
		end

		if not validNpc then
			vehicleTable.passengerLock = nil
			vehicleTable.currentPassengerNpc = nil

			SafeRemoveEntity(vehicleTable.passengerNoCollide)
			vehicleTable.passengerNoCollide = nil

			return true
		end

		local isInVehicle = LIB.NPCPassengerIsInVehicle(npc, vehicle)

		if isInVehicle then
			if not running then
				-- failed after timeout, force npc in again
				npcTable.passengerLock = nil
				npcTable.currentPassengerVehicle = nil

				vehicleTable.passengerLock = nil
				vehicleTable.currentPassengerNpc = nil

				SafeRemoveEntity(vehicleTable.passengerNoCollide)
				vehicleTable.passengerNoCollide = nil

				if vehicleTable.passengerEnterAbort then
					-- prevent infinite loop
					callback(vehicle, npc, false)
					return true
				end

				LIB.NpcEnterVehicle(vehicle, npc, true, function()
					callback(vehicle, npc, false)
				end)

				return true
			end

			-- try again if not timed out
			return false
		end

		npcTable.passengerLock = nil
		npcTable.currentPassengerVehicle = nil

		vehicleTable.passengerLock = nil
		vehicleTable.currentPassengerNpc = nil

		SafeRemoveEntity(vehicleTable.passengerNoCollide)
		vehicleTable.passengerNoCollide = nil

		callback(vehicle, npc, true)

		return true
	end, 0, g_passengerHandlingTimeout)
end


function LIB.Load()
	LIBConstraints = SligWolf_Addons.Constraints
	LIBSpawnmenu = SligWolf_Addons.Spawnmenu
	LIBCoupling = SligWolf_Addons.Coupling
	LIBEntities = SligWolf_Addons.Entities
	LIBSourceIO = SligWolf_Addons.SourceIO
	LIBPosition = SligWolf_Addons.Position
	LIBPhysics = SligWolf_Addons.Physics
	LIBCamera = SligWolf_Addons.Camera
	LIBTimer = SligWolf_Addons.Timer
	LIBModel = SligWolf_Addons.Model
	LIBHook = SligWolf_Addons.Hook
	LIBUtil = SligWolf_Addons.Util

	local function SpawnVehicleFinished(vehicle, ply)
		if not IsValid(vehicle) then return end

		if not vehicle:IsVehicle() then return end
		if not vehicle:IsValidVehicle() then return end

		if not vehicle.sligwolf_vehicle then return end

		local addonname = vehicle.sligwolf_addonname
		if not addonname then return end

		local vat = vehicle:SligWolf_GetAddonTable(addonname)
		SligWolf_Addons.CallFunctionOnAddon(addonname, "SpawnVehicleFinished", vehicle, vat, ply)

		if SERVER then
			local vehicleTable = LIBEntities.GetSpawntable(vehicle) or {}
			local keyValues = LIBSourceIO.GetKeyValues(vehicle)

			local spawnFrozen = false
			local overrideBodyStates = false

			local spawnFrozenKV = tonumber(keyValues.sligwolf_frozen or 0) or 0
			if spawnFrozenKV == 0 then
				spawnFrozen = vehicleTable.SLIGWOLF_SpawnFrozen or false
				overrideBodyStates = false
			elseif spawnFrozenKV == 1 then
				spawnFrozen = false
				overrideBodyStates = true
			elseif spawnFrozenKV == 2 then
				spawnFrozen = true
				overrideBodyStates = true
			end

			LIBEntities.ApplySpawnState(vehicle)
			LIBEntities.EnableMotion(vehicle, not spawnFrozen)

			if overrideBodyStates then
				LIBEntities.EnableBodySystemMotion(vehicle, not spawnFrozen)
			end

			local isSpawnedByEngine = LIB.IsSpawnedByEngine(vehicle)
			if isSpawnedByEngine then
				local trailerData = LIBCoupling.GetTrailerData(vehicle)
				trailerData.lightState = tobool(keyValues.sligwolf_light)

				SligWolf_Addons.CallFunctionOnAddon(addonname, "LightsUpdateGlows", vehicle)

				-- @TODO: Code a proper EngineState library/logic?
				local engineState = tobool(keyValues.sligwolf_engine)
				SligWolf_Addons.CallFunctionOnAddon(addonname, "EngineState", vehicle, vat, engineState)
			end
		end
	end

	LIBHook.AddCustom("SpawnSystemFinished", "Library_Vehicle_SpawnVehicleFinished", SpawnVehicleFinished, 20000)

	local function PlayerEnteredVehicle(ply, vehicle)
		if not IsValid(vehicle) then return end
		if not IsValid(ply) then return end

		if not vehicle:IsVehicle() then return end
		if not vehicle:IsValidVehicle() then return end

		if not vehicle.sligwolf_vehicle then return end

		local addonname = vehicle.sligwolf_addonname
		if not addonname then return end

		local vat = vehicle:SligWolf_GetAddonTable(addonname)

		LIBCamera.LeaveCamera(ply)

		SligWolf_Addons.CallFunctionOnAddon(addonname, "EnterVehicle", ply, vehicle, vat)
	end

	LIBHook.Add("PlayerEnteredVehicle", "Library_Vehicle_PlayerEnteredVehicle", PlayerEnteredVehicle, 20000)

	local function PlayerLeaveVehicle(ply, vehicle)
		if not IsValid(vehicle) then return end
		if not IsValid(ply) then return end

		if not vehicle:IsVehicle() then return end
		if not vehicle:IsValidVehicle() then return end

		if not vehicle.sligwolf_vehicle then return end

		local addonname = vehicle.sligwolf_addonname
		if not addonname then return end

		local vat = vehicle:SligWolf_GetAddonTable(addonname)

		SligWolf_Addons.CallFunctionOnAddon(addonname, "LeaveVehicle", ply, vehicle, vat)

		LIB.ResetDriverMaxHealth(ply)
		LIBCamera.LeaveCamera(ply)
	end

	LIBHook.Add("PlayerLeaveVehicle", "Library_Vehicle_PlayerLeaveVehicle", PlayerLeaveVehicle, 20000)

	local function OnPostEntityCreated(ent)
		if not IsValid(ent) then return end
		if not ent:IsVehicle() then return end

		LIBTimer.SimpleNextFrame(function()
			if not IsValid(ent) then return end
			if not ent:IsVehicle() then return end
			if not ent:IsValidVehicle() then return end

			LIBHook.RunCustom("OnPostVehicleCreated", ent)
		end)
	end

	LIBHook.AddCustom("OnPostEntityCreated", "Library_Vehicle_OnPostEntityCreated", OnPostEntityCreated, 10000)

	local function HandleVehicleSpawn(vehicle)
		if not IsValid(vehicle) then return end
		if not vehicle:IsVehicle() then return end
		if not vehicle:IsValidVehicle() then return end

		local vehicleSpawnname = LIBEntities.GetSpawnname(vehicle)
		if not vehicleSpawnname then
			return
		end

		local vehicleTable = LIBEntities.GetSpawntable(vehicle)
		if not vehicleTable then
			return
		end

		local addonname = vehicleTable.SLIGWOLF_Addonname
		if not addonname then
			return
		end

		SligWolf_Addons.CallFunctionOnAddon(addonname, "HandleVehicleSpawn", vehicle, vehicleSpawnname, vehicleTable)
	end

	LIBHook.AddCustom("OnPostVehicleCreated", "Library_Vehicle_HandleVehicleSpawn", HandleVehicleSpawn, 10000)
end

return true

