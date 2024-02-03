AddCSLuaFile()

--[[
	Rules for this addon:
		1)  Use this addon as a legacy addon (folder version) for your server ONLY,
			if you don't wish updates from the official workshop addon.
		2)  The following code protects against loading stolen SW addons 
			and fake SW addons that maybe contain malicious code. 
			Leave this code as it is, do not support such a bad behavior.
]]

SW_Addons = SW_Addons or {}
SW_Addons.BaseVersion = "2023-07-28"

SW_Addons.Addondata = SW_Addons.Addondata or {}
SW_Addons.AddondataSorted = nil

SW_Addons.ERROR = "ERROR"
SW_Addons.ERROR_BAD_VERSION = "ERROR_BAD_VERSION"
SW_Addons.ERROR_CONFLICTING_ADDON = "ERROR_CONFLICTING_ADDON"
SW_Addons.ERROR_UNKNOWN_ADDON = "ERROR_UNKNOWN_ADDON"

SW_Addons.IsManuallyReloading = false

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
}

local g_WorkshopIDCache = {}
local g_WorkshopAddonsCache = {}
local g_WorkshopAddonsFilesCache = {}
local g_FunctionPathCache = {}

local g_WorkshopIDWhitelist = {
	["base"] = "2866238940",
	["slig"] = "104914708",
	["hovercraft"] = "105010554",
	["hotrod"] = "105011898",
	["powerboat"] = "105140639",
	["bluex11"] = "105142403",
	["motorbike"] = "105144348",
	["fcc"] = "105146169",
	["tank"] = "105147125",
	["train"] = "105147817",
	["gokart"] = "105150660",
	["loopings"] = "105780180",
	["snowmobile"] = "105781997",
	["seat"] = "107865704",
	["hands"] = "113764710",
	["tram"] = "114589891",
	["thirdteen"] = "119968146",
	["bluex13"] = "122248418",
	["thirdteennpc"] = "123685947",
	["slignpc"] = "123686602",
	["bus"] = "130227747",
	["western"] = "132174849",
	["rerailer"] = "132843280",
	["oldbots"] = "147802259",
	["modelpack"] = "147812851",
	["minitrains"] = "149759773",
	["bgcar"] = "173717507",
	["grenadelauncher"] = "175664622",
	["limousine"] = "180567595",
	["siren"] = "337151920",
	["truck"] = "194583946",
	["rustyer"] = "219898030",
	["racecar"] = "230317839",
	["ferry"] = "239910715",
	["bluex14"] = "256428548",
	["crane"] = "263027561",
	["forklift"] = "264931812",
	["cranetrain"] = "270201182",
	["leotank"] = "288026358",
	["bluex12"] = "292674440",
	["polizei"] = "183178671",
	["trabant"] = "342855123",
	["cranetruck"] = "357910009",
	["dieselhenschel"] = "361586208",
	["autotrain"] = "366345014",
	["wagons"] = "379538128",
	["longdiesel"] = "381210427",
	["garbagetruck"] = "394277409",
	["towtruck"] = "456773274",
	["aliencutbug"] = "646068704",
	["st3tram"] = "707877689",
	["tractor"] = "1105243365",
	["bluex15"] = "1231937933",
	["jeeps"] = "1375274405",
	["tinyhoverracer"] = "1375275167",
	["orblauncher"] = "1391435350",
	["hl2weaponreplacements"] = "3008753645",
}

local g_realmText = SERVER and "server" or "client"
local g_realmColor = SERVER and Color(137, 222, 255) or Color(255, 222, 102)
local g_errorColor = Color(255, 90, 90)
local g_successColor = Color(90, 192, 90)
local g_prefixColor = Color(200, 200, 200)

local addWorkshopClientDownload = nil

if SERVER then
	local cvarAllowWorkshopDownload = CreateConVar(
		"sv_sw_addons_allow_workshop_download",
		"1",
		bit.bor(FCVAR_ARCHIVE, FCVAR_GAMEDLL),
		"Allow or disallow workshop downloads (resource.AddWorkshop()) of SW Addons for joining clients. Requires server restart. (Default: 1)",
		0,
		1
	)

	addWorkshopClientDownload = function(wsid)
		if !cvarAllowWorkshopDownload:GetBool() then return end

		resource.AddWorkshop(wsid)
	end
end

local function runWithErrorNoHalt(func, ...)
	local status, errOrResult = pcall(func, ...)
	
	if status then
		return true, errOrResult
	end
	
	errOrResult = tostring(errOrResult or "")
	if errOrResult == "" then
		return false, nil
	end
	
	ErrorNoHaltWithStack(errOrResult)
	return false, nil
end

