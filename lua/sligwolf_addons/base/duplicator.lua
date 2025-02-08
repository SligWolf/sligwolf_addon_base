AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SLIGWOLF_ADDON then
	SligWolf_Addons.AutoLoadAddon(function() end)
	return
end

local LIBDuplicator = SligWolf_Addons.Duplicator
local LIBEntities = SligWolf_Addons.Entities

function SLIGWOLF_ADDON:RegisterEntityDuplicatorModifier(ent, params)
	if not IsValid(ent) then return end

	params = params or {}
	local name = tostring(params.name or "")

	if name == "" then
		local vehicleType = tostring(ent.sligwolf_vehicle_type or "")
		local entName = tostring(LIBEntities.GetName(ent) or "")

		name = {}

		if vehicleType ~= "" then
			table.insert(name, vehicleType)
		end

		if entName ~= "" then
			table.insert(name, entName)
		end

		name = table.concat(name, "_")
	end

	if name ~= "" then
		name = "_" .. name
	end

	name = "SW_ADDON_" .. self.Addonname .. name

	params.name = name

	LIBDuplicator.RegisterEntityDuplicatorModifier(ent, params)
end

return true

