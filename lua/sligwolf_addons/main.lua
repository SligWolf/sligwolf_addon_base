AddCSLuaFile()

--[[
	Rules for this addon:
		1)  Use this addon as a legacy addon (folder version) for your server ONLY,
			if you don't wish updates from the official workshop addon.
		2)  The following code protects against loading stolen SW addons
			and fake SW addons that maybe contain malicious code.
			Leave this code as it is, do not support such a bad behavior.
]]

local SligWolf_Addons = _G.SligWolf_Addons or {}
_G.SligWolf_Addons = nil

do
	-- clear old instance of SligWolf_Addons, but keep the detourBackups
	local detourBackups = table.Copy(SligWolf_Addons._detourBackups or {})
	table.Empty(SligWolf_Addons)
	SligWolf_Addons._detourBackups = detourBackups
end


-- Check sum of SW Base validation script "sligwolf_addons/basecheck.lua".
-- It contains logic to validate the SW Base addon being installed, up to date and active. (SHA256)
local BASECHECK_SCRIPT_CHECKSUM = "af17bec9ab37327d33e9f6bd7a149a348802e26ff049913deb42cdfe38fc728d"

-- Version validation requirements to make sure everything is up to date.
SligWolf_Addons.BaseApiVersion = "1.2.4"

-- Minimum supported game version.
SligWolf_Addons.MinGameVersionServer = 241209
SligWolf_Addons.MinGameVersionClient = 241209


SligWolf_Addons.Addondata = SligWolf_Addons.Addondata or {}
SligWolf_Addons.AddondataSorted = nil

SligWolf_Addons.IsManuallyReloading = false

local ENUM_ERROR_UNSPECIFIED = "ERROR_UNSPECIFIED"
local ENUM_ERROR_BAD_VERSION = "ERROR_BAD_VERSION"
local ENUM_ERROR_BAD_GAME_VERSION = "ERROR_BAD_GAME_VERSION"
local ENUM_ERROR_CONFLICTING_ADDON = "ERROR_CONFLICTING_ADDON"
local ENUM_ERROR_UNKNOWN_ADDON = "ERROR_UNKNOWN_ADDON"
local ENUM_ERROR_NOT_LOADED = "ERROR_NOT_LOADED"

SligWolf_Addons.ERROR_UNSPECIFIED = ENUM_ERROR_UNSPECIFIED
SligWolf_Addons.ERROR_BAD_VERSION = ENUM_ERROR_BAD_VERSION
SligWolf_Addons.ERROR_BAD_GAME_VERSION = ENUM_ERROR_BAD_GAME_VERSION
SligWolf_Addons.ERROR_CONFLICTING_ADDON = ENUM_ERROR_CONFLICTING_ADDON
SligWolf_Addons.ERROR_UNKNOWN_ADDON = ENUM_ERROR_UNKNOWN_ADDON
SligWolf_Addons.ERROR_NOT_LOADED = ENUM_ERROR_NOT_LOADED

local g_DefaultHooks = {
	Think = "Think",
	Tick = "Tick",
	PlyInit = "PlayerInitialSpawn",
	EntInit = "InitPostEntity",
	KeyPress = "KeyPress",
	KeyRelease = "KeyRelease",
	HUDPaint = "HUDPaint",
	VehicleOrderThink = "Think",
	VehicleOrderMenu = "PopulateToolMenu",
	VehicleOrderLeave = "PlayerLeaveVehicle",

	AllAddonsLoaded = "SLIGWOLF_AllAddonsLoaded",
	TrackAssamblerContentAutoInclude = "SLIGWOLF_AllAddonsLoaded",
}

local g_FunctionPathCache = {}
local g_LuaFileExistsCache = {}
local g_WorkshopAddonsCache = {}
local g_WorkshopAddonsFilesCache = {}

