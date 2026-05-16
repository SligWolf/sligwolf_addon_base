local SligWolf_Addons = _G.SligWolf_Addons
if not SligWolf_Addons then
	return
end

local LIB = SligWolf_Addons:NewLib("Mapping")

local LIBSkinsystem = nil
local LIBPrint = nil
local LIBUtil = nil
local LIBFile = nil

local function getVehicleTablesByClass()
	local result = {}

	local vehicleTables = LIBUtil.GetList("Vehicles")

	local count = 0

	for spawnname, vehicleTable in pairs(vehicleTables) do
		if not istable(vehicleTable) then
			continue
		end

		if not vehicleTable.Is_SLIGWOLF then
			continue
		end

		if vehicleTable.SLIGWOLF_Hidden then
			continue
		end

		local fgd = vehicleTable.SLIGWOLF_FGD
		if not fgd then
			continue
		end

		local class = tostring(fgd.class or "")
		if class == "" then
			continue
		end

		local items = result[class] or {}
		result[class] = items

		table.insert(items, {
			spawnname = spawnname,
			title = vehicleTable.Name,
			addontitle = SligWolf_Addons.GetAddonTitle(vehicleTable.SLIGWOLF_Addonname) or vehicleTable.SLIGWOLF_Addonname,
		})

		count = count + 1
	end

	return result, count
end

local function getVehicleThemesByAddon()
	local items = {}

	local vehicleThemes = LIBSkinsystem.GetAllThemes("vehicle")

	for _, themesInAddon in pairs(vehicleThemes) do
		local themes = themesInAddon.themes
		if not themes or #themes <= 1 then
			continue
		end

		local addonname = themesInAddon.addonname
		local addontitle = SligWolf_Addons.GetAddonTitle(addonname) or addonname

		for _, theme in ipairs(themes) do
			if theme.isRandom then
				continue
			end

			if theme.isPlayerColored then
				continue
			end

			local name = theme.name
			local title = theme.button.title or name
			local key = string.format("%s_%s", addonname, name)

			table.insert(items, {
				key = key,
				title = title,
				addontitle = addontitle,
			})
		end
	end

	return items
end

local function vehicleThemesOptionsListSorter(a, b)
	return a.key < b.key
end

local function getVehicleThemesOptionsList(options)
	options = options or {}

	local lines = {}

	table.insert(lines, [[\t\t"" : "Auto"]])
	table.insert(lines, [[\t\t"default" : "Default"]])
	table.insert(lines, [[\t\t"random" : "Random"]])
	table.insert(lines, [[\t\t"player" : "Player Colored"]])

	table.sort(options, vehicleThemesOptionsListSorter)

	for _, item in ipairs(options) do
		local key = item.key
		local title = item.title
		local addontitle = item.addontitle

		local line = string.format(
			[[\t\t"%s" : "%s (%s | %s)"]],
			key,
			key,
			title,
			addontitle
		)

		table.insert(lines, line)
	end

	lines = table.concat(lines, "\n")
	return lines
end

local function spawnnameOptionsListSorter(a, b)
	return a.spawnname < b.spawnname
end

local function getSpawnnameOptionsList(options)
	options = options or {}

	local lines = {}
	table.insert(lines, [[\t\t"" : "Nothing (No SW-ADDON Vehicle)"]])

	table.sort(options, spawnnameOptionsListSorter)

	for _, item in ipairs(options) do
		local title = item.title
		local addontitle = item.addontitle
		local spawnname = item.spawnname

		local line = ""

		if addontitle == title then
			line = string.format(
				[[\t\t"%s" : "%s (%s)"]],
				spawnname,
				spawnname,
				title
			)
		else
			line = string.format(
				[[\t\t"%s" : "%s (%s | %s)"]],
				spawnname,
				spawnname,
				title,
				addontitle
			)
		end

		table.insert(lines, line)
	end

	lines = table.concat(lines, "\n")
	return lines
end

