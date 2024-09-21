AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Entities = SligWolf_Addons.Entities or {}
table.Empty(SligWolf_Addons.Entities)

local LIB = SligWolf_Addons.Entities

local LIBUtil = nil
local LIBTimer = nil
local LIBPrint = nil
local LIBPosition = nil
local LIBMeta = nil

function LIB.Load()
	LIBUtil = SligWolf_Addons.Util
	LIBTimer = SligWolf_Addons.Timer
	LIBPrint = SligWolf_Addons.Print
	LIBPosition = SligWolf_Addons.Position
	LIBMeta = SligWolf_Addons.Meta
end

local function getCache(ent)
	local entTable = ent:SligWolf_GetTable()

	local entCache = entTable.EntCache or {}
	entTable.EntCache = entCache

	local parents = entCache.parents or {}
	entCache.parents = parents

	local children = entCache.children or {}
	entCache.children = children

	return entCache
end

LIB.GetEntityCache = getCache

local function clearChildrenCacheHelper(ent)
	if not IsValid(ent) then return end

	local cache = getCache(ent)
	if not cache then return end

	table.Empty(cache.children)
end

function LIB.ClearChildrenCache(ent)
	if not IsValid(ent) then return end

	clearChildrenCacheHelper(ent)

	local cache = getCache(ent)
	if not cache then return end

	for _, parent in pairs(cache.parents) do
		clearChildrenCacheHelper(parent)
	end
end

function LIB.ClearCache(ent)
	if not IsValid(ent) then return end

	LIB.ClearChildrenCache(ent)

	local cache = getCache(ent)
	if not cache then return end

	table.Empty(cache.parents)
end

function LIB.RemoveBadDupeData(data)
	if not data then return end

	LIBMeta.RemoveBadDupeData(data)

	if not data.sligwolf_entity then
		return
	end

	data.sligwolf_Addonname = nil
	data.spawnname = nil
	data.addonCache = nil
	data.addonIdCache = nil

	-- Remove values whose names starting with "_"
	for key, _ in pairs(data) do
		if not isstring(key) then
			continue
		end

		if key == "" then
			continue
		end

		if key[1] ~= "_" then
			continue
		end

		data[key] = nil
	end
end

function LIB.ToString(ent)
	local entStr = tostring(ent)

	if not IsValid(ent) then
		return entStr
	end

	local name = LIB.GetName(ent) or ""
	local addonname = ""

	if name ~= "" then
		name = string.format("[name: %s]", name)
	end

	if ent.sligwolf_Addonname then
		addonname = string.format("[addon: %s]", ent.sligwolf_Addonname)
	end

	local str = string.format("%s%s%s", entStr, addonname, name)
	return str
end

function LIB.GetPrintName(ent)
	if not IsValid(ent) then
		return "No Entity"
	end

	local name = string.Trim(ent.PrintName or "")
	if name ~= "" then
		return name
	end

	name = string.Trim(ent.NPCData and ent.NPCData.Name or "")
	if name ~= "" then
		return name
	end

	name = string.Trim(ent.VehicleTable and ent.VehicleTable.Name or "")
	if name ~= "" then
		return name
	end

	return ent:GetClass()
end

function LIB.GetSentTableFromSpawnname(sentSpawnname)
	if not sentSpawnname then return nil end

	local sentList = LIBUtil.GetList("SpawnableEntities")
	local sentTable = sentList[sentSpawnname]

	if not sentTable then return nil end
	return sentTable
end

function LIB.MakeEnt(classname, plyOwner, parent, name, addonname)
	if not SERVER then return end

	local ent = ents.Create(classname)
	if not IsValid(ent) then
		return nil
	end

	if IsValid(parent) then
		addonname = addonname or parent.sligwolf_Addonname
	end

	LIB.SetName(ent, name)
	LIB.SetParent(ent, parent)

	if ent.sligwolf_baseEntity and addonname then
		ent:SetAddonID(addonname)
	end

	ent:SetNWBool("sligwolf_entity", true)
	ent:SetNWBool("sligwolf_subentity", true)

	ent.sligwolf_entity = true
	ent.sligwolf_subentity = true
	ent.sligwolf_Addonname = addonname

	if IsValid(plyOwner) then
		LIB.SetOwner(ent, plyOwner)
	end

	LIB.InheritSpawnEffectFromParent(ent)

	return ent
end

