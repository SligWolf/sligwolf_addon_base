AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SLIGWOLF_ADDON then
	SligWolf_Addons.AutoLoadAddon(function() end)
	return
end

local LIBSpamprotection = SligWolf_Addons.Spamprotection
local LIBEntities = SligWolf_Addons.Entities
local LIBHook = SligWolf_Addons.Hook

function SLIGWOLF_ADDON:GetEntityTable(ent)
	local entAddonTable = ent:SligWolf_GetAddonTable(self.Addonname)
	return entAddonTable
end

function SLIGWOLF_ADDON:MakeEnt(classname, plyOwner, parent, name)
	local ent = LIBEntities.MakeEnt(classname, plyOwner, parent, name, self.Addonname)
	if not ent then
		return nil
	end

	return ent
end

function SLIGWOLF_ADDON:MakeEntEnsured(classname, plyOwner, parent, name)
	local ent = self:MakeEnt(classname, plyOwner, parent, name)
	if not IsValid(ent) then
		self:RemoveFaultyEntities(
			{parent},
			"Couldn't create '%s' entity named '%s' for %s. Removing entities.",
			tostring(classname),
			tostring(name or "<unnamed>"),
			parent
		)

		return
	end

	return ent
end

function SLIGWOLF_ADDON:RemoveFaultyEntities(tb, errReasonFormat, ...)
	LIBEntities.RemoveEntities(tb)
	self:ErrorNoHaltWithStack(errReasonFormat, ...)
end

function SLIGWOLF_ADDON:AddToEntList(name, ent)
	name = tostring(name or "")

	self.ents = self.ents or {}
	self.ents[name] = self.ents[name] or {}

	if IsValid(ent) then
		self.ents[name][ent] = true
	else
		self.ents[name][ent] = nil
	end
end

function SLIGWOLF_ADDON:RemoveFromEntList(name, ent)
	name = tostring(name or "")

	self.ents = self.ents or {}
	self.ents[name] = self.ents[name] or {}
	self.ents[name][ent] = nil
end

function SLIGWOLF_ADDON:GetAllFromEntList(name)
	name = tostring(name or "")

	self.ents = self.ents or {}
	return self.ents[name] or {}
end

function SLIGWOLF_ADDON:ForEachInEntList(name, func)
	if not isfunction(func) then return end
	name = tostring(name or "")

	local entlist = self:GetAllFromEntList(name)

	local index = 1
	for k, v in pairs(entlist) do
		if not IsValid(k) then
			entlist[k] = nil
			continue
		end

		local bbreak = func(self, index, k)
		if bbreak == false then
			break
		end

		index = index + 1
	end
end

function SLIGWOLF_ADDON:HandleSpawnFinishedEvent(ent, callNow)
	if not IsValid(ent) then
		return
	end

	if LIBEntities.IsMarkedForDeletion(ent) then
		return
	end

	local entTable = ent:SligWolf_GetTable()
	if entTable.wasHandleSpawnFinishedEventRequested then
		return
	end

	entTable.wasHandleSpawnFinishedEventRequested = true

	local request = function(thisEnt)
		if LIBEntities.IsMarkedForDeletion(thisEnt) then
			return
		end

		local superparent = LIBEntities.GetSuperParent(thisEnt)
		if not IsValid(superparent) then
			return
		end

		if thisEnt == superparent then
			return
		end

		self:HandleSpawnFinishedEventInternal(superparent)
	end

	if callNow then
		request(ent)
		return
	end

	-- Make sure we have a delay of at least 2 frames.
	self:EntityTimerNextFrame(ent, "HandleSpawnFinishedEvent", function(thisEnt)
		if LIBEntities.IsMarkedForDeletion(thisEnt) then
			return
		end

		self:EntityTimerNextFrame(thisEnt, "HandleSpawnFinishedEvent", request)
	end)
end

function SLIGWOLF_ADDON:HandleSpawnFinishedEventInternal(superparent)
	local superparentEntTable = superparent:SligWolf_GetTable()

	if superparentEntTable.isDoneSpawningParts then
		return
	end

	local timernameEvent = "HandleSpawnFinishedEventInternal"
	local timernameEventTimeout = "HandleSpawnFinishedEventInternalTimeout"

	LIBSpamprotection.DelayNextSpawnForOwner(superparent)

	self:EntityTimerOnce(superparent, timernameEvent, 0.26, function()
		if LIBEntities.IsMarkedForDeletion(superparent) then
			return
		end

		if superparentEntTable.isDoneSpawningParts then
			return
		end

		if not superparentEntTable.isSpawningParts then
			return
		end

		superparentEntTable.isSpawningParts = nil

		local owner = LIBEntities.GetOwner(superparent)
		LIBSpamprotection.DelayNextSpawn(owner)

		LIBHook.RunCustom("SpawnSystemFinished", superparent, owner)

		self:EntityTimerRemove(superparent, timernameEventTimeout)

		superparentEntTable.isDoneSpawningParts = true
	end)

	if not superparentEntTable.isSpawningParts then
		superparentEntTable.isSpawningParts = true

		self:EntityTimerOnce(superparent, timernameEventTimeout, 2, function()
			if LIBEntities.IsMarkedForDeletion(superparent) then
				return
			end

			if superparentEntTable.isDoneSpawningParts then
				return
			end

			if not superparentEntTable.isSpawningParts then
				return
			end

			self:EntityTimerRemove(superparent, timernameEvent)

			superparentEntTable.isSpawningParts = nil
			superparentEntTable.isDoneSpawningParts = nil

			if SERVER then
				self:RemoveFaultyEntities(
					{superparent},
					"Infinite spawn loop detected at entity %s. Timeout after 2 seconds. Removing entities.",
					superparent
				)
			end
		end)
	end
end

return true

