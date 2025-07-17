AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Physics = SligWolf_Addons.Physics or {}
table.Empty(SligWolf_Addons.Physics)

local LIB = SligWolf_Addons.Physics

local LIBEntities = nil
local LIBSpamprotection = nil

local g_CollidingSystems = {}

local function runCallOnCollideList(ent, data)
	if not IsValid(ent) then
		return
	end

	local entTable = ent:SligWolf_GetTable()
	local callOnCollide = entTable.callOnCollide

	if not callOnCollide then
		return
	end

	local superparent = LIBEntities.GetSuperParent(ent)
	if not IsValid(superparent) then
		superparent = nil
	end

	if data then
		local otherEnt = data.HitEntity
		local otherSuperparent = LIBEntities.GetSuperParent(otherEnt)

		if not IsValid(otherSuperparent) then
			otherSuperparent = nil
		end

		data.HitSuperParent = otherSuperparent
	end

	for key, thisFunction in pairs(callOnCollide) do
		thisFunction(ent, superparent, data)
	end
end

function LIB.CallOnCollide(ent, name, func)
	if not SERVER then
		return
	end

	if not IsValid(ent) then
		return
	end

	if not ent.sligwolf_physEntity then
		return
	end

	name = tostring(name or "")
	if name == "" then
		error("name is missing")
		return
	end

	local entTable = ent:SligWolf_GetTable()

	entTable.callOnCollide = entTable.callOnCollide or {}
	entTable.callOnCollide[name] = func

	if entTable.hasCallOnCollideHook then
		return
	end

	entTable.hasCallOnCollideHook = true

	if ent.sligwolf_baseEntity then
		local oldPhysicsCollide = ent.PhysicsCollide

		ent.PhysicsCollide = function(thisent, data, ...)
			oldPhysicsCollide(thisent, data, ...)
			runCallOnCollideList(thisent, data)
		end
	else
		local callbackId = ent:AddCallback("PhysicsCollide", function(thisent, data)
			runCallOnCollideList(thisent, data)
		end)

		entTable.callOnCollideHookId = callbackId
	end
end

function LIB.AddDefaultCollisionHooks(ent)
	if not SERVER then
		return
	end

	if not IsValid(ent) then
		return
	end

	if not ent.sligwolf_physEntity then
		return
	end

	LIB.CallOnCollide(ent, "Listen", function(thisent, superparent, data)
		if not superparent then
			return
		end

		local id = superparent:GetCreationID()
		g_CollidingSystems[id] = superparent

		if not data then
			return
		end

		local otherSuperparent = data.HitSuperParent
		if not otherSuperparent then
			return
		end

		local otherId = otherSuperparent:GetCreationID()
		g_CollidingSystems[otherId] = otherSuperparent
	end)

	LIBSpamprotection.AddCollisionHooks(ent)
end

function LIB.GetCollidingSystems()
	return g_CollidingSystems
end

function LIB.InitializeAsPhysEntity(ent)
	if not IsValid(ent) then
		return
	end

	if not ent.sligwolf_entity then
		return
	end

	ent.sligwolf_physEntity = true
	LIB.AddDefaultCollisionHooks(ent)
	LIB.ClearPhysObjectsCache(ent)
end

function LIB.IsValidPhysObject(phys)
	if not IsValid(phys) then
		return false
	end

	local name = string.lower(phys:GetName())
	if name == "vehiclewheel" then
		-- wheels do act crazy when messed with
		return false
	end

	return true
end

function LIB.GetPhysObjects(ent)
	if not IsValid(ent) then
		return nil
	end

	if ent:IsPlayer() then
		return nil
	end

	local entTable = ent:SligWolf_GetTable()
	local cache = entTable.physObjects

	if cache ~= nil then
		if not cache then
			return nil
		end

		if IsValid(cache[1]) then
			-- Invalidate cache if phys objects were destroyed or recreated.
			return cache
		end
	end

	cache = nil

	if istable(entTable.physObjects) then
		table.Empty(entTable.physObjects)
	end

	entTable.physObjects = nil

	local physcount = ent:GetPhysicsObjectCount()

	if physcount <= 0 then
		entTable.physObjects = false
		return nil
	end

	local physObjects = {}

	for i = 1, physcount do
		local phys = ent:GetPhysicsObjectNum(i - 1)

		if not LIB.IsValidPhysObject(phys) then
			continue
		end

		table.insert(physObjects, phys)
	end

	if table.IsEmpty(physObjects) then
		entTable.physObjects = false
		return nil
	end

	entTable.physObjects = physObjects
	return physObjects
end

function LIB.ClearPhysObjectsCache(ent)
	if not IsValid(ent) then
		return
	end

	if ent:IsPlayer() then
		return
	end

	local entTable = ent:SligWolf_GetTable()

	if istable(entTable.physObjects) then
		table.Empty(entTable.physObjects)
	end

	entTable.physObjects = nil
end

local function setEnableMotionInternal(physObject, bool)
	if not IsValid(physObject) then
		return
	end

	if not bool then
		physObject:Sleep()
	end

	physObject:EnableMotion(bool)

	if bool then
		physObject:Wake()
	end
end

local function getEnableMotionInternal(physObject)
	if not IsValid(physObject) then
		return false
	end

	return physObject:IsMotionEnabled()
end

function LIB.EnableMotion(entOrPhys, bool)
	if not IsValid(entOrPhys) then
		return
	end

	bool = bool or false

	if isentity(entOrPhys) then
		if not entOrPhys.sligwolf_entity then
			-- Do not use LIB.GetPhysObjects on non sw-addon entities to prevent over caching.

			local physObject = entOrPhys:GetPhysicsObject()
			setEnableMotionInternal(physObject, bool)

			return
		end

		local physObjects = LIB.GetPhysObjects(entOrPhys)
		if not physObjects then
			return
		end

		for i, physObject in ipairs(physObjects) do
			setEnableMotionInternal(physObject, bool)
		end

		return
	end

	if not LIB.IsValidPhysObject(entOrPhys) then
		return
	end

	setEnableMotionInternal(entOrPhys, bool)
end

function LIB.IsMotionEnabled(entOrPhys)
	if not IsValid(entOrPhys) then
		return false
	end

	if isentity(entOrPhys) then
		if not entOrPhys.sligwolf_entity then
			-- Do not use LIB.GetPhysObjects on non sw-addon entities to prevent over caching.

			local physObject = entOrPhys:GetPhysicsObject()
			return getEnableMotionInternal(physObject)
		end

		local physObjects = LIB.GetPhysObjects(entOrPhys)
		if not physObjects then
			return false
		end

		for i, physObject in ipairs(physObjects) do
			if not getEnableMotionInternal(physObject) then
				return false
			end
		end

		return true
	end

	if not LIB.IsValidPhysObject(entOrPhys) then
		return false
	end

	return getEnableMotionInternal(entOrPhys)
end

function LIB.IsTraceableCollision(solidType, collisionGroup)
	if solidType and solidType == SOLID_NONE then
		return false
	end

	if collisionGroup and collisionGroup == COLLISION_GROUP_IN_VEHICLE then
		return false
	end

	return true
end

function LIB.Load()
	LIBEntities = SligWolf_Addons.Entities
	LIBSpamprotection = SligWolf_Addons.Spamprotection

	local LIBHook = SligWolf_Addons.Hook

	if SERVER then
		local function ClearCollidingSystems()
			table.Empty(g_CollidingSystems)
		end

		LIBHook.Add("Tick", "Library_Physics_ClearCollidingSystems", ClearCollidingSystems, 100000)
	end
end

return true

