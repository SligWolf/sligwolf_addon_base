AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SLIGWOLF_ADDON then
	SligWolf_Addons.AutoLoadAddon(function() end)
	return
end

local SligWolf_Addons = SligWolf_Addons
local SpawnmenuLIB = SligWolf_Addons.Spawnmenu

local g_allAddonCategoryName = "All"
local g_allAddonCategory = {
	order = -1000000,
	icon = "icon16/world.png"
}

function SLIGWOLF_ADDON:AddSpawnMenuItemAddonCategory(itemClass, name, obj)
	local addonName = self.Addonname

	SpawnmenuLIB.AddSpawnMenuItemAddonCategory(addonName, itemClass, name, obj)
end

SLIGWOLF_ADDON:AddSpawnMenuItemAddonCategory("prop", g_allAddonCategoryName, g_allAddonCategory)
SLIGWOLF_ADDON:AddSpawnMenuItemAddonCategory("entity", g_allAddonCategoryName, g_allAddonCategory)
SLIGWOLF_ADDON:AddSpawnMenuItemAddonCategory("npc", g_allAddonCategoryName, g_allAddonCategory)
SLIGWOLF_ADDON:AddSpawnMenuItemAddonCategory("weapon", g_allAddonCategoryName, g_allAddonCategory)
SLIGWOLF_ADDON:AddSpawnMenuItemAddonCategory("vehicle", g_allAddonCategoryName, g_allAddonCategory)

function SLIGWOLF_ADDON:AddPlayerModel(name, playerModel, vHandsModel, skin, bodygroup)
	SpawnmenuLIB.AddPlayerModel(name, playerModel, vHandsModel, skin, bodygroup)
end

function SLIGWOLF_ADDON:AddProp(model, obj)
	obj = obj or {}

	local addonName = tostring(obj.addonName or "")
	if addonName == "" then
		addonName = self.Addonname
	end

	SpawnmenuLIB.AddProp(addonName, model, obj)
end

function SLIGWOLF_ADDON:AddEntity(spawnname, obj)
	obj = obj or {}

	local addonName = tostring(obj.addonName or "")
	if addonName == "" then
		addonName = self.Addonname
	end

	SpawnmenuLIB.AddEntity(addonName, spawnname, obj)
end

function SLIGWOLF_ADDON:AddWeapon(spawnname, obj)
	obj = obj or {}

	local addonName = tostring(obj.addonName or "")
	if addonName == "" then
		addonName = self.Addonname
	end

	SpawnmenuLIB.AddWeapon(addonName, spawnname, obj)
end

function SLIGWOLF_ADDON:AddNPC(spawnname, obj)
	obj = obj or {}

	local addonName = tostring(obj.addonName or "")
	if addonName == "" then
		addonName = self.Addonname
	end

	SpawnmenuLIB.AddNPC(addonName, spawnname, obj)
end

function SLIGWOLF_ADDON:AddVehicle(spawnname, vehiclescript, obj)
	spawnname = tostring(spawnname or "")
	if spawnname == "" then
		error("no spawnname")
		return
	end

	obj = obj or {}

	local model = tostring(obj.model or "")
	if model == "" then
		error("no model")
		return
	end

	local addonName = tostring(obj.addonName or "")
	if addonName == "" then
		addonName = self.Addonname
	end

	SpawnmenuLIB.AddVehicle(addonName, spawnname, vehiclescript, obj)

	self.RegisterdVehicleSpawnnamesByModel = self.RegisterdVehicleSpawnnamesByModel or {}

	if not self.RegisterdVehicleSpawnnamesByModel[model] then
		self.RegisterdVehicleSpawnnamesByModel[model] = spawnname
	end
end

return true

