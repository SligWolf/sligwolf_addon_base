local SligWolf_Addons = _G.SligWolf_Addons
if not SligWolf_Addons then
	return
end

local LIB = SligWolf_Addons:NewLib("Rail")

local CONSTANTS = SligWolf_Addons.Constants

local LIBPosition = SligWolf_Addons.Position
local LIBEntities = SligWolf_Addons.Entities
local LIBTracer = SligWolf_Addons.Tracer

local g_maxRailCheckTraceAttachmentPairs = 4

LIB.ENUM_RAIL_CHECK_MODE_ALL = 0
LIB.ENUM_RAIL_CHECK_MODE_NONE = 1
LIB.ENUM_RAIL_CHECK_MODE_ANY = 2

LIB.ENUM_GAUGE_DEFAULT = "default"
LIB.ENUM_GAUGE_AUTO = "auto"

LIB.ENUM_GAUGE_PHX = "phx"
LIB.ENUM_GAUGE_RSG = "rsg"
LIB.ENUM_GAUGE_RSG3FT = "rsg3ft"
LIB.ENUM_GAUGE_RON2FT = "ron2ft"
LIB.ENUM_GAUGE_MT12 = "mt12"

local g_spawnnamePartToGaugeRegister = LIB.g_spawnnamePartToGaugeRegister or {}
LIB.g_spawnnamePartToGaugeRegister = g_spawnnamePartToGaugeRegister

local g_spawnnameFullToGaugeRegister = LIB.g_spawnnameFullToGaugeRegister or {}
LIB.g_spawnnameFullToGaugeRegister = g_spawnnameFullToGaugeRegister

local g_gaugesByName = LIB.g_gaugesByName or {}
LIB.g_gaugesByName = g_gaugesByName

local g_gaugesByWidth = LIB.g_gaugesByWidth or {}
LIB.g_gaugesByWidth = g_gaug_gaugesByWidthges

local g_gaugenameBlacklist = {
	[""] = true,
	[LIB.ENUM_GAUGE_DEFAULT] = true,
	[LIB.ENUM_GAUGE_AUTO] = true,
}

function LIB.GetRailCheckAttachments(ent)
	if not IsValid(ent) then
		return nil
	end

	local entTable = ent:SligWolf_GetTable()

	local railCheckAttachmentsCache = entTable.railCheckAttachmentsCache
	if railCheckAttachmentsCache then
		return railCheckAttachmentsCache
	end

	railCheckAttachmentsCache = {}
	entTable.railCheckAttachmentsCache = railCheckAttachmentsCache

	for id = 0, g_maxRailCheckTraceAttachmentPairs - 1 do
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
		table.insert(railCheckAttachmentsCache, line)
	end

	return railCheckAttachmentsCache
end

function LIB.HasRailCheckAttachments(ent)
	local attachmentGroups = LIB.GetRailCheckAttachments(ent)
	if not attachmentGroups then
		return false
	end

	if table.IsEmpty(attachmentGroups) then
		return false
	end

	return true
end

local function doIsOnRailTrace(ent)
	local attachmentGroups = LIB.GetRailCheckAttachments(ent)
	if not attachmentGroups then
		return false
	end

	for i, attachments in ipairs(attachmentGroups) do
		local tr = LIBTracer.TracerAttachmentChain(ent, attachments)
		if not tr then
			continue
		end

		if not tr.Hit then
			continue
		end

		local hitEnt = tr.Entity
		if IsValid(hitEnt) and hitEnt.sligwolf_ignoreOnRailCheck then
			continue
		end

		return true
	end

	return false
end

function LIB.IsOnRail(ent, bypassCache)
	if not IsValid(ent) then
		return false
	end

	local entTable = ent:SligWolf_GetTable()

	local now = RealTime()

	local isOnRailResultCache = entTable.isOnRailResultCache or {}
	entTable.isOnRailResultCache = isOnRailResultCache

	if bypassCache ~= true and isOnRailResultCache.nextRefresh and isOnRailResultCache.nextRefresh > now then
		return isOnRailResultCache.result
	end

	local result = doIsOnRailTrace(ent)

	isOnRailResultCache.result = result
	isOnRailResultCache.nextRefresh = now + 0.05

	return result
end

local function checkOnRailForEntListAny(entities, bypassCache, additionalBodyEnt)
	if LIB.HasRailCheckAttachments(additionalBodyEnt) and LIB.IsOnRail(additionalBodyEnt, bypassCache) then
		return true
	end

	if not entities then
		return false
	end

	for i, ent in ipairs(entities) do
		if not LIB.IsOnRail(ent, bypassCache) then
			continue
		end

		return true
	end

	return false
end

