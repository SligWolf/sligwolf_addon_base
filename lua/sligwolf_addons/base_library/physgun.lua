AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Physgun = SligWolf_Addons.Physgun or {}
table.Empty(SligWolf_Addons.Physgun)

local LIB = SligWolf_Addons.Physgun

local LIBEntities = nil

LIB.PHYSGUN_CARRIED_MODE_SYSTEM = 0
LIB.PHYSGUN_CARRIED_MODE_BODY = 1
LIB.PHYSGUN_CARRIED_MODE_DIRECT = 2

local function cleanUpCarriedList(carriedList)
	if not carriedList then
		return
	end

	for thisPlyId, thisPly in pairs(carriedList) do
		if IsValid(thisPly) then
			continue
		end

		carriedList[thisPlyId] = nil
	end
end

local function isPhysgunCarried(carriedList)
	if not carriedList then
		return false
	end

	if table.IsEmpty(carriedList) then
		return false
	end

	return true
end

local function markPhysgunCarried(carriedList, ply)
	if not carriedList then
		return
	end

	cleanUpCarriedList(carriedList)

	if IsValid(ply) then
		local plyId = ply:EntIndex()
		carriedList[plyId] = ply
	end
end

local function unmarkPhysgunCarried(carriedList, ply)
	if not carriedList then
		return
	end

	if IsValid(ply) then
		local plyId = ply:EntIndex()
		carriedList[plyId] = nil
	end

	cleanUpCarriedList(carriedList)
end

function LIB.IsPhysgunCarried(ent, checkMode)
	if CLIENT then
		local root = LIBEntities.GetSuperParent(ent)
		if not IsValid(root) then
			return false
		end

		local isPhysgunCarried = root:GetNWBool("sligwolf_isPhysgunCarried", false)

		if not isPhysgunCarried then
			return false
		end

		return true
	end

	local carriedList = LIB.GetPhysgunCarringPlayers(ent, checkMode)
	if not isPhysgunCarried(carriedList) then
		return false
	end

	return true
end

function LIB.GetPhysgunCarringPlayers(ent, checkMode)
	if not SERVER then
		return nil
	end

	if not checkMode then
		checkMode = LIB.PHYSGUN_CARRIED_MODE_SYSTEM
	end

	if checkMode == LIB.PHYSGUN_CARRIED_MODE_DIRECT then
		return ent.sligwolf_isPhysgunCarriedDirectly
	end

	if checkMode == LIB.PHYSGUN_CARRIED_MODE_BODY then
		local body = LIBEntities.GetNearstBody(ent)
		if not IsValid(body) then
			return nil
		end

		return body.sligwolf_isPhysgunCarriedBody
	end

	if checkMode == LIB.PHYSGUN_CARRIED_MODE_SYSTEM then
		local root = LIBEntities.GetSuperParent(ent)
		if not IsValid(root) then
			return nil
		end

		return root.sligwolf_isPhysgunCarried
	end

	error("unknown checkMode given")
	return nil
end

function LIB.MarkPhysgunCarried(ent, ply)
	if not SERVER then return end

	local wasCarriedByAny = LIB.IsPhysgunCarried(ent, LIB.PHYSGUN_CARRIED_MODE_SYSTEM)

	ent.sligwolf_isPhysgunCarriedDirectly = ent.sligwolf_isPhysgunCarriedDirectly or {}
	markPhysgunCarried(ent.sligwolf_isPhysgunCarriedDirectly, ply)

	local root = LIBEntities.GetSuperParent(ent)
	if not IsValid(root) then
		return
	end

	local body = LIBEntities.GetNearstBody(ent)
	if IsValid(body) then
		body.sligwolf_isPhysgunCarriedBody = body.sligwolf_isPhysgunCarriedBody or {}
		markPhysgunCarried(body.sligwolf_isPhysgunCarriedBody, ply)
	end

	root.sligwolf_isPhysgunCarried = root.sligwolf_isPhysgunCarried or {}
	markPhysgunCarried(root.sligwolf_isPhysgunCarried, ply)

	if not wasCarriedByAny then
		root:SetNWBool("sligwolf_isPhysgunCarried", true)
	end

	local systemEntities = LIBEntities.GetSystemEntities(root)

	for _, thisEnt in ipairs(systemEntities) do
		if not isfunction(thisEnt.OnPhysgunPickup) then
			continue
		end

		thisEnt:OnPhysgunPickup(ent == thisEnt, ply)
	end
end

function LIB.UnmarkPhysgunCarried(ent, ply)
	if not SERVER then return end

	local wasCarriedByAny = LIB.IsPhysgunCarried(ent, LIB.PHYSGUN_CARRIED_MODE_SYSTEM)

	unmarkPhysgunCarried(ent.sligwolf_isPhysgunCarriedDirectly, ply)

	local root = LIBEntities.GetSuperParent(ent)
	if not IsValid(root) then
		return
	end

	local body = LIBEntities.GetNearstBody(ent)
	if IsValid(body) then
		unmarkPhysgunCarried(body.sligwolf_isPhysgunCarriedBody, ply)
	end

	unmarkPhysgunCarried(root.sligwolf_isPhysgunCarried, ply)

	if wasCarriedByAny then
		root:SetNWBool("sligwolf_isPhysgunCarried", false)
	end

	local systemEntities = LIBEntities.GetSystemEntities(root)

	for _, thisEnt in ipairs(systemEntities) do
		if not isfunction(thisEnt.OnPhysgunDrop) then
			continue
		end

		thisEnt:OnPhysgunDrop(ent == thisEnt, ply)
	end
end

function LIB.Load()
	LIBEntities = SligWolf_Addons.Entities

	if SERVER then
		local LIBHook = SligWolf_Addons.Hook

		local function MarkPhysgunCarried(ply, ent)
			if not IsValid(ent) then return end
			if not ent.sligwolf_entity then return end
			if not ent.sligwolf_physEntity then return end

			LIB.MarkPhysgunCarried(ent, ply)
		end

		LIBHook.Add("PhysgunPickup", "Library_Physgun_MarkPhysgunCarried", MarkPhysgunCarried, 30000)

		local function UnmarkPhysgunCarried(ply, ent)
			if not IsValid(ent) then return end
			if not ent.sligwolf_entity then return end
			if not ent.sligwolf_physEntity then return end

			LIB.UnmarkPhysgunCarried(ent, ply)
		end

		LIBHook.Add("PhysgunDrop", "Library_Physgun_UnmarkPhysgunCarried", UnmarkPhysgunCarried, 30000)
	end
end

return true

