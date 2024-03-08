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
LIB.PHYSGUN_CARRIED_MODE_DIRECT = 1
LIB.PHYSGUN_CARRIED_MODE_BODY = 2

local function cleanUpCarriedList(carriedList)
	if not carriedList then
		return
	end

	carriedList.register = carriedList.register or {}
	carriedList.entities = carriedList.entities or {}
	carriedList.players = carriedList.players or {}

	local register = carriedList.register
	local entities = carriedList.entities
	local players = carriedList.players

	table.Empty(entities)
	table.Empty(players)

	for thisEntId, registerItem in pairs(register) do
		local thisEnt = registerItem.ent

		if not IsValid(thisEnt) then
			register[thisEntId] = nil
			continue
		end

		local plyList = registerItem.ply
		if not plyList then
			register[thisEntId] = nil
			continue
		end

		for thisPlyId, thisPly in pairs(plyList) do
			if not IsValid(thisPly) then
				plyList[thisPlyId] = nil
				continue
			end

			players[thisPlyId] = thisPly
		end

		if table.IsEmpty(plyList) then
			register[thisEntId] = nil
			continue
		end

		entities[thisEntId] = thisEnt
	end
end

local function isPhysgunCarried(carriedList, ent, checkMode)
	if not carriedList then
		return false
	end

	local entities = carriedList.entities
	if not entities then
		return false
	end

	if table.IsEmpty(entities) then
		return false
	end

	if not checkMode or checkMode == LIB.PHYSGUN_CARRIED_MODE_SYSTEM then
		return true
	end

	local entId = ent:EntIndex()
	if checkMode == LIB.PHYSGUN_CARRIED_MODE_DIRECT then
		return IsValid(entities[entId])
	end

	if checkMode == LIB.PHYSGUN_CARRIED_MODE_BODY then
		local body = LIBEntities.GetNearstBody(ent)
		if not body then
			return false
		end

		for _, thisEnt in pairs(entities) do
			local thisBody = LIBEntities.GetNearstBody(thisEnt)
			if not thisBody then
				continue
			end

			if thisBody ~= body then
				continue
			end

			return true
		end

		return false
	end

	if checkMode == LIB.PHYSGUN_CARRIED_MODE_BODY then
		local body = LIBEntities.GetNearstBody(ent)
		if not body then
			return false
		end

		for _, thisEnt in pairs(entities) do
			local thisBody = LIBEntities.GetNearstBody(thisEnt)
			if not thisBody then
				continue
			end

			if thisBody ~= body then
				continue
			end

			return true
		end

		return false
	end

	if checkMode == LIB.PHYSGUN_CARRIED_MODE_PARENT then
		local body = LIBEntities.GetNearstBody(ent)
		if not body then
			return false
		end

		for _, thisEnt in pairs(entities) do
			local thisBody = LIBEntities.GetNearstBody(thisEnt)
			if not thisBody then
				continue
			end

			if thisBody ~= body then
				continue
			end

			return true
		end

		return false
	end

	error("unknown checkMode given")
	return false
end

local function markPhysgunCarried(carriedList, ent, ply)
	if not carriedList then
		return
	end

	carriedList.register = carriedList.register or {}
	local register = carriedList.register

	if IsValid(ent) then
		local entId = ent:EntIndex()

		local registerItem = register[entId] or {}
		register[entId] = registerItem

		registerItem.ent = ent

		local plyList = registerItem.ply or {}
		registerItem.ply = plyList

		if IsValid(ply) then
			local plyId = ply:EntIndex()
			plyList[plyId] = ply
		end
	end

	cleanUpCarriedList(carriedList)
end

local function unmarkPhysgunCarried(carriedList, ent, ply)
	if not carriedList then
		return
	end

	carriedList.register = carriedList.register or {}
	local register = carriedList.register

	if IsValid(ent) then
		local entId = ent:EntIndex()

		local registerItem = register[entId] or {}
		register[entId] = registerItem

		registerItem.ent = ent

		local plyList = registerItem.ply or {}
		registerItem.ply = plyList

		if IsValid(ply) then
			local plyId = ply:EntIndex()
			plyList[plyId] = nil
		end
	end

	cleanUpCarriedList(carriedList)
