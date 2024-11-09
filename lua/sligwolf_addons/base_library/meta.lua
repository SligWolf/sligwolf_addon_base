AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Meta = SligWolf_Addons.Meta or {}
table.Empty(SligWolf_Addons.Meta)

local LIB = SligWolf_Addons.Meta

function LIB.BuildMetaEntity()
	local META = FindMetaTable("Entity")

	if not META then
		error("Couldn't find Entity metatable!")
		return
	end

	LIB.BuildGenericMetaFunctions(META)
end

function LIB.BuildGenericMetaFunctions(META)
	local getTable = META.GetTable

	local sligwolf_getTable = function(thisEnt)
		local entTable = getTable(thisEnt)

		local tab = entTable.sligwolf_internalTable

		if tab then
			return tab
		end

		tab = {}
		entTable.sligwolf_internalTable = tab

		return tab
	end

	META.SligWolf_GetTable = sligwolf_getTable

	META.SligWolf_GetAddonTable = function(thisEnt, addonname)
		local entTable = sligwolf_getTable(thisEnt)
		local addondata = entTable.addondata

		if not addondata then
			addondata = {}
			entTable.addondata = addondata
		end

		local addonEntTable = addondata[addonname]
		if addonEntTable then
			return addonEntTable
		end

		addonEntTable = {}
		addondata[addonname] = addonEntTable

		return addonEntTable
	end
end

function LIB.RemoveBadDupeData(data)
	if not data then return end

	data.sligwolf_internalTable = nil
end

LIB.BuildMetaEntity()

return true

