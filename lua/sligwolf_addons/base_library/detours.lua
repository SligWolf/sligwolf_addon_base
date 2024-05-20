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

		hook.Run("SLIGWOLF_EntityRemovedByToolgun", ent)

		return oldFunc(name, effectData, ...)
	end
end

function LIB.CreateDuplicaterPasteHooks()
	g_detourBackups.duplicatorCreateEntityFromTable = g_detourBackups.duplicatorCreateEntityFromTable or duplicator.CreateEntityFromTable
	local oldFunc = g_detourBackups.duplicatorCreateEntityFromTable

	-- We override duplicator.Paste, because that the only way to globally detect entity are being pasted.

	duplicator.CreateEntityFromTable = function(ply, ...)
		hook.Run("SLIGWOLF_DuplicatorPrePaste", ply)

		local result = {oldFunc(ply, ...)}
		local ent = result[1]

		if not IsValid(ent) then
			ent = nil
		end

		hook.Run("SLIGWOLF_DuplicatorPostPaste", ply)
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
		hook.Run("SLIGWOLF_DuplicatorPrePaste", ply)

		local result = {oldFunc(ply, ...)}
		local ent = result[1]

		if not IsValid(ent) then
			ent = nil
		end

		hook.Run("SLIGWOLF_DuplicatorPostPaste", ply)
		return unpack(result)
	end
end

if SERVER then
	LIB.CreateRemoverToolHook()
	LIB.CreateDuplicaterPasteHooks()
end

function LIB.AllAddonsLoaded()
	if SERVER then
		LIB.CreateAdvDuplicater1PasteHooks()
	end
end

return true