local g_WorkshopIDWhitelist = {
	["base"] = "2866238940",
	["aliencutbug"] = "646068704",
	["automatictrain"] = "366345014",
	["bgcar"] = "173717507",
	["bluex11"] = "105142403",
	["bluex12"] = "292674440",
	["bluex13"] = "122248418",
	["bluex14"] = "256428548",
	["bluex15"] = "1231937933",
	["bus"] = "130227747",
	["crane"] = "263027561",
	["cranetrain"] = "270201182",
	["cranetruck"] = "357910009",
	["dieselhenschel"] = "361586208",
	["dieselludmilla"] = "381210427",
	["fcc"] = "105146169",
	["ferry"] = "239910715",
	["forklift"] = "264931812",
	["garbagetruck"] = "394277409",
	["gausstank"] = "105147125",
	["germancop"] = "183178671",
	["gokart"] = "105150660",
	["greent7"] = "105147817",
	["grenadelauncher"] = "175664622",
	["hands"] = "113764710",
	["hl2coopvehicles"] = "3384120217",
	["hotrod"] = "105011898",
	["hovercraft"] = "105010554",
	["jeeps"] = "1375274405",
	["leotank"] = "288026358",
	["limousine"] = "180567595",
	["loopings"] = "105780180",
	["minitrains"] = "149759773",
	["modelpack"] = "147812851",
	["motorbike"] = "105144348",
	["orblauncher"] = "1391435350",
	["powerboat"] = "105140639",
	["racecar"] = "230317839",
	["rerailer"] = "132843280",
	["robotgen1"] = "147802259",
	["robotgen2"] = "119968146",
	["robotgen2npc"] = "123685947",
	["robotgen3"] = "3384124517",
	["rustyer"] = "219898030",
	["seats"] = "107865704",
	["siren"] = "337151920",
	["slig"] = "104914708",
	["slignpc"] = "123686602",
	["snowmobile"] = "105781997",
	["st3tram"] = "707877689",
	["tinyhoverracer"] = "1375275167",
	["towtruck"] = "456773274",
	["trabant"] = "342855123",
	["tractor"] = "1105243365",
	["tram"] = "114589891",
	["truck"] = "194583946",
	["vrhl2weapons"] = "3008753645",
	["wagons"] = "379538128",
	["westernloco"] = "132174849",
	["wheelpack"] = "3384113283",
	["wpsuspensiontrain"] = "3297918081",
}

local g_realmText = SERVER and "server" or "client"
local g_realmColor = SERVER and Color(137, 222, 255) or Color(255, 222, 102)
local g_realmLuaPath = SERVER and "lsv" or "lcl"
local g_errorColor = Color(255, 90, 90)
local g_successColor = Color(90, 192, 90)
local g_prefixColor = Color(200, 200, 200)

local addWorkshopClientDownload = nil

if SERVER then
	local cvarAllowWorkshopDownload = CreateConVar(
		"sv_sligwolf_addons_allow_workshop_download",
		"1",
		bit.bor(FCVAR_ARCHIVE, FCVAR_GAMEDLL),
		"Allow or disallow workshop downloads (resource.AddWorkshop()) of SW Addons for joining clients. Requires server restart. (Default: 1)",
		0,
		1
	)

	addWorkshopClientDownload = function(wsid)
		if not cvarAllowWorkshopDownload:GetBool() then return end

		resource.AddWorkshop(wsid)
	end
end

local function inValidateSortedAddondata()
	local sligwolfAddons = _G.SligWolf_Addons
	if not sligwolfAddons then return end

	sligwolfAddons.AddondataSorted = nil
end

local function buildHookCaller(functionName, eventName)
	local sligwolfAddons = _G.SligWolf_Addons
	if not sligwolfAddons then
		return
	end

	if not sligwolfAddons.LibrariesLoaded then
		return
	end

	local identifier = "addon_" .. functionName
	if sligwolfAddons.Hook.Has(eventName, identifier) then
		return
	end

	sligwolfAddons.Hook.Add(eventName, identifier, function(...)
		return sligwolfAddons.CallFunctionOnAllAddons(functionName, ...)
	end, 3000000)
end

local function AddHooks(addon)
	local addedhooks = addon.hooks or {}

	for functionName, eventName in pairs(g_DefaultHooks) do
		buildHookCaller(functionName, eventName)
	end

	for functionName, eventName in pairs(addedhooks) do
		functionName = tostring(functionName or "")
		eventName = tostring(eventName or "")

		if functionName == "" then continue end
		if eventName == "" then continue end

		buildHookCaller(functionName, eventName)
	end
end

local g_validBase = nil

local function ValidateBaseCheckScript()
	if g_validBase ~= nil then
		return g_validBase
	end

	g_validBase = nil

	if not BASECHECK_SCRIPT_CHECKSUM then
		return true
	end

	if BASECHECK_SCRIPT_CHECKSUM == "" then
		return true
	end

	local sligwolfAddons = _G.SligWolf_Addons
	if not sligwolfAddons then
		return false
	end

	if not sligwolfAddons.LibrariesLoaded then
		return false
	end

	local hash = sligwolfAddons.Util.CheckSumOfFile("sligwolf_addons/basecheck.lua", "LUA")
	if not hash then
		g_validBase = true
		return true
	end

	if hash ~= BASECHECK_SCRIPT_CHECKSUM then
		g_validBase = false
		return false
	end

	g_validBase = true
	return true
