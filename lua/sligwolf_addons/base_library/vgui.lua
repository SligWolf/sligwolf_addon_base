local SligWolf_Addons = SligWolf_Addons
if not SligWolf_Addons then
	return
end

if SligWolf_Addons:ReloadAddonSystem() then
	return
end

local function loadVgui(name)
	local path = string.format("sligwolf_addons/base_library/vgui/%s.lua", name)

	if SERVER then
		SligWolf_Addons.AddCSLuaFile(path)
		return
	end

	SligWolf_Addons.Include(path)
end

loadVgui("ctrlnumpad")

return true

