AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SLIGWOLF_ADDON then
	SligWolf_Addons.AutoLoadAddon(function() end)
	return
end

SligWolf_Addons.Include("sligwolf_addons/base/util.lua")
SligWolf_Addons.Include("sligwolf_addons/base/entities.lua")
SligWolf_Addons.Include("sligwolf_addons/base/duplicator.lua")
SligWolf_Addons.Include("sligwolf_addons/base/errorhandling.lua")
SligWolf_Addons.Include("sligwolf_addons/base/soundfunctions.lua")
SligWolf_Addons.Include("sligwolf_addons/base/sound.lua")
SligWolf_Addons.Include("sligwolf_addons/base/spawnmenu.lua")
SligWolf_Addons.Include("sligwolf_addons/base/timer.lua")
SligWolf_Addons.Include("sligwolf_addons/base/vehicle.lua")
SligWolf_Addons.Include("sligwolf_addons/base/vehiclecontrol.lua")
SligWolf_Addons.Include("sligwolf_addons/base/vehicleparts.lua")
SligWolf_Addons.Include("sligwolf_addons/base/lights.lua")
SligWolf_Addons.Include("sligwolf_addons/base/trackasm_adapter.lua")

SLIGWOLF_ADDON:TrackAssamblerAddContent()

return true