end

local function GetPathOfFunction(funcobj)
	if not isfunction(funcobj) then
		return nil
	end

	if g_FunctionPathCache[funcobj] then
		return g_FunctionPathCache[funcobj]
	end

	local info = debug.getinfo(funcobj) or {}
	local path = tostring(info.short_src or info.source or "")

	if path == "" then
		return nil
	end

	g_FunctionPathCache = {}
	g_FunctionPathCache[funcobj] = path
	return path
end

local function GetAddonNameOfFunction(funcobj)
	local path = GetPathOfFunction(funcobj)
	if not path then
		return nil
	end

	local folders = string.Explode("/", path, false)
	local count = #folders

	local name = folders[count-1]
	return name
end

local function GetWorkshopAddonsFromPath(path)
	if g_WorkshopAddonsFilesCache[path] then
		return g_WorkshopAddonsFilesCache[path]
	end

	if #g_WorkshopAddonsCache <= 0 then
		g_WorkshopAddonsCache = engine.GetAddons() or {}
	end

	if #g_WorkshopAddonsCache <= 0 then
		return nil
	end

	local found = false

	for _, wsAddon in ipairs(g_WorkshopAddonsCache) do
		if not wsAddon then continue end
		if not wsAddon.mounted then continue end
		if not wsAddon.downloaded then continue end

		local addonTitle = tostring(wsAddon.title or "")
		if addonTitle == "" then continue end

		local wsid = tostring(wsAddon.wsid or "")
		if wsid == "" then continue	end

		if not file.Exists(path, addonTitle) then continue end
		local addonFile = tostring(wsAddon.file or "")

		addonFile = string.Replace(addonFile, "\\", "/")
		addonFile = string.Trim(addonFile)

		wsAddon.file = addonFile
		wsAddon.title = addonTitle
		wsAddon.wsid = wsid

		g_WorkshopAddonsFilesCache[path] = g_WorkshopAddonsFilesCache[path] or {}
		g_WorkshopAddonsFilesCache[path][wsid] = wsAddon

		found = true
	end

	if not found then
		return nil
	end

	return g_WorkshopAddonsFilesCache[path]
end

local function GetWorkshopAddonsOfFunction(funcobj)
	local path = GetPathOfFunction(funcobj)
	if not path then
		return nil
	end

	local addons = GetWorkshopAddonsFromPath(path)
	if not addons then
		return nil
	end

	return addons
end

local function GetWorkshopID(name)
	name = tostring(name or "")

	if name == "" then
		return nil
	end

	local wsid = g_WorkshopIDWhitelist[name]
	if not wsid then
		return nil
	end

	return wsid
end

local function CheckWorkshopID(wsid, name)
	wsid = tostring(wsid or "")
	name = tostring(name or "")

	if wsid == "" then
		-- Loaded as legacy addon (addons folder)
		-- This is explicitly allowed, because:
		--   1) Users or server maintainers must not be forced to use the workshop copy.
		--   2) Installing as legacy addon is done to avoid automatic updates which is a widespread practice.

		return true
	end

	local allowedWorkshopID = GetWorkshopID(name)
	if not allowedWorkshopID then
		-- This addon is not whitelisted.
		return false
	end

	if allowedWorkshopID ~= wsid then
		-- This is a foreign, illegal or otherwise unapproved workshop copy.
		return false
	end

	-- This addon is an official workshop copy.
	return true
end

local function CheckWorkshopAddon(wsAddon, name)
	if not wsAddon then
		return true
	end

	local valid = CheckWorkshopID(wsAddon.wsid, name)
	if not valid then
		return false
	end

	return true
end

local function CheckWorkshopAddons(wsAddons, name)
	if not wsAddons then
		return true
	end

	-- If any unapproved SW addon is mounted, we will not load this addon and its original version.
	-- Both will not be loaded, because we can not determine which of these 2 addons is approved or not.

	for _, wsAddon in pairs(wsAddons) do
		if CheckWorkshopAddon(wsAddon, name) then continue end

		return false
	end

	return true
end

local function MsgCInfo(...)
	MsgC(g_prefixColor, "[SW-ADDONS] ")
	MsgC(...)
	Msg("\n")
