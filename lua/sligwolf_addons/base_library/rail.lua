local SligWolf_Addons = _G.SligWolf_Addons
if not SligWolf_Addons then
	return
end

local LIB = SligWolf_Addons:NewLib("Rail")

local LIBPosition = SligWolf_Addons.Position
local LIBEntities = SligWolf_Addons.Entities
local LIBTrace = SligWolf_Addons.Trace
local LIBRailscan = SligWolf_Addons.Railscan

local g_maxRailCheckTraceAttachmentPairs = 4

LIB.ENUM_RAIL_CHECK_MODE_ALL = 0
LIB.ENUM_RAIL_CHECK_MODE_NONE = 1
LIB.ENUM_RAIL_CHECK_MODE_ANY = 2

LIB.MIN_GAUGE_WIDTH = 3
LIB.MAX_GAUGE_WIDTH = 96

LIB.TRAIN_GAUGE_DEFAULT = "default"
LIB.TRAIN_GAUGE_AUTO = "auto"

LIB.TRAIN_GAUGE_PHX = "phx"
LIB.TRAIN_GAUGE_RSG = "rsg"
LIB.TRAIN_GAUGE_RSG3FT = "rsg3ft"
LIB.TRAIN_GAUGE_RON2FT = "ron2ft"
LIB.TRAIN_GAUGE_MT12 = "mt12"

LIB.TRAIN_GAUGE_WP = "wp"

LIB.TRAIN_CLASS_REGULAR = "regular"
LIB.TRAIN_CLASS_NARROW = "narrow"
LIB.TRAIN_CLASS_MINIATURE = "miniature"
LIB.TRAIN_CLASS_WP = "wp"

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
	[LIB.TRAIN_GAUGE_DEFAULT] = true,
	[LIB.TRAIN_GAUGE_AUTO] = true,
}

local g_trainClassesByName = LIB.g_trainClassesByName or {}
LIB.g_trainClassesByName = g_trainClassesByName

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
		local tr = LIBTrace.TraceAttachmentChain(ent, attachments)
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

function LIB.AddGauge(gaugeName, params)
	gaugeName = tostring(gaugeName or "")
	gaugeName = string.lower(gaugeName)

	params = table.Copy(params or {})

	if gaugeName == "" then
		error("no gaugeName was given")
		return
	end

	local isReal = g_gaugenameBlacklist[gaugeName] ~= true
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
	local titleShort = string.upper(gaugeName)

	if title == "" then
		title = titleShort
	end

	local gauge = {}
	g_gaugesByName[gaugeName] = gauge

	-- clear gauges caches
	table.Empty(g_gaugesByWidth)
	table.Empty(g_gaugesOrdered)

	gauge.name = gaugeName
	gauge.title = title
	gauge.titleShort = titleShort
	gauge.isReal = isReal

	gauge.modelDirectoryName = string.format("gauge_%s", gaugeName)

	gauge.width = width
	gauge.tolerance = tolerance

	gauge.trainClass = params.trainClass

	gauge.scanFunction = params.scanFunction
	gauge.scanParams = params.scanParams

	gauge.defaultTrainParams = params.defaultTrainParams
end

function LIB.GetGaugeByName(gaugeName)
	gaugeName = tostring(gaugeName or "")
	gaugeName = string.lower(gaugeName)

	local gauge = g_gaugesByName[gaugeName]
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

function LIB.HasGaugeByName(gaugeName)
	return LIB.GetGaugeByName(gaugeName) ~= nil
end

function LIB.HasGaugeByWidth(gaugeName)
	return LIB.GetGaugeByWidth(gaugeName) ~= nil
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

function LIB.AddTrainClass(trainClassName, params)
	trainClassName = tostring(trainClassName or "")
	trainClassName = string.lower(trainClassName)

	params = table.Copy(params or {})

	if trainClassName == "" then
		error("no trainClassName was given")
		return
	end

	local title = tostring(params.title or "")
	local titleShort = string.upper(trainClassName)

	if title == "" then
		title = titleShort
	end

	local trainClass = {}
	g_trainClassesByName[trainClassName] = trainClass

	trainClass.name = trainClassName
	trainClass.title = title
	trainClass.titleShort = titleShort

	trainClass.modelDirectoryName = string.format("class_%s", trainClassName)

	trainClass.scanFunction = params.scanFunction
	trainClass.scanParams = params.scanParams

	trainClass.defaultTrainParams = params.defaultTrainParams
