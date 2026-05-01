local SligWolf_Addons = _G.SligWolf_Addons
if not SligWolf_Addons then
	return
end

local LIB = SligWolf_Addons:NewLib("Skinsystem")

local LIBDuplicator = nil
local LIBEntities = nil
local LIBTimer = nil
local LIBHook = nil

function LIB.Load()
	LIBDuplicator = SligWolf_Addons.Duplicator
	LIBEntities = SligWolf_Addons.Entities
	LIBTimer = SligWolf_Addons.Timer
	LIBHook = SligWolf_Addons.Hook

	local function ApplySkinTheme(ply, ent)
		if not IsValid(ply) then return end
		if not IsValid(ent) then return end

		local spawntable = LIBEntities.GetSpawntable(ent)

		if not spawntable then return end
		if not spawntable.Is_SLIGWOLF then return end

		local addonname = spawntable.SLIGWOLF_Addonname
		if not addonname then return end

		local addon = SligWolf_Addons.GetAddon(addonname)
		if not addon then
			return
		end

		-- LIBDuplicator.WasDuped might only be available in the next frame
		LIBTimer.SimpleNextFrame(function()
			if not IsValid(ent) then return end

			if LIBDuplicator.WasDuped(ent) then
				return
			end

			addon:SkinApplyThemeFromSelection(ent, ply)
		end)
	end

	LIBHook.Add("PlayerSpawnedVehicle", "Library_Skinsystem_ApplySkinTheme", ApplySkinTheme, 11000)
	LIBHook.Add("PlayerSpawnedNPC", "Library_Skinsystem_ApplySkinTheme", ApplySkinTheme, 11000)
	LIBHook.Add("PlayerSpawnedSENT", "Library_Skinsystem_ApplySkinTheme", ApplySkinTheme, 11000)
	LIBHook.Add("PlayerSpawnedSWEP", "Library_Skinsystem_ApplySkinTheme", ApplySkinTheme, 11000)
end

return true