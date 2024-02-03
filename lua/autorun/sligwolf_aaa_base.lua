-- It is named "aaa_base" so it loads first on Windows
-- https://wiki.facepunch.com/gmod/Lua_Loading_Order

AddCSLuaFile()

if !SW_Addons then
	include("sw_addons/init.lua")
end