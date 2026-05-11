AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SLIGWOLF_ADDON then
	SligWolf_Addons:ReloadAddonSystem()
	return
end

local LIBEntities = SligWolf_Addons.Entities
local LIBConvar = SligWolf_Addons.Convar
local LIBPrint = SligWolf_Addons.Print
local LIBUtil = SligWolf_Addons.Util

local g_root_path = "ROOT"

SLIGWOLF_ADDON.g_skinMaps = {}
SLIGWOLF_ADDON.g_skinThemes = {}
SLIGWOLF_ADDON.g_skinThemesForRandom = {}
SLIGWOLF_ADDON.g_skinThemesOrdered = {}
SLIGWOLF_ADDON.g_skinThemesDefaults = {}
SLIGWOLF_ADDON.g_skinThemesRandomPickers = {}

function SLIGWOLF_ADDON:SkinGetConvarName(category)
	local convarName = string.format("cl_sligwolf_%s_theme_%s", self.Addonname, category)
	return convarName
end

function SLIGWOLF_ADDON:SkinAddConvar(category)
	if SERVER then
		return nil
	end

	local defaultTheme = self:SkinGetDefaultTheme(category)
	if not defaultTheme then
		return nil
	end

	local defaultThemeName = defaultTheme.name
	local convarName = self:SkinGetConvarName(category)
	local help = string.format("Set the color theme for the next spawned object for category '%s' in addon '%s'", category, self.Addonname)

	LIBConvar.AddClientConvar(convarName, {
		default = defaultThemeName,
		shouldsave = true,
		userinfo = true,
		help = help,
	})

	return convarName
end

function SLIGWOLF_ADDON:SkinGetSelectedThemeName(ply, category)
	if not IsValid(ply) and CLIENT then
		ply = LocalPlayer()
	end

	local defaultTheme = self:SkinGetDefaultTheme(category)
	if not defaultTheme then
		return nil
	end

	local defaultThemeName = defaultTheme.name
	if not IsValid(ply) then
		return defaultThemeName
	end

	if not ply:IsPlayer() then
		return defaultThemeName
	end

	if ply:IsBot() then
		return defaultThemeName
	end

	local convarName = self:SkinGetConvarName(category)
	local themeName = tostring(ply:GetInfo(convarName))

	if themeName == "" or themeName == "default" then
		return defaultThemeName
	end

	if themeName == "random" then
		local theme = self:SkinGetRandomPickerTheme(category)
		if not theme then
			return defaultThemeName
		end

		return theme.name
	end

	local theme = self:SkinGetTheme(category, themeName, false)
	if not theme then
		LIBPrint.Warn(
			"Theme '%s' was not found in addon '%s'. Failing back to default.",
			themeName,
			self.Addonname
		)

		return defaultThemeName
	end

	return theme.name
end

function SLIGWOLF_ADDON:GetThemeNameFromKeyValue(category, keyValue)
	category = tostring(category or "")
	keyValue = tostring(keyValue or "")

	local defaultTheme = self:SkinGetDefaultTheme(category)
	if not defaultTheme then
		return nil
	end

	local defaultThemeName = defaultTheme.name

	if keyValue == "" or keyValue == "default" then
		return defaultThemeName
	end

	if keyValue == "random" then
		local theme = self:SkinGetRandomPickerTheme(category)
		if not theme then
			return defaultThemeName
		end

		return theme.name
	end

	local separatorPos = string.find(keyValue, "_")
	if not separatorPos then
		LIBPrint.Warn("Malformed sligwolf_theme = '%s'. Failing back to default.", keyValue)
		return defaultThemeName
	end

	local foundAddonname = string.sub(keyValue, 1, separatorPos - 1)
	local themeName = string.sub(keyValue, separatorPos + 1)

	if foundAddonname ~= self.Addonname then
		LIBPrint.Warn(
			"Addon mismatch in sligwolf_theme = '%s', expected addon '%s', got '%s'. Failing back to default.",
			keyValue,
			self.Addonname,
			foundAddonname
		)

		return defaultThemeName
	end

	local theme = self:SkinGetTheme(category, themeName, true)
	if not theme then
		LIBPrint.Warn(
			"Theme '%s' was not found in addon '%s', got sligwolf_theme = '%s'. Failing back to default.",
			themeName,
			self.Addonname,
			keyValue
		)

		return defaultThemeName
	end

	return theme.name
