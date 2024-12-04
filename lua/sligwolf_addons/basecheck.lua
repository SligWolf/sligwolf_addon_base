AddCSLuaFile()

--[[
	This script is to ensure that SW Base and the addon are compatible with each other.
	The user is notified with an error message in a non-spammy way if this isn't the case.

	This script is intended to be stand alone and is shipped separately in each addon.
]]

local SLIGWOLF_BASECHECK = {}

local g_commonErrorText = [[
  > https://steamcommunity.com/sharedfiles/filedetails/?id=2866238940

  If you are on a multiplayer server, please tell a server admin about this problem.
  Otherwise read the FAQ on the Workshop page carefully.
]]

function SLIGWOLF_BASECHECK.ErrorNoHaltWithStack(err, allowSpam)
	err = tostring(err or "")

	if err == "" then
		return
	end

	if not allowSpam then
		if SLIGWOLF_BASECHECK.HadError(err) then
			return
		end
	end

	ErrorNoHaltWithStack(err)

	if not allowSpam then
		SLIGWOLF_BASECHECK.MarkError(err)
	end
end

function SLIGWOLF_BASECHECK.CheckBaseAddon(allowSpam)
	if not SLIGWOLF_BASECHECK.CheckBaseAddonExist(allowSpam) then
		return false
	end

	if not SLIGWOLF_BASECHECK.CheckBaseAddonVersion(allowSpam) then
		return false
	end

	return true
end

function SLIGWOLF_BASECHECK.CheckBaseAddonExist(allowSpam)
	local SligWolf_Addons = SligWolf_Addons

	if not SligWolf_Addons then
		SLIGWOLF_BASECHECK.ErrorNoHaltWithStack(
			"[SW-ADDONS] ERROR: 'SW Base' addon needed. Get it on Workshop:\n" .. g_commonErrorText,
			allowSpam
		)
		return false
	end

	return true
end

function SLIGWOLF_BASECHECK.CheckBaseAddonVersion(allowSpam)
	local SligWolf_Addons = SligWolf_Addons

	if not SligWolf_Addons then
		return false
	end

	local currentBaseApiVersion = tostring(SligWolf_Addons.BaseApiVersion or "")
	local requiredBaseApiVersion = tostring(SLIGWOLF_BASECHECK.RequiredBaseApiVersion or "")
	local addonname = tostring(SLIGWOLF_BASECHECK.Addonname or "")

	local versionMatch = SLIGWOLF_BASECHECK.MatchVersion(currentBaseApiVersion, requiredBaseApiVersion)
	if versionMatch then
		return true
	end

	if currentBaseApiVersion == "" then
		currentBaseApiVersion = "unknown"
	else
		currentBaseApiVersion = "v" .. currentBaseApiVersion
	end

	if requiredBaseApiVersion == "" then
		requiredBaseApiVersion = "unknown"
	else
		requiredBaseApiVersion = "v" .. requiredBaseApiVersion
	end

	local addonnameFormated = ""

	if addonname == "" then
		addonnameFormated = "The version of this addon"
	else
		addonnameFormated = string.format(
			"The version of addon '%s' (%s)",
			addonname,
			requiredBaseApiVersion
		)
	end

	local err = string.format(
		"[SW-ADDONS] ERROR: %s does not match to the 'SW Base' addon version (%s).\nUpdate your local addons or use their respective Workshop versions:\n%s",
		addonnameFormated,
		currentBaseApiVersion,
		g_commonErrorText
	)

	SLIGWOLF_BASECHECK.ErrorNoHaltWithStack(err, allowSpam)
	return false
end

function SLIGWOLF_BASECHECK.CheckBaseAddonLoaded(allowSpam)
	local SligWolf_Addons = SligWolf_Addons

	if not SligWolf_Addons then
		return false
	end

	if not SligWolf_Addons.IsLoaded or not SligWolf_Addons.IsLoaded() then
		SLIGWOLF_BASECHECK.ErrorNoHaltWithStack(
			"[SW-ADDONS] ERROR: 'SW Base' addon was not loaded. Conflict, errors or too many addons? (More than ~1000 addons are not supported.)\n" .. g_commonErrorText,
			allowSpam
		)
		return false
	end

	return true
end

function SLIGWOLF_BASECHECK.CheckGameVersion()
	local SligWolf_Addons = SligWolf_Addons

	if not SligWolf_Addons then
		return false
	end

	local NEED_VERSION  = nil

	if SERVER then
		NEED_VERSION = SligWolf_Addons.MinGameVersionServer
	else
		NEED_VERSION = SligWolf_Addons.MinGameVersionClient
	end

	if not NEED_VERSION then
		return false
	end

	if VERSION > 5 and VERSION < NEED_VERSION then
		if SERVER then
			SLIGWOLF_BASECHECK.ErrorNoHaltWithStack(
				"[SW-ADDONS] ERROR: Can't load 'SW Base' addon. Your game (server) is outdated. Please update the game.",
				false
			)
		else
			SLIGWOLF_BASECHECK.ErrorNoHaltWithStack(
				"[SW-ADDONS] ERROR: Can't load 'SW Base' addon. Your game (client) is outdated. Please update the game.",
				false
			)
		end

		return false
	end

	return true
