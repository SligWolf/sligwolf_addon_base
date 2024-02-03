AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SLIGWOLF_ADDON then
	SligWolf_Addons.AutoLoadAddon(function() end)
	return
end

local LIBUtil = SligWolf_Addons.Util

function SLIGWOLF_ADDON:IsDeveloper()
	--MsgN("DEPRECATED: Use SligWolf_Addons.Util.IsDeveloper instead")
	return LIBUtil.IsDeveloper()
end

return true