function LIB.SetupChildEntity(ent, parent, collision, attachmentid)
	if not IsValid(ent) then return end
	if not IsValid(parent) then return end

	if attachmentid and isstring(attachmentid) then
		attachmentid = parent:LookupAttachment(attachmentid) or 0
	end

	attachmentid = tonumber(attachmentid or 0)

	ent:SetParent(parent, attachmentid)

	if collision then
		ent:SetCollisionGroup(collision)
	end

	ent:SetMoveType(MOVETYPE_NONE)

	ent.DoNotDuplicate = true
	ent.sligwolf_noUnfreeze = true
	ent.sligwolf_noBodySystemApplyMotion = true

	LIB.RemoveEntitiesOnDelete(parent, ent)

	local phys = ent:GetPhysicsObject()
	if IsValid(phys) then
		phys:Sleep()
	end

	return ent
end

function LIB.SetOwner(ent, plyOwner)
	if not IsValid(ent) then return end

	if ent.sligwolf_baseEntity then
		ent:SetOwningPlayer(plyOwner)
		return
	end

	if not ent.CPPISetOwner then
		return
	end

	ent:CPPISetOwner(plyOwner)
end

function LIB.GetOwner(ent)
	if not IsValid(ent) then return end

	if ent.sligwolf_baseEntity then
		return ent:GetOwningPlayer()
	end

	if not ent.CPPIGetOwner then
		return
	end

	return ent:CPPIGetOwner()
end

function LIB.ConstraintIsAllowed(ent, ply, mode)
	if not IsValid(ent) then return false end
	if not IsValid(ply) then return false end

	mode = tostring(mode or "")
	mode = string.lower(mode)

	if mode == "" then
		mode = "weld"
	end

	local allowtool = true

	if ent.CPPICanTool then
		allowtool = ent:CPPICanTool(ply, mode) or false
	end

	if not allowtool then return false end
	return true
end

function LIB.RemoveEntityWithEffects(ent)
	if LIB.IsMarkedForDeletion(ent, true) then
		return
	end

	constraint.RemoveAll(ent)

	LIBTimer.Simple(1, function()
		LIB.RemoveEntity(ent, false)
	end)

	ent:SetNotSolid(true)
	ent:SetMoveType(MOVETYPE_NONE)
	ent:SetNoDraw(true)

	local ed = EffectData()
	ed:SetOrigin(ent:GetPos())
	ed:SetEntity(ent)

	util.Effect("entity_remove", ed, true, true)
end

function LIB.IsMarkedForDeletion(ent, withEffect)
	if not IsValid(ent) then
		return true
	end

	if ent:IsMarkedForDeletion() then
		return true
	end

	if withEffect == false then
		return false
	end

	local entTable = ent:SligWolf_GetTable()
	if entTable.isMarkedForDeletionWithEffect then
		return true
	end

	return false
end

function LIB.RemoveEntity(ent, withEffect)
	withEffect = withEffect or false

	if LIB.IsMarkedForDeletion(ent, withEffect) then
		return
	end

	if withEffect then
		LIB.RemoveEntityWithEffects(ent)
		return
	end

	ent:Remove()
end

function LIB.RemoveEntities(entities, withEffect)
	if not entities then
		return
	end

	if not istable(entities) then
		entities = {entities}
	end

	for k, v in pairs(entities) do
		if isentity(v) then
			LIB.RemoveEntity(v, withEffect)
		end

		if k ~= v and isentity(k) then
			LIB.RemoveEntity(k, withEffect)
		end
	end
end

function LIB.RemoveFaultyEntities(entities, errReasonFormat, ...)
	LIB.RemoveEntities(entities, false)
	LIBPrint.ErrorNoHaltWithStack(errReasonFormat, ...)
end

function LIB.RemoveSystemEntities(superparent, withEffect)
	local entities = LIB.GetSystemEntities(superparent)
	LIB.RemoveEntities(entities, withEffect)
end

function LIB.RemoveSystemEntitiesOnDelete(ent)
	if not IsValid(ent) then
		return
	end

	LIB.CallOnRemove(ent, "RemoveSystemEntitiesOnDelete", function(thisent, withEffect)
		LIB.RemoveSystemEntities(thisent, withEffect)
	end)
end