end

function LIB.IsPhysgunCarried(ent, checkMode)
	local root = LIBEntities.GetSuperParent(ent)
	if not IsValid(root) then
		return false
	end

	if CLIENT then
		local isPhysgunCarried = root:GetNWBool("sligwolf_isPhysgunCarried", false)

		if not isPhysgunCarried then
			return false
		end

		return true
	end

	local rootEntTable = root:SligWolf_GetTable()
	if not rootEntTable then
		return false
	end

	local carriedList = rootEntTable.isPhysgunCarriedSystem

	if not isPhysgunCarried(carriedList, ent, checkMode) then
		return false
	end

	return true
end

function LIB.GetPhysgunCarredEntities(ent)
	if not SERVER then
		return nil
	end

	local root = LIBEntities.GetSuperParent(ent)
	if not IsValid(root) then
		return nil
	end

	local rootEntTable = root:SligWolf_GetTable()
	if not rootEntTable then
		return false
	end

	local carriedList = rootEntTable.isPhysgunCarriedSystem
	if not carriedList then
		return nil
	end

	return carriedList.entities
end

function LIB.GetPhysgunCarringPlayers(ent)
	if not SERVER then
		return nil
	end

	local root = LIBEntities.GetSuperParent(ent)
	if not IsValid(root) then
		return nil
	end

	local rootEntTable = root:SligWolf_GetTable()
	if not rootEntTable then
		return false
	end

	local carriedList = rootEntTable.isPhysgunCarriedSystem
	if not carriedList then
		return nil
	end

	return carriedList.players
end

function LIB.MarkPhysgunCarried(ent, ply)
	if not SERVER then return end

	local wasCarriedByAny = LIB.IsPhysgunCarried(ent, LIB.PHYSGUN_CARRIED_MODE_SYSTEM)

	local root = LIBEntities.GetSuperParent(ent)
	if not IsValid(root) then
		return
	end

	local rootEntTable = root:SligWolf_GetTable()
	if not rootEntTable then
		return nil
	end

	rootEntTable.isPhysgunCarriedSystem = rootEntTable.isPhysgunCarriedSystem or {}
	markPhysgunCarried(rootEntTable.isPhysgunCarriedSystem, ent, ply)

	local isCarriedByAny = LIB.IsPhysgunCarried(ent, LIB.PHYSGUN_CARRIED_MODE_SYSTEM)

	if not wasCarriedByAny and isCarriedByAny then
		root:SetNWBool("sligwolf_isPhysgunCarried", true)
	end

	local systemEntities = LIBEntities.GetSystemEntities(root)

	for _, thisEnt in ipairs(systemEntities) do
		if not isfunction(thisEnt.OnPhysgunPickup) then
			continue
		end

		thisEnt:OnPhysgunPickup(ent, ply)
	end
end

function LIB.UnmarkPhysgunCarried(ent, ply)
	if not SERVER then return end

	local wasCarriedByAny = LIB.IsPhysgunCarried(ent, LIB.PHYSGUN_CARRIED_MODE_SYSTEM)

	local root = LIBEntities.GetSuperParent(ent)
	if not IsValid(root) then
		return
	end

	local rootEntTable = root:SligWolf_GetTable()
	if not rootEntTable then
		return nil
	end

	unmarkPhysgunCarried(rootEntTable.isPhysgunCarriedSystem, ent, ply)

	local isCarriedByAny = LIB.IsPhysgunCarried(ent, LIB.PHYSGUN_CARRIED_MODE_SYSTEM)

	if wasCarriedByAny and not isCarriedByAny then
		root:SetNWBool("sligwolf_isPhysgunCarried", false)
	end

	local systemEntities = LIBEntities.GetSystemEntities(root)

	for _, thisEnt in ipairs(systemEntities) do
		if not isfunction(thisEnt.OnPhysgunDrop) then
			continue
		end

		thisEnt:OnPhysgunDrop(ent, ply)
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

