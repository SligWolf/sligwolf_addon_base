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
local g_stableAfterTime = 10

local LIBEntities = nil
local LIBPhysics = nil
local LIBVehicle = nil
local LIBTimer = nil
local LIBPrint = nil
local LIBUtil = nil

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
	LIB.SetNextAllowedSpawnTime(ply, now + 0.05)
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

	local message = LIBPrint.FormatMessage("You are spawning too often, please slow down!")
	LIBPrint.Notify(1, message, 3, ply)

	return false
end

function LIB.AddCollisionHooks(ent)
	if not IsValid(ent) then
		return
	end

	local entTable = ent:SligWolf_GetTable()
	entTable.stableAfterTick = engine.TickCount() + 66 * g_stableAfterTime

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
	if LIBEntities.IsMarkedForDeletion(ent) then
		return
	end

	LIBEntities.EnableSystemMotion(ent, false)

	LIBTimer.SimpleNextFrame(function()
		if LIBEntities.IsMarkedForDeletion(ent) then
			return
		end

		local printName = LIBEntities.GetPrintName(ent)

		local owner = LIBEntities.GetOwner(ent)
		if IsValid(owner) then
			LIBPrint.Print("Removed %s, because of stuck or laggy physics!\n  Entity: %s\n  Owner: %s\n", printName, ent, owner)
		else
			LIBPrint.Print("Removed %s, because of stuck or laggy physics!\n  Entity: %s\n", printName, ent)
		end

		local carringPlayers = LIBPhysgun.GetPhysgunCarringPlayers(ent) or {}
		local passengers = LIBEntities.GetPassengers(ent, true) or {}

		local rf = RecipientFilter()

		if IsValid(owner) then
			rf:AddPlayer(owner)
		end

		rf:AddPlayers(carringPlayers)
		rf:AddPlayers(passengers)

		local message = LIBPrint.FormatMessage(
			"Removed %s! Stuck or laggy physics!",
			printName
		)

		LIBPrint.Notify(1, message, 5, rf)

		LIBEntities.RemoveSystemEntities(ent, true)
	end)
end

function LIB.Load()
	LIBEntities = SligWolf_Addons.Entities
	LIBPhysics = SligWolf_Addons.Physics
	LIBPhysgun = SligWolf_Addons.Physgun
	LIBVehicle = SligWolf_Addons.Vehicle
	LIBTimer = SligWolf_Addons.Timer
	LIBPrint = SligWolf_Addons.Print
	LIBUtil = SligWolf_Addons.Util

	local LIBHook = SligWolf_Addons.Hook

	if SERVER then
		local function MarkAsDupe(ply)
			LIB.SetIsDuplicatorSpawn(ply, true)
		end

		local function UnmarkAsDupe(ply)
			LIB.SetIsDuplicatorSpawn(ply, false)
			LIB.DelayNextSpawn(ply)
		end

		LIBHook.AddCustom("DuplicatorPrePaste", "Library_SpamProtection_MarkAsDupe", MarkAsDupe, 1000)
		LIBHook.AddCustom("DuplicatorPostPaste", "Library_SpamProtection_UnmarkAsDupe", UnmarkAsDupe, 1000)

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

		if g_maxCollisionSpamCount > 0 then
			local function RemoveSpamCollisions()
				local collidingSystems = LIBPhysics.GetCollidingSystems(ent)

				local removeCandidates = {}
				local nowTick = engine.TickCount()

				for _, superparent in pairs(collidingSystems) do
					if LIBEntities.IsMarkedForDeletion(superparent) then
						continue
					end

					local superparentTable = superparent:SligWolf_GetTable()

					local delta = superparentTable.systemCollisionSpamCount or 0
					superparentTable.systemCollisionSpamCount = 0

					if delta < g_maxCollisionSpamCount then
						continue
					end

					local stableAfterTick = superparentTable.stableAfterTick
					if stableAfterTick and stableAfterTick <= nowTick then
						-- Entities living long enough ticks are considered as stable.
						return
					end

					table.insert(removeCandidates, superparent)
				end

				if not table.IsEmpty(removeCandidates) then
					-- Remove the newest entity first
					LIBUtil.SortEntitiesBySpawn(removeCandidates)

					for _, removeCandidate in ipairs(removeCandidates) do
						-- Remove only one entity at a time
						LIB.RemoveSpamCollisionEntities(removeCandidate)
						break
					end
				end
			end

			LIBHook.Add("Tick", "Library_SpamProtection_RemoveSpamCollisions", RemoveSpamCollisions, 2000)
		end
	end
end

return true