local function inValidateSortedAddondata()
	local swAddons = _G.SW_Addons
	if !swAddons then return end

	swAddons.AddondataSorted = nil
end

local g_BuiltHooks = {}

local function buildHookCaller(functionName, hookName)
	local swAddons = _G.SW_Addons
	if !swAddons then return end

	local hookId = "sw_hookSystem_" .. hookName .. "_" .. functionName
	if g_BuiltHooks[hookId] then return end
	
	hook.Remove(hookName, hookId)
	hook.Add(hookName, hookId, function(...)
		return swAddons.CallFunctionOnAllAddons(functionName, ...)
	end)
	
	g_BuiltHooks[hookId] = true
end

local function AddHooks(swAddon)
	local addedhooks = swAddon.hooks or {}

	for functionName, hookName in pairs(g_DefaultHooks) do
		buildHookCaller(functionName, hookName)
	end
	
	for functionName, hookName in pairs(addedhooks) do
		functionName = tostring(functionName or "")
		hookName = tostring(hookName or "")
		
		if functionName == "" then continue end
		if hookName == "" then continue end
	
		buildHookCaller(functionName, hookName)
	end
end

local function GetPathOfFunction(funcobj)
	if !isfunction(funcobj) then
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
	if !path then
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
		if !wsAddon then continue end
		if !wsAddon.mounted then continue end
		if !wsAddon.downloaded then continue end
	
		local addonTitle = tostring(wsAddon.title or "")
		if addonTitle == "" then continue end

		local wsid = tostring(wsAddon.wsid or "")
		if wsid == "" then continue	end
		
		if !file.Exists(path, addonTitle) then continue end
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
	
	if !found then
		return nil
	end
	
	return g_WorkshopAddonsFilesCache[path]
end

local function GetWorkshopAddonsOfFunction(funcobj)
	local path = GetPathOfFunction(funcobj)
	if !path then
		return nil
	end
	
	local addons = GetWorkshopAddonsFromPath(path)
	if !addons then
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
	if !wsid then
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
	if !allowedWorkshopID then
		-- This addon is not whitelisted.
		return false
	end
	
	if allowedWorkshopID != wsid then
		-- This is a foreign, illegal or otherwise not approved workshop copy.
		return false
	end
	
	-- This addon is an official workshop copy.
	return true
end

local function CheckWorkshopAddon(wsAddon, name)
	if !wsAddon then
		return true
	end

	local valid = CheckWorkshopID(wsAddon.wsid, name)
	if !valid then
		return false
	end
	
	return true
end

local function CheckWorkshopAddons(wsAddons, name)
	if !wsAddons then
		return true
	end

	-- If any unapproved SW addon is mounted, we will not load this addon and its original.
	-- Both get not loaded, because we can not determine which of these 2 addons which is approved or not.
	
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
		errorCode = SW_Addons.ERROR
	end
	
	MsgCInfo(g_errorColor, text, g_errorColor, " [", errorCode, "]")
end

local function MsgCSuccess(text)
	text = tostring(text or "")
	if text == "" then return end
	
	MsgCInfo(g_realmColor, text, g_successColor, " [OK]")
end

local function MsgCUnapprovedAddons(unapprovedWsAddons, name)
	if !unapprovedWsAddons then return end

	name  = tostring(name or "")
	if name == "" then return end
	
	local errorText = string.format("Addon '%s' could not be loaded at %s!", name, g_realmText)
	MsgCError(errorText, SW_Addons.ERROR_CONFLICTING_ADDON)
	
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

