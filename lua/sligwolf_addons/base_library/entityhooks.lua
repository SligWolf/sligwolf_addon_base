local SligWolf_Addons = _G.SligWolf_Addons
if not SligWolf_Addons then
	return
end

local LIB = SligWolf_Addons:NewLib("Entityhooks")

local LIBDuplicator = nil
local LIBEntities = nil
local LIBSourceIO = nil
local LIBVehicle = nil
local LIBHook = nil

local g_keyValueClassWhiteList = LIB.g_keyValueClassWhiteList or {}
LIB.g_keyValueClassWhiteList = g_keyValueClassWhiteList

local g_entityCreatedQueue = LIB.g_entityCreatedQueue or {}
LIB.g_entityCreatedQueue = g_entityCreatedQueue

function LIB.ListenToKeyValueForClasses(classes)
	if not classes then
		return
	end

	if not istable(classes) then
		classes = {classes}
	end

	if table.IsEmpty(classes) then
		classes = {classes}
	end

	for _, class in pairs(classes) do
		class = tostring(class or "")
		g_keyValueClassWhiteList[class] = true
	end
end

function LIB.RegisterKeyValue(ent, key, value)
	local entTable = ent:SligWolf_GetTable()

	local keyValues = entTable.keyValues or {}
	entTable.keyValues = keyValues

	local isMapOutputs = LIBSourceIO.IsMapOutputString(value)

	if isMapOutputs then
		value = LIBSourceIO.ParseMapOutputString(key, value)
		LIB.RegisterOutput(ent, key, value)
	else
		keyValues[key] = value
	end
end

function LIB.RegisterOutput(ent, outputName, outputData)
	if not outputData then
		return
	end

	local entTable = ent:SligWolf_GetTable()

	local mapOutputs = entTable.mapOutputs or {}
	entTable.mapOutputs = mapOutputs

	local outputs = mapOutputs[outputName] or {}
	mapOutputs[outputName] = outputs

	table.insert(outputs, outputData)
end

local function IsAllowed(ent, key, value)
	local class = ent:GetClass()

	if g_keyValueClassWhiteList[class] then
		return true
	end

	if ent.sligwolf_entity then
		return true
	end

	if string.StartsWith(key, "sligwolf_") then
		return true
	end

	return false
end

local function ApplyEntityCreatedQueue()
	-- Call hooks as listed in g_entityCreatedQueue for their entities

	for _, item in ipairs(g_entityCreatedQueue) do
		local ent1 = item.ent1
		local ent2 = item.ent2
		local hookName = item.hookName

		if LIBEntities.IsMarkedForDeletion(ent1) then
			continue
		end

		if ent2 ~= nil and LIBEntities.IsMarkedForDeletion(ent2) then
			continue
		end

		LIBHook.RunCustom(hookName, ent1, ent2)
	end

	table.Empty(g_entityCreatedQueue)

	-- Remove temporary hook, so it doesn't idle if no entities are being created
	LIBHook.Remove("Tick", "Library_EntityHooks_ApplyEntityCreatedQueue")
end

function LIB.AddToEntityCreatedQueue(hookName, ent1, ent2)
	table.insert(g_entityCreatedQueue, {
		hookName = hookName,
		ent1 = ent1,
		ent2 = ent2,
	})

	if #g_entityCreatedQueue == 1 then
		-- Start temporary hook as soon as the first queue entry is made
		LIBHook.Add("Tick", "Library_EntityHooks_ApplyEntityCreatedQueue", ApplyEntityCreatedQueue, -100000)
	end
end