function LIB.RemoveEntitiesOnDelete(ent, entitiesToRemove)
	if not IsValid(ent) then
		return
	end

	if not entitiesToRemove then
		return
	end

	if not istable(entitiesToRemove) then
		entitiesToRemove = {entitiesToRemove}
	end

	local entTable = ent:SligWolf_GetTable()

	entTable.entitiesToRemove = entTable.entitiesToRemove or {}
	local removeList = entTable.entitiesToRemove

	for k, v in pairs(entitiesToRemove) do
		if isentity(v) and IsValid(v) then
			removeList[v] = true
		end

		if k ~= v and isentity(k) and IsValid(k) then
			removeList[k] = true
		end
	end

	removeList[ent] = nil

	LIB.CallOnRemove(ent, "RemoveEntityOnDelete", function(thisent, withEffect)
		local thisEntTable = thisent:SligWolf_GetTable()
		LIB.RemoveEntities(thisEntTable.entitiesToRemove, withEffect)
	end)
end

function LIB.CallOnRemove(ent, name, func)
	if not IsValid(ent) then
		return
	end

	name = tostring(name or "")
	if name == "" then
		error("name is missing")
		return
	end

	local entTable = ent:SligWolf_GetTable()

	entTable.callOnRemove = entTable.callOnRemove or {}
	entTable.callOnRemove[name] = func
end

local function runCallOnRemoveList(ent, withEffect)
	if not IsValid(ent) then
		return
	end

	local entTable = ent:SligWolf_GetTable()
	local callOnRemove = entTable.callOnRemove

	if not callOnRemove then
		return
	end

	for key, thisFunction in pairs(callOnRemove) do
		ProtectedCall(function()
			thisFunction(ent, withEffect)
		end)

		if not withEffect then
			callOnRemove[key] = nil
		end
	end

	if not withEffect then
		entTable.callOnRemove = nil
	end
end

function LIB.RunCallOnRemove(ent)
	runCallOnRemoveList(ent, false)
end

function LIB.RunCallOnRemoveEffect(ent)
	runCallOnRemoveList(ent, true)
end

function LIB.InheritSpawnEffectFromParent(ent)
	if _G.DisablePropCreateEffect then return end

	if LIB.IsMarkedForDeletion(ent, true) then
		return
	end

	local parent = LIB.GetParent(ent)
	local spawnEffect = ent:GetSpawnEffect()

	if IsValid(parent) and parent ~= ent then
		spawnEffect = parent:GetSpawnEffect()
	end

	ent:SetSpawnEffect(spawnEffect)
end

function LIB.DoPropSpawnedEffect(ent)
	if _G.DisablePropCreateEffect then return end

	if LIB.IsMarkedForDeletion(ent, true) then
		return
	end

	ent:SetSpawnEffect(true)
end

local function GenerateUnknownEntityName(ent)
	local name = util.MD5(tostring(ent))
	return name
end

function LIB.GetName(ent)
	if not IsValid(ent) then return end

	local entTable = ent:SligWolf_GetTable()
	local name = LIBUtil.ValidateName(entTable.Name)

	if CLIENT and name == "" then
		name = GenerateUnknownEntityName(ent)
	end

	return name
end

function LIB.SetName(ent, name)
	if not IsValid(ent) then return end

	LIB.ClearChildrenCache(ent)

	local entTable = ent:SligWolf_GetTable()

	local parent = LIB.GetParent(ent)

	name = LIBUtil.ValidateName(name)
	if name == "" then
		name = GenerateUnknownEntityName(ent)
	end

	local oldname = LIB.GetName(ent)
	entTable.Name = name

	LIB.UnregisterChild(parent, oldname)
	LIB.RegisterChild(parent, name, ent)

	LIB.ClearChildrenCache(ent)
end

function LIB.GetParent(ent)
	if not IsValid(ent) then return end

	if ent.sligwolf_baseEntity then
		local parent = ent:GetParentEntity()

		if IsValid(parent) and parent ~= ent then
			return parent
		end

		return nil
	end

	local cache = getCache(ent).parents
	if cache then
		local parent = cache.ParentENT

		if IsValid(parent) and parent ~= ent then
			return parent
		end

		parent = ent:GetNWEntity("sligwolf_parent")

		if IsValid(parent) and parent ~= ent then
			return parent
		end
	end

	return nil
end

