AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Duplicator = SligWolf_Addons.Duplicator or {}
table.Empty(SligWolf_Addons.Duplicator)

local LIB = SligWolf_Addons.Duplicator

local LIBHook = nil
local LIBMeta = nil

function LIB.RemoveBadDupeData(data)
	if not data then return end

	LIBMeta.RemoveBadDupeData(data)

	if not data.sligwolf_entity then
		return
	end

	data.spawnname = nil
	data.spawnProperties = nil
	data.defaultSpawnProperties = nil

	data.addonCache = nil
	data.addonIdCache = nil

	data.DoNotDuplicate = nil

	-- Remove values whose names starting with "_", "sligwolf_" or "SLIGWOLF_"
	for key, _ in pairs(data) do
		if not isstring(key) then
			continue
		end

		if key == "" then
			continue
		end

		if string.StartsWith(key, "_") then
			data[key] = nil
			continue
		end

		if string.StartsWith(key, "sligwolf_") then
			data[key] = nil
			continue
		end

		if string.StartsWith(key, "SLIGWOLF_") then
			data[key] = nil
			continue
		end
	end
end

function LIB.Load()
	LIBHook = SligWolf_Addons.Hook
	LIBMeta = SligWolf_Addons.Meta

	if SERVER then
		local function onDuplicated(ent, ...)
			if not IsValid(ent) then return end

			local entTable = ent:SligWolf_GetTable()
			local oldOnDuplicated = entTable._oldOnDuplicated

			entTable.isDuped = true

			if isfunction(oldOnDuplicated) then
				oldOnDuplicated(ent, ...)
			end

			local swOnDuplicated = entTable.OnDuplicated
			if isfunction(swOnDuplicated) then
				swOnDuplicated(ent, ...)
			end
		end

		local function OnEntityCreated(ent)
			if not IsValid(ent) then return end

			local entTable = ent:SligWolf_GetTable()
			entTable._oldOnDuplicated = entTable._oldOnDuplicated or ent.OnDuplicated

			ent.OnDuplicated = onDuplicated
		end

		LIBHook.Add("OnEntityCreated", "Library_Duplicator_OnEntityCreated", OnEntityCreated, 1000)
	end
end

return true

