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

local g_trackasmlib = nil

function LIB.Exist()
	local trackasmlib = g_trackasmlib or _G.trackasmlib
	if not istable(trackasmlib) then return false end

	local isEmptyFunc = trackasmlib.IsEmpty
	if not isfunction(isEmptyFunc) then return false end

	local synchronizeDSVFunc = trackasmlib.SynchronizeDSV
	if not isfunction(synchronizeDSVFunc) then return false end

	return trackasmlib
end

function LIB.GetLib()
	return g_trackasmlib
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

