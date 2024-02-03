-- It is named "zzz_base" so it loads first on Linux
-- https://wiki.facepunch.com/gmod/Lua_Loading_Order

AddCSLuaFile()

if not SligWolf_Addons then
	include("sligwolf_addons/main.lua")
end