function LIB.SetParent(ent, parent)
	if not IsValid(ent) then return end

	if parent == ent then
		parent = nil
	end

	local oldParent = LIB.GetParent(ent)

	LIB.ClearChildrenCache(ent)

	local name = LIB.GetName(ent)

	local cache = getCache(ent).parents

	cache.ParentENT = parent

	if ent.sligwolf_baseEntity then
		ent:SetParentEntity(parent)
	else
		ent:SetNWEntity("sligwolf_parent", parent or NULL)
	end

	cache.SuperParentENT = nil
	cache.NearstBodyENT = nil
	cache.ParentBodyENT = nil

	LIB.UnregisterChild(oldParent, name)
	LIB.RegisterChild(parent, name, ent)

	LIB.ClearChildrenCache(ent)
end

function LIB.CalcSuperParent(ent)
	if not IsValid(ent) then return end

	local curparent = ent

	while true do
		if not IsValid(curparent) then
			break
		end

		local parent = LIB.GetParent(curparent)
		if not IsValid(parent) then
			break
		end

		if parent == ent then
			break
		end

		curparent = parent
	end

	if not IsValid(curparent) then
		return
	end

	return curparent
end

function LIB.CalcNearstBody(ent)
	if not IsValid(ent) then return end

	local curparent = ent

	while true do
		if not IsValid(curparent) then
			break
		end

		if curparent.sligwolf_isBody then
			break
		end

		if curparent:GetNWBool("sligwolf_isBody", false) then
			break
		end

		local parent = LIB.GetParent(curparent)
		if not IsValid(parent) then
			break
		end

		if parent == ent then
			break
		end

		curparent = parent
	end

	if not IsValid(curparent) then
		return
	end

	if curparent.sligwolf_isBody then
		return curparent
	end

	if curparent:GetNWBool("sligwolf_isBody", false) then
		return curparent
	end

	return nil
end

function LIB.GetSuperParent(ent)
	if not IsValid(ent) then return end

	local cache = getCache(ent).parents

	local superParent = cache.SuperParentENT

	if IsValid(superParent) then
		return superParent
	end

	superParent = LIB.CalcSuperParent(ent)
	if not IsValid(superParent) then
		superParent = ent
	end

	cache.SuperParentENT = superParent
	LIB.ClearChildrenCache(ent)

	return superParent
end

function LIB.GetNearstBody(ent)
	if not IsValid(ent) then return end

	local cache = getCache(ent).parents

	local body = cache.NearstBodyENT

	if IsValid(body) then
		return body
	end

	body = LIB.CalcNearstBody(ent)
	if not IsValid(body) then
		body = LIB.GetSuperParent(ent)
	end

	cache.NearstBodyENT = body
	cache.ParentBodyENT = nil

	return body
end

function LIB.BuildSubBodyLists(ent)
	local root = LIB.GetSuperParent(ent)
	if not IsValid(root) then
		return
	end

	local entities = LIB.GetSystemEntities(root)
	if not entities then
		return
	end

	for i, thisEnt in ipairs(entities) do
		local body = LIB.GetNearstBody(thisEnt)
		local bodyParent = LIB.GetParent(body)
		local parentBody = LIB.GetNearstBody(bodyParent)

		if not IsValid(bodyParent) then
			continue
		end

		local parentBodyCache = getCache(parentBody).children

		parentBodyCache.SubBodyENTs = parentBodyCache.SubBodyENTs or {}
		parentBodyCache.SubBodyENTs[body:EntIndex()] = body
	end
end

function LIB.GetSubBodies(ent)
	local body = LIB.GetNearstBody(ent)
	if not IsValid(body) then
		return nil
	end

	local cache = getCache(body).children

	if not cache.SubBodyENTs then
		LIB.BuildSubBodyLists(body)
	end

	return cache.SubBodyENTs
end

function LIB.GetParentBody(ent)
	if not IsValid(ent) then return end

	local cache = getCache(ent).parents

	local parentBody = cache.ParentBodyENT
	if IsValid(parentBody) then
		return parentBody
	end

	local body = LIB.GetNearstBody(ent)
	local bodyParent = LIB.GetParent(body)

	parentBody = LIB.GetNearstBody(bodyParent)
	if not IsValid(parentBody) then
		parentBody = LIB.GetSuperParent(ent)
	end

	cache.ParentBodyENT = parentBody
	return parentBody
end

function LIB.GetEntityPath(ent)
	if not IsValid(ent) then return end

	local name = LIB.GetName(ent)
	local parent = LIB.GetParent(ent)

	if not IsValid(parent) then
		return name
	end

	local parent_name = LIB.GetName(parent)
	name = parent_name .. "/" .. name

	return name
