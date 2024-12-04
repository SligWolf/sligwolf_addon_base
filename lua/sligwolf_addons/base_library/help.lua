AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Help = SligWolf_Addons.Help or {}
table.Empty(SligWolf_Addons.Help)

local LIB = SligWolf_Addons.Help

local LIBNet = nil

local g_helpFunction = {}
local g_emptyFunction = function() end

function LIB.AddHelp(name, callback)
	name = tostring(name or "")

	if not isfunction(callback) then
		callback = g_emptyFunction
	end

	g_helpFunction[name] = callback
end

function LIB.CallHelp(name, ply)
	name = tostring(name or "")

	if CLIENT then
		ply = LocalPlayer()
	end

	if not IsValid(ply) then
		return
	end

	if SERVER then
		LIBNet.Start("help")
			net.WriteString(name)
		LIBNet.Send(ply)
	end

	local callback = g_helpFunction[name]
	if not callback then
		return
	end

	callback(ply, name)
end

function LIB.OpenUrl(url)
	if SERVER then
		return
	end

	url = tostring(url or "")

	if url == "" then
		return
	end

	if not string.StartsWith(url, "https://steamcommunity.com/groups/SligWolfAddons/") then
		error("Attempted to open unapproved URL.")
		return
	end

	gui.OpenURL(url)
end

function LIB.Load()
	LIBNet = SligWolf_Addons.Net

	if SERVER then
		LIBNet.AddNetworkString("help")
	end

	if CLIENT then
		LIBNet.Receive("help", function(len)
			local name = net.ReadString()
			LIB.CallHelp(name)
		end)
	end

	LIB.AddHelp("", function()
		LIB.OpenUrl("https://steamcommunity.com/groups/SligWolfAddons/discussions")
	end)
end

return true

