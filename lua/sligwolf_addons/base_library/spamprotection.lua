AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Spamprotection = SligWolf_Addons.Spamprotection or {}
table.Empty(SligWolf_Addons.Spamprotection)

local LIB = SligWolf_Addons.Spamprotection

local g_maxCollisionSpamCount = 30
local g_maxStableTime = 10

local LIBEntities = nil
local LIBPhysics = nil
local LIBVehicle = nil
local LIBTimer = nil
local LIBPrint = nil

function LIB.SetNextAllowedSpawnTime(ply, time)
	if not IsValid(ply) then
		return
	end

	time = tonumber(time or 0) or 0

	local plyTable = ply:SligWolf_GetTable()
	plyTable.allowedNextSpawnTime = time
end

function LIB.GetNextAllowedSpawnTime(ply)
	if not IsValid(ply) then
		return
	end

	local plyTable = ply:SligWolf_GetTable()
	local time = plyTable.allowedNextSpawnTime or 0

	return time
end

function LIB.IsNextSpawnDelayed(ply)
	if not IsValid(ply) then
		return false
	end

	local now = RealTime()
	local time = LIB.GetNextAllowedSpawnTime(ply)

	if time <= now then
		return false
	end

	return true
end

function LIB.DelayNextSpawn(ply)
	if not IsValid(ply) then
		return
	end

	local now = RealTime()
	LIB.SetNextAllowedSpawnTime(ply, now + 0.15)
end

function LIB.DelayNextSpawnForOwner(ent)
	if LIBEntities.IsMarkedForDeletion(ent) then
		return
	end

	local owner = LIBEntities.GetOwner(ent)
	LIB.DelayNextSpawn(owner)
end

function LIB.IsDuplicatorSpawn(ply)
	if not IsValid(ply) then
		return false
	end

	if AdvDupe2 and AdvDupe2.SpawningEntity then
		-- Only AdvDupe2 has this flag, others are feed by detours
		return true
	end

	local plyTable = ply:SligWolf_GetTable()

	if not plyTable.isDuplicatorSpawning then
		return false
	end

	return true
end

function LIB.SetIsDuplicatorSpawn(ply, bool)
	if not IsValid(ply) then
		return
	end

	local plyTable = ply:SligWolf_GetTable()
	plyTable.isDuplicatorSpawning = bool or false
end

function LIB.CanSpawn(ply, spawnTable)
	if not IsValid(ply) then
		return true
	end

	if not spawnTable.Is_SLIGWOLF then
		return true
	end

	if LIB.IsDuplicatorSpawn(ply) then
		return true
	end

	if not LIB.IsNextSpawnDelayed(ply) then
		return true
	end

	local now = RealTime()
	local nextSpawnTime = LIB.GetNextAllowedSpawnTime(ply)
	local left = math.max(nextSpawnTime - now, 0)

	local message = nil

	if left <= 1 then
		message = LIBPrint.FormatMessage("You are spawning too often, please slow down!")
	else
		message = LIBPrint.FormatMessage("You are spawning too often, please slow down! (%0.2f sec left)", left)
	end

	LIBPrint.Notify(NOTIFY_ERROR, message, 3, ply)

	return false
end

function LIB.AddCollisionHooks(ent)
	if not IsValid(ent) then
		return
	end

	LIBPhysics.CallOnCollide(ent, "SpamCount", function(thisent, superparent, data)
		if not superparent then
			return
		end

		if not data then
			return
		end

		local otherSuperparent = data.HitSuperParent
		if not otherSuperparent then
			return
		end

		if superparent == otherSuperparent then
			return
		end

		local superparentTable = superparent:SligWolf_GetTable()

		superparentTable.systemCollisionSpamCount = (superparentTable.systemCollisionSpamCount or 0) + 1
		superparentTable.systemCollisionSpamCount = superparentTable.systemCollisionSpamCount % 2^31

		local otherSuperparentTable = otherSuperparent:SligWolf_GetTable()

		otherSuperparentTable.systemCollisionSpamCount = (otherSuperparentTable.systemCollisionSpamCount or 0) + 1
		otherSuperparentTable.systemCollisionSpamCount = otherSuperparentTable.systemCollisionSpamCount % 2^31
	end)
