AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

local LIBEntities = SligWolf_Addons.Entities
local LIBHook = SligWolf_Addons.Hook

local function RegisterKeyValue(ent, key, value)
	if not IsValid(ent) then return end
	if not string.StartsWith(key, "sligwolf_") then return end

	ent.sligwolf_kv = ent.sligwolf_kv or {}
	ent.sligwolf_kv[key] = value
end

LIBHook.Add("EntityKeyValue", "Library_EntityHooks_RegisterKeyValue", RegisterKeyValue, 20000)

local function MarkPhysgunPickedUp(ply, ent)
	if not SERVER then return end
	if not IsValid(ent) then return end
	if not ent.sligwolf_entity then return end
	if not ent.sligwolf_physEntity then return end

	LIBEntities.MarkPhysgunPickedUp(ent, ply)
end

LIBHook.Add("PhysgunPickup", "Library_EntityHooks_MarkPhysgunPickedUp", MarkPhysgunPickedUp, 20000)

local function UnmarkPhysgunPickedUp(ply, ent)
	if not SERVER then return end
	if not IsValid(ent) then return end
	if not ent.sligwolf_entity then return end
	if not ent.sligwolf_physEntity then return end

	LIBEntities.UnmarkPhysgunPickedUp(ent, ply)
end

LIBHook.Add("PhysgunDrop", "Library_EntityHooks_UnmarkPhysgunPickedUp", UnmarkPhysgunPickedUp, 20000)

LIBHook.Add("OnPhysgunFreeze", "Library_EntityHooks_UpdateFreeze", function(weapon, phys, ent, ply)
	if not SERVER then return end
	LIBEntities.UpdateBodySystemMotion(ent, true)
end, 21000)

LIBHook.Add("CanPlayerUnfreeze", "Library_EntityHooks_UpdateFreeze", function(ply, ent, phys)
	if not SERVER then return end
	LIBEntities.UpdateBodySystemMotion(ent, true)
end, 21000)

LIBHook.Add("OnPhysgunPickup", "Library_EntityHooks_UpdateFreeze", function(ply, ent)
	if not SERVER then return end
	LIBEntities.UpdateBodySystemMotion(ent, true)
end, 21000)

LIBHook.Add("PhysgunDrop", "Library_EntityHooks_UpdateFreeze", function(ply, ent)
	if not SERVER then return end
	LIBEntities.UpdateBodySystemMotion(ent, true)
end, 21000)

local function SpawnSystemFinished(ent, ply)
	if not IsValid(ent) then return end
	if not ent.sligwolf_entity then return end

	local systemEntities = LIBEntities.GetSystemEntities(ent)

	for _, thisent in ipairs(systemEntities) do
		if not isfunction(thisent.SpawnSystemFinished) then
			continue
		end

		thisent:SpawnSystemFinished(ply)
	end
end

LIBHook.Add("SLIGWOLF_SpawnSystemFinished", "Library_EntityHooks_SpawnSystemFinished", SpawnSystemFinished, 19000)

return true

