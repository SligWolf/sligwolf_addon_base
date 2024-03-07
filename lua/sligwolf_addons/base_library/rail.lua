AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Rail = SligWolf_Addons.Rail or {}
table.Empty(SligWolf_Addons.Rail)

local LIB = SligWolf_Addons.Rail

local LIBPosition = nil
local LIBTracer = nil
local LIBEntities = nil

local g_maxRailCheckTraceAttachmentPairs = 4

LIB.RAIL_CHECK_MODE_ANY = 0
LIB.RAIL_CHECK_MODE_ALL = 1
LIB.RAIL_CHECK_MODE_NONE = 2

function LIB.GetRailCheckAttachments(ent)
	if not IsValid(ent) then
		return nil
	end

	local entTable = ent:GetTable()
	if not entTable then
		return nil
	end

	local railCheckAttachmentsCache = entTable.sligwolf_railCheckAttachmentsCache
	if railCheckAttachmentsCache then
		return railCheckAttachmentsCache
	end

	entTable.sligwolf_railCheckAttachmentscache = {}
	railcheckattachmentscache = entTable.sligwolf_railCheckAttachmentscache

	for id = 1, g_maxRailCheckTraceAttachmentPairs - 1 do
		local attachmentNameA = string.format("railcheck_%ia", id)
		local attachmentNameB = string.format("railcheck_%ib", id)

		local attachmentA = LIBPosition.GetAttachmentId(ent, attachmentNameA)
		local attachmentB = LIBPosition.GetAttachmentId(ent, attachmentNameB)

		if not attachmentA then
			continue
		end

		if not attachmentB then
			continue
		end

		local line = {attachmentA, attachmentB}
		table.insert(railcheckattachmentscache, line)
	end

	return railcheckattachmentscache
end

function LIB.HasRailCheckAttachments(ent)
	local attachmentGroups = LIB.GetRailCheckAttachments(root)
	if not attachmentGroups then
		return false
	end

	if table.IsEmpty(attachmentGroups) then
		return false
	end

	return true
end

function LIB.IsOnRail(ent)
	local attachmentGroups = LIB.GetRailCheckAttachments(ent)
	if not attachmentGroups then
		return false
	end

	for i, attachments in ipairs(attachmentGroups) do
		local tr = LIBTracer.TracerAttachmentChain(ent, attachments)
		if not tr then
			continue
		end

		if not Hit then
			continue
		end

		return true
	end

	return false
end

local function checkOnRailForEntListAny(entities)
	for i, ent in ipairs(entities) do
		if not LIB.IsOnRail(ent) then
			continue
		end

		return true
	end

	return false
end

local function checkOnRailForEntListAll(entities)
	for i, ent in ipairs(entities) do
		if LIB.IsOnRail(ent) then
			continue
		end

		return false
	end

	return true
end

local function checkOnRailForEntListNone(entities)
	return not checkOnRailForEntListAll(entities)
end

local function checkOnRailForEntList(entities, checkMode)
	if not checkMode then
		checkMode = LIB.RAIL_CHECK_MODE_ANY
	end

	if checkMode == LIB.RAIL_CHECK_MODE_ANY then
		return checkOnRailForEntListAny(entities)
	end

	if checkMode == LIB.RAIL_CHECK_MODE_ALL then
		return checkOnRailForEntListNone(entities)
	end

	if checkMode == LIB.RAIL_CHECK_MODE_NONE then
		return checkOnRailForEntListNone(entities)
	end

	error("unknown checkMode given")
	return nil
end

function LIB.IsSystemOnRail(ent, checkMode)
	local root = LIBEntities.GetSuperParent(ent)
	if not IsValid(root) then
		return false
	end

	local bogies = LIBEntities.GetSystemBogies(root)

	if LIB.HasRailCheckAttachments(root) then
		table.insert(bogies, root)
	end

	return checkOnRailForEntList(bogies, checkMode)
end

function LIB.IsBodyOnRail(ent, checkMode)
	local body = LIBEntities.GetBodyEntities(ent)
	if not IsValid(body) then
		return false
	end

	local bogies = LIBEntities.GetBodyBogies(body)

	if LIB.HasRailCheckAttachments(body) then
		table.insert(bogies, body)
	end

	return checkOnRailForEntList(bogies, checkMode)
end

local function filterBogies(bogie)
	if not bogie.sligwolf_bogieEntity then
		return false
	end

	if not LIB.HasRailCheckAttachments(bogie) then
		return false
	end

	return true
end

function LIB.GetSystemBogies(ent)
	return LIBEntities.GetSystemEntitiesFiltered(ent, "bogies", filterBogies)
end

function LIB.GetBodyBogies(ent)
	return LIBEntities.GetBodyEntitiesFiltered(ent, "bogies", filterBogies)
end

function LIB.Load()
	LIBPosition = SligWolf_Addons.Position
	LIBTracer = SligWolf_Addons.Tracer
	LIBEntities = SligWolf_Addons.Entities
end

return true