end

function LIB.GetChildren(ent)
	if not IsValid(ent) then return end

	local entTable = ent:SligWolf_GetTable()

	local children = entTable.ChildrenENTs or {}
	entTable.ChildrenENTs = children

	return children
end

function LIB.GetChildrenSorted(ent)
	if not IsValid(ent) then return end

	local cache = getCache(ent).children

	if cache.ChildrenENTsSorted then
		return cache.ChildrenENTsSorted
	end

	local children = LIB.GetChildren(ent)

	local byCid = {}

	for k, v in pairs(children) do
		if not IsValid(v) then
			continue
		end

		local cid = v:GetCreationID()
		byCid[cid] = v
	end

	local childrenSorted = {}

	for k, v in SortedPairs(byCid) do
		table.insert(childrenSorted, v)
	end

	cache.ChildrenENTsSorted = childrenSorted
	return childrenSorted
end

function LIB.UnregisterChild(ent, name)
	local children = LIB.GetChildren(ent)
	if not children then return end

	children[name] = nil

	LIB.ClearChildrenCache(ent)
end

function LIB.RegisterChild(ent, name, child)
	if not IsValid(ent) then return end
	if not IsValid(child) then return end

	local children = LIB.GetChildren(ent)
	if not children then return end

	children[name] = child

	LIB.ClearChildrenCache(ent)
end

function LIB.GetChild(ent, name)
	local children = LIB.GetChildren(ent)
	if not children then
		return nil
	end

	local child = children[name]
	if not IsValid(child) then
		return nil
	end

	return child
end

function LIB.GetChildFromPath(ent, path)
	if not IsValid(ent) then return end

	path = tostring(path or "")

	local cache = getCache(ent).children

	local childrenCache = cache.ChildrenPathENTs or {}
	cache.ChildrenPathENTs = childrenCache

	local cachedChild = childrenCache[path]
	if cachedChild ~= nil then
		if cachedChild == false then
			return nil
		end

		return cachedChild
	end

	childrenCache[path] = nil

	local hierarchy = string.Explode("/", path, false) or {}

	local curChild = ent
	for i, v in ipairs(hierarchy) do
		curChild = LIB.GetChild(curChild, v)

		if not curChild then
			childrenCache[path] = false
			return nil
		end
	end

	childrenCache[path] = curChild
	return curChild
end

function LIB.FindChildAtPath(ent, path)
	if not IsValid(ent) then
		return {}
	end

	path = tostring(path or "")

	local cache = getCache(ent).children

	local childrenCache = cache.ChildrenPathFindENTs or {}
	cache.ChildrenPathFindENTs = childrenCache

	local cachedChildren = childrenCache[path]
	if cachedChildren then
		return cachedChildren
	end

	childrenCache[path] = nil

	local hierarchy = string.Explode("/", path, false) or {}
	local lastindex = #hierarchy

	local result = {}

	local curchild = ent
	for k, v in ipairs(hierarchy) do
		if k >= lastindex then
			result = LIB.FindChildren(curchild, v)
			childrenCache[path] = result
			return result
		end

		curchild = LIB.GetChild(curchild, v)
		if not IsValid(curchild) then
			childrenCache[path] = result
			return result
		end
	end

	childrenCache[path] = result
	return result
end

function LIB.ForEachFilteredChild(ent, name, func)
	if not IsValid(ent) then return end
	if not isfunction(func) then return end

	local found = LIB.FindChildAtPath(ent, name)
	local index = 0

	for k, v in pairs(found) do
		index = index + 1
		local bbreak = func(ent, index, k, v)
		if bbreak then break end
	end
end

function LIB.FindChildren(ent, name)
	if not IsValid(ent) then
		return {}
	end

	name = tostring(name or "")

	local cache = getCache(ent).children

	local childrenCache = cache.ChildrenFindENTs or {}
	cache.ChildrenFindENTs = childrenCache

	local cachedChildren = childrenCache[name]
	if cachedChildren then
		return cachedChildren
	end

	childrenCache[name] = nil

	local children = LIB.GetChildren(ent)
	if not children then
		return {}
	end

	local result = {}

	for k, v in pairs(children) do
		if not IsValid(v) then
			continue
		end

		if not string.find(k, name, 0, false) then
			continue
		end

		result[k] = v
	end

	childrenCache[name] = result
	return result
end

