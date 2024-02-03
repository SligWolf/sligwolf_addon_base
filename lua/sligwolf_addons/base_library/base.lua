AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Base = SligWolf_Addons.Base or {}
table.Empty(SligWolf_Addons.Base)

local LIB = SligWolf_Addons.Base

function LIB.ExtendBaseObjectTable(objectTable)
	local TMP_SLIGWOLF_BASE_OBJ = SLIGWOLF_BASE_OBJ
	SLIGWOLF_BASE_OBJ = {}

	local state = SligWolf_Addons.Include("sligwolf_addons/base_library/baseobject.lua")

	table.Merge(objectTable, SLIGWOLF_BASE_OBJ)

	SLIGWOLF_BASE_OBJ = TMP_SLIGWOLF_BASE_OBJ

	return state
end

return true

