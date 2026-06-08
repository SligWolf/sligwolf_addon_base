local SligWolf_Addons = _G.SligWolf_Addons
if not SligWolf_Addons then
	return
end

local LIB = SligWolf_Addons:NewLib("Rail")

local CONSTANTS = SligWolf_Addons.Constants

local LIBPosition = SligWolf_Addons.Position
local LIBEntities = SligWolf_Addons.Entities
local LIBTracer = SligWolf_Addons.Tracer
local LIBRailscan = SligWolf_Addons.Railscan

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

LIB.ENUM_GAUGE_WP = "wp"

LIB.MIN_GAUGE_WIDTH = 3
LIB.MAX_GAUGE_WIDTH = 96

local g_spawnnamePartToGaugeRegister = LIB.g_spawnnamePartToGaugeRegister or {}
LIB.g_spawnnamePartToGaugeRegister = g_spawnnamePartToGaugeRegister

local g_spawnnameFullToGaugeRegister = LIB.g_spawnnameFullToGaugeRegister or {}
LIB.g_spawnnameFullToGaugeRegister = g_spawnnameFullToGaugeRegister

local g_gaugesByName = LIB.g_gaugesByName or {}
LIB.g_gaugesByName = g_gaugesByName

local g_gaugesByWidth = {}
local g_gaugesOrdered = {}

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
		error("no name was given")
		return
	end

	if not params then
		error("params was not given")
		return
	end

	local isReal = g_gaugenameBlacklist[gaugename] ~= true
	local width = 0
	local tolerance = 0

	if isReal then
		width = tonumber(params.width or 0) or 0
		width = math.Round(width)

		if width < LIB.MIN_GAUGE_WIDTH then
			error("params.width is too small")
			return
		end

		if width > LIB.MAX_GAUGE_WIDTH then
			error("params.width is too large")
			return
		end

		tolerance = tonumber(params.tolerance or 0) or 0
		tolerance = math.Round(tolerance)
		tolerance = math.max(tolerance, 0)
	end

	local title = tostring(params.title or "")
	local titleShort = string.upper(gaugename)

	if title == "" then
		title = titleShort
	end

	local defaultTrainParams = params.defaultTrainParams or {}

	local gauge = {}
	g_gaugesByName[gaugename] = gauge

	-- clear gauges caches
	table.Empty(g_gaugesByWidth)
	table.Empty(g_gaugesOrdered)

	gauge.name = gaugename
	gauge.title = title
	gauge.titleShort = titleShort
	gauge.isReal = isReal

	gauge.width = width
	gauge.tolerance = tolerance

	gauge.scanFunction = params.scanFunction

	local gaugeDefaultTrainParams = {}
	gauge.defaultTrainParams = gaugeDefaultTrainParams

	gaugeDefaultTrainParams.trainSizeMin = defaultTrainParams.trainSizeMin or 0
	gaugeDefaultTrainParams.trainSizeMax = defaultTrainParams.trainSizeMax or 0
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

function LIB.GetGaugeByWidth(width)
	width = tonumber(width or 0) or 0
	width = math.Round(width)

	if width < LIB.MIN_GAUGE_WIDTH then
		return nil
	end

	if width > LIB.MAX_GAUGE_WIDTH then
		return nil
	end

	local cachedGauge = g_gaugesByWidth[width]
	if cachedGauge and cachedGauge.isReal then
		-- use from cache if available
		return cachedGauge
	end

	g_gaugesByWidth[width] = nil

	local gauges = LIB.GetGauges()

	-- prioritize direct matches
	for _, gauge in ipairs(gauges) do
		if not gauge.isReal then
			continue
		end

		if gauge.width ~= width then
			continue
		end

		g_gaugesByWidth[width] = gauge
		return gauge
	end

	-- search for matches respecting tolerances
	for _, gauge in ipairs(gauges) do
		if not gauge.isReal then
			continue
		end

		local minGauge = gauge.width
		local maxGauge = minGauge + gauge.tolerance

		if width < minGauge then
			continue
		end

		if width > maxGauge then
			continue
		end

		g_gaugesByWidth[width] = gauge
		return gauge
	end

	return nil
