local SligWolf_Addons = _G.SligWolf_Addons
if not SligWolf_Addons then
	return
end

local LIB = SligWolf_Addons:NewLib("Base")

function LIB.ExtendBaseObjectTable(objectTable)
	local TMP_SLIGWOLF_BASE_OBJ = SLIGWOLF_BASE_OBJ
	SLIGWOLF_BASE_OBJ = {}

	local state = SligWolf_Addons.Include("sligwolf_addons/base_library/baseobject.lua")

	table.Merge(objectTable, SLIGWOLF_BASE_OBJ)

	SLIGWOLF_BASE_OBJ = TMP_SLIGWOLF_BASE_OBJ

	return state
end

return true

