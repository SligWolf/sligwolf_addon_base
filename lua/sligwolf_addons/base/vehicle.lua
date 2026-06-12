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

local LIBSpamprotection = SligWolf_Addons.Spamprotection
local LIBThirdperson = SligWolf_Addons.Thirdperson
local LIBDuplicator = SligWolf_Addons.Duplicator
local LIBEntities = SligWolf_Addons.Entities
local LIBPosition = SligWolf_Addons.Position
local LIBRailscan = SligWolf_Addons.Railscan
local LIBSourceIO = SligWolf_Addons.SourceIO
local LIBVehicle = SligWolf_Addons.Vehicle
local LIBPhysics = SligWolf_Addons.Physics
local LIBTracer = SligWolf_Addons.Tracer
local LIBDebug = SligWolf_Addons.Debug
local LIBPrint = SligWolf_Addons.Print
local LIBRail = SligWolf_Addons.Rail

local g_spawnOffsetMx = Matrix()

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

function SLIGWOLF_ADDON:HandleVehicleSpawnPos(vehicle, ply, title, spawnOffsets, trainOptions, trainGauge)
	local parent = LIBEntities.GetParent(vehicle)
	if IsValid(parent) then
		-- In case it has been attached to a parent, don't apply spawn pos logic.
		return
	end

	local thisSpawnOffset = nil

	local railScanResult = nil
	local railScanResultGauge = nil

	local isDupe = LIBDuplicator.WasDuped(vehicle)

	if not isDupe and trainGauge and IsValid(ply) then
		local aimTrace = LIBTracer.PlayerAimTrace(ply, 5000)

		if aimTrace and aimTrace.Hit then
			LIBDebug.SetLifetime(30)

			railScanResult = LIBRailscan.ScanRailWithGauge(
				vehicle,
				aimTrace,
				trainGauge,
				{
					trainSizeMin = trainOptions.trainSizeMin,
					trainSizeMax = trainOptions.trainSizeMax,
				}
			)

			LIBDebug.ResetLifetime()

			if railScanResult then
				railScanResultGauge = railScanResult.gauge
			end
		end

		if trainGauge == LIBRail.TRAIN_GAUGE_AUTO or trainGauge == LIBRail.TRAIN_GAUGE_DEFAULT then
			local gaugeSpawnnameInfo = LIBRail.GetSpawnnameInfo(
				trainOptions.spawnnameNoGauge,
				railScanResultGauge and railScanResultGauge.name or LIBRail.TRAIN_GAUGE_DEFAULT
			)

			if gaugeSpawnnameInfo then
				-- Respawn the train using the gauge as found by Railscan.ScanRailWithGauge().
				vehicle:Remove()
				ply:ConCommand("gm_spawnvehicle " .. gaugeSpawnnameInfo.spawnnameFull)

				return
			end

			-- no auto on-railing for unsupported gauge
			railScanResultGauge = nil
			railScanResult = nil
		end
	end

	g_spawnOffsetMx:Identity()

	if railScanResult then
		if railScanResultGauge then
			local message = string.format("Fitting %s into %s rail!", title, railScanResultGauge.title)
			LIBPrint.Notify(LIBPrint.NOTIFY_GENERIC, message, 3, ply)
		end

		-- auto on-railing spawn behaviour
		thisSpawnOffset = spawnOffsets.rail

		g_spawnOffsetMx:SetTranslation(railScanResult.pos)
		g_spawnOffsetMx:SetAngles(railScanResult.ang)

		g_spawnOffsetMx:Rotate(Angle(0, -90, 0))
	else
		-- default spawn behaviour
		thisSpawnOffset = isDupe and spawnOffsets.dupe or spawnOffsets.main

		g_spawnOffsetMx:SetTranslation(vehicle:GetPos())
		g_spawnOffsetMx:SetAngles(vehicle:GetAngles())
	end

	if thisSpawnOffset then
		if thisSpawnOffset.pos then
			g_spawnOffsetMx:Translate(thisSpawnOffset.pos)
		end

		if thisSpawnOffset.ang then
			g_spawnOffsetMx:Rotate(thisSpawnOffset.ang)
		end
	end

	local newpos = g_spawnOffsetMx:GetTranslation()
	local newang = g_spawnOffsetMx:GetAngles()

	LIBPosition.SetPosAng(vehicle, newpos, newang)
