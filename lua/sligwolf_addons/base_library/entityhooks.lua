local SligWolf_Addons = _G.SligWolf_Addons
if not SligWolf_Addons then
	return
end

local LIB = SligWolf_Addons:NewLib("Entityhooks")

local LIBEntities = nil
local LIBHook = nil

local g_keyValueClassWhiteList = LIB._KeyValueClassWhiteList or {}
LIB._KeyValueClassWhiteList = g_keyValueClassWhiteList

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

	local isMapOutputs = LIBEntities.IsMapOutputString(value)

	if isMapOutputs then
		value = LIBEntities.ParseMapOutputString(key, value)
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

function LIB.Load()
	LIBEntities = SligWolf_Addons.Entities
	LIBHook = SligWolf_Addons.Hook

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
		if not systemEntities then return end

		for _, thisent in ipairs(systemEntities) do
			if not isfunction(thisent.SpawnSystemFinished) then
				continue
			end

			thisent:SpawnSystemFinished(ply)
		end
	end

	LIBHook.AddCustom("SpawnSystemFinished", "Library_EntityHooks_SpawnSystemEntitiesFinished", SpawnSystemEntitiesFinished, 19000)


	local function SpawnSystemFinished(ent, ply)
		if not IsValid(ent) then return end
		if not ent.sligwolf_entity then return end
		if not ent.sligwolf_baseEntity then return end

		local addonname = ent:GetAddonID()
		if not addonname then return end

		SligWolf_Addons.CallFunctionOnAddon(addonname, "SpawnSystemFinished", ent, ply)
	end

	LIBHook.AddCustom("SpawnSystemFinished", "Library_EntityHooks_SpawnSystemFinished", SpawnSystemFinished, 19100)

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
end

return true

