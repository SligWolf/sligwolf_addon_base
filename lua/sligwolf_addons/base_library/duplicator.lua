AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Duplicator = SligWolf_Addons.Duplicator or {}
table.Empty(SligWolf_Addons.Duplicator)

local LIB = SligWolf_Addons.Duplicator

local LIBPosition = nil
local LIBEntities = nil
local LIBTimer = nil
local LIBHook = nil
local LIBMeta = nil

local g_mainEntityModifierName = "SLIGWOLF_Library_Duplicator_MainEntityModifier"
local g_emptyFunction = function() end

function LIB.RemoveBadDupeData(data)
	if not data then return end

	LIBMeta.RemoveBadDupeData(data)

	if not data.sligwolf_entity then
		return
	end

	data.spawnname = nil
	data.spawnProperties = nil
	data.defaultSpawnProperties = nil

	data.addonCache = nil
	data.addonIdCache = nil

	data.DoNotDuplicate = nil

	-- Remove values whose names starting with "_", "sligwolf_" or "SLIGWOLF_"
	for key, _ in pairs(data) do
		if not isstring(key) then
			continue
		end

		if key == "" then
			continue
		end

		if string.StartsWith(key, "_") then
			data[key] = nil
			continue
		end

		if string.StartsWith(key, "sligwolf_") then
			data[key] = nil
			continue
		end

		if string.StartsWith(key, "SLIGWOLF_") then
			data[key] = nil
			continue
		end
	end
end

local function postCopyCallback(ply, ent, data)
	if not IsValid(ent) then
		return
	end

	data = data or {}

	local timerName = LIBTimer.GetEntityTimerName(ent, "RegisterEntityModifierCallback")

	LIBTimer.Remove(timerName)
	LIBTimer.Until(timerName, 0.1, function()
		if not IsValid(ent) then
			return true
		end

		local superparent = LIBEntities.GetSuperParent(ent)
		if not IsValid(superparent) then
			return true
		end

		if LIBPosition.IsAsyncPositioning(superparent) then
			return false
		end

		local superparentEntTable = superparent:SligWolf_GetTable()

		if superparentEntTable.isSpawningParts then
			return false
		end

		local dupeRegister = superparentEntTable.dupeRegister
		if not dupeRegister then
			return false
		end

		for name, dupeRegisterItem in pairs(dupeRegister) do
			if not dupeRegisterItem.isRegistered then
				continue
			end

			if not dupeRegisterItem.postcopycallback then
				continue
			end

			local thisData = table.Copy(data[name] or {})

			dupeRegisterItem.postcopycallback(superparent, thisData)
		end

		return true
	end, 100)
end

duplicator.RegisterEntityModifier(g_mainEntityModifierName, postCopyCallback)

local function preEntityCopyCallback(ent)
	if not IsValid(ent) then
		return
	end

	local superparent = LIBEntities.GetSuperParent(ent)
	if not IsValid(superparent) then
		return
	end

	local superparentEntTable = superparent:SligWolf_GetTable()

	if superparentEntTable.isSpawningParts then
		return false
	end

	local dupeRegister = superparentEntTable.dupeRegister
	if not dupeRegister then
		return false
	end

	duplicator.ClearEntityModifier(superparent, g_mainEntityModifierName)

	local data = {}

	for name, dupeRegisterItem in pairs(dupeRegister) do
		if not dupeRegisterItem.isRegistered then
			continue
		end

		if not dupeRegisterItem.precopycallback then
			continue
		end

		local thisData = {}
		local tmp = dupeRegisterItem.precopycallback(superparent, thisData)

		if istable(tmp) then
			thisData = tmp
		end

		data[name] = table.Copy(thisData)
	end

	duplicator.StoreEntityModifier(superparent, g_mainEntityModifierName, data)
end

function LIB.RegisterEntityDuplicatorModifier(ent, params)
	if not IsValid(ent) then return end

	local superparent = LIBEntities.GetSuperParent(ent)
	if not IsValid(superparent) then
		return
	end

	local superparentEntTable = superparent:SligWolf_GetTable()

	local dupeRegister = superparentEntTable.dupeRegister or {}
	superparentEntTable.dupeRegister = dupeRegister

	params = params or {}
	local name = tostring(params.name or "")

	local dupeRegisterItem = dupeRegister[name] or {}
	dupeRegister[name] = dupeRegisterItem

	if dupeRegisterItem.isRegistered then
		return
	end

	local precopycallback = params.copy
	local postcopycallback = params.paste

	if not isfunction(precopycallback) then
		precopycallback = g_emptyFunction
	end

	if not isfunction(postcopycallback) then
		postcopycallback = g_emptyFunction
	end

	dupeRegisterItem.name = name
	dupeRegisterItem.precopycallback = precopycallback
	dupeRegisterItem.postcopycallback = postcopycallback

	dupeRegisterItem.isRegistered = true

	if superparentEntTable.dupeRegisterCallbacksRegistered then
		return
	end

	superparentEntTable.dupeRegisterCallbacksRegistered = true

	local oldPreEntityCopy = superparent.PreEntityCopy or g_emptyFunction
	local oldOnEntityCopyTableFinish = superparent.OnEntityCopyTableFinish or g_emptyFunction

	superparent.PreEntityCopy = function(thisent, ...)
		preEntityCopyCallback(thisent, ...)
		return oldPreEntityCopy(thisent, ...)
	end

	superparent.OnEntityCopyTableFinish = function(thisent, data, ...)
		LIB.RemoveBadDupeData(data)
		return oldOnEntityCopyTableFinish(thisent, data, ...)
	end
end


function LIB.Load()
	LIBPosition = SligWolf_Addons.Position
	LIBEntities = SligWolf_Addons.Entities
	LIBTimer = SligWolf_Addons.Timer
	LIBHook = SligWolf_Addons.Hook
	LIBMeta = SligWolf_Addons.Meta

	if SERVER then
		local function onDuplicated(ent, ...)
			if not IsValid(ent) then return end

			local entTable = ent:SligWolf_GetTable()
			local oldOnDuplicated = entTable._oldOnDuplicated

			entTable.isDuped = true

			if isfunction(oldOnDuplicated) then
				oldOnDuplicated(ent, ...)
			end

			local swOnDuplicated = entTable.OnDuplicated
			if isfunction(swOnDuplicated) then
				swOnDuplicated(ent, ...)
			end
		end

		local function OnEntityCreated(ent)
			if not IsValid(ent) then return end

			local entTable = ent:SligWolf_GetTable()
			entTable._oldOnDuplicated = entTable._oldOnDuplicated or ent.OnDuplicated

			ent.OnDuplicated = onDuplicated
		end

		LIBHook.Add("OnEntityCreated", "Library_Duplicator_OnEntityCreated", OnEntityCreated, 1000)
	end
end

return true

