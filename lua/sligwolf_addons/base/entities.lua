AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SLIGWOLF_ADDON then
	SligWolf_Addons.AutoLoadAddon(function() end)
	return
end

local LIBEntities = SligWolf_Addons.Entities
local LIBUtil = SligWolf_Addons.Util
local LIBTimer = SligWolf_Addons.Timer

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
		self:RemoveFaultyEntites(
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

function SLIGWOLF_ADDON:RemoveFaultyEntites(tb, errReasonFormat, ...)
	LIBEntities.RemoveEntites(tb)
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

function SLIGWOLF_ADDON:GetVal(ent, name, default)
	if not IsValid(ent) then return end

	local superparent = LIBEntities.GetSuperParent(ent) or ent
	if not IsValid(superparent) then return end

	local superparentEntTable = superparent:SligWolf_GetTable()
	local path = LIBEntities.GetEntityPath(ent)

	name = LIBUtil.ValidateName(name)
	name = self.NetworkaddonID .. "/" .. path .. "/!" .. name

	local data = superparentEntTable.Data
	if not data then
		return default
	end

	local value = data[name]

	if value == nil then
		value = default
	end

	return value
end

function SLIGWOLF_ADDON:SetVal(ent, name, value)
	if not IsValid(ent) then return end

	local superparent = LIBEntities.GetSuperParent(ent) or ent
	if not IsValid(superparent) then return end

	local superparentEntTable = superparent:SligWolf_GetTable()
	local path = LIBEntities.GetEntityPath(ent)

	name = LIBUtil.ValidateName(name)
	name = self.NetworkaddonID .. "/" .. path .. "/!" .. name

	local data = superparentEntTable.Data or {}
	superparentEntTable.Data = data

	data[name] = value
end

function SLIGWOLF_ADDON:HandleSpawnFinishedEventInternal(superparent)
	local superparentEntTable = superparent:SligWolf_GetTable()

	if superparentEntTable.isDoneSpawningParts then
		return
	end

	local timernameEvent = "HandleSpawnFinishedEvent"
	local timernameEventTimeout = "HandleSpawnFinishedEventTimeout"

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

		hook.Run("SLIGWOLF_SpawnSystemFinished", superparent, owner)

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
				self:RemoveFaultyEntites(
					{superparent},
					"Infinite spawn loop detected at entity %s. Timeout after 2 seconds. Removing entities.",
					superparent
				)
			end
		end)
	end
end

function SLIGWOLF_ADDON:HandleSpawnFinishedEvent(ent)
	if LIBEntities.IsMarkedForDeletion(ent) then
		return
	end

	LIBTimer.SimpleNextFrame(function()
		if LIBEntities.IsMarkedForDeletion(ent) then
			return
		end

		local superparent = LIBEntities.GetSuperParent(ent)
		if not IsValid(superparent) then return end

		if LIBEntities.IsMarkedForDeletion(superparent) then
			return
		end

		self:HandleSpawnFinishedEventInternal(superparent)
	end)
end

function SLIGWOLF_ADDON:SetupDupeModifier(ent, name, precopycallback, postcopycallback)
	if not IsValid(ent) then return end

	name = LIBUtil.ValidateName(name)
	if name == "" then return end

	local superparent = LIBEntities.GetSuperParent(ent)
	if not IsValid(superparent) then return end

	local superparentEntTable = superparent:SligWolf_GetTable()
	if superparentEntTable.duperegistered then return end

	if not isfunction(precopycallback) then
		precopycallback = function() end
	end

	if not isfunction(postcopycallback) then
		postcopycallback = function() end
	end

	local oldPreEntityCopy = superparent.PreEntityCopy or function() end
	local oldOnEntityCopyTableFinish = superparent.OnEntityCopyTableFinish or function() end

	local dupename = "SLIGWOLF_Common_MakeEnt_Dupe_" .. self.NetworkaddonID  .. "_" .. name
	superparentEntTable.dupename = dupename

	superparent.PreEntityCopy = function(thisent, ...)
		local thisSuperparent = LIBEntities.GetSuperParent(thisent)
		if not IsValid(thisSuperparent) then return end

		local thisSuperparentEntTable = thisSuperparent:SligWolf_GetTable()

		if IsValid(thisSuperparent) then
			precopycallback(thisSuperparent)
		end

		local data = table.Copy(thisSuperparentEntTable.Data or {})
		duplicator.StoreEntityModifier(thisSuperparent, dupename, data)

		return oldPreEntityCopy(thisent, ...)
	end

	superparent.OnEntityCopyTableFinish = function(thisent, data, ...)
		LIBEntities.RemoveBadDupeData(data)
		return oldOnEntityCopyTableFinish(thisent, data, ...)
	end

	superparentEntTable.duperegistered = true

	self.duperegistered = self.duperegistered or {}
	if self.duperegistered[dupename] then
		return
	end

	local calledEntityModifier = false
	local timerName = "registerEntityModifier_" .. name

	local entityModifierCallback = function(ply, ent, data)
		calledEntityModifier = true

		if not IsValid(ent) then
			return
		end

		self:EntityTimerUntil(ent, timerName, 0.1, function()
			local thisSuperparent = LIBEntities.GetSuperParent(ent)
			if not IsValid(thisSuperparent) then
				return
			end

			local thisSuperparentEntTable = thisSuperparent:SligWolf_GetTable()

			-- delay the dupe modifier until the entire entity system has been spawned
			if thisSuperparentEntTable.isSpawningParts then
				return
			end

			thisSuperparentEntTable.Data = table.Copy(data or {})

			postcopycallback(thisSuperparent)

			return true
		end)
	end

	duplicator.RegisterEntityModifier(dupename, entityModifierCallback)

	self.duperegistered[dupename] = true

	if calledEntityModifier then
		return
	end

	self:EntityTimerNextFrame(ent, timerName, function()
		if calledEntityModifier then
			return
		end

		local entityMods = ent.EntityMods
		if not entityMods then
			return
		end

		local data = entityMods[dupename]
		if not data then
			return
		end

		entityModifierCallback(nil, ent, data)
	end)
end

return true

