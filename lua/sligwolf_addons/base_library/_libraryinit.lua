AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if SligWolf_Addons:ReloadAddonSystem() then
	return
end

SligWolf_Addons.ResetIncludeErrorState()

local function loadLib(name)
	local path = string.format("sligwolf_addons/base_library/%s.lua", name)

	SligWolf_Addons.AddCSLuaFile(path)
	SligWolf_Addons.Include(path)
end

local function callLoaderFunc(name)
	for _, sublib in pairs(SligWolf_Addons) do
		if not istable(sublib) then
			continue
		end

		if not sublib.__isLib then
			continue
		end

		local func = sublib[name]
		if not isfunction(func) then
			continue
		end

		func()

		sublib[name] = nil
	end
end

-- This helps detecting load time behavour if the game is unfocused.
-- This is only active if the code has been reloaded.
-- If it blinks, the game is ready for testing.
local function loadIndicator()
	if not CLIENT then
		return
	end

	if not SligWolf_Addons.WasReloaded then
		return
	end

	if system.HasFocus() then
		return
	end

	system.FlashWindow()
end

SligWolf_Addons.AddCSLuaFile("sligwolf_addons/base_library/baseobject.lua")

loadLib("constants")
loadLib("print")
loadLib("help")
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
loadLib("constraints")
loadLib("physics")
loadLib("position")
loadLib("entityhooks")
loadLib("duplicator")
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
loadLib("convar")
loadLib("mapping")
loadLib("model")
loadLib("thirdperson")
loadLib("vgui")

callLoaderFunc("Load")
callLoaderFunc("PostLoad")

SligWolf_Addons.Timer.NextFrame("Library_Init_FirstFrame", function()
	callLoaderFunc("FirstFrame")

	SligWolf_Addons.Timer.NextFrame("Library_Init_FirstFrame", loadIndicator)
end)

SligWolf_Addons.Hook.AddCustom("AllAddonsLoaded", "Library_Init_AllAddonsLoaded", function()
	callLoaderFunc("AllAddonsLoaded")
end, 1000)

return true