end

function LIB.TrainClassByName(trainClassName)
	trainClassName = tostring(trainClassName or "")
	trainClassName = string.lower(trainClassName)

	local trainClass = g_trainClassesByName[trainClassName]
	if not trainClass then
		return nil
	end

	return trainClass
end

function LIB.RegisterSpawnnameToGauge(spawnnameNoGauge, gaugeName, spawnnameFull)
	gaugeName = tostring(gaugeName or "")
	gaugeName = string.lower(gaugeName)

	if g_gaugenameBlacklist[gaugeName] then
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
	gauges[gaugeName] = entry

	if not gauges[LIB.TRAIN_GAUGE_DEFAULT] then
		g_spawnnameFullToGaugeRegister[spawnnameFull] = entry
		gauges[LIB.TRAIN_GAUGE_DEFAULT] = entry
		gauges[LIB.TRAIN_GAUGE_AUTO] = entry
	end

	entry.spawnnameFull = spawnnameFull
	entry.spawnnameNoGauge = spawnnameNoGauge
	entry.gaugeName = gaugeName
end

function LIB.GetSpawnnameInfo(spawnnameNoGaugeOrFull, gaugeName)
	spawnnameNoGaugeOrFull = tostring(spawnnameNoGaugeOrFull or "")
	if spawnnameNoGaugeOrFull == "" then
		return nil
	end

	gaugeName = tostring(gaugeName or "")
	gaugeName = string.lower(gaugeName)

	if g_gaugenameBlacklist[gaugeName] then
		gaugeName = LIB.TRAIN_GAUGE_DEFAULT
	end

	if gaugeName == LIB.TRAIN_GAUGE_DEFAULT then
		local entry = g_spawnnameFullToGaugeRegister[spawnnameNoGaugeOrFull]
		if entry and not g_gaugenameBlacklist[entry.gaugeName] then
			return entry
		end
	end

	local gauges = g_spawnnamePartToGaugeRegister[spawnnameNoGaugeOrFull]
	if not gauges then
		return nil
	end

	entry = gauges[gaugeName]
	if not entry then
		return nil
	end

	if g_gaugenameBlacklist[entry.gaugeName] then
		return nil
	end

	return entry
end

