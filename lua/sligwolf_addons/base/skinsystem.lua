AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SLIGWOLF_ADDON then
	SligWolf_Addons:ReloadAddonSystem()
	return
end

local LIBSkinsystem = SligWolf_Addons.Skinsystem
local LIBEntities = SligWolf_Addons.Entities
local LIBConvar = SligWolf_Addons.Convar
local LIBPrint = SligWolf_Addons.Print
local LIBUtil = SligWolf_Addons.Util

local g_root_path = "ROOT"

SLIGWOLF_ADDON.g_skinMaps = {}
SLIGWOLF_ADDON.g_skinThemeConfigs = {}
SLIGWOLF_ADDON.g_skinThemeConfigsForRandom = {}
SLIGWOLF_ADDON.g_skinThemeConfigsOrdered = {}
SLIGWOLF_ADDON.g_skinThemeConfigsDefaults = {}
SLIGWOLF_ADDON.g_skinThemeConfigsRandomPickers = {}
SLIGWOLF_ADDON.g_skinThemeConfigsPlayerColored = {}

local g_skinParamKeys = LIBSkinsystem.g_skinParamKeys

function SLIGWOLF_ADDON:SkinGetConvarName(category)
	local convarName = string.format("cl_sligwolf_%s_theme_%s", self.Addonname, category)
	return convarName
end

function SLIGWOLF_ADDON:SkinAddConvar(category)
	if SERVER then
		return nil
	end

	local defaultThemeConfig = self:SkinGetDefaultThemeConfig(category)
	if not defaultThemeConfig then
		return nil
	end

	local defaultThemeName = defaultThemeConfig.name
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

	local defaultThemeConfig = self:SkinGetDefaultThemeConfig(category)
	if not defaultThemeConfig then
		return nil
	end

	local defaultThemeName = defaultThemeConfig.name
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
		local themeConfig = self:SkinGetRandomPickerThemeConfig(category)
		if not themeConfig then
			return defaultThemeName
		end

		return themeConfig.name
	end

	if themeName == "player" then
		local themeConfig = self:SkinGetPlayerColoredThemeConfig(category)
		if not themeConfig then
			return defaultThemeName
		end

		return themeConfig.name
	end

	local themeConfig = self:SkinGetThemeConfig(category, themeName, false)
	if not themeConfig then
		LIBPrint.Warn(
			"Theme '%s' was not found in addon '%s'. Failing back to default.",
			themeName,
			self.Addonname
		)

		return defaultThemeName
	end

	return themeConfig.name
end

function SLIGWOLF_ADDON:GetThemeNameFromKeyValue(category, keyValue)
	category = tostring(category or "")
	keyValue = tostring(keyValue or "")

	local defaultThemeConfig = self:SkinGetDefaultThemeConfig(category)
	if not defaultThemeConfig then
		return nil
	end

	local defaultThemeName = defaultThemeConfig.name

	if keyValue == "" or keyValue == "default" then
		return defaultThemeName
	end

	if keyValue == "random" then
		local themeConfig = self:SkinGetRandomPickerThemeConfig(category)
		if not themeConfig then
			return defaultThemeName
		end

		return themeConfig.name
	end

	if keyValue == "player" then
		if not IsValid(LIBUtil.GetFailbackPlayer()) then
			return defaultThemeName
		end

		local themeConfig = self:SkinGetPlayerColoredThemeConfig(category)
		if not themeConfig then
			return defaultThemeName
		end

		return themeConfig.name
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

	local themeConfig = self:SkinGetThemeConfig(category, themeName, true)
	if not themeConfig then
		LIBPrint.Warn(
			"Theme '%s' was not found in addon '%s', got sligwolf_theme = '%s'. Failing back to default.",
			themeName,
			self.Addonname,
			keyValue
		)

		return defaultThemeName
	end

	return themeConfig.name
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

				if skinParam and isstring(skinParam) and not LIBSkinsystem.HasSkinMetaFunction(skinParamKey, skinParam) then
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

function SLIGWOLF_ADDON:SkinAddThemeConfig(category, name, config)
	category = tostring(category or "")
	name = tostring(name or "")

	if category == "" then
		return
	end

	if name == "" then
		return
	end

	local themeCategory = self.g_skinThemeConfigs[category] or {}
	self.g_skinThemeConfigs[category] = themeCategory

	local themeConfig = {}
	themeCategory[name] = themeConfig

	themeConfig.name = name
	themeConfig.category = category
	themeConfig.order = config.order or LIBUtil.Order()
	themeConfig.isRandom = config.isRandom or false

	if config.isDefault and not self.g_skinThemeConfigsDefaults[category] then
		self.g_skinThemeConfigsDefaults[category] = themeConfig
		themeConfig.isDefault = true
	end

	if config.isRandom and not self.g_skinThemeConfigsRandomPickers[category] then
		self.g_skinThemeConfigsRandomPickers[category] = themeConfig
		themeConfig.isRandom = true
	end

	if config.isPlayerColored and not self.g_skinThemeConfigsPlayerColored[category] then
		self.g_skinThemeConfigsPlayerColored[category] = themeConfig
		themeConfig.isPlayerColored = true
	end

	local buttonParams = config.button or {}
	local themeParams = config.theme or {}

	themeConfig.button = {
		title = buttonParams.title,
		overlayMaterial = buttonParams.overlayMaterial,
		pieces = buttonParams.pieces,
	}

	local themeParamsInternal = {}
	themeConfig.theme = themeParamsInternal

	for skinParamsName, skinParamsItem in pairs(themeParams) do
		themeParamsInternal[skinParamsName] = {
			color = skinParamsItem.color,
			skin = skinParamsItem.skin,
			bodygroups = skinParamsItem.bodygroups,
		}
	end

	resolveSkinItemNames(themeParamsInternal)

	self.g_skinThemeConfigsOrdered[category] = {}
	self.g_skinThemeConfigsForRandom[category] = {}