local function replacePlaceholder(data, name, value)
	local pattern = "%/%/[ \t]*%{%{" .. string.PatternSafe(name) .. "%}%}"
	data = string.gsub(data, pattern, "{{" .. name .. "}}")

	pattern = "%{%{" .. string.PatternSafe(name) .. "%}%}"
	data = string.gsub(data, pattern, value)

	return data
end

local g_fgd_cache = nil
local g_fgd_cache_filename = "mapping/cache/sligwolf_base_template.fgd.json"

function LIB.WriteFGDCache()
	local data = util.TableToJSON(g_fgd_cache or {}, true)

	local success = LIBFile.Write(g_fgd_cache_filename, data)
	local path = LIBFile.GetAbsolutePath(g_fgd_cache_filename)

	if not success then
		LIBPrint.Print("Mapping.WriteFGDCache: Could not Write to 'data/%s'", path)
		return
	end

	g_fgd_cache = nil
	LIB.ReadFGDCache()
end

function LIB.ReadFGDCache()
	local data = LIBFile.Read(g_fgd_cache_filename, LIBFile.ENUM_NO_ADDON, LIBFile.ENUM_DATA)
	if not data then
		return
	end

	data = util.JSONToTable(data)
	if not data then
		return
	end

	g_fgd_cache = data
	return g_fgd_cache
end

function LIB.GetFGDCacheValue(key)
	if not g_fgd_cache then
		return
	end

	if key == nil then
		return
	end

	return g_fgd_cache[key]
end

function LIB.SetFGDCacheValue(key, value)
	if key == nil then
		return false
	end

	g_fgd_cache = g_fgd_cache or {}
	g_fgd_cache[key] = value

	return true
end

function LIB.IsValidFGDCache()
	if not LIB.GetFGDCacheValue("SW_VERSION") then
		return false
	end

	return true
end

function LIB.ClearFGDCache()
	if not g_fgd_cache then
		return
	end

	table.Empty(g_fgd_cache)
end

function LIB.BuildCache(rebuildCache)
	LIB.ReadFGDCache()

	local validCache = LIB.IsValidFGDCache()

	if not rebuildCache and validCache then
		LIBPrint.Print("Mapping.BuildCache: Reading from FGD cache.")
		return validCache
	end

	LIB.ReadFGDCache()
	LIB.ClearFGDCache()

	local vehicleTables, vehicleTablesCount = getVehicleTablesByClass()

	LIB.SetFGDCacheValue("SW_VERSION", SligWolf_Addons.BaseApiVersion)
	LIB.SetFGDCacheValue("SW_GENERATED_AT", os.date("%Y-%m-%d %H:%M:%S"))
	LIB.SetFGDCacheValue("SW_ADDON_COUNT", SligWolf_Addons.GetLoadedAddonsCount())
	LIB.SetFGDCacheValue("SW_VEHICLE_COUNT", vehicleTablesCount)
	LIB.SetFGDCacheValue("SW_VEHICLE_TABLES", vehicleTables)
	LIB.SetFGDCacheValue("SW_VEHICLE_THEMES", getVehicleThemesByAddon())

	LIB.WriteFGDCache()

	validCache = LIB.IsValidFGDCache()

	if not validCache then
		LIBPrint.Print("Mapping.BuildCache: Could not build FGD cache.")
		return false
	end

	LIBPrint.Print("Mapping.BuildCache: FGD cache refreshed.")
	return true
end

local function insertValueFromCache(fgd, nameCache, nameFgd)
	local value = LIB.GetFGDCacheValue(nameCache)
	if value == nil then
		return
	end

	if not nameFgd then
		nameFgd = nameCache
	end

	value = tostring(value)
	fgd = replacePlaceholder(fgd, nameFgd, value)

	return fgd
end


