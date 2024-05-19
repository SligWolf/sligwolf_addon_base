AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Trackasm = SligWolf_Addons.Trackasm or {}
table.Empty(SligWolf_Addons.Trackasm)

local LIB = SligWolf_Addons.Trackasm
local LIBPrint = nil

local g_trackasmlib = nil
local g_version = nil
local g_versionErrorPrintedChecked = false

function LIB.Exist()
	local trackasmlib = g_trackasmlib or _G.trackasmlib
	if not istable(trackasmlib) then return false end

	local getOpVarFunc = trackasmlib.GetOpVar
	if not isfunction(getOpVarFunc) then return false end

	local isInitFunc = trackasmlib.IsInit
	if not isfunction(isInitFunc) then return false end

	if not LIB.CheckVersion() then return false end

	return true
end

function LIB.GetLib()
	return g_trackasmlib
end

function LIB.GetLibVersion()
	if g_version ~= nil then
		if not g_version then
			return nil
		end

		return g_version
	end

	local trackasmlib = g_trackasmlib or _G.trackasmlib
	if not trackasmlib then
		return nil
	end

	local success = ProtectedCall(function()
		g_version = trackasmlib.GetOpVar("TOOL_VERSION")
	end)

	if not success then
		g_version = false
		return nil
	end

	return g_version
end

function LIB.IsValidVersion()
	local version = LIB.GetLibVersion()
	if not version then
		return false
	end

	if version < "8.749" then
		return false
	end

	return true
end

function LIB.CheckVersion()
	if LIB.IsValidVersion() then
		return true
	end

	if g_versionErrorPrintedChecked then
		return false
	end

	if not LIBPrint then
		return false
	end

	g_versionErrorPrintedChecked = true
	LIBPrint.ErrorNoHalt("TrackAssemblyTool is outdated! (TOOL_VERSION < 8.749)")

	return false
end

function LIB.Load()
	LIBPrint = SligWolf_Addons.Print
end

function LIB.AllAddonsLoaded()
	g_trackasmlib = nil

	if not LIB.Exist() then
		-- ensure the Track Assembly Tool has been loaded
		return
	end

	g_trackasmlib = _G.trackasmlib
end

return true

