AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Protection = SligWolf_Addons.Protection or {}
table.Empty(SligWolf_Addons.Protection)

local LIB = SligWolf_Addons.Protection
local LIBHook = SligWolf_Addons.Hook

function LIB.CheckAllowUse(ent, ply)
	if not IsValid(ent) then return false end
	if not IsValid(ply) then return false end

	local allowuse = true

	if ent.CPPICanUse then
		allowuse = ent:CPPICanUse(ply) or false
	end

	return allowuse
end

local function CantTouch(ply, ent)
	if not IsValid(ply) then return end
	if not IsValid(ent) then return end
	if ent.SLIGWOLF_Blockedprop then return false end
end

LIBHook.Add("PhysgunPickup", "Library_Protection_CantTouch", CantTouch, 10000)

local function CantPickUp(ply, ent)
	if not IsValid(ply) then return end
	if not IsValid(ent) then return end
	if ent.SLIGWOLF_Cantpickup then return false end
end

LIBHook.Add("AllowPlayerPickup", "Library_Protection_CantPickUp", CantPickUp, 10000)

local function CantUnfreeze(ply, ent)
	if not IsValid(ply) then return end
	if not IsValid(ent) then return end
	if ent.SLIGWOLF_NoUnfreeze then return false end
end

LIBHook.Add("CanPlayerUnfreeze", "Library_Protection_CantUnfreeze", CantUnfreeze, 10000)

local function CanTool(ply, tr, tool)
	if not IsValid(ply) then return end

	local ent = tr.Entity
	if ent.SLIGWOLF_BlockAllTools then return false end

	local tb = ent.SLIGWOLF_BlockTool

	if istable(tb) then
		if tb[tool] then
			return false
		end
	end

	if ent.SLIGWOLF_AllowOnlyThisTool == tool then
		return false
	end
end

LIBHook.Add("CanTool", "Library_Protection_CanTool", CanTool, 10000)

local function CanToolReload(ply, tr, tool)
	if not IsValid(ply) then return end

	local ent = tr.Entity
	local tb = ent.SLIGWOLF_DenyToolReload

	if istable(tb) then
		if tb[tool] then
			if ply:KeyPressed(IN_RELOAD) then return false end
		end
	end
end

LIBHook.Add("CanTool", "Library_Protection_CanToolReload", CanToolReload, 10010)

return true