local function GetAllChildrenRecursiveItemHelper(child, container, nodouble, filter)
	if not IsValid(child) then
		return false
	end

	if nodouble[child] then
		return false
	end

	if filter and not filter(child) then
		return false
	end

	nodouble[child] = true
	table.insert(container, child)

	return true
end

local function GetAllChildrenRecursiveHelper(parent, container, nodouble, filter)
	if not IsValid(parent) then
		return
	end

	local children = LIB.GetChildrenSorted(parent)
	if not children then
		return
	end

	nodouble = nodouble or {}

	for i, child in ipairs(children) do
		if not GetAllChildrenRecursiveItemHelper(child, container, nodouble, filter) then
			continue
		end

		GetAllChildrenRecursiveHelper(child, container, nodouble, filter)
	end
end

function LIB.GetChildrenRecursive(ent)
	if not IsValid(ent) then return end

	local cache = getCache(ent).children

	if cache.ChildrenRecursiveENTs then
		return cache.ChildrenRecursiveENTs
	end

	local children = {}

	GetAllChildrenRecursiveHelper(ent, children)

	cache.ChildrenRecursiveENTs = children
	return children
end

function LIB.GetSystemEntities(ent)
	local root = LIB.GetSuperParent(ent)
	if not IsValid(root) then
		return
	end

	local cache = getCache(root).children

	if cache.SystemENTs then
		return cache.SystemENTs
	end

	local children = {}
	local nodouble = {}

	GetAllChildrenRecursiveItemHelper(root, children, nodouble)
	GetAllChildrenRecursiveHelper(ent, children, nodouble)

	children = table.Reverse(children)

	cache.SystemENTs = children
	return children
end

function LIB.GetBodyEntities(ent)
	local body = LIB.GetNearstBody(ent)
	if not IsValid(body) then
		return nil
	end

	local cache = getCache(body).children

	if cache.BodyENTs then
		return cache.BodyENTs
	end

	local children = {}
	local nodouble = {}

	local filter = function(thisent)
		if LIB.GetNearstBody(thisent) ~= body then
			return false
		end

		return true
	end

	GetAllChildrenRecursiveItemHelper(body, children, nodouble, filter)
	GetAllChildrenRecursiveHelper(ent, children, nodouble, filter)

	children = table.Reverse(children)

	cache.BodyENTs = children
	return children
end

local function filterEntities(inputEnts, filteredEnts, filterFunc)
	table.Empty(filteredEnts)

	for i, filteredEnt in ipairs(inputEnts) do
		if not filteredEnt then
			continue
		end

		if not filterFunc(filteredEnt) then
			continue
		end

		table.insert(filteredEnts, filteredEnt)
	end
end

function LIB.GetSystemEntitiesFiltered(ent, cacheName, filterFunc)
	cacheName = tostring(cacheName or "")
	if cacheName == "" then
		return
	end

	local root = LIB.GetSuperParent(ent)
	if not IsValid(root) then
		return nil
	end

	local childrenCache = getCache(root).children

	childrenCache.SystemENTsFilteredCache = childrenCache.SystemENTsFilteredCache or {}
	local cache = childrenCache.SystemENTsFilteredCache

	local cachedEntities = cache[cacheName]

	if cachedEntities then
		return cachedEntities
	end

	local entities = LIB.GetSystemEntities(ent)
	if not entities then
		return nil
	end

	filterFunc = filterFunc or function()
		return true
	end

	cache[cacheName] = cache[cacheName] or {}
	cachedEntities = cache[cacheName]

	filterEntities(entities, cachedEntities, filterFunc)

	return cachedEntities
end

function LIB.GetBodyEntitiesFiltered(ent, cacheName, filterFunc)
	cacheName = tostring(cacheName or "")
	if cacheName == "" then
		return nil
	end

	local body = LIB.GetNearstBody(ent)
	if not IsValid(body) then
		return nil
	end

	local childrenCache = getCache(body).children

	childrenCache.BodyENTsFilteredCache = childrenCache.BodyENTsFilteredCache or {}
	local cache = childrenCache.BodyENTsFilteredCache

	local cachedEntities = cache[cacheName]

	if cachedEntities then
		return cachedEntities
	end

	local entities = LIB.GetBodyEntities(ent)
	if not entities then
		return nil
	end

	filterFunc = filterFunc or function()
		return true
	end

	cache[cacheName] = cache[cacheName] or {}
	cachedEntities = cache[cacheName]

	filterEntities(entities, cachedEntities, filterFunc)

	return cachedEntities
