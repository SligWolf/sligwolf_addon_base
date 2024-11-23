AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Detours = SligWolf_Addons.Detours or {}
table.Empty(SligWolf_Addons.Detours)

local LIB = SligWolf_Addons.Detours

local LIBSpawnmenu = nil
local LIBHook = nil

local g_detourBackups = SligWolf_Addons._detourBackups

if not g_detourBackups then
	error("SligWolf_Addons._detourBackups missing, bad install?")
	return
end

function LIB.CreateRemoverToolHook()
	g_detourBackups.utilEffect = g_detourBackups.utilEffect or util.Effect
	local oldFunc = g_detourBackups.utilEffect

	-- We override util.Effect, because that the only way to detect the entity
	-- being removed by the remover toolgun.

	util.Effect = function(name, effectData, ...)
		if name ~= "entity_remove" then
			return oldFunc(name, effectData, ...)
		end

		if not effectData then
			return oldFunc(name, effectData, ...)
		end

		local ent = effectData:GetEntity()
		if not IsValid(ent) then
			return oldFunc(name, effectData, ...)
		end

		if ent:IsMarkedForDeletion() then
			return oldFunc(name, effectData, ...)
		end

		-- Make sure we only affect entities spawned by our addon code
		if not ent.sligwolf_entity then
			return oldFunc(name, effectData, ...)
		end

		-- Make sure the effect is emitted from inside the remover tool function
		if not ent:GetNoDraw() then
			return oldFunc(name, effectData, ...)
		end

		local entTable = ent:SligWolf_GetTable()
		if entTable.hasCalledRemoveEffectHook then
			return oldFunc(name, effectData, ...)
		end

		entTable.hasCalledRemoveEffectHook = true
		entTable.isMarkedForDeletionWithEffect = true

		LIBHook.RunCustom("EntityRemovedByToolgun", ent)

		return oldFunc(name, effectData, ...)
	end
end

function LIB.CreateDuplicaterPasteHooks()
	g_detourBackups.duplicatorCreateEntityFromTable = g_detourBackups.duplicatorCreateEntityFromTable or duplicator.CreateEntityFromTable
	local oldFunc = g_detourBackups.duplicatorCreateEntityFromTable

	-- We override duplicator.Paste, because that the only way to globally detect entity are being pasted.

	duplicator.CreateEntityFromTable = function(ply, ...)
		LIBHook.RunCustom("DuplicatorPrePaste", ply)

		local result = {oldFunc(ply, ...)}
		local ent = result[1]

		if not IsValid(ent) then
			ent = nil
		end

		LIBHook.RunCustom("DuplicatorPostPaste", ply)
		return unpack(result)
	end
end

function LIB.CreateAdvDuplicater1PasteHooks()
	if not AdvDupe then
		return
	end

	if not AdvDupe.CreateEntityFromTable then
		return
	end

	g_detourBackups.AdvDupe1CreateEntityFromTable = g_detourBackups.AdvDupe1CreateEntityFromTable or AdvDupe.CreateEntityFromTable
	local oldFunc = g_detourBackups.AdvDupe1CreateEntityFromTable

	-- We override duplicator.Paste, because that the only way to globally detect entity are being pasted.

	AdvDupe.CreateEntityFromTable = function(ply, ...)
		LIBHook.RunCustom("DuplicatorPrePaste", ply)

		local result = {oldFunc(ply, ...)}
		local ent = result[1]

		if not IsValid(ent) then
			ent = nil
		end

		LIBHook.RunCustom("DuplicatorPostPaste", ply)
		return unpack(result)
	end
end

function LIB.FixSENTAliases()
	g_detourBackups.scriptedentsGetMember = g_detourBackups.scriptedentsGetMember or scripted_ents.GetMember
	local oldFunc = g_detourBackups.scriptedentsGetMember

	-- The affected functions do not respect scripted_ents.Alias(), so we had to add a substitute for it.

	scripted_ents.GetMember = function(name, membername, ...)
		name = LIBSpawnmenu.GetEntityClassFromAlias(name) or name
		return oldFunc(name, membername, ...)
	end

	g_detourBackups.scriptedentsGetStored = g_detourBackups.scriptedentsGetStored or scripted_ents.GetStored
	local oldFunc = g_detourBackups.scriptedentsGetStored

	scripted_ents.GetStored = function(name, ...)
		name = LIBSpawnmenu.GetEntityClassFromAlias(name) or name
		return oldFunc(name, ...)
	end

	g_detourBackups.scriptedentsGetType = g_detourBackups.scriptedentsGetType or scripted_ents.GetType
	local oldFunc = g_detourBackups.scriptedentsGetType

	scripted_ents.GetType = function(name, ...)
		name = LIBSpawnmenu.GetEntityClassFromAlias(name) or name
		return oldFunc(name, ...)
	end

	g_detourBackups.scriptedentsIsBasedOn = g_detourBackups.scriptedentsIsBasedOn or scripted_ents.IsBasedOn
	local oldFunc = g_detourBackups.scriptedentsIsBasedOn

	scripted_ents.IsBasedOn = function(name, base, ...)
		name = LIBSpawnmenu.GetEntityClassFromAlias(name) or name
		base = LIBSpawnmenu.GetEntityClassFromAlias(base) or base

		return oldFunc(name, base, ...)
	end

	g_detourBackups.scriptedentsGetList = g_detourBackups.scriptedentsGetList or scripted_ents.GetList
	local oldFunc = g_detourBackups.scriptedentsGetList

	scripted_ents.GetList = function(...)
		local realEntities = oldFunc(...)
		local result = {}

		for class, data in pairs(realEntities) do
			result[class] = data
		end

		local aliases = LIBSpawnmenu.GetEntityAliasList()

		for alias, class in pairs(aliases) do
			local aliasData = result[class]
			if not aliasData then
				continue
			end

			result[alias] = aliasData
		end

		return result
	end

	g_detourBackups.scriptedentsGetSpawnable = g_detourBackups.scriptedentsGetSpawnable or scripted_ents.GetSpawnable
	local oldFunc = g_detourBackups.scriptedentsGetSpawnable

	scripted_ents.GetSpawnable = function(...)
		local realEntities = oldFunc(...)
		local tmp = {}

		for _, data in ipairs(realEntities) do
			tmp[class] = data
		end

		local aliases = LIBSpawnmenu.GetEntityAliasList()

		for alias, class in pairs(aliases) do
			local aliasData = tmp[class]
			if not aliasData then
				continue
			end

			tmp[alias] = aliasData
		end

		local result = {}

		for k, data in pairs(tmp) do
			table.insert(result, data)
		end

		return result
	end
end

if SERVER then
	LIB.CreateRemoverToolHook()
	LIB.CreateDuplicaterPasteHooks()
end

LIB.FixSENTAliases()

function LIB.Load()
	LIBSpawnmenu = SligWolf_Addons.Spawnmenu
	LIBHook = SligWolf_Addons.Hook
end

function LIB.AllAddonsLoaded()
	if SERVER then
		LIB.CreateAdvDuplicater1PasteHooks()
	end
end

return true

