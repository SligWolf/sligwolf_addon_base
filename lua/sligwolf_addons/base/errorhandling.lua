AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SLIGWOLF_ADDON then
	SligWolf_Addons.AutoLoadAddon(function() end)
	return
end

local CONSTANTS = SligWolf_Addons.Constants

local LIBPrint = SligWolf_Addons.Print

local function extendErrorFormat(format, addon)
	format = tostring(format or "")

	local addonname = tostring(addon.NiceName or addon.Addonname or "")
	if addonname == "" then
		addonname = "Unknown Addon"
	end

	addonname = LIBPrint.FormatSafe(addonname)

	format = string.format("[%s] %s", addonname, format)
	return format
end

function SLIGWOLF_ADDON:Error(format, ...)
	format = extendErrorFormat(format, self)
	LIBPrint.Error(format, ...)
end

function SLIGWOLF_ADDON:ErrorNoHalt(format, ...)
	format = extendErrorFormat(format, self)
	LIBPrint.ErrorNoHalt(format, ...)
end

function SLIGWOLF_ADDON:ErrorNoHaltWithStack(format, ...)
	format = extendErrorFormat(format, self)
	LIBPrint.ErrorNoHaltWithStack(format, ...)
end

function SLIGWOLF_ADDON:CallFunctionWithErrorNoHalt(func, ...)
	if not isfunction(func) then
		return false, nil
	end

	if CONSTANTS.DEBUG_ERROR then
		func(...)
		return true
	end

	local status, errOrResult = pcall(func, ...)

	if status then
		return true, errOrResult
	end

	errOrResult = tostring(errOrResult or "")
	if errOrResult == "" then
		return false, nil
	end

	self:ErrorNoHaltWithStack(errOrResult)
	return false, nil
end

function SLIGWOLF_ADDON:CallAddonFunctionWithErrorNoHalt(addonFunc, ...)
	if isstring(addonFunc) then
		addonFunc = self[addonFunc]
	end

	if not isfunction(addonFunc) then
		return false, nil
	end

	return self:CallFunctionWithErrorNoHalt(addonFunc, self, ...)
end

return true

