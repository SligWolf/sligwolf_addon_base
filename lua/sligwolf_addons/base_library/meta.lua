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

function LIB.BuildMetaPlayer()
	local META = FindMetaTable("Player")

	if not META then
		error("Couldn't find Player metatable!")
		return
	end

	LIB.BuildGenericMetaFunctions(META)
end

function LIB.BuildMetaEntity()
	local META = FindMetaTable("Entity")

	if not META then
		error("Couldn't find Entity metatable!")
		return
	end

	LIB.BuildGenericMetaFunctions(META)
end

function LIB.BuildGenericMetaFunctions(META)
	META.SligWolf_GetTable = function(thisEnt)
		local tab = thisEnt.sligwolf_internalTable

		if tab then
			return tab
		end

		tab = {}
		thisEnt.sligwolf_internalTable = tab

		return tab
	end
end

LIB.BuildMetaPlayer()
LIB.BuildMetaEntity()

return true