function SW_Addons.LoadAddon(name, forceReload)
	name = tostring(name or "")
	if name == "" then
		return false
	end
	
	name = string.lower(name)
	name = string.Replace(name, "/", "") 
	name = string.Replace(name, "\\", "")
	
	local swAddons = _G.SW_Addons
	if !swAddons then
		return false
	end

	if swAddons.IsLoadingAddon(name) then
		return true
	end
	
	if swAddons.HasLoadedAddon(name) and !forceReload then
		return true
	end

	swAddons.Addondata = swAddons.Addondata or {}
	
	local initFile = "sw_addons/"..name.."/init.lua"
	
	local check = file.Exists(initFile, "LUA")
	if !check then
		local errorText = string.format("Unknown addon '%s' at %s!", name, g_realmText)
		MsgCError(errorText, swAddons.ERROR_UNKNOWN_ADDON)
		
		swAddons.Addondata[name] = {
			Addonname = name,
			Loaded = false,
			Loading = false,
		}
	
		return false
	end
	
	-- We check the authenticity of the workshop copy, because:
	--   1) We don't want to support or to tolerate stolen copies on the workshop.
	--   2) We want to make sure that we don't run unapproved or malicious code.
	--   3) We explicitly allow installing the addon as a legacy addon (folder version),
	--      if you want to avoid potentially unwanted auto updates from the workshop version.
	
	local wsAddons = GetWorkshopAddonsFromPath("lua/"..initFile)
	if !CheckWorkshopAddons(wsAddons, name) then
		MsgCUnapprovedAddons(wsAddons, name)
		
		swAddons.Addondata[name] = {
			Addonname = name,
			Loaded = false,
			Loading = false,
		}

		return false
	end
	
	local wsid = GetWorkshopID(name)
	
	if SERVER and addWorkshopClientDownload and wsid then
		addWorkshopClientDownload(wsid)
	end

	swAddons.Addondata[name] = {
		Addonname = name,
		Loaded = false,
		Loading = true,
	}
	
	local TMP_SW_ADDON = SW_ADDON

	SW_ADDON = {}
	SW_ADDON.Addonname = name
	SW_ADDON.NetworkaddonID = "SW_"..name
	SW_ADDON.WorkshopID = wsid
	SW_ADDON.Loaded = false
	SW_ADDON.Loading = true
	
	local files = {
		"sw_addons/base/common.lua",
		"sw_addons/"..name.."/init.lua",
	}
	
	local ok = true
	local lastErrorCode = nil
	
	for _, path in ipairs(files) do
		local check = file.Exists(path, "LUA")
		if !check then
			ok = false
			continue
		end
		
		if !runWithErrorNoHalt(AddCSLuaFile, path) then
			ok = false
		end

		local loaded, errorCode = runWithErrorNoHalt(include, path)
		if !loaded or errorCode != nil then
			ok = false
			lastErrorCode = errorCode
		end
	end
	
	local func = SW_ADDON.Afterload
	if isfunction(func) then
		if !runWithErrorNoHalt(func, SW_ADDON) then
			ok = false
		end
	end

	AddHooks(SW_ADDON)
	
	local niceName = tostring(SW_ADDON.NiceName or "")
	local author = tostring(SW_ADDON.Author or "")
	local version = tostring(SW_ADDON.Version or "")
	
	if niceName != "" and version != "" then
		niceName = string.format("%s - v%s", niceName, version)
	end
	
	-- The author being empty, is a sign of the script not being loaded.
	if author == "" then
		ok = false
	end
	
	SW_ADDON.Loaded = ok
	SW_ADDON.Loading = false

	swAddons.Addondata[name] = SW_ADDON
	SW_ADDON = TMP_SW_ADDON
	
	local loadedText = ""
	local stateText = ok and "loaded" or "could not be loaded"
	
	if niceName != "" then
		loadedText = string.format("Addon '%s' (%s) %s at %s!", name, niceName, stateText, g_realmText)
	else
		loadedText = string.format("Addon '%s' %s at %s!", name, stateText, g_realmText)
	end
	
	if ok then
		MsgCSuccess(loadedText)
	else
		MsgCError(loadedText, lastErrorCode)
	end
	
	inValidateSortedAddondata()
	return true
end

function SW_Addons.GetAddons()
	local swAddons = _G.SW_Addons
	if !swAddons then return end
	if !swAddons.Addondata then return end

	return swAddons.Addondata
end

function SW_Addons.GetAddonsSorted()
	local swAddons = _G.SW_Addons
	if !swAddons then return end
	if !swAddons.Addondata then return end

	if swAddons.AddondataSorted and #swAddons.AddondataSorted > 0 then
		return swAddons.AddondataSorted
	end
	
	local addondataSorted = {}
	swAddons.AddondataSorted = nil
	
	for name, addon in SortedPairs(swAddons.Addondata) do
		if !addon then continue end
		
		local order = #addondataSorted + 1
		
		addondataSorted[order] = {
			order = order,
			name = name,
			addon = addon,
		}
	end
	
	swAddons.AddondataSorted = addondataSorted
	return swAddons.AddondataSorted
end

function SW_Addons.CallFunctionOnAllAddons(addonFunc, ...)
	local swAddons = _G.SW_Addons
	if !swAddons then return end
	if !swAddons.Addondata then return end
	
	local sortedAddondata = swAddons.GetAddonsSorted()
	local returnResult = nil
	
	for order, addonItem in ipairs(sortedAddondata) do
		if !addonItem then continue end
		
		local addon = addonItem.addon
		if !addon then continue end
		if !addon.Loaded then continue end
		
		local callAddonFunctionWithErrorNoHalt = addon.CallAddonFunctionWithErrorNoHalt
		if !isfunction(callAddonFunctionWithErrorNoHalt) then continue end
		
		local ok, result = callAddonFunctionWithErrorNoHalt(addon, addonFunc, ...)
		
		if ok and result != nil then
			returnResult = result
		end
	end

	return returnResult
