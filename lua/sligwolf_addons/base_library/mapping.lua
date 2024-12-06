AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Mapping = SligWolf_Addons.Mapping or {}
table.Empty(SligWolf_Addons.Mapping)

local LIB = SligWolf_Addons.Mapping

local LIBPrint = nil
local LIBUtil = nil
local LIBFile = nil

function LIB.Load()
	LIBPrint = SligWolf_Addons.Print
	LIBUtil = SligWolf_Addons.Util
	LIBFile = SligWolf_Addons.File
end

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

		local class = tostring(vehicleTable.Class or "")
		if class == "" then
			continue
		end

		result[class] = result[class] or {}
		local items = result[class]

		table.insert(items, {
			spawnname = spawnname,
			title = vehicleTable.Name,
			addontitle = SligWolf_Addons.GetAddonTitle(vehicleTable.SLIGWOLF_Addonname) or vehicleTable.SLIGWOLF_Addonname,
		})

		count = count + 1
	end

	return result, count
end

local function spawnnameOptionsListSorter(a, b)
	if a.addontitle ~= b.addontitle then
		return a.addontitle < b.addontitle
	end

	if a.title ~= b.title then
		return a.title < b.title
	end

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

		local line = string.format(
			[[\t\t"%s" : "%s | %s (%s)"]],
			spawnname,
			addontitle,
			title,
			spawnname
		)

		table.insert(lines, line)
	end

	lines = table.concat(lines, "\n")
	return lines
end

local function replacePlaceholder(data, name, value)
	local pattern = "%/%/[ \t]*%{%{" .. string.PatternSafe(name) .. "%}%}"
	data = string.gsub(data, pattern, "{{" .. name .. "}}")

	local pattern = "%{%{" .. string.PatternSafe(name) .. "%}%}"
	data = string.gsub(data, pattern, value)

	return data
end

local g_fgd_cache = nil
local g_fgd_cache_filename = "mapping/cache/sligwolf_base.fgd.json"

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

	LIB.WriteFGDCache()

	local validCache = LIB.IsValidFGDCache()

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
	local fileName = "mapping/sligwolf_base.fgd.txt"

	local fgd = LIBFile.Read(fileName, LIBFile.ENUM_NO_ADDON, LIBFile.ENUM_DATA_STATIC) or ""
	if fgd == "" then
		LIBPrint.Print(
			"Mapping.GenerateFGD: FGD template '%s' not found or empty",
			LIBFile.GetAbsolutePath(fileName, LIBFile.ENUM_NO_ADDON, LIBFile.ENUM_DATA_STATIC)
		)

		return
	end

	local hasCache = LIB.BuildCache(rebuildCache)
	if not hasCache then
		return
	end

	local vehicleTables = LIB.GetFGDCacheValue("SW_VEHICLE_TABLES")

	fgd = replacePlaceholder(fgd, "SW_VERSION", SligWolf_Addons.BaseApiVersion)
	fgd = replacePlaceholder(fgd, "SW_GENERATED_AT", os.date("%Y-%m-%d %H:%M:%S"))

	fgd = insertValueFromCache(fgd, "SW_VERSION", "SW_CACHE_VERSION")
	fgd = insertValueFromCache(fgd, "SW_GENERATED_AT", "SW_CACHE_GENERATED_AT")
	fgd = insertValueFromCache(fgd, "SW_ADDON_COUNT", "SW_CACHE_ADDON_COUNT")
	fgd = insertValueFromCache(fgd, "SW_VEHICLE_COUNT", "SW_CACHE_VEHICLE_COUNT")

	fgd = replacePlaceholder(
		fgd,
		"SW_SPAWNNAME_PROP_VEHICLE_PRISONER_POD_OPTIONS",
		getSpawnnameOptionsList(vehicleTables["prop_vehicle_prisoner_pod"])
	)

	fgd = replacePlaceholder(
		fgd,
		"SW_SPAWNNAME_PROP_VEHICLE_AIRBOAT_OPTIONS",
		getSpawnnameOptionsList(vehicleTables["prop_vehicle_airboat"])
	)

	fgd = replacePlaceholder(
		fgd,
		"SW_SPAWNNAME_PROP_VEHICLE_JEEP_OPTIONS",
		getSpawnnameOptionsList(vehicleTables["prop_vehicle_jeep"])
	)

	fgd = LIBUtil.NormalizeNewlines(fgd, "\r\n")
	fgd = string.Replace(fgd, "\\t", "\t")

	local success = LIBFile.Write(fileName, fgd)
	local path = LIBFile.GetAbsolutePath(fileName)

	if success then
		LIBPrint.Print("Mapping.GenerateFGD: Written to 'data/%s'. Ready for copy and paste.", path)
	else
		LIBPrint.Print("Mapping.GenerateFGD: Could not Write to 'data/%s'", path)
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

return true

