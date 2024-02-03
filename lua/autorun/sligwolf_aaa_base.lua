-- It is named "aaa_base" so it loads first on Windows
-- https://wiki.facepunch.com/gmod/Lua_Loading_Order

AddCSLuaFile()

if not SligWolf_Addons then
	include("sligwolf_addons/main.lua")
end

