local SligWolf_Addons = _G.SligWolf_Addons
if not SligWolf_Addons then
	return
end

local LIB = SligWolf_Addons:NewLib("Skinsystem")

local CONSTANTS = SligWolf_Addons.Constants

local LIBDuplicator = nil
local LIBSourceIO = nil
local LIBEntities = nil
local LIBUtil = nil
local LIBHook = nil

LIB.g_skinParamKeys = {
	"skin",
	"color",
	"bodygroups",
}

local g_skinMetaNames = {}
local g_skinParamKeys = LIB.g_skinParamKeys

LIB.ENUM_KEY_ALL = "all"
LIB.ENUM_KEY_SKIN = "skin"
LIB.ENUM_KEY_COLOR = "color"
LIB.ENUM_KEY_BODYGROUPS = "bodygroups"

function LIB.GetAllThemes(category)
	local result = {}
	local sortedAddondata = SligWolf_Addons.GetAddonsSorted()

	for _, addon in ipairs(sortedAddondata) do
		local themeConfigs = addon:SkinGetThemeConfigs(category)

		if not themeConfigs then
			continue
		end

		local addonResult = {}
		addonResult.addonname = addon.Addonname
		addonResult.defaultTheme = addon:SkinGetDefaultThemeConfig(category)
		addonResult.randomPickerTheme = addon:SkinGetRandomPickerThemeConfig(category)

		local themesResult = {}
		addonResult.themes = themesResult

		for i, themeConfig in ipairs(themeConfigs) do
			table.insert(themesResult, themeConfig)
		end

		table.insert(result, addonResult)
	end

	return result
end

function LIB.AddSkinMetaFunction(key, name, func)
	if key == LIB.ENUM_KEY_ALL then
		for _, v in ipairs(g_skinParamKeys) do
			LIB.AddSkinMetaFunction(v, name, func)
		end

		return
	end

	local g_skinMetaNamesForKey = g_skinMetaNames[key] or {}
	g_skinMetaNames[key] = g_skinMetaNamesForKey

	g_skinMetaNamesForKey[name] = func
end

function LIB.HasSkinMetaFunction(key, name)
	local g_skinMetaNamesForKey = g_skinMetaNames[key]
	if not g_skinMetaNamesForKey then
		return false
	end

	return g_skinMetaNamesForKey[name] ~= nil
end

function LIB.CallSkinMetaFunction(key, name, ent)
	local g_skinMetaNamesForKey = g_skinMetaNames[key]
	if not g_skinMetaNamesForKey then
		return false
	end

	local func = g_skinMetaNamesForKey[name]
	if not func then
		return false
	end

	return func(key, name, ent)
end

function LIB.GetColorPlayer(ent)
	if not IsValid(ent) then
		return LIBUtil.GetFailbackPlayer()
	end

	if ent:IsPlayer() then
		return ent
	end

	local ply = LIBEntities.GetOwner(ent)
	if not IsValid(ply) then
		return LIBUtil.GetFailbackPlayer()
	end

	return ply
end

function LIB.Load()
	LIBDuplicator = SligWolf_Addons.Duplicator
	LIBEntities = SligWolf_Addons.Entities
	LIBSourceIO = SligWolf_Addons.SourceIO
	LIBTimer = SligWolf_Addons.Timer
	LIBUtil = SligWolf_Addons.Util
	LIBHook = SligWolf_Addons.Hook

	LIB.AddSkinMetaFunction(LIB.ENUM_KEY_ALL, "", function()
		return nil
	end)

	LIB.AddSkinMetaFunction(LIB.ENUM_KEY_ALL, "void", function()
		return nil
	end)

	LIB.AddSkinMetaFunction(LIB.ENUM_KEY_COLOR, "playerMainColor", function(key, name, ent)
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

	LIB.AddSkinMetaFunction(LIB.ENUM_KEY_COLOR, "playerWeaponColor", function(key, name, ent)
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