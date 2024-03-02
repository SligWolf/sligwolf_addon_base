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

	local path = LIBEntities.GetEntityPath(ent)

	superparent.SLIGWOLF_Vars = superparent.SLIGWOLF_Vars or {}
	local vars = superparent.SLIGWOLF_Vars

	name = LIBUtil.ValidateName(name)
	name = self.NetworkaddonID .. "/" .. path .. "/!" .. name

	local data = vars.Data or {}
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

	local path = LIBEntities.GetEntityPath(ent)

	superparent.SLIGWOLF_Vars = superparent.SLIGWOLF_Vars or {}
	local vars = superparent.SLIGWOLF_Vars

	name = LIBUtil.ValidateName(name)
	name = self.NetworkaddonID .. "/" .. path .. "/!" .. name

	vars.Data = vars.Data or {}
	vars.Data[name] = value
end

function SLIGWOLF_ADDON:HandleSpawnFinishedEvent(superparent)
	if superparent.sligwolf_isDoneSpawningParts then
		return
	end

	local timernameEvent = "HandleSpawnFinishedEvent"
	local timernameEventTimeout = "HandleSpawnFinishedEventTimeout"

	self:EntityTimerOnce(superparent, timernameEvent, 0.26, function()
		if superparent:IsMarkedForDeletion() then
			return
		end

		if superparent.sligwolf_isDoneSpawningParts then
			return
		end

		if not superparent.sligwolf_isSpawningParts then
			return
		end

		superparent.sligwolf_isSpawningParts = nil

		local owner = LIBEntities.GetOwner(superparent)

		hook.Run("SLIGWOLF_SpawnSystemFinished", superparent, owner)

		self:EntityTimerRemove(superparent, timernameEventTimeout)

		superparent.sligwolf_isDoneSpawningParts = true
	end)

	if not superparent.sligwolf_isSpawningParts then
		superparent.sligwolf_isSpawningParts = true

		self:EntityTimerOnce(superparent, timernameEventTimeout, 2, function()
			if superparent:IsMarkedForDeletion() then
				return
			end

			if superparent.sligwolf_isDoneSpawningParts then
				return
			end

			if not superparent.sligwolf_isSpawningParts then
				return
			end

			self:EntityTimerRemove(superparent, timernameEvent)

			superparent.sligwolf_isSpawningParts = nil
			superparent.sligwolf_isDoneSpawningParts = nil

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

function SLIGWOLF_ADDON:SetupDupeModifier(ent, name, precopycallback, postcopycallback)
	if not IsValid(ent) then return end

	name = LIBUtil.ValidateName(name)
	if name == "" then return end

	local superparent = LIBEntities.GetSuperParent(ent) or ent
	if not IsValid(superparent) then return end

	superparent.SLIGWOLF_Vars = superparent.SLIGWOLF_Vars or {}
	local vars = superparent.SLIGWOLF_Vars

	if vars.duperegistered then return end

	if not isfunction(precopycallback) then
		precopycallback = function() end
	end

	if not isfunction(postcopycallback) then
		postcopycallback = function() end
	end

	local oldprecopy = superparent.PreEntityCopy or function() end
	local dupename = "SLIGWOLF_Common_MakeEnt_Dupe_" .. self.NetworkaddonID  .. "_" .. name
	vars.dupename = dupename

	superparent.PreEntityCopy = function(...)
		if IsValid(superparent) then
			precopycallback(superparent)
		end

		vars.Data = vars.Data or {}
		duplicator.StoreEntityModifier(superparent, dupename, vars.Data)

		return oldprecopy(...)
	end
	vars.duperegistered = true

	self.duperegistered = self.duperegistered or {}
	if self.duperegistered[dupename] then return end

	duplicator.RegisterEntityModifier(dupename, function(ply, ent, data)
		if not IsValid(ent) then return end

		self:EntityTimerUntil(ent, "registerEntityModifier_" .. name, 0.1, function()
			local superparent = LIBEntities.GetSuperParent(ent) or ent
			if not IsValid(superparent) then return end

			-- delay the dupe modifier until the entire entity system has been spawned
			if superparent.sligwolf_isSpawningParts then return end

			superparent.SLIGWOLF_Vars = superparent.SLIGWOLF_Vars or {}
			local vars = superparent.SLIGWOLF_Vars

			vars.Data = data or {}

			if IsValid(superparent) then
				postcopycallback(superparent)
			end

			return true
		end)
	end)

	self.duperegistered[dupename] = true
end

return true