end

function LIB.HasGaugeByName(gaugename)
	return LIB.GetGaugeByName(gaugename) ~= nil
end

function LIB.HasGaugeByWidth(gaugename)
	return LIB.GetGaugeByWidth(gaugename) ~= nil
end

function LIB.GetGauges()
	if g_gaugesOrdered and not table.IsEmpty(g_gaugesOrdered) then
		return g_gaugesOrdered
	end

	for _, gauge in SortedPairsByMemberValue(g_gaugesByName, "width", true) do
		table.insert(g_gaugesOrdered, gauge)
	end

	return g_gaugesOrdered
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
	local traimParamsLarge = {
		trainSizeMin = -256,
		trainSizeMax = 256,
	}

	local traimParamsSmall = {
		trainSizeMin = -24,
		trainSizeMax = 24,
	}

	LIB.AddGauge(LIB.ENUM_GAUGE_DEFAULT, {
		title = "Default",
	})

	LIB.AddGauge(LIB.ENUM_GAUGE_AUTO, {
		title = "Auto",
		scanFunction = function(gauge, trainEnt, aimTrace, trainParams)
			return LIBRailscan.ScanRailAutoInternal(trainEnt, aimTrace, trainParams)
		end,
	})

	LIB.AddGauge(LIB.ENUM_GAUGE_PHX, {
		title = "PHX",
		width = 80,
		defaultTrainParams = traimParamsLarge,
		scanFunction = function(gauge, trainEnt, aimTrace, trainParams)
			return LIBRailscan.ScanLargeRailInternal(gauge, trainEnt, aimTrace, trainParams)
		end,
	})

	LIB.AddGauge(LIB.ENUM_GAUGE_RSG, {
		title = "RSG",
		width = 56,
		tolerance = 2,
		defaultTrainParams = traimParamsLarge,
		scanFunction = function(gauge, trainEnt, aimTrace, trainParams)
			return LIBRailscan.ScanLargeRailInternal(gauge, trainEnt, aimTrace, trainParams)
		end,
	})

	LIB.AddGauge(LIB.ENUM_GAUGE_RSG3FT, {
		title = "RSG 3ft",
		width = 36,
		tolerance = 1,
		defaultTrainParams = traimParamsLarge,
		scanFunction = function(gauge, trainEnt, aimTrace, trainParams)
			return LIBRailscan.ScanLargeRailInternal(gauge, trainEnt, aimTrace, trainParams)
		end,
	})

	LIB.AddGauge(LIB.ENUM_GAUGE_RON2FT, {
		title = "Ron 2ft",
		width = 32,
		defaultTrainParams = traimParamsLarge,
		scanFunction = function(gauge, trainEnt, aimTrace, trainParams)
			return LIBRailscan.ScanLargeRailInternal(gauge, trainEnt, aimTrace, trainParams)
		end,
	})

	LIB.AddGauge(LIB.ENUM_GAUGE_MT12, {
		title = "Minitrains",
		width = 12,
		defaultTrainParams = traimParamsSmall,
		scanFunction = function(gauge, trainEnt, aimTrace, trainParams)
			return LIBRailscan.ScanSmallRailInternal(gauge, trainEnt, aimTrace, trainParams)
		end,
	})

	LIB.AddGauge(LIB.ENUM_GAUGE_WP, {
		title = "Wuppertal Suspension Rail",
		width = 4,
		defaultTrainParams = traimParamsLarge,
		scanFunction = function(gauge, trainEnt, aimTrace, trainParams)
			return LIBRailscan.ScanMonoRailInternal(gauge, trainEnt, aimTrace, trainParams)
		end,
	})
end

function LIB.Load()
	LIBPosition = SligWolf_Addons.Position
	LIBEntities = SligWolf_Addons.Entities
	LIBTracer = SligWolf_Addons.Tracer
	LIBRailscan = SligWolf_Addons.Railscan
end

return true

