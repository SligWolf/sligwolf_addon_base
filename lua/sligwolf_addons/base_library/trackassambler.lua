AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Trackassambler = SligWolf_Addons.Trackassambler or {}
table.Empty(SligWolf_Addons.Trackassambler)

local LIB = SligWolf_Addons.Trackassambler

local g_trackasmlib = nil

function LIB.Exist()
	if not LIB.GetLib() then return false end
	return true
end

function LIB.GetLib()
	local trackasmlib = g_trackasmlib or _G.trackasmlib
	if not istable(trackasmlib) then return nil end

	local isEmptyFunc = trackasmlib.IsEmpty
	if not isfunction(isEmptyFunc) then return nil end

	local synchronizeDSVFunc = trackasmlib.SynchronizeDSV
	if not isfunction(synchronizeDSVFunc) then return nil end

	return trackasmlib
end

return true