function LIB.GenerateFGD(rebuildCache)
	local fileNameGenerated = "mapping/sligwolf_base.fgd.txt"
	local fileNameGeneratedAbsolute = LIBFile.GetAbsolutePath(fileNameGenerated)

	local fileNameTempate = "mapping/sligwolf_base_template.fgd.txt"
	local fileNameTempateAbsolute = LIBFile.GetAbsolutePath(fileNameTempate, LIBFile.ENUM_NO_ADDON, LIBFile.ENUM_DATA_STATIC)

	local fgdContent = LIBFile.Read(fileNameTempate, LIBFile.ENUM_NO_ADDON, LIBFile.ENUM_DATA_STATIC) or ""
	if fgdContent == "" then
		LIBPrint.Print(
			"Mapping.GenerateFGD: FGD template '%s' not found or empty",
			fileNameTempateAbsolute
		)

		return
	end

	local hasCache = LIB.BuildCache(rebuildCache)
	if not hasCache then
		return
	end

	local vehicleTables = LIB.GetFGDCacheValue("SW_VEHICLE_TABLES")

	fgdContent = replacePlaceholder(fgdContent, "SW_VERSION", SligWolf_Addons.BaseApiVersion)
	fgdContent = replacePlaceholder(fgdContent, "SW_GENERATED_AT", os.date("%Y-%m-%d %H:%M:%S"))
	fgdContent = replacePlaceholder(fgdContent, "SW_GENERATED_TEMPLATE", fileNameTempateAbsolute)

	fgdContent = insertValueFromCache(fgdContent, "SW_VERSION", "SW_CACHE_VERSION")
	fgdContent = insertValueFromCache(fgdContent, "SW_GENERATED_AT", "SW_CACHE_GENERATED_AT")
	fgdContent = insertValueFromCache(fgdContent, "SW_ADDON_COUNT", "SW_CACHE_ADDON_COUNT")
	fgdContent = insertValueFromCache(fgdContent, "SW_VEHICLE_COUNT", "SW_CACHE_VEHICLE_COUNT")

	fgdContent = replacePlaceholder(
		fgdContent,
		"SW_VEHICLE_THEMES_OPTIONS",
		getVehicleThemesOptionsList(LIB.GetFGDCacheValue("SW_VEHICLE_THEMES"))
	)

	fgdContent = replacePlaceholder(
		fgdContent,
		"SW_SPAWNNAME_AIRBOAT_OPTIONS",
		getSpawnnameOptionsList(vehicleTables["prop_vehicle_sligwolf_airboat"])
	)

	fgdContent = replacePlaceholder(
		fgdContent,
		"SW_SPAWNNAME_JEEP_OPTIONS",
		getSpawnnameOptionsList(vehicleTables["prop_vehicle_sligwolf_jeep"])
	)

	fgdContent = replacePlaceholder(
		fgdContent,
		"SW_SPAWNNAME_POD_OPTIONS",
		getSpawnnameOptionsList(vehicleTables["prop_vehicle_sligwolf_pod"])
	)

	fgdContent = replacePlaceholder(
		fgdContent,
		"SW_SPAWNNAME_TRAIN_OPTIONS",
		getSpawnnameOptionsList(vehicleTables["prop_vehicle_sligwolf_train"])
	)

	fgdContent = LIBUtil.NormalizeNewlines(fgdContent, "\r\n")
	fgdContent = string.Replace(fgdContent, "\\t", "\t")

	local success = LIBFile.Write(fileNameGenerated, fgdContent)

	if success then
		LIBPrint.Print("Mapping.GenerateFGD: Written to 'data/%s'. Ready for copy and paste.", fileNameGeneratedAbsolute)
	else
		LIBPrint.Print("Mapping.GenerateFGD: Could not Write to 'data/%s'", fileNameGeneratedAbsolute)
	end
end

if SERVER then
	concommand.Add("sv_sligwolf_mapping_generate_fgd", function(ply, cmd, args)
		if not LIBUtil.IsAdminForCMD(ply) then
			return
		end

		local rebuildCache = tobool(args[1])

		LIB.GenerateFGD(rebuildCache)
	end)
end

function LIB.Load()
	LIBSkinsystem = SligWolf_Addons.Skinsystem
	LIBPrint = SligWolf_Addons.Print
	LIBUtil = SligWolf_Addons.Util
	LIBFile = SligWolf_Addons.File
end

return true

