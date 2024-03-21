-- It is named "sligwolf_aaa_base" so it loads first among all sligwolf addons.
-- https://wiki.facepunch.com/gmod/Lua_Loading_Order

AddCSLuaFile()

if SligWolf_Addons then
	return
end

include("sligwolf_addons/main.lua")

