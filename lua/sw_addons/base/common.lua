AddCSLuaFile()

if !SW_Addons then
	return
end

if !SW_ADDON then
	SW_Addons.AutoLoadAddon(function() end)
	return
end

include("sw_addons/base/bonemanipulation.lua")
include("sw_addons/base/camera.lua")
include("sw_addons/base/entities.lua")
include("sw_addons/base/errorhandling.lua")
include("sw_addons/base/protection.lua")
include("sw_addons/base/positioning.lua")
include("sw_addons/base/sound.lua")
include("sw_addons/base/spawnmenu.lua")
include("sw_addons/base/speedcalculation.lua")
include("sw_addons/base/timer.lua")
include("sw_addons/base/tracing.lua")
include("sw_addons/base/util.lua")
include("sw_addons/base/vehicle.lua")
include("sw_addons/base/vehicleorder.lua")
include("sw_addons/base/vehicleparts.lua")
include("sw_addons/base/vehicletrailer.lua")
include("sw_addons/base/vr.lua")