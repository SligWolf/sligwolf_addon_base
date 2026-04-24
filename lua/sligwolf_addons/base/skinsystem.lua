AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SLIGWOLF_ADDON then
	SligWolf_Addons:ReloadAddonSystem()
	return
end

local CONSTANTS = SligWolf_Addons.Constants

local LIBEntities = SligWolf_Addons.Entities

SLIGWOLF_ADDON.g_skinMaps = {}
SLIGWOLF_ADDON.g_skinThemes = {}
SLIGWOLF_ADDON.g_skinThemesDefaults = {}

function SLIGWOLF_ADDON:SkinGetCategoryAndMapName(ent)
	local spawntable = LIBEntities.GetSpawntable(ent)

	if not spawntable then return end
	if not spawntable.Is_SLIGWOLF then return end
	if spawntable.SLIGWOLF_Addonname ~= self.Addonname then return end

	local categoryName = spawntable.SLIGWOLF_SkinCategory
	if not categoryName then return end

	local mapName = spawntable.SLIGWOLF_SkinMapName
	if not mapName then return end

	return categoryName, mapName
end

function SLIGWOLF_ADDON:SkinAddMap(name, partsData)
	name = tostring(name or "")

	if name == "" then
		return
	end

	local map =  {}
	self.g_skinMaps[name] = map

	map.name = name

	local parts = {}
	map.parts = parts

	for partPath, partProperties in pairs(partsData) do
		parts[partPath] = {
			path = partPath,
			color = partProperties.color,
			skin = partProperties.skin,
			bodygroups = partProperties.bodygroups,
		}
	end
end

function SLIGWOLF_ADDON:SkinGetMap(name)
	name = tostring(name or "")
	if name == "" then
		return nil
	end

	local map = self.g_skinMaps[name]
	if not map then
		return nil
	end

	return map
end

local g_skinParamKeys = {
	"skin",
	"color",
	"bodygroups",
}

local function resolveSkinItemNames(themeSkinParams)
	for i = 0, 8 do
		if i >= 8 then
			table.Empty(themeSkinParams)
			error("infinite loop in resolveSkinItemNames detected")
			return
		end

		local nextRound = false

		for skinParamsName, skinParamsItemUnresolved in pairs(themeSkinParams) do
			for _, skinParamKey in ipairs(g_skinParamKeys) do
				local skinParam = skinParamsItemUnresolved[skinParamKey]

				if skinParam and isstring(skinParam) then
					local skinParamsItemResolved = themeSkinParams[skinParam]
					if skinParamsItemResolved then
						skinParam = skinParamsItemResolved[skinParamKey]

						if skinParam then
							nextRound = true
						end
					else
						skinParam = nil
					end
				end

				skinParamsItemUnresolved[skinParamKey] = skinParam
			end
		end

		if not nextRound then
			return
		end
	end
end

function SLIGWOLF_ADDON:SkinAddTheme(category, name, themeData)
	category = tostring(category or "")
	name = tostring(name or "")

	if category == "" then
		return
	end

	if name == "" then
		return
	end

	local themeCategory = self.g_skinThemes[category] or {}
	self.g_skinThemes[category] = themeCategory

	local theme = {}
	themeCategory[name] = theme

	theme.name = name
	theme.category = category

	if themeData.isDefault then
		self.g_skinThemesDefaults[category] = theme
		theme.isDefault = true
	end

	local buttonParams = themeData.button or {}
	local skinParams = themeData.skin or {}

	theme.button = {
		title = buttonParams.title,
		colors = buttonParams.colors,
		order = buttonParams.order,
	}

	local themeSkinParams = {}
	theme.map = themeSkinParams

	for skinParamsName, skinParamsItem in pairs(skinParams) do
		themeSkinParams[skinParamsName] = {
			color = skinParamsItem.color,
			skin = skinParamsItem.skin,
			bodygroups = skinParamsItem.bodygroups,
		}
	end

	resolveSkinItemNames(themeSkinParams)
end

function SLIGWOLF_ADDON:SkinGetTheme(category, name)
	category = tostring(category or "")
	name = tostring(name or "")

	if category == "" then
		return nil
	end

	if name == "" then
		return nil
	end

	local themeCategory = self.g_skinThemes[category]
	if not themeCategory then
		return nil
	end

	local theme = themeCategory[name]
	if not theme then
		return nil
	end

	return theme
end

function SLIGWOLF_ADDON:SkinApplyTheme(superparent, themeName)
	superparent = LIBEntities.GetSuperParent(superparent)
	if not IsValid(superparent) then
		return
	end

	local categoryName, mapName = self:SkinGetCategoryAndMapName(superparent)
	if not categoryName then
		return
	end

	local map = self:SkinGetMap(mapName)
	if not map then
		return
	end

	local theme = self:SkinGetTheme(categoryName, themeName)
	if not theme then
		return
	end

	local parts = skinMap.parts
	local themeSkinParams = theme.themeSkinParams

	local entTable = superparent:SligWolf_GetTable()

	local appliedTheme = {}
	entTable.appliedTheme = appliedTheme

	for _, partProperties in pairs(parts) do
		local path = partProperties.path

		local appliedThemeEntry = {}
		appliedTheme[path] = appliedThemeEntry

		-- Resolve names to color/skin/bodygroups from theme
		for _, skinParamKey in ipairs(g_skinParamKeys) do
			local partProperty = partProperties[skinParamKey]
			if partProperty and isstring(itempartPropertyParam) then
				local skinParam = themeSkinParams[partProperty]

				if skinParam then
					partProperty = skinParam[skinParamKey]
				end
			end

			appliedThemeEntry[skinParamKey] = partProperty
		end

		local itemColor = appliedThemeEntry.color
		local itemSkin = appliedThemeEntry.skin
		local itemBodygroups = appliedThemeEntry.bodygroups

		if not itemColor or not IsColor(itemColor) then
			itemColor = CONSTANTS.colorDefault
		end

		if not itemSkin or not isnumber(itemSkin) then
			itemSkin = 0
		end

		if not itemBodygroups or not istable(itemBodygroups) then
			itemBodygroups = {}
		end

		appliedThemeEntry.color = itemColor
		appliedThemeEntry.skin = itemSkin
		appliedThemeEntry.bodygroups = nil -- itemBodygroups -- @TODO

		local ent = nil

		if path == "" then
		 	ent = superparent
		else
		 	ent = LIBEntities.GetChildFromPath(superparent, path)
		end

		if not IsValid(ent) then
			continue
		end

		ent:SetColor(itemColor)
		ent:SetSkin(itemSkin)

		-- for bodygroupName, bodygroup in pairs(itemBodygroups) do -- @TODO
		-- 	LIBEntities.SetBodygroupSubId(ent, bodygroup.index, bodygroup.mesh)
		-- end
	end
end

function SLIGWOLF_ADDON:SkinGetAppliedThemeData(superparent, path)
	if not path then
		return nil
	end

	superparent = LIBEntities.GetSuperParent(superparent)
	if not IsValid(superparent) then
		return
	end

	local _, mapName = self:SkinGetCategoryAndMapName(superparent)
	if not mapName then
		return
	end

	local map = self:SkinGetMap(mapName)
	if not map then
		return
	end

	local parts = map.parts
	if not parts[path] then
		return
	end

	local entTable = superparent:SligWolf_GetTable()
	local appliedTheme = entTable.appliedTheme

	if not appliedTheme then
		return
	end

	local appliedThemeData = appliedTheme[path]
	if not appliedThemeData then
		return
	end

	return appliedThemeData
end

return true