function LIB.Load()
	LIBDuplicator = SligWolf_Addons.Duplicator
	LIBEntities = SligWolf_Addons.Entities
	LIBPhysics = SligWolf_Addons.Physics
	LIBSourceIO = SligWolf_Addons.SourceIO
	LIBVehicle = SligWolf_Addons.Vehicle
	LIBHook = SligWolf_Addons.Hook
	LIBUtil = SligWolf_Addons.Util

	LIB.ListenToKeyValueForClasses({
		"prop_vehicle_airboat",
		"prop_vehicle_jeep",
		"prop_vehicle_prisoner_pod",
	})

	if SERVER then
		-- Make sure we get ALL key values for later,
		-- as ent:GetKeyValues does not return all keyValues.
		local function RegisterKeyValue(ent, key, value)
			if not IsValid(ent) then return end
			if not IsAllowed(ent, key, value) then return end

			LIB.RegisterKeyValue(ent, key, value)
		end

		LIBHook.Add("EntityKeyValue", "Library_EntityHooks_RegisterKeyValue", RegisterKeyValue, 20000)

		LIBHook.Add("OnPhysgunFreeze", "Library_EntityHooks_UpdateFreeze", function(weapon, phys, ent, ply)
			LIBEntities.UpdateBodySystemMotion(ent, true)
		end, 20000)

		LIBHook.Add("CanPlayerUnfreeze", "Library_EntityHooks_UpdateFreeze", function(ply, ent, phys)
			LIBEntities.UpdateBodySystemMotion(ent, true)
		end, 20000)

		LIBHook.Add("OnPhysgunPickup", "Library_EntityHooks_UpdateFreeze", function(ply, ent)
			LIBEntities.UpdateBodySystemMotion(ent, true)
		end, 20000)

		LIBHook.Add("PhysgunDrop", "Library_EntityHooks_UpdateFreeze", function(ply, ent)
			LIBEntities.UpdateBodySystemMotion(ent, true)
		end, 20000)
	end

	local function SpawnSystemFinishedClearCaches(ent, ply)
		if not IsValid(ent) then return end
		if not ent.sligwolf_entity then return end

		local systemEntities = LIBEntities.GetSystemEntities(ent)
		if not systemEntities then return end

		for _, thisent in ipairs(systemEntities) do
			LIBEntities.ClearCache(thisent)
		end
	end

	LIBHook.AddCustom("SpawnSystemFinished", "Library_EntityHooks_SpawnSystemFinishedClearCaches", SpawnSystemFinishedClearCaches, 1000)

	local function SpawnSystemEntitiesFinished(ent, ply)
		if not IsValid(ent) then return end
		if not ent.sligwolf_entity then return end

		local systemEntities = LIBEntities.GetSystemEntities(ent)
		if systemEntities then
			for _, thisent in ipairs(systemEntities) do
				if not thisent.SpawnSystemFinished then
					continue
				end

				thisent:SpawnSystemFinished(ply)
			end
		end

		local addonname = nil

		if ent.sligwolf_baseEntity then
			addonname = ent:GetAddonID()
		end

		if not addonname or addonname == "" then
			addonname = ent.sligwolf_addonname
		end

		local addon = SligWolf_Addons.GetAddon(addonname)
		if addon then
			if addon.SpawnSystemFinished then
				addon:SpawnSystemFinished(ent, ply)
			end

			if ent:IsVehicle() and ent:IsValidVehicle() then
				local vat = ent:SligWolf_GetAddonTable(addonname)

				if addon.SpawnVehicleFinished then
					addon:SpawnVehicleFinished(ent, vat, ply)
				end
			end
		end
	end

	LIBHook.AddCustom("SpawnSystemFinished", "Library_EntityHooks_SpawnSystemEntitiesFinished", SpawnSystemEntitiesFinished, 10000)

	local function CallOnPostAddonEntityCreated(ent)
		local spawnname = LIBEntities.GetSpawnname(ent)
		if not spawnname then return end

		local spawntable = LIBEntities.GetSpawntable(ent)
		if not spawntable then return end
		if not spawntable.Is_SLIGWOLF then return end

		local addonname = spawntable.SLIGWOLF_Addonname
		if not addonname then return end

		ent.sligwolf_entity = true
		ent.sligwolf_addonname = addonname

		if ent.sligwolf_baseEntity then
			ent:SetAddonID(addonname)
		end

		ent["sligwolf_is_" .. addonname] = true

		LIBHook.RunCustom("OnPostAddonEntityCreated", ent, spawnname, spawntable, addonname)
	end

	LIBHook.AddCustom("OnPostEntityCreated", "Library_EntityHooks_CallOnPostAddonEntityCreated", CallOnPostAddonEntityCreated, -100000)

	local function CallPostPlayerSpawnedAddonEntity(ply, ent)
		local spawnname = LIBEntities.GetSpawnname(ent)
		if not spawnname then return end

		local spawntable = LIBEntities.GetSpawntable(ent)
		if not spawntable then return end
		if not spawntable.Is_SLIGWOLF then return end

		local addonname = spawntable.SLIGWOLF_Addonname
		if not addonname then return end

		LIBHook.RunCustom("PostPlayerSpawnedAddonEntity", ply, ent, spawnname, spawntable, addonname)
	end

	LIBHook.AddCustom("PostPlayerSpawnedEntity", "Library_EntityHooks_CallPostPlayerSpawnedAddonEntity", CallPostPlayerSpawnedAddonEntity, -100000)

	if SERVER then
		local function SpawnSystemFinishedApplyKeyValues(ent, ply)
			local spawnTable = LIBEntities.GetSpawntable(ent) or {}
			local keyValues = LIBSourceIO.GetKeyValues(ent)

			local static = ent.sligwolf_physBaseEntity and ent:GetStatic()

			local spawnFrozen = spawnTable.SLIGWOLF_SpawnFrozen or false
			local overrideSystemMotion = false

			if not static then
				local frozenKeyValue = tonumber(keyValues.sligwolf_frozen or 0) or 0
				if frozenKeyValue == 1 then
					spawnFrozen = false
					overrideSystemMotion = true
				elseif frozenKeyValue == 2 then
					spawnFrozen = true
					overrideSystemMotion = true
				end
			else
				-- Static entities are always frozen
				spawnFrozen = true
				overrideSystemMotion = true
			end

			LIBEntities.EnablePhysicsAfterSpawn(ent)
			LIBEntities.EnableMotion(ent, not spawnFrozen)

			if overrideSystemMotion then
				LIBEntities.EnableSystemMotion(ent, not spawnFrozen)
			end

			local isSpawnedByEngine = LIBSourceIO.IsSpawnedByEngine(ent)
			if isSpawnedByEngine then
				LIBVehicle.VehicleSetLightState(ent, keyValues.sligwolf_light)
				LIBVehicle.VehicleSetEngineState(ent, keyValues.sligwolf_engine)
			end
		end

		LIBHook.AddCustom("SpawnSystemFinished", "Library_EntityHooks_SpawnSystemFinishedApplyKeyValues", SpawnSystemFinishedApplyKeyValues, 11000)

		local function DisablePhysicsDuringSpawn(ent, spawnname, spawntable, addonname)
			local keyValues = LIBSourceIO.GetKeyValues(ent)

			local static = ent.sligwolf_physBaseEntity and ent:GetStatic()

			local spawnFrozen = spawntable.SLIGWOLF_SpawnFrozen or false

			if not static then
				local frozenKeyValue = tonumber(keyValues.sligwolf_frozen or 0) or 0
				if frozenKeyValue == 1 then
					spawnFrozen = false
				elseif frozenKeyValue == 2 then
					spawnFrozen = true
				end
			else
				-- Static entities are always frozen
				spawnFrozen = true
			end

			LIBEntities.DisablePhysicsDuringSpawn(ent, spawnFrozen, ent:IsSolid())

			SligWolf_Addons.CallFunctionOnAddon(addonname, "HandleSpawnFinishedEvent", ent)
		end

		LIBHook.AddCustom("OnPostAddonEntityCreated", "Library_EntityHooks_DisablePhysicsDuringSpawn", DisablePhysicsDuringSpawn, 11000)
	end

	local function RunCallOnRemoveEffect(ent)
		if not IsValid(ent) then return end

		LIBEntities.RunCallOnRemoveEffect(ent)
	end

	LIBHook.AddCustom("EntityRemovedByToolgun", "Library_EntityHooks_RunCallOnRemoveEffect", RunCallOnRemoveEffect, 1000)

	local function RunCallOnRemove(ent, fullUpdate)
		if fullUpdate then return end

		if not IsValid(ent) then return end
		if not ent.sligwolf_entity then return end

		LIBEntities.RunCallOnRemove(ent)
	end

	LIBHook.Add("EntityRemoved", "Library_EntityHooks_RunCallOnRemove", RunCallOnRemove, 1000)

	local function OnEntityCreated(ent)
		if not IsValid(ent) then return end

		if SERVER then
			LIBDuplicator.StoreIsDupedEntityModifier(ent)
		end

		LIB.AddToEntityCreatedQueue("OnPostEntityCreated", ent)
	end

	LIBHook.Add("OnEntityCreated", "Library_EntityHooks_OnEntityCreated", OnEntityCreated, 1000)

	local function PlayerSpawnedEntity(ply, ent)
		if not IsValid(ply) then return end
		if not IsValid(ent) then return end

		local entTable = ent:SligWolf_GetTable()
		entTable.ownerPlayer = ply
		entTable.spawnerPlayer = ply

		LIB.AddToEntityCreatedQueue("PostPlayerSpawnedEntity", ply, ent)
	end

	LIBHook.Add("PlayerSpawnedVehicle", "Library_EntityHooks_PlayerSpawnedEntity", PlayerSpawnedEntity, 1000)
	LIBHook.Add("PlayerSpawnedNPC", "Library_EntityHooks_PlayerSpawnedEntity", PlayerSpawnedEntity, 1000)
	LIBHook.Add("PlayerSpawnedSENT", "Library_EntityHooks_PlayerSpawnedEntity", PlayerSpawnedEntity, 1000)
	LIBHook.Add("PlayerSpawnedSWEP", "Library_EntityHooks_PlayerSpawnedEntity", PlayerSpawnedEntity, 1000)
end

return true