end

function SW_Addons.CallFunctionOnAddon(addonname, addonFunc, ...)
	local swAddons = _G.SW_Addons
	if !swAddons then return end
	
	local addon = SW_Addons.GetAddon(addonname)
	if !addon then return end
		
	local sortedAddondata = swAddons.GetAddonsSorted()
	local returnResult = nil
	
	local callAddonFunctionWithErrorNoHalt = addon.CallAddonFunctionWithErrorNoHalt
	if !isfunction(callAddonFunctionWithErrorNoHalt) then return end

	local ok, result = callAddonFunctionWithErrorNoHalt(addon, addonFunc, ...)
	
	if ok and result != nil then
		returnResult = result
	end
	
	return returnResult
end

function SW_Addons.ReloadAllAddons()
	local swAddons = _G.SW_Addons
	if !swAddons then return end
	if !swAddons.Addondata then return end
	if !swAddons.LoadAddon then return end
	
	local sortedAddondata = swAddons.GetAddonsSorted()
	local reloadList = {}
	
	for order, addonItem in ipairs(sortedAddondata) do
		if !addonItem then continue	end
	
		reloadList[#reloadList + 1] = addonItem.name
	end
	
	local isAddonEnv = !!SW_ADDON
	
	for i, addonName in ipairs(reloadList) do
		local isBase = addonName == "base"
		local forceReload = !isBase or !isAddonEnv
	
		swAddons.LoadAddon(addonName, forceReload)
	end
end

function SW_Addons.AutoLoadAddon(funcobj)
	local swAddons = _G.SW_Addons
	if !swAddons then
		return false
	end

	if !swAddons.LoadAddon then
		return false
	end

	if !isfunction(funcobj) then
		return false
	end

	local name = GetAddonNameOfFunction(funcobj)
	local wsAddons = GetWorkshopAddonsOfFunction(funcobj)

	-- We check the authenticity of the workshop copy, because:
	--   1) We don't want to support or to tolerate stolen copies on the workshop.
	--   2) We want to make sure that we don't run unapproved or malicious code.
	--   3) We explicitly allow installing the addon as a legacy addon (folder version),
	--      if you want to avoid potentially unwanted auto updates from the workshop version.

	if !CheckWorkshopAddons(wsAddons, name) then
		MsgCUnapprovedAddons(wsAddons, name)

		return false
	end

	return swAddons.LoadAddon(name, true)
end

function SW_Addons.GetAddon(name)
	local swAddons = _G.SW_Addons
	if !swAddons then
		return nil
	end

	if !SW_Addons.HasLoadedAddon(name) then
		return nil
	end
	
	return swAddons.Addondata[name]
end

function SW_Addons.HasLoadedAddon(name)
	local swAddons = _G.SW_Addons
	if !swAddons then
		return false
	end

	if !swAddons.Addondata then
		return false
	end
	
	if !swAddons.Addondata[name] then
		return false
	end
	
	if !swAddons.Addondata[name].Loaded then
		return false
	end
	
	return true
end

function SW_Addons.IsLoadingAddon(name)
	local swAddons = _G.SW_Addons
	if !swAddons then
		return false
	end

	if !swAddons.Addondata then
		return false
	end
	
	if !swAddons.Addondata[name] then
		return false
	end
	
	if !swAddons.Addondata[name].Loading then
		return false
	end
	
	return true
end

local function OnSWBaseReload(name)
	if name != "base" then return end
	
	local swAddons = _G.SW_Addons
	if !swAddons then
		return false
	end

	swAddons.ReloadAllAddons()
	inValidateSortedAddondata()
end

if SERVER then
	util.AddNetworkString("sw_reload_addon")
	
	local function runAdminOnly(ply, func)
		if IsValid(ply) then
			if ply:IsAdmin() then
				func()
			end
			
			return
		end
	
		func()
	end
	
	concommand.Add("sv_sw_reload_addon", function(ply, cmd, args)
		local name = tostring(args[1] or "")
		
		runAdminOnly(ply, function()
			SW_Addons.IsManuallyReloading = true
			SW_Addons.LoadAddon(name, true)
			OnSWBaseReload(name)
			SW_Addons.IsManuallyReloading = false
			
			net.Start("sw_reload_addon")
				net.WriteString(name)
			net.Broadcast()
		end)
	end)
else
	net.Receive("sw_reload_addon", function(length)
		local name = net.ReadString() 
		
		SW_Addons.IsManuallyReloading = true
		SW_Addons.LoadAddon(name, true)
		OnSWBaseReload(name)
		SW_Addons.IsManuallyReloading = false
	end)
end

inValidateSortedAddondata()
include("sw_addons/base/init.lua")
inValidateSortedAddondata()