local function checkOnRailForEntListAll(entities, bypassCache, additionalBodyEnt)
	if LIB.HasRailCheckAttachments(additionalBodyEnt) and not LIB.IsOnRail(additionalBodyEnt, bypassCache) then
		return false
	end

	if not entities then
		return true
	end

	for i, ent in ipairs(entities) do
		if LIB.IsOnRail(ent, bypassCache) then
			continue
		end

		return false
	end

	return true
end

local function checkOnRailForEntListNone(entities, bypassCache, additionalBodyEnt)
	return not checkOnRailForEntListAny(entities, bypassCache, additionalBodyEnt)
end

local function checkOnRailForEntList(entities, bypassCache, checkMode, additionalBodyEnt)
	if not checkMode or checkMode == LIB.ENUM_RAIL_CHECK_MODE_ALL then
		return checkOnRailForEntListAll(entities, bypassCache, additionalBodyEnt)
	end

	if checkMode == LIB.ENUM_RAIL_CHECK_MODE_NONE then
		return checkOnRailForEntListNone(entities, bypassCache, additionalBodyEnt)
	end

	if checkMode == LIB.ENUM_RAIL_CHECK_MODE_ANY then
		return checkOnRailForEntListAny(entities, bypassCache, additionalBodyEnt)
	end

	error("unknown checkMode given")
	return nil
end

function LIB.IsSystemOnRail(ent, checkMode, bypassCache)
	local root = LIBEntities.GetSuperParent(ent)
	if not IsValid(root) then
		return false
	end

	local bogies = LIB.GetSystemBogies(root)
	return checkOnRailForEntList(bogies, bypassCache, checkMode, root)
end

function LIB.IsWagonOnRail(ent, checkMode, bypassCache)
	local body = LIBEntities.GetNearstBody(ent)
	if not IsValid(body) then
		return false
	end

	local bogies = LIB.GetWagonBogies(body)
	return checkOnRailForEntList(bogies, bypassCache, checkMode, body)
end

function LIB.IsBogieOnRail(ent, bypassCache)
	local body = LIBEntities.GetNearstBody(ent)
	if not IsValid(body) then
		return false
	end

	local bogie = LIB.GetBogie(body)

	if not IsValid(bogie) and LIB.HasRailCheckAttachments(body) then
		bogie = body
	end

	if not LIB.IsOnRail(bogie, bypassCache) then
		return false
	end

	return true
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

function LIB.GetWagonBogies(ent)
	local body = LIBEntities.GetNearstBody(ent)
	if not IsValid(body) then
		return nil
	end

	local cache = LIBEntities.GetEntityCache(body).children
	if cache.Bogies then
		return cache.Bogies
	end

	local subBodies = LIBEntities.GetSubBodies(body)
	if not subBodies then
		return nil
	end

	local bogies = {}

	for _, child in pairs(subBodies) do
		local bogie = LIB.GetBogie(child)
		table.insert(bogies, bogie)
	end

	cache.Bogies = bogies
	return bogies
end

function LIB.GetBogie(ent)
	local body = LIBEntities.GetNearstBody(ent)
	if not IsValid(body) then
		return nil
	end

	local cache = LIBEntities.GetEntityCache(body).children
	local cachedBogie = cache.Bogie

	if cachedBogie ~= nil then
		if cachedBogie == false then
			return nil
		end

		return cachedBogie
	end

	local bogies = LIBEntities.GetBodyEntitiesFiltered(body, "bogies", filterBogies)

	for i, bogie in ipairs(bogies) do
		cache.Bogie = bogie
		return bogie
	end

	cache.Bogie = false
	return nil
end

local g_switchModels = {}

function LIB.AddSwitchModelStates(mainModel, states, printName)
	mainModel = tostring(mainModel or "")
	printName = tostring(printName or "")

	states = states or {}

	g_switchModels[mainModel] = g_switchModels[mainModel] or {}
	local statesOfModel = g_switchModels[mainModel]

	statesOfModel.ordered = statesOfModel.ordered or {}
	statesOfModel.indexed = statesOfModel.indexed or {}

	local ordered = statesOfModel.ordered
	local indexed = statesOfModel.indexed

	for name, item in pairs(states) do
		if not isstring(name) or name == "" then
			error(string.format("invalid model state name given for '%s'", mainModel))
			return
		end

		if indexed[name] then
			continue
		end

		local model = tostring(item.model or "")

		if model == "" then
			error(string.format("model for state '%s' was not given for '%s'", name, mainModel))
			return
		end

		local isDefault = name == "default"

		local order = tonumber(item.order or 0) or 0

		if isDefault then
			order = 0
		end

		item.order = order

		if not item.id or not isDefault then
			item.id = -1
		end

		if not item.name or not isDefault then
			item.name = name
		end

		item.model = model

		if order ~= 0 then
			table.insert(ordered, item)
		end

		indexed[name] = item
	end

	table.SortByMember(ordered, "order", true)

	for i, item in ipairs(ordered) do
		item.id = i
	end

	statesOfModel.count = #ordered
	statesOfModel.printName = printName