end


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
		partPath = tostring(partPath)

		if partPath == "" then
			partPath = g_root_path
		end

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

local g_skinParamVoid = {
	[""] = true,
	["void"] = true,
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

				if skinParam and isstring(skinParam) and not g_skinParamVoid[skinParam] then
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
	theme.order = themeData.order or LIBUtil.Order()
	theme.isRandom = themeData.isRandom or false

	if themeData.isDefault and not self.g_skinThemesDefaults[category] then
		self.g_skinThemesDefaults[category] = theme
		theme.isDefault = true
	end

	if themeData.isRandom and not self.g_skinThemesRandomPickers[category] then
		self.g_skinThemesRandomPickers[category] = theme
		theme.isRandom = true
	end

	local buttonParams = themeData.button or {}
	local themeParams = themeData.theme or {}

	theme.button = {
		title = buttonParams.title,
		pieces = buttonParams.pieces,
	}

	local themeParamsInternal = {}
	theme.theme = themeParamsInternal

	for skinParamsName, skinParamsItem in pairs(themeParams) do
		themeParamsInternal[skinParamsName] = {
			color = skinParamsItem.color,
			skin = skinParamsItem.skin,
			bodygroups = skinParamsItem.bodygroups,
		}
	end

	resolveSkinItemNames(themeParamsInternal)

	self.g_skinThemesOrdered[category] = {}
	self.g_skinThemesForRandom[category] = {}
end

function SLIGWOLF_ADDON:SkinGetTheme(category, name, resolveRandom)
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

	if not resolveRandom or not theme.isRandom then
		return theme
	end

	local nonRandomThemes = self.g_skinThemesForRandom[category] or {}

	if table.IsEmpty(nonRandomThemes) then
		for _, nonRandomTheme in pairs(themeCategory) do
			if nonRandomTheme.isRandom then
				continue
			end

			table.insert(nonRandomThemes, nonRandomTheme)
		end
	end

	local randomKey = math.random(#nonRandomThemes)
	local randomTheme = nonRandomThemes[randomKey]

	if not randomTheme then
		return nil
	end

	return randomTheme
end

function SLIGWOLF_ADDON:SkinGetThemes(category)
	category = tostring(category or "")

	if category == "" then
		return nil
	end

	local themesOrdered = self.g_skinThemesOrdered[category] or {}
	self.g_skinThemesOrdered[category] = themesOrdered

	if not table.IsEmpty(themesOrdered) then
		return themesOrdered
	end

	local themes = self.g_skinThemes[category]
	if not themes then
		return nil
	end

	for i, theme in SortedPairsByMemberValue(themes, "order") do
		table.insert(themesOrdered, theme)
	end

	return themesOrdered
end

function SLIGWOLF_ADDON:SkinGetDefaultTheme(category)
	category = tostring(category or "")

	if category == "" then
		return nil
	end

	local defaultTheme = self.g_skinThemesDefaults[category]
	if defaultTheme then
		defaultTheme.isDefault = true
		return defaultTheme
	end

	local themes = self:SkinGetThemes(category)
	if not themes then
		return nil
	end

	for i, theme in ipairs(themes) do
		self.g_skinThemesDefaults[category] = theme
		theme.isDefault = true
		return theme
	end

	return nil
end

function SLIGWOLF_ADDON:SkinGetRandomPickerTheme(category)
	category = tostring(category or "")

	if category == "" then
		return nil
	end

	local randomPickerTheme = self.g_skinThemesRandomPickers[category]
	if randomPickerTheme then
		randomPickerTheme.isRandom = true
		return randomPickerTheme
	end

	return nil
end

function SLIGWOLF_ADDON:SkinApplyTheme(superparent, themeData)
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

	local parts = map.parts
	local entTable = superparent:SligWolf_GetTable()

	local appliedTheme = {}
	entTable.appliedTheme = appliedTheme

	for _, partProperties in pairs(parts) do
		local path = partProperties.path
		local themeEntry = themeData[path]

		if not themeEntry then
			continue
		end

		local itemColor = partProperties.color and themeEntry.color
		local itemSkin = partProperties.skin and themeEntry.skin
		local itemBodygroups = partProperties.bodygroups and themeEntry.bodygroups

		if not itemColor or not istable(itemColor) then
			itemColor = nil
		end

		if not itemSkin or not isnumber(itemSkin) then
			itemSkin = nil
		end

		if not itemBodygroups or not istable(itemBodygroups) then
			itemBodygroups = nil
		end

		local appliedThemeEntry = {}

		if itemColor then
			appliedThemeEntry.color = Color(
				itemColor.r,
				itemColor.g,
				itemColor.b,
				itemColor.a
			)

			appliedTheme[path] = appliedThemeEntry
		end

		if itemSkin then
			appliedThemeEntry.skin = itemSkin
			appliedTheme[path] = appliedThemeEntry
		end

		if itemBodygroups then
			appliedThemeEntry.bodygroups = itemBodygroups
			appliedTheme[path] = appliedThemeEntry
		end

		local ent = nil

		if path == g_root_path then
		 	ent = superparent
		else
		 	ent = LIBEntities.GetChildFromPath(superparent, path)
		end

		if not IsValid(ent) then
			continue
		end

		if itemColor then
			ent:SetColor(itemColor)
		end

		if itemSkin then
			ent:SetSkin(itemSkin)
		end

		LIBEntities.SetBodygroupMeshIds(ent, itemBodygroups)
	end
end

function SLIGWOLF_ADDON:SkinApplyThemeByName(superparent, themeName)
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

	local theme = self:SkinGetTheme(categoryName, themeName, true)
	if not theme then
		return
	end

	local parts = map.parts
	local themeParams = theme.theme

	local themeData = {}

	for _, partProperties in pairs(parts) do
		local path = partProperties.path

		local appliedThemeEntry = {}

		-- Resolve names to color/skin/bodygroups from theme
		for _, skinParamKey in ipairs(g_skinParamKeys) do
			local partProperty = partProperties[skinParamKey]
			if partProperty and isstring(partProperty) and not g_skinParamVoid[partProperty] then
				local skinParam = themeParams[partProperty]

				if skinParam then
					partProperty = skinParam[skinParamKey]
				end
			end

			if partProperty and not g_skinParamVoid[partProperty] then
				appliedThemeEntry[skinParamKey] = partProperty
				themeData[path] = appliedThemeEntry
			end
		end
	end

	self:SkinApplyTheme(superparent, themeData)
end

function SLIGWOLF_ADDON:SkinGetAppliedThemeDataOfPath(superparent, path)
	if not path then
		return nil
	end

	if path == "" then
		path = g_root_path
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

function SLIGWOLF_ADDON:SkinReapplyThemeDataForPath(superparent, path)
	if not path then
		return nil
	end

	if path == "" then
		path = g_root_path
	end

	superparent = LIBEntities.GetSuperParent(superparent)
	if not IsValid(superparent) then
		return
	end

	local themeData = self:SkinGetAppliedThemeDataOfPath(superparent, path)
	if not themeData then
		return
	end

	local itemColor = themeData.color
	local itemSkin = themeData.skin
	local itemBodygroups = themeData.bodygroups

	local ent = nil

	if path == g_root_path then
		ent = superparent
	else
		ent = LIBEntities.GetChildFromPath(superparent, path)
	end

	if itemColor then
		ent:SetColor(itemColor)
	end

	if itemSkin then
		ent:SetSkin(itemSkin)
	end

	LIBEntities.SetBodygroupMeshIds(ent, itemBodygroups)
end

function SLIGWOLF_ADDON:SkinGetThemeData(superparent)
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

	local parts = map.parts
	local themeData = {}

	for _, partProperties in pairs(parts) do
		local path = partProperties.path

		local ent = nil

		if path == g_root_path then
		 	ent = superparent
		else
		 	ent = LIBEntities.GetChildFromPath(superparent, path)
		end

		if not IsValid(ent) then
			continue
		end

		local themeEntry = {}

		if partProperties.color then
			themeEntry.color = ent:GetColor()
			themeData[path] = themeEntry
		end

		if partProperties.skin then
			themeEntry.skin = ent:GetSkin()
			themeData[path] = themeEntry
		end

		if partProperties.bodygroups then
			themeEntry.bodygroups = LIBEntities.GetBodygroupMeshIds(ent)
			themeData[path] = themeEntry
		end
	end

	return themeData
end

function SLIGWOLF_ADDON:SkinHasAppliedTheme(superparent)
	superparent = LIBEntities.GetSuperParent(superparent)
	if not IsValid(superparent) then
		return false
	end

	local entTable = superparent:SligWolf_GetTable()
	local appliedTheme = entTable.appliedTheme

	if not appliedTheme then
		return false
	end

	if table.IsEmpty(appliedTheme) then
		return false
	end

	return true
end

return true

