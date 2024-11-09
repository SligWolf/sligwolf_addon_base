AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Model = SligWolf_Addons.Model or {}
table.Empty(SligWolf_Addons.Model)

local LIB = SligWolf_Addons.Model

local CONSTANTS = SligWolf_Addons.Constants

local LIBPrint = nil

local g_IsValidModelCache = {}
local g_IsValidModelFileCache = {}

function LIB.IsGmodErrorModel(model)
	model = tostring(model or "")

	if model == "" then
		return true
	end

	if model == CONSTANTS.mdlGmodError then
		return true
	end

	return false
end

function LIB.IsErrorModel(model)
	model = tostring(model or "")

	if LIB.IsGmodErrorModel(model) then
		return true
	end

	if model == CONSTANTS.mdlError then
		return true
	end

	return false
end

function LIB.IsValidModel(model)
	model = tostring(model or "")

	if LIB.IsGmodErrorModel(model) then
		return false
	end

	if g_IsValidModelCache[model] then
		return true
	end

	g_IsValidModelCache[model] = nil

	if not LIB.IsValidModelFile(model) then
		return false
	end

	util.PrecacheModel(model)

	if not util.IsValidModel(model) then
		return false
	end

	g_IsValidModelCache[model] = true
	return true
end

function LIB.IsValidModelFile(model)
	model = tostring(model or "")

	if LIB.IsGmodErrorModel(model) then
		return false
	end

	if g_IsValidModelFileCache[model] then
		return true
	end

	g_IsValidModelFileCache[model] = nil

	if model == "" then
		return false
	end

	if IsUselessModel(model) then
		return false
	end

	if not file.Exists(model, "GAME") then
		return false
	end

	g_IsValidModelFileCache[model] = true
	return true
end

local g_ModelCache = {}
local g_loadedModels = nil

function LIB.LoadModel(path, fallbackPath)
	path = tostring(path or "")
	fallbackPath = tostring(fallbackPath or "")

	local err = CONSTANTS.mdlError
	if path == "" then
		path = err
	end

	if fallbackPath == "" then
		fallbackPath = err
	end

	if path == err then
		path = fallbackPath
	end

	if path == fallbackPath then
		fallbackPath = err
	end

	local cacheId = string.format("%s_%s", path, fallbackPath)

	if g_ModelCache[cacheId] ~= nil then
		local mdl = g_ModelCache[cacheId]
		if not mdl then
			return nil
		end

		return mdl
	end

	g_ModelCache[cacheId] = false

	if not LIB.IsValidModel(path) then
		local mdl = LIB.LoadModel(fallbackPath, err)

		if LIB.IsGmodErrorModel(mdl) then
			return nil
		end

		g_ModelCache[cacheId] = mdl
		return mdl
	end

	util.PrecacheModel(path)

	g_ModelCache[cacheId] = path
	g_loadedModels = nil

	return path
end

LIB.LoadModel(CONSTANTS.mdlError)

function LIB.GetLoadedModels()
	if g_loadedModels then
		return g_loadedModels
	end

	g_loadedModels = {}

	for _, mdl in pairs(g_ModelCache) do
		if not mdl then
			continue
		end

		table.insert(g_loadedModels, mdl)
	end

	table.sort(g_loadedModels)

	return g_loadedModels
end

function LIB.IsValidModelEntity(ent)
	if not IsValid(ent) then return false end

	local model = tostring(ent:GetModel() or "")
	if model == "" then return false end

	if not LIB.IsValidModel(model) then return false end
	return true
end

function LIB.SetModel(ent, path, fallbackPath)
	path = tostring(path or "")
	fallbackPath = tostring(fallbackPath or "")

	local entTable = ent:SligWolf_GetTable()
	local oldModel = entTable.model

	local model = LIB.LoadModel(path, fallbackPath)

	local valid = true

	if LIB.IsGmodErrorModel(model) then
		LIBPrint.ErrorNoHaltWithStack(
			"Model.SetModel: Entity has invalid model.\n  Entity: %s\n  Model: %s\n  Fallback: %s",
			ent,
			path ~= "" and path or "<empty>",
			fallbackPath ~= "" and fallbackPath or "<empty>"
		)

		model = CONSTANTS.mdlGmodError
		valid = false
	elseif LIB.IsErrorModel(model) and LIB.IsErrorModel(fallbackPath) then
		LIBPrint.ErrorNoHaltWithStack(
			"Model.SetModel: Entity has global fallback model.\n  Entity: %s\n  Model: %s\n  Fallback: %s",
			ent,
			path ~= "" and path or "<empty>",
			fallbackPath ~= "" and fallbackPath or "<empty>"
		)

		valid = false
	end

	if oldModel and model == oldModel then
		return entTable.validmodel
	end

	entTable.model = path
	ent:SetModel(path)

	entTable.validmodel = valid
	return valid
end

function LIB.GuessAddonIDByModelName(model)
	if not LIB.IsValidModel(model) then
		return
	end

	local addonid = string.match(model, "^models/sligwolf/([%w%s_]+)/" ) or ""
	if addonid == "" then
		return
	end

	if not SligWolf_Addons.HasLoadedAddon(addonid) then
		return
	end

	return addonid
end

function LIB.Load()
	LIBPrint = SligWolf_Addons.Print
end

return true