end

function SLIGWOLF_ADDON:SkinGetThemeConfig(category, name, resolveRandom)
	category = tostring(category or "")
	name = tostring(name or "")

	if category == "" then
		return nil
	end

	if name == "" then
		return nil
	end

	local themeCategory = self.g_skinThemeConfigs[category]
	if not themeCategory then
		return nil
	end

	local themeConfig = themeCategory[name]
	if not themeConfig then
		return nil
	end

	if not resolveRandom or not themeConfig.isRandom then
		return themeConfig
	end

	local nonRandomThemeConfigs = self.g_skinThemeConfigsForRandom[category] or {}

	if table.IsEmpty(nonRandomThemeConfigs) then
		for _, nonRandomThemeConfig in pairs(themeCategory) do
			if nonRandomThemeConfig.isRandom then
				continue
			end

			table.insert(nonRandomThemeConfigs, nonRandomThemeConfig)
		end
	end

	local randomKey = math.random(#nonRandomThemeConfigs)
	local randomThemeConfig = nonRandomThemeConfigs[randomKey]

	if not randomThemeConfig then
		return nil
	end

	return randomThemeConfig
end

function SLIGWOLF_ADDON:SkinGetThemeConfigs(category)
	category = tostring(category or "")

	if category == "" then
		return nil
	end

	local themeConfigsOrdered = self.g_skinThemeConfigsOrdered[category] or {}
	self.g_skinThemeConfigsOrdered[category] = themeConfigsOrdered

	if not table.IsEmpty(themeConfigsOrdered) then
		return themeConfigsOrdered
	end

	local themeConfigs = self.g_skinThemeConfigs[category]
	if not themeConfigs then
		return nil
	end

	for i, themeConfig in SortedPairsByMemberValue(themeConfigs, "order") do
		table.insert(themeConfigsOrdered, themeConfig)
	end

	return themeConfigsOrdered
end

function SLIGWOLF_ADDON:SkinGetDefaultThemeConfig(category)
	category = tostring(category or "")

	if category == "" then
		return nil
	end

	local defaultThemeConfig = self.g_skinThemeConfigsDefaults[category]
	if defaultThemeConfig then
		defaultThemeConfig.isDefault = true
		return defaultThemeConfig
	end

	local themeConfigs = self:SkinGetThemeConfigs(category)
	if not themeConfigs then
		return nil
	end

	for i, themeConfig in ipairs(themeConfigs) do
		self.g_skinThemeConfigsDefaults[category] = themeConfig
		themeConfig.isDefault = true
		return themeConfig
	end

	return nil
end

function SLIGWOLF_ADDON:SkinGetRandomPickerThemeConfig(category)
	category = tostring(category or "")

	if category == "" then
		return nil
	end

	local randomPickerThemeConfig = self.g_skinThemeConfigsRandomPickers[category]
	if randomPickerThemeConfig then
		randomPickerThemeConfig.isRandom = true
		return randomPickerThemeConfig
	end

	return nil
end

function SLIGWOLF_ADDON:SkinGetPlayerColoredThemeConfig(category)
	category = tostring(category or "")

	if category == "" then
		return nil
	end

	local playerColoredThemeConfig = self.g_skinThemeConfigsPlayerColored[category]
	if playerColoredThemeConfig then
		playerColoredThemeConfig.isPlayerColored = true
		return playerColoredThemeConfig
	end

	return nil
end

function SLIGWOLF_ADDON:SkinApplyThemeData(superparent, themeData)
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

function SLIGWOLF_ADDON:SkinApplyThemeByName(superparent, themeConfigName)
	superparent = LIBEntities.GetSuperParent(superparent)
	if not IsValid(superparent) then
		return
	end

	local categoryName = self:SkinGetCategoryAndMapName(superparent)
	if not categoryName then
		return
	end

	local themeConfig = self:SkinGetThemeConfig(categoryName, themeConfigName, true)
	if not themeConfig then
		return
	end

	self:SkinApplyThemeFromConfig(superparent, themeConfig)
end

function SLIGWOLF_ADDON:SkinApplyThemeFromConfig(superparent, themeConfig)
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

	if not themeConfig then
		return
	end

	local parts = map.parts
	local themeParams = themeConfig.theme

	local themeData = {}

	for _, partProperties in pairs(parts) do
		local path = partProperties.path

		local appliedThemeEntry = {}

		-- Resolve names to color/skin/bodygroups from theme
		for _, skinParamKey in ipairs(g_skinParamKeys) do
			local partProperty = partProperties[skinParamKey]
			if partProperty and isstring(partProperty) and not LIBSkinsystem.HasSkinMetaFunction(skinParamKey, partProperty) then
				local skinParam = themeParams[partProperty]

				if skinParam then
					partProperty = skinParam[skinParamKey]
				end
			end

			if partProperty then
				if LIBSkinsystem.HasSkinMetaFunction(skinParamKey, partProperty) then
					partProperty = LIBSkinsystem.CallSkinMetaFunction(skinParamKey, partProperty, superparent)
				end

				if partProperty then
					appliedThemeEntry[skinParamKey] = partProperty
					themeData[path] = appliedThemeEntry
				end
			end
		end
	end

	self:SkinApplyThemeData(superparent, themeData)
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