end

local function MsgCError(text, errorCode)
	text = tostring(text or "")
	errorCode = tostring(errorCode or "")

	if text == "" then
		return
	end

	if errorCode == "" then
		errorCode = ENUM_ERROR_UNSPECIFIED
	end

	MsgCInfo(g_errorColor, text, g_errorColor, " [", errorCode, "]")
end

local function MsgCSuccess(text)
	text = tostring(text or "")
	if text == "" then return end

	MsgCInfo(g_realmColor, text, g_successColor, " [OK]")
end

local function MsgCUnapprovedAddons(unapprovedWsAddons, name)
	if not unapprovedWsAddons then return end

	name  = tostring(name or "")
	if name == "" then return end

	local errorText = string.format("Addon '%s' could not be loaded at %s!", name, g_realmText)
	MsgCError(errorText, ENUM_ERROR_CONFLICTING_ADDON)

	local errorText = "  Unapproved or conflicting addon detected. Please uninstall this addon:\n"
	MsgC(g_errorColor, errorText)

	for _, unapprovedWsAddon in pairs(unapprovedWsAddons) do
		if CheckWorkshopAddon(unapprovedWsAddon, name) then	continue end

		local addonFile = unapprovedWsAddon.file
		local addonTitle = unapprovedWsAddon.title
		local wsid = unapprovedWsAddon.wsid
		local errorText = ""

		if addonFile == "" then
			errorText = string.format("  - %s (%s)", addonTitle, wsid)
		else
			errorText = string.format("  - %s (%s) [file: %s]", addonTitle, wsid, addonFile)
		end

		MsgC(g_errorColor, errorText)
		Msg("\n")
	end
end

local g_hasIncludeErrors = false

local function throwIncludeError(err)
	err = tostring(err or "")
	err = string.Trim(err or "")

	if err == "" then
		return
	end

	g_hasIncludeErrors = true

	ErrorNoHaltWithStack(err .. "\n")
end

local function luaExists(luafile)
	luafile = tostring(luafile or "")
	luafile = string.lower(luafile or "")

	if luafile == "" then
		return false
	end

	if g_LuaFileExistsCache[luafile] ~= nil then
		return g_LuaFileExistsCache[luafile] or false
	end

	local exists = file.Exists(luafile, g_realmLuaPath)

	if not exists then
		g_LuaFileExistsCache[luafile] = false
		return false
	end

	g_LuaFileExistsCache[luafile] = true
	return true
end

local function saveCSLuaFile(luafile)
	luafile = tostring(luafile or "")
	luafile = string.lower(luafile or "")

	if luafile == "" then
		return false
	end

	local status = xpcall(function()
		if CLIENT then
			return
		end

		if not luaExists(luafile) then
			local err = string.format("Couldn't AddCSLuaFile file '%s' (File not found)", luafile)
			error(err)

			return
		end

		AddCSLuaFile(luafile)
	end, throwIncludeError)

	if not status then
		g_hasIncludeErrors = true
		return false
	end

	return true
end

local function saveInclude(luafile)
	luafile = tostring(luafile or "")
	luafile = string.lower(luafile or "")

	if luafile == "" then
		return nil
	end

	local status, result = xpcall(function()
		if SERVER then
			-- Too slow on clientside on some servers
			-- See: https://github.com/Facepunch/garrysmod-issues/issues/5674

			if not luaExists(luafile) then
				local err = string.format("Couldn't include file '%s' (File not found)", luafile)
				error(err)

				return nil
			end
		end

		local r = include(luafile)

		if not r then
			local err = string.format("Couldn't include file '%s' (Error during execution or file not found)", luafile)
			error(err)

			return nil
		end

		return r
	end, throwIncludeError)

	if not status then
		g_hasIncludeErrors = true
		return false, nil
	end

	return true, result
end

local function saveIncludeAddonInit(luafile)
	luafile = tostring(luafile or "")
	luafile = string.lower(luafile or "")

	if luafile == "" then
		return nil, ENUM_ERROR_UNSPECIFIED
	end

	local status, result = saveInclude(luafile)

	if not status then
		return false, ENUM_ERROR_NOT_LOADED
	end

	if result == true then
		return true
	end

	if string.StartsWith(result, "ERROR_") then
		return false, result
	end

	result = result or ENUM_ERROR_UNSPECIFIED

	local resultStr = tostring(result)

	if resultStr == "" then
		resultStr = ENUM_ERROR_UNSPECIFIED
	end

	local err = string.format("Included file '%s' returned in a bad state! (state: %s)", luafile, resultStr)

	throwIncludeError(err)
	return false, result
