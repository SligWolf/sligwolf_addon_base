AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.meta = SligWolf_Addons.meta or {}
table.Empty(SligWolf_Addons.meta)

local LIB = SligWolf_Addons.meta

function LIB.BuildMetaEntity()
	local META = FindMetaTable("Entity")

	if not META then
		error("Couldn't find Entity metatable!")
		return
	end

	local getTable = META.GetTable

	LIB.BuildGenericMetaFunctions(META, getTable)
end

function LIB.BuildGenericMetaFunctions(META, getTable)
	META.SligWolf_GetTable = function(thisEnt)
		local entTable = getTable(thisEnt)

		local tab = entTable.sligwolf_internalTable

		if tab then
			return tab
		end

		tab = {}
		entTable.sligwolf_internalTable = tab

		return tab
	end
end

LIB.BuildMetaEntity()

return true

