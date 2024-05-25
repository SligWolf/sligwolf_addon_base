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

function LIB.GetCollidingSystems(ent)
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