end

local function resetIncludeErrorState()
	g_hasIncludeErrors = false
end

function SligWolf_Addons.Include(luafile)
	return saveInclude(luafile)
end

function SligWolf_Addons.IncludeSimple(luafile)
	local loaded, result = saveInclude(luafile)

	if not loaded then
		return nil
	end

	return result
end

function SligWolf_Addons.AddCSLuaFile(luafile)
	return saveCSLuaFile(luafile)
end

function SligWolf_Addons.LuaExists(luafile)
	return luaExists(luafile)
end

function SligWolf_Addons.ResetIncludeErrorState()
	resetIncludeErrorState()
end

function SligWolf_Addons.HasNoIncludeErrors()
	return not g_hasIncludeErrors
end

function SligWolf_Addons.HasIncludeErrors()
	return g_hasIncludeErrors
end

local emptyAddonToString = function(thisAddon)
	return string.format(
		"Addon [id:%s][not loaded]",
		thisAddon.Addonname or "<unknown>"
	)
end

local validAddonToString = function(thisAddon)
	if not thisAddon.Loaded then
		return emptyAddonToString(thisAddon)
	end

	local addonname = thisAddon.Addonname or "<unknown>"
	local workshopID = thisAddon.WorkshopID or "<no ws>"
	local fullNiceName = tostring(thisAddon.FullNiceName or thisAddon.NiceName or "")

	if fullNiceName == "" then
		return string.format(
			"Addon [id:%s][ws:%s]",
			addonname,
			workshopID
		)
	end

	return string.format(
		"Addon [id:%s][ws:%s][%s]",
		addonname,
		workshopID,
		fullNiceName
	)
end

