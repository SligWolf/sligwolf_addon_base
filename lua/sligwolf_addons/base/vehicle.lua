AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SLIGWOLF_ADDON then
	SligWolf_Addons:ReloadAddonSystem()
	return
end

local SligWolf_Addons = SligWolf_Addons

local CONSTANTS = SligWolf_Addons.Constants

local LIBThirdperson = SligWolf_Addons.Thirdperson
local LIBPosition = SligWolf_Addons.Position
local LIBEntities = SligWolf_Addons.Entities
local LIBVehicle = SligWolf_Addons.Vehicle
local LIBPhysics = SligWolf_Addons.Physics

function SLIGWOLF_ADDON:MakeVehicle(spawnname, plyOwner, parent, name)
	local ent = LIBVehicle.MakeVehicle(spawnname, plyOwner, parent, name, self.Addonname)
	if not ent then
		return nil
	end

	return ent
end

function SLIGWOLF_ADDON:MakeVehicleEnsured(spawnname, plyOwner, parent, name)
	local ent = self:MakeVehicle(spawnname, plyOwner, parent, name)
	if not IsValid(ent) then
		self:RemoveFaultyEntities(
			{parent},
			"Couldn't create '%s' vehicle entity named '%s' for %s. Removing entities.",
			tostring(spawnname),
			tostring(name or "<unnamed>"),
			parent
		)

		return nil
	end

	return ent
end

function SLIGWOLF_ADDON:HandleVehicleSpawnAddVehicleType(vehicle, customSpawnProperties)
	local addonname = self.Addonname
	vehicle.sligwolf_addonname = addonname

	vehicle["sligwolf_is_" .. addonname] = true

	local vehicleType = tostring(customSpawnProperties.vehicleType or "")
	vehicleType = string.lower(vehicleType)

	if vehicleType ~= "" then
		customSpawnProperties.vehicleType = vehicleType

		vehicle["sligwolf_is_" .. addonname .. "_" .. vehicleType] = true
		vehicle["sligwolf_isType_" .. vehicleType] = true

		self:AddToEntList("vehicles_" .. vehicleType, vehicle)
	else
		vehicleType = nil
		customSpawnProperties.vehicleType = nil
	end

	vehicle.sligwolf_vehicle_type = vehicleType

	self:AddToEntList("vehicles", vehicle)
end

function SLIGWOLF_ADDON:HandleVehicleSpawnAddDenyToolReload(vehicle, customSpawnProperties)
	local denyToolReload = customSpawnProperties.denyToolReload
	if not denyToolReload then
		denyToolReload = {
			"weld",
			"nocollide",
			"remover",
		}
	end

	local denyToolReloadIndexed = {}

	for k, v in pairs(denyToolReload) do
		if isstring(k) then
			denyToolReloadIndexed[k] = tobool(v)
			continue
		end

		denyToolReloadIndexed[v] = true
	end

	vehicle.sligwolf_denyToolReload	= denyToolReloadIndexed
	customSpawnProperties.denyToolReload = denyToolReloadIndexed
end

function SLIGWOLF_ADDON:HandleVehicleSpawn(vehicle, vehicleSpawnname, vehicleTable)
	local isSpawnedByEngine = LIBVehicle.IsSpawnedByEngine(vehicle)

	local keyValues = table.Copy(vehicleTable.KeyValues or {})
	local class = vehicleTable.Class
	local members = vehicleTable.Members
	local customSpawnProperties = vehicleTable.SLIGWOLF_Custom or {}

	local entTable = vehicle:SligWolf_GetTable()

	vehicle.sligwolf_entity = true
	vehicle.sligwolf_vehicle = true
	vehicle.sligwolf_headVehicle = true

	self:HandleVehicleSpawnAddVehicleType(vehicle, customSpawnProperties)
	self:HandleVehicleSpawnAddDenyToolReload(vehicle, customSpawnProperties)

	LIBThirdperson.SetThirdpersonParameters(vehicle, customSpawnProperties.thirdperson)

	local spawnOffset = customSpawnProperties.spawnOffset
	local spawnOffsetDupe = customSpawnProperties.spawnOffsetDupe or customSpawnProperties.spawnOffset

	LIBPhysics.InitializeAsPhysEntity(vehicle)

	if isSpawnedByEngine then
		-- We must not change the vehicle script after spawn
		keyValues.vehiclescript = nil

		LIBVehicle.SetupVehicleKeyValues(vehicle, keyValues)
	end

	local keyValuesOverride = entTable.keyValuesOverride or {}
	if keyValuesOverride then
		keyValuesOverride.vehiclescript = nil

		LIBVehicle.SetupVehicleKeyValues(vehicle, keyValuesOverride)
		entTable.keyValuesOverride = nil
	end

	vehicle.VehicleName = vehicleSpawnname
	vehicle.VehicleTable = vehicleTable

	entTable.customSpawnProperties = customSpawnProperties

	local ply = entTable.spawnerPlayer

	if isSpawnedByEngine then
		if vehicle.SetVehicleClass and SERVER then
			vehicle:SetVehicleClass(vehicleSpawnname)
		end

		vehicle.ClassOverride = class

		if members then
			table.Merge(vehicle, members)

			if SERVER then
				duplicator.StoreEntityModifier(vehicle, "VehicleMemDupe", members)
			end
		end


	end

	LIBEntities.EnableMotion(vehicle, false)

	self:HandleSpawnFinishedEvent(vehicle)

	local spawnVehicle = function(thisVehicle)
		local vat = self:GetEntityTable(thisVehicle)

		self:CallAddonFunctionWithErrorNoHalt(
			"SpawnVehicle",
			ply,
			thisVehicle,
			vat,
			customSpawnProperties
		)
	end

	local callsback = false
	local isDupe = entTable.isDuped

	if SERVER and not isSpawnedByEngine then
		local pos = vehicle:GetPos()
		local ang = vehicle:GetAngles()

		local newpos = nil
		local newang = nil

		if not isDupe and spawnOffset then
			newpos, newang = LocalToWorld(spawnOffset.pos or CONSTANTS.vecZero, spawnOffset.ang or CONSTANTS.angZero, pos, ang)
		elseif isDupe and spawnOffsetDupe then
			newpos, newang = LocalToWorld(spawnOffsetDupe.pos or CONSTANTS.vecZero, spawnOffsetDupe.ang or CONSTANTS.angZero, pos, ang)
		end

		if newpos and newang then
			callsback = LIBPosition.SetPosAng(vehicle, newpos, newang, spawnVehicle)
		end
	end

	if not callsback then
		spawnVehicle(vehicle)
	end
end

return true

