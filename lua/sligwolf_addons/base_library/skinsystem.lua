local SligWolf_Addons = _G.SligWolf_Addons
if not SligWolf_Addons then
	return
end

local LIB = SligWolf_Addons:NewLib("Skinsystem")

local LIBDuplicator = nil
local LIBSourceIO = nil
local LIBEntities = nil
local LIBHook = nil

function LIB.GetAllThemes(category)
	local result = {}
	local sortedAddondata = SligWolf_Addons.GetAddonsSorted()

	for _, addon in ipairs(sortedAddondata) do
		local themes = addon:SkinGetThemes(category)

		if not themes then
			continue
		end

		local addonResult = {}
		addonResult.addonname = addon.Addonname
		addonResult.defaultTheme = addon:SkinGetDefaultTheme(category)
		addonResult.randomPickerTheme = addon:SkinGetRandomPickerTheme(category)

		local themesResult = {}
		addonResult.themes = themesResult

		for i, theme in ipairs(themes) do
			table.insert(themesResult, theme)
		end

		table.insert(result, addonResult)
	end

	return result
end

function LIB.Load()
	LIBDuplicator = SligWolf_Addons.Duplicator
	LIBEntities = SligWolf_Addons.Entities
	LIBSourceIO = SligWolf_Addons.SourceIO
	LIBTimer = SligWolf_Addons.Timer
	LIBHook = SligWolf_Addons.Hook

	if SERVER then
		local function ApplySkinThemeFromPlayer(ply, ent)
			local spawntable = LIBEntities.GetSpawntable(ent)

			if not spawntable then return end
			if not spawntable.Is_SLIGWOLF then return end

			local addonname = spawntable.SLIGWOLF_Addonname
			if not addonname then return end

			local addon = SligWolf_Addons.GetAddon(addonname)
			if not addon then
				return
			end

			if LIBDuplicator.WasDuped(ent) then
				return
			end

			local keyValues = LIBSourceIO.GetKeyValues(ent)
			local themeKeyValue = keyValues.sligwolf_theme or ""

			if themeKeyValue ~= "" then
				-- A theme has already been from key value. e.g. via Hammer.
				return
			end

			local categoryName = addon:SkinGetCategoryAndMapName(ent)
			if not categoryName then
				return
			end

			local themeName = addon:SkinGetSelectedThemeName(ply, categoryName)
			if not themeName then
				return
			end

			addon:SkinApplyThemeByName(ent, themeName)
		end

		LIBHook.AddCustom("PostPlayerSpawnedEntity", "Library_Skinsystem_ApplySkinThemeFromPlayer", ApplySkinThemeFromPlayer, 11000)

		local function ApplySkinThemeFromKeyValue(ent)
			local spawntable = LIBEntities.GetSpawntable(ent)

			if not spawntable then return end
			if not spawntable.Is_SLIGWOLF then return end

			local addonname = spawntable.SLIGWOLF_Addonname
			if not addonname then return end

			local addon = SligWolf_Addons.GetAddon(addonname)
			if not addon then
				return
			end

			if LIBDuplicator.WasDuped(ent) then
				return
			end

			if addon:SkinHasAppliedTheme(ent) then
				-- A theme has already been set from somewhere else.
				return
			end

			local keyValues = LIBSourceIO.GetKeyValues(ent)
			local themeKeyValue = string.lower(keyValues.sligwolf_theme or "")

			if themeKeyValue == "" and ent:GetSkin() ~= 0 then
				-- Don't override source engine skin if we are on default theme.
				return
			end

			local categoryName = addon:SkinGetCategoryAndMapName(ent)
			if not categoryName then
				return
			end

			local themeName = addon:GetThemeNameFromKeyValue(categoryName, themeKeyValue)
			if not themeName then
				return
			end

			addon:SkinApplyThemeByName(ent, themeName)
		end

		LIBHook.AddCustom("OnPostEntityCreated", "Library_Skinsystem_ApplySkinThemeFromKeyValue", ApplySkinThemeFromKeyValue, 11000)
	end
end

return true