end

function LIB.FindPropInSphere(ent, radius, attachment, filterA, filterB)
	if not IsValid(ent) then return nil end
	radius = tonumber(radius or 10)
	filterA = tostring(filterA or "none")
	filterB = tostring(filterB or "none")

	local new_ent = nil

	local pos = LIBPosition.GetAttachmentPosAng(ent, attachment)
	local objs = ents.FindInSphere(pos, radius) or {}

	for k, v in pairs(objs) do
		if not IsValid(v) then continue end
		local mdl = v:GetModel()
		if mdl == filterA or mdl == filterB then
			new_ent = v
			return new_ent
		end
	end

	return nil
end

function LIB.GetKeyValues(ent)
	local keyValues = {}

	for key, value in pairs(ent:GetKeyValues() or {}) do
		key = string.lower(key)
		keyValues[key] = value
	end

	local entTable = ent:SligWolf_GetTable()

	for key, value in pairs(entTable.keyValues or {}) do
		key = string.lower(key)
		keyValues[key] = value
	end

	return keyValues
end

function LIB.GetKeyValue(ent, key)
	key = string.lower(key)

	local keyValues = LIB.GetKeyValues(ent)
	return keyValues[key]
end

function LIB.CanApplyBodySystemMotion(ent)
	if not IsValid(ent) then
		return false
	end

	if not ent.sligwolf_entity then
		return false
	end

	if not ent.sligwolf_physEntity then
		return false
	end

	if ent.sligwolf_noBodySystemApplyMotion then
		return false
	end

	if ent:GetPhysicsObjectCount() ~= 1 then
		-- ignore ragdolls
		return false
	end

	return true
end

function LIB.EnableSystemMotion(srcEnt, motion)
	local root = LIB.GetSuperParent(srcEnt)

	if not IsValid(root) then
		return
	end

	local systemEntities = LIB.GetSystemEntities(root)

	for _, thisent in ipairs(systemEntities) do
		if not LIB.CanApplyBodySystemMotion(thisent) then
			continue
		end

		-- @DEBUG: Color entities according to their motion state
		-- if motion then
		-- 	SligWolf_Addons.Debug.HighlightEntities(thisent, Color(0, 255, 0))
		-- else
		-- 	SligWolf_Addons.Debug.HighlightEntities(thisent, Color(255, 0, 0))
		-- end

		LIB.EnableMotion(thisent, motion)
	end
end

function LIB.EnableBodySystemMotion(srcEnt, motion)
	local body = LIB.GetNearstBody(srcEnt)

	if not IsValid(body) then
		return
	end

	local bodyEntities = LIB.GetBodyEntities(body)

	for _, thisent in ipairs(bodyEntities) do
		if not LIB.CanApplyBodySystemMotion(thisent) then
			continue
		end

		-- @DEBUG: Color entities according to their motion state
		-- if motion then
		-- 	SligWolf_Addons.Debug.HighlightEntities(thisent, Color(0, 255, 0))
		-- else
		-- 	SligWolf_Addons.Debug.HighlightEntities(thisent, Color(255, 0, 0))
		-- end

		LIB.EnableMotion(thisent, motion)
	end
end

function LIB.UpdateBodySystemMotion(srcEnt, delayed)
	if not IsValid(srcEnt) then
		return false
	end

	local phys = srcEnt:GetPhysicsObject()
	if not IsValid(phys) then
		return
	end

	local motion = phys:IsMotionEnabled()

	if not LIB.CanApplyBodySystemMotion(srcEnt) then
		return
	end

	if not delayed then
		LIB.EnableBodySystemMotion(srcEnt, motion)
		return
	end

	local body = LIB.GetNearstBody(srcEnt)

	if not IsValid(body) then
		return
	end

	local bid = body:GetCreationID()

	LIBTimer.NextFrame("Library_Entities_UpdateBodySystemMotion_" .. bid, function()
		LIB.UpdateBodySystemMotion(srcEnt, false)
	end)
end

function LIB.EnableMotion(ent, bool)
	if not IsValid(ent) then return end

	local phys = ent:GetPhysicsObject()
	if not IsValid(phys) then return end

	phys:EnableMotion(bool or false)
end