end

function LIB.GetSwitchModelStates(mainModel)
	mainModel = tostring(mainModel or "")

	local statesOfModel = g_switchModels[mainModel]
	if not statesOfModel then
		return
	end

	local count = statesOfModel.count or 0
	if count <= 0 then
		return
	end

	local ordered = statesOfModel.ordered
	local indexed = statesOfModel.indexed

	if not ordered then
		return
	end

	if not indexed then
		return
	end

	if table.IsEmpty(ordered) then
		return
	end

	if table.IsEmpty(indexed) then
		return
	end

	if not indexed["default"] then
		error(string.format("default state missing for '%s'", mainModel))
		return
	end

	return statesOfModel
end

function LIB.AddGauge(gaugename, params)
	gaugename = tostring(gaugename or "")
	gaugename = string.lower(gaugename)

	params = table.Copy(params or {})

	if gaugename == "" then
		error("bad name was given")
		return
	end

	if not params then
		error("params was not given")
		return
	end

	local isReal = g_gaugenameBlacklist[gaugename] ~= true
	local width = 0

	if isReal then
		width = tonumber(params.width or 0) or 0
		width = math.Round(width)

		if width < 4 then
			error("params.width is too small")
			return
		end

		if width > 128 then
			error("params.width is too large")
			return
		end
	end

	local title = tostring(params.title or "")
	local titleShort = string.upper(gaugename)

	if title == "" then
		title = titleShort
	end

	local scanParams = params.scanParams or {}
	local defaultTrainParams = params.defaultTrainParams or {}

	local gauge = {}
	g_gaugesByName[gaugename] = gauge
	g_gaugesByWidth[width] = gauge

	gauge.name = gaugename
	gauge.title = title
	gauge.titleShort = titleShort
	gauge.isReal = isReal

	gauge.width = width

	local gaugeScanParams = {}
	gauge.scanParams = gaugeScanParams

	local gaugeDefaultTrainParams = {}
	gauge.defaultTrainParams = gaugeDefaultTrainParams

	if isReal then
		gaugeScanParams.offsetPos = scanParams.offsetPos or CONSTANTS.vecZero
		gaugeScanParams.offsetAng = scanParams.offsetAng or CONSTANTS.angZero
		gaugeScanParams.maxRailTopTraceZ = scanParams.maxRailTopTraceZ
		gaugeScanParams.minRailTopTraceZ = scanParams.minRailTopTraceZ
		gaugeScanParams.marginRailTopTrace = scanParams.marginRailTopTrace
		gaugeScanParams.marginRailEdgeBelow = scanParams.marginRailEdgeBelow
		gaugeScanParams.marginRailEdgeAbove = scanParams.marginRailEdgeAbove
		gaugeScanParams.marginStraight = scanParams.marginStraight
		gaugeScanParams.layers = scanParams.layers

		gaugeDefaultTrainParams.trainSizeMin = defaultTrainParams.trainSizeMin or 0
		gaugeDefaultTrainParams.trainSizeMax = defaultTrainParams.trainSizeMax or 0
	end
end

function LIB.GetGaugeByName(gaugename)
	gaugename = tostring(gaugename or "")
	gaugename = string.lower(gaugename)

	local gauge = g_gaugesByName[gaugename]
	if not gauge then
		return nil
	end

	return gauge
end

function LIB.GetGaugeByWidth(gaugewidth)
	gaugewidth = tonumber(gaugewidth or 0) or 0
	gaugewidth = math.Round(gaugewidth)

	if gaugewidth <= 0 then
		return nil
	end

	local gauge = g_gaugesByWidth[gaugewidth]
	if not gauge then
		return nil
	end

	if not gauge.isReal then
		return nil
	end

	return gauge
end

function LIB.HasGaugeByName(gaugename)
	return LIB.GetGaugeByName(gaugename) ~= nil
end

function LIB.HasGaugeByWidth(gaugename)
	return LIB.GetGaugeByWidth(gaugename) ~= nil
end

function LIB.GetGauges()
	return g_gaugesByName
end

