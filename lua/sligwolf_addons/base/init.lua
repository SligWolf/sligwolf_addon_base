AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SLIGWOLF_ADDON then
	SligWolf_Addons.AutoLoadAddon(function() end)
	return
end

SLIGWOLF_ADDON.Author = "SligWolf"
SLIGWOLF_ADDON.NiceName = "Base"
SLIGWOLF_ADDON.Version = SligWolf_Addons.BaseVersion

return true
