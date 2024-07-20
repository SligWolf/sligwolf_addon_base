-- It is named "zzz_" so it loads after most addons.
-- https://wiki.facepunch.com/gmod/Lua_Loading_Order

-- This is used to integrate our content into other addons that supports it via their APIs.

AddCSLuaFile()

local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if SligWolf_Addons.CallAddonsLoadedEvent then
	return
end

if SligWolf_Addons.CallAllAddonsLoadedHook then
	SligWolf_Addons.CallAllAddonsLoadedHook()
end

