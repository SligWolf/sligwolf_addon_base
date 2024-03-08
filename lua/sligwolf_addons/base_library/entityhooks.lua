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

			ent.sligwolf_kv = ent.sligwolf_kv or {}
			ent.sligwolf_kv[key] = value
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

	LIBHook.Add("SLIGWOLF_SpawnSystemFinished", "Library_EntityHooks_SpawnSystemFinishedClearCaches", SpawnSystemFinishedClearCaches, 1000)

	local function SpawnSystemFinished(ent, ply)
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

	LIBHook.Add("SLIGWOLF_SpawnSystemFinished", "Library_EntityHooks_SpawnSystemFinished", SpawnSystemFinished, 19000)
end

return true

