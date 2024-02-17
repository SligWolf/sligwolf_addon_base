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

	if ent.sligwolf_blockedprop then
		return false
	end

	if ent:GetNWBool("sligwolf_blockedprop", false) then
		return false
	end
end

LIBHook.Add("PhysgunPickup", "Library_Protection_CantTouch", CantTouch, 10000)

local function CantPickUp(ply, ent)
	if not IsValid(ply) then return end
	if not IsValid(ent) then return end

	if ent.sligwolf_noPickup then
		return false
	end

	if ent:GetNWBool("sligwolf_noPickup", false) then
		return false
	end
end

LIBHook.Add("AllowPlayerPickup", "Library_Protection_CantPickUp", CantPickUp, 10000)

local function CantUnfreeze(ply, ent)
	if not IsValid(ply) then return end
	if not IsValid(ent) then return end

	if ent.sligwolf_noUnfreeze then
		return false
	end

	if ent:GetNWBool("sligwolf_noUnfreeze", false) then
		return false
	end
end

LIBHook.Add("CanPlayerUnfreeze", "Library_Protection_CantUnfreeze", CantUnfreeze, 10000)

local function CanTool(ply, trace, mode, tool, button)
	if not IsValid(ply) then return end

	local ent = trace.Entity
	if not IsValid(ent) then return end

	if ent.sligwolf_blockAllTools then
		return false
	end

	if ent:GetNWBool("sligwolf_blockAllTools", false) then
		return false
	end

	local tb = ent.sligwolf_blockTool

	if istable(tb) then
		if tb[mode] then
			return false
		end
	end

	if ent.sligwolf_allowOnlyThisTool == tool then
		return false
	end
end

LIBHook.Add("CanTool", "Library_Protection_CanTool", CanTool, 10000)

local function CanToolReload(ply, trace, mode, tool, button)
	if not IsValid(ply) then return end

	-- reload case
	if button ~= 3 then return end

	local ent = trace.Entity
	if not IsValid(ent) then return end

	local tb = ent.sligwolf_denyToolReload

	if not istable(tb) then return end
	if not tb[mode] then return end

	return false
end

LIBHook.Add("CanTool", "Library_Protection_CanToolReload", CanToolReload, 10010)

return true

