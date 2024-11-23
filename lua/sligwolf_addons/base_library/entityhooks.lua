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

function LIB.Load()
	local LIBEntities = SligWolf_Addons.Entities
	local LIBHook = SligWolf_Addons.Hook

	if SERVER then
		local function RegisterKeyValue(ent, key, value)
			if not IsValid(ent) then return end
			if not string.StartsWith(key, "sligwolf_") then return end

			local entTable = ent:SligWolf_GetTable()

			entTable.keyValues = entTable.keyValues or {}
			entTable.keyValues[key] = value
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

