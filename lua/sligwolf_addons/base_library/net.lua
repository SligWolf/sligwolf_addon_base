AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Net = SligWolf_Addons.Net or {}
table.Empty(SligWolf_Addons.Net)

local LIB = SligWolf_Addons.Net

local g_nameprefix = "SLIGWOLF_NW_"
local g_maxIdentifierLen = 44

local function getName(identifier)
	identifier = g_nameprefix .. tostring(identifier or "")

	local len = #identifier
	assert(len < g_maxIdentifierLen, string.format("identifier '%s' must shorter than %i chars, got %i chars", identifier, g_maxIdentifierLen, len))

	return identifier
end

function LIB.AddNetworkString(identifier)
	if CLIENT then return end

	local name = getName(identifier)

	util.AddNetworkString(name)
end

function LIB.Start(identifier, ...)
	local name = getName(identifier)

	return net.Start(name, ...)
end

-- function LIB.Start(identifier, ...)
-- 	local name = getName(identifier)

-- 	return net.Start(name, ...)
-- end

return true

