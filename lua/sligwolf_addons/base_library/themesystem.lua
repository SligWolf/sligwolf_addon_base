local SligWolf_Addons = _G.SligWolf_Addons
if not SligWolf_Addons then
	return
end

local LIB = SligWolf_Addons:NewLib("Themesystem")

local CONSTANTS = SligWolf_Addons.Constants

local LIBDuplicator = SligWolf_Addons.Duplicator
local LIBSourceIO = SligWolf_Addons.SourceIO
local LIBEntities = SligWolf_Addons.Entities
local LIBPlayer = SligWolf_Addons.Player
local LIBHook = SligWolf_Addons.Hook

LIB.g_themeParamKeys = {
	"skin",
	"color",
	"bodygroups",
}

local g_themeMetaNames = {}
local g_themeParamKeys = LIB.g_themeParamKeys

LIB.KEY_ALL = "all"
LIB.KEY_SKIN = "skin"
LIB.KEY_COLOR = "color"
LIB.KEY_BODYGROUPS = "bodygroups"

LIB.THEME_DEFAULT = "default"
LIB.THEME_RANDOM = "random"
LIB.THEME_PLAYER = "player"

function LIB.GetAllThemes(category)
	local result = {}
	local sortedAddondata = SligWolf_Addons.GetAddonsSorted()

	for _, addon in ipairs(sortedAddondata) do
		local themeConfigs = addon:ThemeGetConfigs(category)

		if not themeConfigs then
			continue
		end

		local addonResult = {}
		addonResult.addonname = addon.Addonname
		addonResult.defaultTheme = addon:ThemeGetDefaultConfig(category)
		addonResult.randomPickerTheme = addon:ThemeGetRandomPickerConfig(category)

		local themesResult = {}
		addonResult.themes = themesResult

		for i, themeConfig in ipairs(themeConfigs) do
			table.insert(themesResult, themeConfig)
		end

		table.insert(result, addonResult)
	end

	return result
end

function LIB.AddThemeMetaFunction(key, name, func)
	if key == LIB.KEY_ALL then
		for _, v in ipairs(g_themeParamKeys) do
			LIB.AddThemeMetaFunction(v, name, func)
		end

		return
	end

	local g_themeMetaNamesForKey = g_themeMetaNames[key] or {}
	g_themeMetaNames[key] = g_themeMetaNamesForKey

	g_themeMetaNamesForKey[name] = func
end

function LIB.HasThemeMetaFunction(key, name)
	local g_themeMetaNamesForKey = g_themeMetaNames[key]
	if not g_themeMetaNamesForKey then
		return false
	end

	return g_themeMetaNamesForKey[name] ~= nil
end

function LIB.CallThemeMetaFunction(key, name, ent)
	local g_themeMetaNamesForKey = g_themeMetaNames[key]
	if not g_themeMetaNamesForKey then
		return false
	end

	local func = g_themeMetaNamesForKey[name]
	if not func then
		return false
	end

	return func(key, name, ent)
end

function LIB.GetColorPlayer(ent)
	if not IsValid(ent) then
		return LIBPlayer.GetFailbackPlayer()
	end

	if ent:IsPlayer() then
		return ent
	end

	local ply = LIBEntities.GetOwner(ent)
	if not IsValid(ply) then
		return LIBPlayer.GetFailbackPlayer()
	end

	return ply
end

function LIB.Load()
	LIBDuplicator = SligWolf_Addons.Duplicator
	LIBEntities = SligWolf_Addons.Entities
	LIBSourceIO = SligWolf_Addons.SourceIO
	LIBPlayer = SligWolf_Addons.Player
	LIBHook = SligWolf_Addons.Hook

	LIB.AddThemeMetaFunction(LIB.KEY_ALL, "", function()
		return nil
	end)

	LIB.AddThemeMetaFunction(LIB.KEY_ALL, "void", function()
		return nil
	end)

	LIB.AddThemeMetaFunction(LIB.KEY_COLOR, "playerMainColor", function(key, name, ent)
		local ply = LIB.GetColorPlayer(ent)
		if not IsValid(ply) then
			return CONSTANTS.colorError1
		end

		local colorVector = ply:GetPlayerColor()
		if not colorVector then
			return CONSTANTS.colorError1
		end

		return colorVector:ToColor()
	end)

	LIB.AddThemeMetaFunction(LIB.KEY_COLOR, "playerWeaponColor", function(key, name, ent)
		local ply = LIB.GetColorPlayer(ent)
		if not IsValid(ply) then
			return CONSTANTS.colorError2
		end

		local colorVector = ply:GetWeaponColor()
		if not colorVector then
			return CONSTANTS.colorError2
		end

		return colorVector:ToColor()
	end)

	if SERVER then
		local function ApplySkinThemeFromPlayer(ply, ent, spawnname, spawntable, addonname)
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

			local categoryName = addon:ThemeGetCategoryAndMapName(ent)
			if not categoryName then
				return
			end

			local themeName = addon:ThemeGetSelectedName(ply, categoryName)
			if not themeName then
				return
			end

			addon:ThemeApplyByName(ent, themeName)
		end

		LIBHook.AddCustom("PostPlayerSpawnedAddonEntity", "Library_Themesystem_ApplySkinThemeFromPlayer", ApplySkinThemeFromPlayer, 11000)

		local function ApplySkinThemeFromKeyValue(ent, spawnname, spawntable, addonname)
			local addon = SligWolf_Addons.GetAddon(addonname)
			if not addon then
				return
			end

			if LIBDuplicator.WasDuped(ent) then
				return
			end

			if addon:ThemeHasApplied(ent) then
				-- A theme has already been set from somewhere else.
				return
			end

			local keyValues = LIBSourceIO.GetKeyValues(ent)
			local themeKeyValue = keyValues.sligwolf_theme or ""

			if themeKeyValue == "" and ent:GetSkin() ~= 0 then
				-- Don't override source engine skin if we are on default theme.
				return
			end

			local categoryName = addon:ThemeGetCategoryAndMapName(ent)
			if not categoryName then
				return
			end

			local themeName = addon:ThemeGetNameFromKeyValue(categoryName, themeKeyValue)
			if not themeName then
				return
			end

			addon:ThemeApplyByName(ent, themeName)
		end

		LIBHook.AddCustom("OnPostAddonEntityCreated", "Library_Themesystem_ApplySkinThemeFromKeyValue", ApplySkinThemeFromKeyValue, 12000)
	end
end

return true