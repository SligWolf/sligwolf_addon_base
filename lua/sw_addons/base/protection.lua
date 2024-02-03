AddCSLuaFile()

if !SW_Addons then
	return
end

if !SW_ADDON then
	SW_Addons.AutoLoadAddon(function() end)
	return
end

local function CantTouch(ply, ent)
    if !IsValid(ply) then return end
    if !IsValid(ent) then return end
    if ent.__SW_Blockedprop then return false end
end
hook.Remove("PhysgunPickup", "SW_Common_CantTouch")
hook.Add("PhysgunPickup", "SW_Common_CantTouch", CantTouch)

local function CantPickUp(ply, ent)
    if !IsValid(ply) then return end
    if !IsValid(ent) then return end
    if ent.__SW_Cantpickup then return false end
end
hook.Remove("AllowPlayerPickup", "SW_Common_CantPickUp")
hook.Add("AllowPlayerPickup", "SW_Common_CantPickUp", CantPickUp)

local function CantUnfreeze(ply, ent)
    if !IsValid(ply) then return end
	if !IsValid(ent) then return end
	if ent.__SW_NoUnfreeze then return false end
end
hook.Remove("CanPlayerUnfreeze", "SW_Common_CantUnfreeze")
hook.Add("CanPlayerUnfreeze", "SW_Common_CantUnfreeze", CantUnfreeze)

local function Tool(ply, tr, tool)
    if !IsValid(ply) then return end
	
	local ent = tr.Entity
	debugoverlay.Text(tr.HitPos, tostring(tool), 3, false) 
	
	if ent.__SW_BlockAllTools then return false end
	
	local tb = ent.__SW_BlockTool
	
	if istable(tb) then
		if tb[tool] then
			return false
		end
	end
	
	if ent.__SW_AllowOnlyThisTool == tool then 
		return false
	end
end
hook.Remove("CanTool", "SW_Common_Tool")
hook.Add("CanTool", "SW_Common_Tool", Tool)

local function ToolReload(ply, tr, tool)
    if !IsValid(ply) then return end

	local ent = tr.Entity
	local tb = ent.__SW_DenyToolReload
	
	if istable(tb) then
		if tb[tool] then
			if ply:KeyPressed(IN_RELOAD) then return false end
		end
	end
end
hook.Remove("CanTool", "SW_Common_ToolReload")
hook.Add("CanTool", "SW_Common_ToolReload", ToolReload)

function SW_ADDON:CheckAllowUse(ent, ply)
	if !IsValid(ent) then return false end
	if !IsValid(ply) then return false end
	
	local allowuse = true
	
    if ent.CPPICanUse then
		allowuse = ent:CPPICanUse(ply) or false
	end
	
    return allowuse
end