function SligWolf_Addons.LoadAddon(name, forceReload)
	name = tostring(name or "")
	if name == "" then
		return false
	end

	name = string.lower(name)
	name = string.Replace(name, "/", "")
	name = string.Replace(name, "\\", "")

	local sligwolfAddons = _G.SligWolf_Addons
	if not sligwolfAddons then
		return false
	end

	if not sligwolfAddons.IsLoadingAddon then
		return false
	end

	if not sligwolfAddons.HasLoadedAddon then
		return false
	end

	if sligwolfAddons.IsLoadingAddon(name) then
		return true
	end

	if sligwolfAddons.HasLoadedAddon(name) and not forceReload then
		return true
	end

	sligwolfAddons.Addondata = sligwolfAddons.Addondata or {}

	if name ~= "base" and not ValidateBaseCheckScript() then
		local errorText = string.format("SW Base validation script corrupted or outdated, make sure this addon and 'SW Base' is up to date. Can not load addon '%s' at %s!", name, g_realmText)
		MsgCError(errorText, sligwolfAddons.ERROR_BAD_VERSION)

		ErrorNoHaltWithStack(errorText)

		sligwolfAddons.Addondata[name] = nil
		return false
	end

	local initFile = "sligwolf_addons/" .. name .. "/init.lua"

	local check = sligwolfAddons.LuaExists(initFile)
	if not check then
		local errorText = string.format("Unknown addon '%s' at %s!", name, g_realmText)
		MsgCError(errorText, sligwolfAddons.ERROR_UNKNOWN_ADDON)

		sligwolfAddons.Addondata[name] = nil
		return false
	end

	-- We check the authenticity of the workshop copy, because:
	--   1) We don't want to support or to tolerate stolen copies on the workshop.
	--   2) We want to make sure that we don't run unapproved or malicious code.
	--   3) We explicitly allow installing the addon as a legacy addon (folder version),
	--      if you want to avoid potentially unwanted auto updates from the workshop version.

	local wsAddons = GetWorkshopAddonsFromPath("lua/" .. initFile)
	if not CheckWorkshopAddons(wsAddons, name) then
		MsgCUnapprovedAddons(wsAddons, name)

		sligwolfAddons.Addondata[name] = {
			Addonname = name,
			Loaded = false,
			Loading = false,
			ToString = emptyAddonToString,
		}

		return false
	end

	local wsid = GetWorkshopID(name)

	if SERVER and addWorkshopClientDownload and wsid then
		addWorkshopClientDownload(wsid)
	end

	sligwolfAddons.Addondata[name] = {
		Addonname = name,
		Loaded = false,
		Loading = true,
		ToString = emptyAddonToString,
	}

	local luaDirectory = "sligwolf_addons/" .. name

	local thisAddon = {}

	thisAddon.Addonname = name
	thisAddon.LuaDirectory = luaDirectory
	thisAddon.WorkshopID = wsid
	thisAddon.Loaded = false
	thisAddon.Loading = true
	thisAddon.ToString = emptyAddonToString

	local files = {
		"sligwolf_addons/base/addoncore.lua",
		luaDirectory .. "/init.lua",
	}

	resetIncludeErrorState()

	local ok = true
	local lastErrorCode = nil

	for _, path in ipairs(files) do
		if not saveCSLuaFile(path) then
			ok = false
			continue
		end

		local TMP_SLIGWOLF_ADDON = SLIGWOLF_ADDON
		SLIGWOLF_ADDON = thisAddon

		local loaded, errorCode = saveIncludeAddonInit(path)

		SLIGWOLF_ADDON = TMP_SLIGWOLF_ADDON

		if not loaded then
			ok = false
			lastErrorCode = errorCode
		end
	end

	if g_hasIncludeErrors then
		ok = false
	end

	resetIncludeErrorState()

	if ok then
		AddHooks(thisAddon)
	end

	local niceName = tostring(thisAddon.NiceName or "")
	local version = tostring(thisAddon.Version or "")

	if niceName ~= "" and version ~= "" then
		niceName = string.format("%s - v%s", niceName, version)
	end

	thisAddon.Loaded = ok
	thisAddon.Loading = false
	thisAddon.FullNiceName = niceName

	if ok then
		thisAddon.ToString = validAddonToString
	else
		thisAddon.ToString = emptyAddonToString
	end

	sligwolfAddons.Addondata[name] = thisAddon
	inValidateSortedAddondata()

	if ok then
		local loadFunc = thisAddon.Load

		if isfunction(loadFunc) then
			local status = xpcall(loadFunc, throwIncludeError, thisAddon)

			if not status then
				ok = false
			end
		end
	end

	if not ok then
		thisAddon.Loaded = false
		thisAddon.ToString = emptyAddonToString
	end

	local loadedText = ""
	local stateText = ok and "loaded" or "could not be loaded"

	if niceName ~= "" then
		loadedText = string.format("Addon '%s' (%s) %s at %s!", name, niceName, stateText, g_realmText)
	else
		loadedText = string.format("Addon '%s' %s at %s!", name, stateText, g_realmText)
	end

	if ok then
		MsgCSuccess(loadedText)
	else
		MsgCError(loadedText, lastErrorCode)
	end

	sligwolfAddons.Addondata[name] = thisAddon
	inValidateSortedAddondata()

	return true
end

function SligWolf_Addons.GetAddons()
	local sligwolfAddons = _G.SligWolf_Addons
	if not sligwolfAddons then return end
	if not sligwolfAddons.Addondata then return end

	return sligwolfAddons.Addondata
end

function SligWolf_Addons.GetAddonsSorted()
	local sligwolfAddons = _G.SligWolf_Addons
	if not sligwolfAddons then return end
	if not sligwolfAddons.Addondata then return end

	if sligwolfAddons.AddondataSorted and #sligwolfAddons.AddondataSorted > 0 then
		return sligwolfAddons.AddondataSorted
	end

	local addondataSorted = {}
	sligwolfAddons.AddondataSorted = nil

	for name, addon in SortedPairs(sligwolfAddons.Addondata) do
		if not addon then continue end

		local order = #addondataSorted + 1

		addondataSorted[order] = {
			order = order,
			name = name,
			addon = addon,
		}
	end

	sligwolfAddons.AddondataSorted = addondataSorted
	return sligwolfAddons.AddondataSorted
end

function SligWolf_Addons.CallFunctionOnAllAddons(addonFunc, ...)
	local sligwolfAddons = _G.SligWolf_Addons

	if not sligwolfAddons then return end
	if not sligwolfAddons.IsLoaded then return end
	if not sligwolfAddons.IsLoaded() then return end

	if not sligwolfAddons.Addondata then return end

	local sortedAddondata = sligwolfAddons.GetAddonsSorted()
	local returnResult = nil

	for order, addonItem in ipairs(sortedAddondata) do
		if not addonItem then continue end

		local addon = addonItem.addon
		if not addon then continue end
		if not addon.Loaded then continue end

		local callAddonFunctionWithErrorNoHalt = addon.CallAddonFunctionWithErrorNoHalt
		if not isfunction(callAddonFunctionWithErrorNoHalt) then continue end

		local ok, result = callAddonFunctionWithErrorNoHalt(addon, addonFunc, ...)

		if ok and result ~= nil then
			returnResult = result
		end
	end

	return returnResult
