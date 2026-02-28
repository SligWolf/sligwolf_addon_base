AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Entityhooks = SligWolf_Addons.Entityhooks or {}
table.Empty(SligWolf_Addons.Entityhooks)

local LIB = SligWolf_Addons.Entityhooks

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

local function parseIOString(ioString)
	-- Newer Source Engine games use this symbol as a delimiter
	local rawData = string.Explode("\x1B", ioString)
	if #rawData < 2 then
		rawData = string.Explode(",", ioString)

		if #rawData < 2 then
			return nil
		end
	end

	local result = {}
	result.target = rawData[1] or ""
	result.input = rawData[2] or ""
	result.param = rawData[3] or ""
	result.delay = tonumber(rawData[4]) or 0
	result.times = tonumber(rawData[5]) or -1

	return result
end

local function isIOString(ioString)
	if string.find(ioString, "\x1B", 0, true) then
		return true
	end

	if string.find(ioString, ",", 0, true) then
		return true
	end

	return false
end

function LIB.Load()
	local LIBEntities = SligWolf_Addons.Entities
	local LIBHook = SligWolf_Addons.Hook

	if SERVER then
		-- Make sure we get ALL key values for later,
		-- as ent:GetKeyValues does not return all keyValues.
		local function RegisterKeyValue(ent, key, value)
			if not IsValid(ent) then return end
			if not IsAllowed(ent, key, value) then return end

			local entTable = ent:SligWolf_GetTable()

			local keyValues = entTable.keyValues or {}
			entTable.keyValues = keyValues

			local mapIO = entTable.mapIO or {}
			entTable.mapIO = mapIO

			local isMapIO = isIOString(value)

			if isMapIO then
				local outputs = mapIO[key] or {}

				local value = parseIOString(value)
				if value then
					table.insert(outputs, value)
					mapIO[key] = outputs
				end
			else
				keyValues[key] = value
			end
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