end

function SLIGWOLF_BASECHECK.DoRuntimeChecks()
	local SligWolf_Addons = SligWolf_Addons

	if not SLIGWOLF_BASECHECK.CheckBaseAddonVersion(SligWolf_Addons.IsManuallyReloading) then
		return SligWolf_Addons.ERROR_BAD_VERSION
	end

	if not SLIGWOLF_BASECHECK.CheckGameVersion() then
		return SligWolf_Addons.ERROR_BAD_GAME_VERSION
	end

	if not SLIGWOLF_BASECHECK.CheckBaseAddonLoaded() then
		return SligWolf_Addons.ERROR_NOT_LOADED
	end

	return nil
end

function SLIGWOLF_BASECHECK.HadError(err)
	err = tostring(err or "")

	if err == "" then
		return
	end

	local errors = _G.SLIGWOLF_ADDON_errorList
	if not errors then
		return false
	end

	local byKey = errors.byKey
	if not byKey then
		return false
	end

	if not byKey[err] then
		return false
	end

	return true
end

function SLIGWOLF_BASECHECK.MarkError(err)
	err = tostring(err or "")

	if err == "" then
		return
	end

	local errors = _G.SLIGWOLF_ADDON_errorList or {}
	_G.SLIGWOLF_ADDON_errorList = errors

	errors.byKey = errors.byKey or {}
	errors.ordered = errors.ordered or {}

	local byKey = errors.byKey
	local ordered = errors.ordered

	if byKey[err] then
		return
	end

	byKey[err] = true
	table.insert(ordered, err)
end

function SLIGWOLF_BASECHECK.HasErrors()
	local errors = _G.SLIGWOLF_ADDON_errorList
	if not errors then
		return false
	end

	local ordered = errors.ordered
	if not ordered then
		return false
	end

	if #ordered <= 0 then
		return false
	end

	return true
end

function SLIGWOLF_BASECHECK.GetErrors()
	local errors = _G.SLIGWOLF_ADDON_errorList
	if not errors then
		return
	end

	local ordered = errors.ordered
	if not ordered then
		return
	end

	return ordered
end

local function semanticSplit(versionString)
	versionString = tostring(versionString or "")

	local version = string.Explode(".", versionString, false)

	local major = tonumber(version[1] or 0) or 0
	local minor = tonumber(version[2] or 0) or 0
	local patch = tonumber(version[3] or 0) or 0

	return major, minor, patch
end

function SLIGWOLF_BASECHECK.MatchVersion(currentVersion, requiredVersion)
	currentVersion = tostring(currentVersion or "")
	requiredVersion = tostring(requiredVersion or "")

	if currentVersion == "" then
		return false
	end

	if requiredVersion == "" then
		return false
	end

	if currentVersion == requiredVersion then
		return true
	end

	local cMajor, cMinor, cPatch = semanticSplit(currentVersion)
	local rMajor, rMinor, rPatch = semanticSplit(requiredVersion)

	if cMajor ~= rMajor then
		return false
	end

	if cMinor < rMinor then
		return false
	end

	if cMinor > rMinor then
		return true
	end

	-- case: cMinor == rMinor
	if cPatch >= rPatch then
		return true
	end

	return false
end

if CLIENT then
	-- Tell the client user about issues they might have in the chat on connection

	local colError = Color(255, 128, 128)

	local function clearHook()
		hook.Remove("InitPostEntity", "SLIGWOLF_BASECHECK_addErrorDisplayHook")
		timer.Remove("SLIGWOLF_BASECHECK_addErrorDisplayHook_timer")
	end

	local function displayErrorsInChat()
		clearHook()

		if not SLIGWOLF_BASECHECK.HasErrors() then
			return
		end

		local errors = SLIGWOLF_BASECHECK.GetErrors()

		for i, err in ipairs(errors) do
			chat.AddText(colError, err)
		end
	end

	local function addErrorDisplayHook()
		clearHook()

		hook.Add("InitPostEntity", "SLIGWOLF_BASECHECK_addErrorDisplayHook", function()
			clearHook()

			if not SLIGWOLF_BASECHECK.HasErrors() then
				return
			end

			timer.Create("SLIGWOLF_BASECHECK_addErrorDisplayHook_timer", 1, 1, displayErrorsInChat)
		end)
	end

	addErrorDisplayHook()
end

return SLIGWOLF_BASECHECK