end

function SligWolf_Addons.CallFunctionOnAddon(addonname, addonFunc, ...)
	local sligwolfAddons = _G.SligWolf_Addons
	if not sligwolfAddons then return end

	local addon = SligWolf_Addons.GetAddon(addonname)
	if not addon then return end

	local returnResult = nil

	local callAddonFunctionWithErrorNoHalt = addon.CallAddonFunctionWithErrorNoHalt
	if not isfunction(callAddonFunctionWithErrorNoHalt) then return end

	local ok, result = callAddonFunctionWithErrorNoHalt(addon, addonFunc, ...)

	if ok and result ~= nil then
		returnResult = result
	end

	return returnResult
end

function SligWolf_Addons.ReloadLibraries()
	local sligwolfAddons = _G.SligWolf_Addons
	if not sligwolfAddons then return end

	g_validBase = nil

	sligwolfAddons.BASE_ADDON = nil

	sligwolfAddons.LoadingLibraries = true
	sligwolfAddons.Include("sligwolf_addons/base_library/_libraryinit.lua")
	sligwolfAddons.LoadingLibraries = nil

	sligwolfAddons.LibrariesLoaded = sligwolfAddons.HasNoIncludeErrors()

	sligwolfAddons.BASE_ADDON = sligwolfAddons.GetAddon("base")
end

function SligWolf_Addons.ReloadAllAddons()
	local sligwolfAddons = _G.SligWolf_Addons
	if not sligwolfAddons then return end
	if not sligwolfAddons.Addondata then return end
	if not sligwolfAddons.LoadAddon then return end

	g_validBase = nil

	sligwolfAddons.ReloadLibraries()

	local sortedAddondata = sligwolfAddons.GetAddonsSorted()
	local reloadList = {}

	for order, addonItem in ipairs(sortedAddondata) do
		if not addonItem then continue	end

		reloadList[#reloadList + 1] = addonItem.name
	end

	local isAddonEnv = istable(SLIGWOLF_ADDON)

	for i, addonName in ipairs(reloadList) do
		local isBase = addonName == "base"
		local forceReload = not isBase or not isAddonEnv

		sligwolfAddons.LoadAddon(addonName, forceReload)
	end

	inValidateSortedAddondata()

	sligwolfAddons.BASE_ADDON = sligwolfAddons.GetAddon("base")

	sligwolfAddons.AllAddonsLoaded = nil
	sligwolfAddons.CallAllAddonsLoadedHook()
end

function SligWolf_Addons.AutoLoadAddon(funcobj)
	local sligwolfAddons = _G.SligWolf_Addons
	if not sligwolfAddons then
		return false
	end

	if not sligwolfAddons.LoadAddon then
		return false
	end

	if not isfunction(funcobj) then
		return false
	end

	local name = GetAddonNameOfFunction(funcobj)
	local wsAddons = GetWorkshopAddonsOfFunction(funcobj)

	-- We check the authenticity of the workshop copy, because:
	--   1) We don't want to support or to tolerate stolen copies on the workshop.
	--   2) We want to make sure that we don't run unapproved or malicious code.
	--   3) We explicitly allow installing the addon as a legacy addon (folder version),
	--      if you want to avoid potentially unwanted auto updates from the workshop version.

	if not CheckWorkshopAddons(wsAddons, name) then
		MsgCUnapprovedAddons(wsAddons, name)

		return false
	end

	return sligwolfAddons.LoadAddon(name, true)
end

function SligWolf_Addons.GetLoadedAddonsCount()
	local sligwolfAddons = _G.SligWolf_Addons
	if not sligwolfAddons then
		return 0
	end

	if not sligwolfAddons.IsLoaded then
		return 0
	end

	if not sligwolfAddons.IsLoaded() then
		return 0
	end

	local addondata = sligwolfAddons.Addondata
	if not addondata then
		return 0
	end

	local count = 0

	for _, addon in pairs(addondata) do
		if not addon.Loaded then
			continue
		end

		count = count + 1
	end

	return count
end