do
	LIB.AddTrainClass(LIB.TRAIN_CLASS_REGULAR, {
		title = "Regular Train",
		defaultTrainParams = {
			trainSizeMin = -384,
			trainSizeMax = 384,
		},
		scanParams = {
			offsetPos = Vector(0, 0, -5),
			offsetAng = Angle(0, 0, 0),
			maxRailTopTraceZ = 32,
			minRailTopTraceZ = 0,
			marginRailTopTrace = 3,
			marginRailEdgeBelow = 4,
			marginRailEdgeAbove = 2,
			marginStraight = 2,
			layersWall = {
				0, -4, 4
			},
			layersFlat = {
				0, -4, 4
			},
		},
	})

	LIB.AddTrainClass(LIB.TRAIN_CLASS_NARROW, {
		title = "Narrow Train",
		defaultTrainParams = {
			trainSizeMin = -256,
			trainSizeMax = 256,
		},
		scanParams = {
			offsetPos = Vector(0, 0, -5),
			offsetAng = Angle(0, 0, 0),
			maxRailTopTraceZ = 32,
			minRailTopTraceZ = 0,
			marginRailTopTrace = 2,
			marginRailEdgeBelow = 4,
			marginRailEdgeAbove = 2,
			marginStraight = 2,
			layersWall = {
				0, -3, 3
			},
			layersFlat = {
				0, -3, 3
			},
		},
	})

	LIB.AddTrainClass(LIB.TRAIN_CLASS_MINIATURE, {
		title = "Miniature Train",
		defaultTrainParams = {
			trainSizeMin = -24,
			trainSizeMax = 24,
		},
		scanParams = {
			offsetPos = Vector(0, 0, -1),
			offsetAng = Angle(0, 0, 0),
			maxRailTopTraceZ = 8,
			minRailTopTraceZ = 0,
			marginRailTopTrace = 0.5,
			marginRailEdgeBelow = 1,
			marginRailEdgeAbove = 2,
			marginStraight = 1,
			layersWall = {
				0, 1, -1
			},
			layersFlat = {
				0, 1, -1
			},
		},
	})

	LIB.AddTrainClass(LIB.TRAIN_CLASS_WP, {
		title = "Wuppertal Suspension Train",
		defaultTrainParams = {
			trainSizeMin = -512,
			trainSizeMax = 512,
		},
		scanParams = {
			offsetPos = Vector(0, 0, -1),
			offsetAng = Angle(0, 0, 0),
			maxRailTopTraceZ = 48,
			minRailTopTraceZ = -48,
			maxRailHeight = 18,
			minRailHeight = 6,
			marginRailEdgeBelow = 1,
			marginRailEdgeAbove = 2,
			marginRailOuterWidth = 12,
			marginStraight = 2,
			layersWall = {
				0, -2, 2, 8, 12, 16, -8, -12, -16
			},
			layersFlat = {
				0, -2, 2
			},
		},
		scanFunction = function(...)
			return LIBRailscan.ScanMonoRailInternal(...)
		end,
	})

	LIB.AddGauge(LIB.TRAIN_GAUGE_DEFAULT, {
		title = "Default",
	})

	LIB.AddGauge(LIB.TRAIN_GAUGE_AUTO, {
		title = "Auto",
		scanParams = {
			items = {
				{
					trainClass = LIB.TRAIN_CLASS_REGULAR,
					maxGauge = LIB.MAX_GAUGE_WIDTH,
					minGauge = 50,
				},
				{
					trainClass = LIB.TRAIN_CLASS_NARROW,
					maxGauge = 40,
					minGauge = 24,
				},
				{
					trainClass = LIB.TRAIN_CLASS_MINIATURE,
					maxGauge = 16,
					minGauge = 8,
				},
			}
		},
		scanFunction = function(gauge, trainEnt, aimTrace, scanParams, trainParams)
			return LIBRailscan.ScanRailAutoInternal(trainEnt, aimTrace, scanParams, trainParams)
		end,
	})

	LIB.AddGauge(LIB.TRAIN_GAUGE_PHX, {
		title = "PHX",
		width = 80,
		trainClass = LIB.TRAIN_CLASS_REGULAR,
	})

	LIB.AddGauge(LIB.TRAIN_GAUGE_RSG, {
		title = "RSG",
		width = 56,
		tolerance = 2,
		trainClass = LIB.TRAIN_CLASS_REGULAR,
	})

	LIB.AddGauge(LIB.TRAIN_GAUGE_RSG3FT, {
		title = "RSG 3ft",
		width = 36,
		tolerance = 2,
		trainClass = LIB.TRAIN_CLASS_NARROW,
	})

	LIB.AddGauge(LIB.TRAIN_GAUGE_RON2FT, {
		title = "Ron 2ft",
		width = 32,
		trainClass = LIB.TRAIN_CLASS_NARROW,
	})

	LIB.AddGauge(LIB.TRAIN_GAUGE_MT12, {
		title = "Minitrains",
		width = 12,
		trainClass = LIB.TRAIN_CLASS_MINIATURE,
	})

	LIB.AddGauge(LIB.TRAIN_GAUGE_WP, {
		title = "Wuppertal Suspension Rail",
		width = 4,
		trainClass = LIB.TRAIN_CLASS_WP,
	})
end

function LIB.Load()
	LIBPosition = SligWolf_Addons.Position
	LIBEntities = SligWolf_Addons.Entities
	LIBTrace = SligWolf_Addons.Trace
	LIBRailscan = SligWolf_Addons.Railscan
end

return true

