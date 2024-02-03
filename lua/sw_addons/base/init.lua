AddCSLuaFile()

if !SW_Addons then
	return
end

if !SW_ADDON then
	SW_Addons.AutoLoadAddon(function() end)
	return
end

SW_ADDON.Author = "SligWolf"
SW_ADDON.NiceName = "Base"
SW_ADDON.Version = SW_Addons.BaseVersion