function LIB.LockEntityToMountPoint(selfEnt)
	if not IsValid(selfEnt) then
		return false
	end

	if not selfEnt.sligwolf_physEntity then
		return false
	end

	if IsValid(selfEnt.sligwolf_lockConstraintWeld) then
		return true
	end

	local mountPoint = LIBPosition.GetMountPoint(selfEnt)
	if not mountPoint then
		return false
	end

	if not LIBPosition.RemountToMountPoint(selfEnt, mountPoint) then
		return false
	end

	local parentEnt = mountPoint.parentEnt

	local weldConstraint = constraint.Weld(
		selfEnt,
		parentEnt,
		0,
		0,
		0,
		false,
		false
	)

	if not IsValid(weldConstraint) then
		return false
	end

	weldConstraint.DoNotDuplicate = true
	selfEnt.sligwolf_lockConstraintWeld = weldConstraint

	-- @DEBUG: Color entity according to their lock state
	-- SligWolf_Addons.Debug.HighlightEntities(selfEnt, Color(255, 0, 0))

	return true
end

function LIB.UnlockEntityFromMountPoint(selfEnt)
	if not IsValid(selfEnt) then
		return false
	end

	if not selfEnt.sligwolf_physEntity then
		return false
	end

	LIB.RemoveEntity(selfEnt.sligwolf_lockConstraintWeld, false)

	-- @DEBUG: Color entity according to their lock state
	-- SligWolf_Addons.Debug.HighlightEntities(selfEnt, Color(0, 255, 0))

	return true
end

-- used to never hit the players
local g_notSolidToPlayersCollisionGroup = COLLISION_GROUP_PASSABLE_DOOR

-- only change entities with those
local g_collisionGroupWhitelist = {
	[COLLISION_GROUP_NONE] = true,
	[COLLISION_GROUP_VEHICLE] = true,
	[COLLISION_GROUP_PLAYER] = true,
	[COLLISION_GROUP_NPC] = true,
}

function LIB.SetUnsolidToPlayerRecursive(ent, unsolid)
	local children = LIB.GetChildrenRecursive(ent)
	if not children then
		return
	end

	children = table.ClearKeys(children)
	table.insert(children, ent)

	for i, child in ipairs(children) do
		if not IsValid(child) then
			continue
		end

		if not child.sligwolf_physEntity then
			continue
		end

		local entTable = child:SligWolf_GetTable()
		local oldCollisionGroup = entTable.sligwolf_oldCollisionGroupForPlayers

		if unsolid then
			local collisionGroup = child:GetCollisionGroup()
			if not g_collisionGroupWhitelist[collisionGroup] then
				continue
			end

			if not oldCollisionGroup then
				entTable.sligwolf_oldCollisionGroupForPlayers = collisionGroup
				child:SetCollisionGroup(g_notSolidToPlayersCollisionGroup)
			end

			continue
		end

		if not oldCollisionGroup then
			continue
		end

		child:SetCollisionGroup(oldCollisionGroup)
		entTable.sligwolf_oldCollisionGroupForPlayers = nil
	end
end

function LIB.GetHeadVehicle(ent)
	local root = LIB.GetSuperParent(ent)

	if not IsValid(root) then
		return
	end

	local systemEntities = LIB.GetSystemEntities(root)

	for _, thisent in ipairs(systemEntities) do
		if not thisent:IsVehicle() then
			continue
		end

		if not thisent:IsValidVehicle() then
			continue
		end

		if not thisent.sligwolf_headVehicle then
			continue
		end

		return thisent
	end

	return
end

function LIB.GetDriver(ent)
	local vehicle = LIB.GetHeadVehicle(ent)

	if not IsValid(vehicle) then
		return
	end

	local driver = vehicle:GetDriver()
	if not IsValid(driver) then
		return
	end

	return driver
end

function LIB.GetPassengers(ent, includeDriver)
	local root = LIB.GetSuperParent(ent)

	if not IsValid(root) then
		return
	end

	local systemEntities = LIB.GetSystemEntities(root)

	local passengers = {}

	for _, thisent in ipairs(systemEntities) do
		if not thisent:IsVehicle() then
			continue
		end

		if not thisent:IsValidVehicle() then
			continue
		end

		local thispassenger = thisent:GetDriver()
		if not IsValid(thispassenger) then
			continue
		end

		if not includeDriver and thisent.sligwolf_headVehicle then
			continue
		end

		passengers[thispassenger] = thispassenger
	end

	passengers = table.ClearKeys(passengers)

	return passengers
end

return true