end

function LIB.RemoveSpamCollisionEntities(ent)
	if not IsValid(ent) then
		return
	end

	LIBEntities.EnableSystemMotion(ent, false)
	LIBEntities.RemoveSystemEntites(ent, true)

	local owner = LIBEntities.GetOwner(ent)
	if IsValid(owner) then
		LIBPrint.Print("Removed entity, because of stuck or laggy physics!\n  Entity: %s\n  Owner: %s", ent, owner)
	else
		LIBPrint.Print("Removed entity, because of stuck or laggy physics!\n  Entity: %s", ent)
	end

	LIBTimer.Once("NotifyRemovedSpamCollisionEntities", 0.25, function()
		if not IsValid(ent) then
			return
		end

		local thisOwner = LIBEntities.GetOwner(ent)
		if not IsValid(thisOwner) then
			return
		end

		local message = LIBPrint.FormatMessage("Removed stuck and laggy physics!")
		LIBPrint.Notify(NOTIFY_ERROR, message, 2, thisOwner)
	end)

	return
end

function LIB.Load()
	LIBEntities = SligWolf_Addons.Entities
	LIBPhysics = SligWolf_Addons.Physics
	LIBVehicle = SligWolf_Addons.Vehicle
	LIBTimer = SligWolf_Addons.Timer
	LIBPrint = SligWolf_Addons.Print

	local LIBHook = SligWolf_Addons.Hook

	if SERVER then
		local function MarkAsDupe(ply)
			LIB.SetIsDuplicatorSpawn(ply, true)
		end

		local function UnmarkAsDupe(ply)
			LIB.SetIsDuplicatorSpawn(ply, false)
			LIB.DelayNextSpawn(ply)
		end

		LIBHook.Add("SLIGWOLF_DuplicatorPrePaste", "Library_SpamProtection_MarkAsDupe", MarkAsDupe, 1000)
		LIBHook.Add("SLIGWOLF_DuplicatorPostPaste", "Library_SpamProtection_UnmarkAsDupe", UnmarkAsDupe, 1000)

		local function AntiVehicleSpam(ply, model, spawnname)
			local spawnTable = LIBVehicle.GetVehicleTableFromSpawnname(spawnname)
			if not spawnTable then
				return
			end

			if LIB.CanSpawn(ply, spawnTable) then
				return
			end

			return false
		end

		LIBHook.Add("PlayerSpawnVehicle", "Library_SpamProtection_AntiVehicleSpam", AntiVehicleSpam, 1000)

		local function AntiSentSpam(ply, spawnname)
			local spawnTable = LIBEntities.GetSentTableFromSpawnname(spawnname)
			if not spawnTable then
				return
			end

			if LIB.CanSpawn(ply, spawnTable) then
				return
			end

			return false
		end

		LIBHook.Add("PlayerSpawnSENT", "Library_SpamProtection_AntiSentSpam", AntiSentSpam, 1000)

		local function CalcSystemCollisionCountDelta()
			if g_maxCollisionSpamCount <= 0 then
				return
			end

			local collidingSystems = LIBPhysics.GetCollidingSystems(ent)

			local removed = false

			for id, superparent in pairs(collidingSystems) do
				if not IsValid(superparent) then
					continue
				end

				local superparentTable = superparent:SligWolf_GetTable()

				local delta = superparentTable.systemCollisionSpamCount or 0
				superparentTable.systemCollisionSpamCount = 0

				if removed then
					-- only remove one at a time
					continue
				end

				if delta < g_maxCollisionSpamCount then
					continue
				end

				local now = CurTime()
				local creationTime = superparent:GetCreationTime()
				local age = math.max(now - creationTime, 0)

				if age >= g_maxStableTime then
					-- Entities older than 10 sec are considered as stable.
					return
				end

				LIB.RemoveSpamCollisionEntities(superparent)
				removed = true
			end

			-- @TODO always remove the newest entity first
		end

		LIBHook.Add("Tick", "Library_SpamProtection_CalcSystemCollisionCountDelta", CalcSystemCollisionCountDelta, 2000)
	end
end

return true

