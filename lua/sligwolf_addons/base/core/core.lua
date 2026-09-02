AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SLIGWOLF_ADDON then
	SligWolf_Addons:ReloadAddonSystem()
	return
end

SligWolf_Addons.Include("sligwolf_addons/base/core/util.lua")
SligWolf_Addons.Include("sligwolf_addons/base/core/entities.lua")
SligWolf_Addons.Include("sligwolf_addons/base/core/duplicator.lua")
SligWolf_Addons.Include("sligwolf_addons/base/core/errorhandling.lua")
SligWolf_Addons.Include("sligwolf_addons/base/core/soundfunctions.lua")
SligWolf_Addons.Include("sligwolf_addons/base/core/spawnmenu.lua")
SligWolf_Addons.Include("sligwolf_addons/base/core/timer.lua")
SligWolf_Addons.Include("sligwolf_addons/base/core/vehicle.lua")
SligWolf_Addons.Include("sligwolf_addons/base/core/vehiclecontrol.lua")
SligWolf_Addons.Include("sligwolf_addons/base/core/vehicleparts.lua")
SligWolf_Addons.Include("sligwolf_addons/base/core/lights.lua")
SligWolf_Addons.Include("sligwolf_addons/base/core/trackasm_adapter.lua")
SligWolf_Addons.Include("sligwolf_addons/base/core/themesystem.lua")

SLIGWOLF_ADDON:TrackAssamblerAddContent()
SLIGWOLF_ADDON:SpawnmenuContentAutoInclude()

return true

