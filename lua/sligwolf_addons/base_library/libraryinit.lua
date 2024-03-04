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

SligWolf_Addons.AddCSLuaFile("sligwolf_addons/base_library/baseobject.lua")

loadLib("constants")
loadLib("print")
loadLib("hook")
loadLib("timer")
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
loadLib("seat")
loadLib("vr")
loadLib("vgui")
loadLib("convar")

SligWolf_Addons.Print.Load()
SligWolf_Addons.Entities.Load()
SligWolf_Addons.Position.Load()
SligWolf_Addons.Vehicle.Load()
SligWolf_Addons.VehicleControl.Load()
SligWolf_Addons.Coupling.Load()
SligWolf_Addons.Tracer.Load()
SligWolf_Addons.Util.Load()
SligWolf_Addons.Seat.Load()
SligWolf_Addons.VR.Load()
SligWolf_Addons.Convar.Load()

return true