end

function SLIGWOLF_ADDON:HandleVehicleSpawn(vehicle, vehicleSpawnname, vehicleTable)
	local isSpawnedByEngine = LIBSourceIO.IsSpawnedByEngine(vehicle)

	local title = vehicleTable.Name
	local class = vehicleTable.Class
	local members = vehicleTable.Members
	local thirdperson = vehicleTable.SLIGWOLF_Thirdperson
	local isTrain = vehicleTable.SLIGWOLF_IsTrain

	local keyValues = table.Copy(vehicleTable.KeyValues or {})
	local customSpawnProperties = table.Copy(vehicleTable.SLIGWOLF_Custom or {})
	local spawnOffsets = table.Copy(vehicleTable.SLIGWOLF_SpawnOffsets or {})
	local trainOptions = table.Copy(vehicleTable.SLIGWOLF_TrainOptions or {})
	local spawnOBB = table.Copy(vehicleTable.SLIGWOLF_SpawnOBB or {})

	local trainGauge = nil
	local trainGaugeTable = nil

	if isTrain then
		trainGauge = trainOptions.gauge
		trainGaugeTable = LIBRail.GetGaugeByName(trainOptions.gauge)
	end

	local entTable = vehicle:SligWolf_GetTable()

	vehicle.sligwolf_entity = true
	vehicle.sligwolf_vehicle = true
	vehicle.sligwolf_train = isTrain
	vehicle.sligwolf_headVehicle = true

	self:HandleVehicleSpawnAddVehicleType(vehicle, customSpawnProperties)
	self:HandleVehicleSpawnAddDenyToolReload(vehicle, customSpawnProperties)

	LIBThirdperson.SetThirdpersonParameters(vehicle, thirdperson)

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

	if SERVER and isSpawnedByEngine then
		if vehicle.SetVehicleClass and vehicle.SetDTString then
			vehicle:SetVehicleClass(vehicleSpawnname)
		end

		vehicle.ClassOverride = class

		if members then
			table.Merge(vehicle, members)
			duplicator.StoreEntityModifier(vehicle, "VehicleMemDupe", members)
		end
	end

	local callSpawnVehicle = function(thisVehicle, success)
		if LIBEntities.IsMarkedForDeletion(thisVehicle) then
			return true
		end

		if not success then
			self:ErrorNoHalt("CallSpawnVehicle timed out after 10 seconds\n")
			return true
		end

		if CLIENT and trainGaugeTable and not trainGaugeTable.isReal then
		 	return true
		end

		-- try again if the position is not final yet
		if LIBPosition.IsAsyncPositioning(thisVehicle) then
			return false
		end

		if LIBSpamprotection.DeleteIfInsufficientSpawnSpace(thisVehicle, spawnOBB) then
			-- Entity has been removed
			return true
		end

		local vat = self:GetEntityTable(thisVehicle)

		self:CallAddonFunctionWithErrorNoHalt(
			"SpawnVehicle",
			ply,
			thisVehicle,
			vat,
			customSpawnProperties
		)

		return true
	end

	if SERVER and not isSpawnedByEngine then
		self:HandleVehicleSpawnPos(vehicle, ply, title, spawnOffsets, trainOptions, trainGauge)
	end

	if LIBEntities.IsMarkedForDeletion(vehicle) then
		return
	end

	local delay = LIBTimer.TickTime(2)

	self:EntityTimerRemove(vehicle, "HandleVehicleSpawn_WaitForAsyncPositioning")
	self:EntityTimerUntil(vehicle, "HandleVehicleSpawn_WaitForAsyncPositioning", delay, callSpawnVehicle, 0, 10)
end

return true