function LIB.RegisterSpawnnameToGauge(spawnnameNoGauge, gaugename, spawnnameFull)
	gaugename = tostring(gaugename or "")
	gaugename = string.lower(gaugename)

	if g_gaugenameBlacklist[gaugename] then
		return
	end

	spawnnameNoGauge = tostring(spawnnameNoGauge or "")
	if spawnnameNoGauge == "" then
		return
	end

	spawnnameFull = tostring(spawnnameFull or "")
	if spawnnameFull == "" then
		return
	end

	local gauges = g_spawnnamePartToGaugeRegister[spawnnameNoGauge] or {}
	g_spawnnamePartToGaugeRegister[spawnnameNoGauge] = gauges

	local entry = {}
	gauges[gaugename] = entry

	if not gauges[LIB.ENUM_GAUGE_DEFAULT] then
		g_spawnnameFullToGaugeRegister[spawnnameFull] = entry
		gauges[LIB.ENUM_GAUGE_DEFAULT] = entry
		gauges[LIB.ENUM_GAUGE_AUTO] = entry
	end

	entry.spawnnameFull = spawnnameFull
	entry.spawnnameNoGauge = spawnnameNoGauge
	entry.gaugename = gaugename
end

function LIB.GetSpawnnameInfo(spawnnameNoGaugeOrFull, gaugename)
	spawnnameNoGaugeOrFull = tostring(spawnnameNoGaugeOrFull or "")
	if spawnnameNoGaugeOrFull == "" then
		return nil
	end

	gaugename = tostring(gaugename or "")
	gaugename = string.lower(gaugename)

	if g_gaugenameBlacklist[gaugename] then
		gaugename = LIB.ENUM_GAUGE_DEFAULT
	end

	if gaugename == LIB.ENUM_GAUGE_DEFAULT then
		local entry = g_spawnnameFullToGaugeRegister[spawnnameNoGaugeOrFull]
		if entry and not g_gaugenameBlacklist[entry.gaugename] then
			return entry
		end
	end

	local gauges = g_spawnnamePartToGaugeRegister[spawnnameNoGaugeOrFull]
	if not gauges then
		return nil
	end

	entry = gauges[gaugename]
	if not entry then
		return nil
	end

	if g_gaugenameBlacklist[entry.gaugename] then
		return nil
	end

	return entry
end

do
	-- Large rails, such as: PHX, rsg, rsg3ft, ron2ft
	local scanParamsLarge = {
		offsetPos = Vector(0, 0, -5),
		offsetAng = Angle(0, 0, 0),
		maxRailTopTraceZ = 32,
		minRailTopTraceZ = 0,
		marginRailTopTrace = 3,
		marginRailEdgeBelow = 4,
		marginRailEdgeAbove = 2,
		marginStraight = 2,
		layers = {
			0, -4, 4
		},
	}

	local traimParamsLarge = {
		trainSizeMin = -512,
		trainSizeMax = 512,
	}

	-- Small rails, such as: Minitrains (mt12)
	local scanParamsSmall = {
		offsetPos = Vector(0, 0, -1),
		offsetAng = Angle(0, 0, 0),
		maxRailTopTraceZ = 8,
		minRailTopTraceZ = 0,
		marginRailTopTrace = 0.5,
		marginRailEdgeBelow = 1,
		marginRailEdgeAbove = 2,
		marginStraight = 1,
		layers = {
			0, 1, -1
		},
	}

	local traimParamsSmall = {
		trainSizeMin = -32,
		trainSizeMax = 32,
	}

	LIB.AddGauge(LIB.ENUM_GAUGE_DEFAULT, {
		title = "Default",
	})

	LIB.AddGauge(LIB.ENUM_GAUGE_AUTO, {
		title = "Auto",
	})

	LIB.AddGauge(LIB.ENUM_GAUGE_PHX, {
		title = "PHX",
		width = 80,
		scanParams = scanParamsLarge,
		defaultTrainParams = traimParamsLarge,
	})

	LIB.AddGauge(LIB.ENUM_GAUGE_RSG, {
		title = "RSG",
		width = 58,
		scanParams = scanParamsLarge,
		defaultTrainParams = traimParamsLarge,
	})

	LIB.AddGauge(LIB.ENUM_GAUGE_RSG3FT, {
		title = "RSG 3ft",
		width = 36,
		scanParams = scanParamsLarge,
		defaultTrainParams = traimParamsLarge,
	})

	LIB.AddGauge(LIB.ENUM_GAUGE_RON2FT, {
		title = "Ron 2ft",
		width = 32,
		scanParams = scanParamsLarge,
		defaultTrainParams = traimParamsLarge,
	})

	LIB.AddGauge(LIB.ENUM_GAUGE_MT12, {
		title = "Minitrains",
		width = 12,
		scanParams = scanParamsSmall,
		defaultTrainParams = traimParamsSmall,
	})
end

function LIB.Load()
	LIBPosition = SligWolf_Addons.Position
	LIBEntities = SligWolf_Addons.Entities
	LIBTracer = SligWolf_Addons.Tracer
end

return true

