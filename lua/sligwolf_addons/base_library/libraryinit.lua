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

local function callLoaderFunc(name)
	for _, lib in pairs(SligWolf_Addons) do
		if not istable(lib) then
			continue
		end

		local func = lib[name]

		if not isfunction(func) then
			continue
		end

		func()

		lib[name] = nil
	end
end

local function callLoaders()
	callLoaderFunc("Load")
end

local function callAllAddonsLoaded()
	callLoaderFunc("AllAddonsLoaded")
end

SligWolf_Addons.AddCSLuaFile("sligwolf_addons/base_library/baseobject.lua")

loadLib("constants")
loadLib("print")
loadLib("hook")
loadLib("meta")
loadLib("detours")
loadLib("timer")
loadLib("debug")
loadLib("util")
loadLib("file")
loadLib("base")
loadLib("bones")
loadLib("camera")
loadLib("entities")
loadLib("physics")
loadLib("position")
loadLib("entityhooks")
loadLib("tracer")
loadLib("vehiclecontrol")
loadLib("coupling")
loadLib("font")
loadLib("net")
loadLib("protection")
loadLib("spamprotection")
loadLib("spawnmenu")
loadLib("vehicle")
loadLib("velocity")
loadLib("physgun")
loadLib("seat")
loadLib("rail")
loadLib("trackasm")
loadLib("vr")
loadLib("wire")
loadLib("vgui")
loadLib("convar")

callLoaders()

SligWolf_Addons.Hook.Add("SLIGWOLF_AllAddonsLoaded", "Library_Init_AllAddonsLoaded", callAllAddonsLoaded, 1000)

return true