function SligWolf_Addons.GetAddon(name)
	local sligwolfAddons = _G.SligWolf_Addons
	if not sligwolfAddons then
		return nil
	end

	local addondata = sligwolfAddons.Addondata
	if not addondata then
		return nil
	end

	local addon = addondata[name]
	if not addon then
		return nil
	end

	if not addon.Loaded then
		return nil
	end

	return addon
end

function SligWolf_Addons.HasLoadedAddon(name)
	local sligwolfAddons = _G.SligWolf_Addons
	if not sligwolfAddons then
		return false
	end

	if not sligwolfAddons.IsLoaded then
		return false
	end

	if not sligwolfAddons.IsLoaded() then
		return false
	end

	local addondata = sligwolfAddons.Addondata
	if not addondata then
		return false
	end

	local addon = addondata[name]
	if not addon then
		return false
	end

	if not addon.Loaded then
		return false
	end

	return true
end

function SligWolf_Addons.IsLoadingAddon(name)
	local sligwolfAddons = _G.SligWolf_Addons
	if not sligwolfAddons then
		return false
	end

	local addondata = sligwolfAddons.Addondata
	if not addondata then
		return false
	end

	local addon = addondata[name]
	if not addon then
		return false
	end

	if not addon.Loading then
		return false
	end

	return true
end

function SligWolf_Addons.IsLoaded()
	local sligwolfAddons = _G.SligWolf_Addons
	if not sligwolfAddons then
		return false
	end

	if not sligwolfAddons.LibrariesLoaded then
		return false
	end

	if not sligwolfAddons.BASE_ADDON then
		return false
	end

	if not sligwolfAddons.BASE_ADDON.Loaded then
		return false
	end

	return true
end

function SligWolf_Addons.GetAddonTitle(name)
	local sligwolfAddons = _G.SligWolf_Addons
	if not sligwolfAddons then
		return nil
	end

	local addon = sligwolfAddons.GetAddon(name)
	if not addon then
		return nil
	end

	return addon.NiceName
end

function SligWolf_Addons.CallAllAddonsLoadedHook()
	local sligwolfAddons = _G.SligWolf_Addons
	if not sligwolfAddons then
		return
	end

	if sligwolfAddons.AllAddonsLoaded then
		return
	end

	if not SligWolf_Addons.IsLoaded() then
		return
	end

	sligwolfAddons.AllAddonsLoaded = true
	sligwolfAddons.Hook.RunCustom("AllAddonsLoaded")
end

local function OnBaseReload(name)
	if name ~= "base" then
		return
	end

	local sligwolfAddons = _G.SligWolf_Addons
	if not sligwolfAddons then
		return
	end

	sligwolfAddons.ReloadAllAddons()
end

if SERVER then
	util.AddNetworkString("sligwolf_reload_addon")

	local function runAdminOnly(ply, func)
		if IsValid(ply) then
			if ply:IsAdmin() then
				func()
			end

			return
		end

		func()
	end

	concommand.Add("sv_sligwolf_reload_addon", function(ply, cmd, args)
		local name = tostring(args[1] or "")

		runAdminOnly(ply, function()
			g_validBase = nil

			SligWolf_Addons.IsManuallyReloading = true
			SligWolf_Addons.LoadAddon(name, true)
			OnBaseReload(name)
			SligWolf_Addons.IsManuallyReloading = false

			net.Start("sligwolf_reload_addon")
				net.WriteString(name)
			net.Broadcast()
		end)
	end)
else
	net.Receive("sligwolf_reload_addon", function(length)
		local name = net.ReadString()

		g_validBase = nil

		SligWolf_Addons.IsManuallyReloading = true
		SligWolf_Addons.LoadAddon(name, true)
		OnBaseReload(name)
		SligWolf_Addons.IsManuallyReloading = false
	end)
end

local status = ProtectedCall(function()
	-- Make sure addons are globally accessible when everything is ready
	_G.SligWolf_Addons = SligWolf_Addons

	SligWolf_Addons.ReloadLibraries()
	SligWolf_Addons.BASE_ADDON = nil

	inValidateSortedAddondata()
	include("sligwolf_addons/base/init.lua")
	inValidateSortedAddondata()

	SligWolf_Addons.BASE_ADDON = SligWolf_Addons.GetAddon("base")
end)

if not status then
	-- In case of an error, destroy the corrupted SW addon system
	table.Empty(SligWolf_Addons)

	if istable(_G.SligWolf_Addons) then
		table.Empty(_G.SligWolf_Addons)
	end

	_G.SligWolf_Addons = nil
	return
end

return true

