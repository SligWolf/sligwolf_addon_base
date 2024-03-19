AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.ResetIncludeErrorState()

local function loadLib(name)
	local path = string.format("sligwolf_addons/base_library/%s.lua", name)

	SligWolf_Addons.Include(path)
end

local function callLoaders()
	for _, lib in pairs(SligWolf_Addons) do
		if not istable(lib) then
			continue
		end

		local loader = lib.Load

		if not isfunction(loader) then
			continue
		end

		loader()
	end
end

SligWolf_Addons.AddCSLuaFile("sligwolf_addons/base_library/baseobject.lua")

loadLib("constants")
loadLib("print")
loadLib("hook")
loadLib("meta")
loadLib("timer")
loadLib("debug")
loadLib("util")
loadLib("base")
loadLib("bones")
loadLib("camera")
loadLib("entities")
loadLib("position")
loadLib("entityhooks")
loadLib("tracer")
loadLib("vehiclecontrol")
loadLib("coupling")
loadLib("font")
loadLib("net")
loadLib("protection")
loadLib("spawnmenu")
loadLib("vehicle")
loadLib("velocity")
loadLib("physgun")
loadLib("seat")
loadLib("rail")
loadLib("trackassambler")
loadLib("vr")
loadLib("vgui")
loadLib("convar")

callLoaders()

return true

