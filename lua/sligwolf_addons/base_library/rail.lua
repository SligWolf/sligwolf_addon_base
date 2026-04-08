local SligWolf_Addons = _G.SligWolf_Addons
if not SligWolf_Addons then
	return
end

local LIB = SligWolf_Addons:NewLib("Rail")

local CONSTANTS = SligWolf_Addons.Constants

local LIBPosition = nil
local LIBEntities = nil
local LIBDebug = nil
local LIBTracer = nil

local g_maxRailCheckTraceAttachmentPairs = 4

LIB.ENUM_RAIL_CHECK_MODE_ALL = 0
LIB.ENUM_RAIL_CHECK_MODE_NONE = 1
LIB.ENUM_RAIL_CHECK_MODE_ANY = 2

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

local g_groundThreshold = math.cos(math.rad(64))
local g_railParallelThreshold = math.cos(math.rad(1))
local g_railTopThreshold = math.cos(math.rad(1))

local g_layerVec = Vector()
local g_spaceCheckVec = Vector()

local g_dirAng = Angle()
local g_yawOffsetAng = Angle()

local g_baseMx = Matrix()
local g_layerMx = Matrix()
local g_worldMx = Matrix()
local g_trackMx = Matrix()
local g_offsetMx = Matrix()

local g_traceResultBufferA = {}
local g_traceResultBufferB = {}

local g_layers = {
	0, -4, 4
}

local g_dirs = {
	0, 90
}

local function setupRailRotationMatrix(mx, railSideNormal, railTopNormal)
	local forward = railSideNormal:Cross(railTopNormal)
	forward:Normalize()

	local right = forward:Cross(railTopNormal)
	right:Normalize()

	local up = railTopNormal

	mx:SetForward(forward)
	mx:SetRight(right)
	mx:SetUp(up)
end

local function finalizeRailTopNormal(ply, mx, railSidePos, railSideNormal, estimatedRailTopNormal, railOffsetTop, railOffsetBottom)
	mx:Identity()
	mx:SetTranslation(railSidePos)
	setupRailRotationMatrix(mx, railSideNormal, estimatedRailTopNormal)

	local traceTopStartPos = mx * railOffsetTop
	local traceTopEndPos = mx * railOffsetBottom

	-- Tracer for finding the top sides of rail tracks
	local traceTop = LIBTracer.Tracer(ply, traceTopStartPos, traceTopEndPos, nil, g_traceResultBufferA)

	if not traceTop or not traceTop.Hit or traceTop.StartSolid or traceTop.AllSolid then
		return nil
	end

	return traceTop.HitNormal, traceTop.HitPos
end

local function estimateRailTopNormal(ply, mx, railSidePos, railSideNormal, upNormal, railOffsetTop, railOffsetBottom)
	local railTopNormal = finalizeRailTopNormal(ply, mx, railSidePos, railSideNormal, upNormal, railOffsetTop, railOffsetBottom)
	return railTopNormal
end

local function validateTopNormals(railTopNormalA, railTopNormalB)
	if not railTopNormalA then
		return false
	end

	if not railTopNormalB then
		return false
	end

	-- Ensure both hit surfaces are pointing in the same direction (usually upwarts)
	if railTopNormalA:Dot(railTopNormalB) < g_railTopThreshold then
		return false
	end

	-- Ensure the track is not too steep
	if math.abs(railTopNormalA.z) < g_groundThreshold or math.abs(railTopNormalB.z) < g_groundThreshold then
		return false
	end

	return true
end

local function getPlayerSidedNormals(eyeNormal, railSideNormalA, railSideNormalB, railTopNormalA, railTopNormalB)
	local traceEyeDotA = railSideNormalA:Dot(eyeNormal)
	local traceEyeDotB = railSideNormalB:Dot(eyeNormal)

	if traceEyeDotA > 0 then
		return railSideNormalA, railTopNormalA
	elseif traceEyeDotB > 0 then
		return railSideNormalB, railTopNormalB
	end

	return nil
end

local function checkRailStraightSpace(ply, mx, trainLength, trackGauge, marginStraight, heightOffset)
	if trainLength <= 0 then
		return true
	end

	local gaugeEdgeDistanceA = trackGauge / 2 - marginStraight
	local gaugeEdgeDistanceB = trackGauge / 2 - marginStraight * 2
	local trainLengthEdgeDistance = trainLength / 2

	g_spaceCheckVec.z = heightOffset

	g_spaceCheckVec.y = -gaugeEdgeDistanceA
	g_spaceCheckVec.x = trainLengthEdgeDistance
	local straightTraceStartA = mx * g_spaceCheckVec

	g_spaceCheckVec.y = -gaugeEdgeDistanceB
	g_spaceCheckVec.x = -trainLengthEdgeDistance
	local straightTraceEndA = mx * g_spaceCheckVec

	g_spaceCheckVec.y = gaugeEdgeDistanceA
	g_spaceCheckVec.x = trainLengthEdgeDistance
	local straightTraceStartB = mx * g_spaceCheckVec

	g_spaceCheckVec.y = gaugeEdgeDistanceB
	g_spaceCheckVec.x = -trainLengthEdgeDistance
	local straightTraceEndB = mx * g_spaceCheckVec

	local straightTraceA = LIBTracer.Tracer(ply, straightTraceStartA, straightTraceEndA, nil, g_traceResultBufferA)
	local straightTraceB = LIBTracer.Tracer(ply, straightTraceStartB, straightTraceEndB, nil, g_traceResultBufferB)

	if not straightTraceA or straightTraceA.Hit or straightTraceA.StartSolid or straightTraceA.AllSolid then
		return false
	end

	if not straightTraceB or straightTraceB.Hit or straightTraceB.StartSolid or straightTraceB.AllSolid then
		return false
	end

	return true
end

local function checkRailCrossSpace(ply, mx, width, heightOffset)
	g_spaceCheckVec.z = heightOffset
	g_spaceCheckVec.x = 0

	g_spaceCheckVec.y = width / 2
	local crossTraceStart = mx * g_spaceCheckVec

	g_spaceCheckVec.y = -width / 2
	local crossTraceEnd = mx * g_spaceCheckVec

	local crossTrace = LIBTracer.Tracer(ply, crossTraceStart, crossTraceEnd, nil, g_traceResultBufferA)

	if crossTrace and crossTrace.Hit and crossTrace.StartSolid and crossTrace.AllSolid then
		return false
	end

	return true
end

function LIB.ScanRail(ply, tr, parameters)
	parameters = parameters or {}

	local layers = parameters.layers or g_layers
	if not layers or table.IsEmpty(layers) then
		return nil
	end

	local trainLength = parameters.trainLength or 0

	local maxGauge = parameters.maxGauge or 84
	local minGauge = parameters.minGauge or 16

	local maxGaugeDiagonal = maxGauge * 1.5

	local maxRailGaugeDiagonalVecStart = Vector(maxGaugeDiagonal, 0, 0)
	local maxRailGaugeDiagonalVecEnd = Vector(-maxGaugeDiagonal, 0, 0)

	local maxRailTopTraceZ = parameters.maxRailTopTraceZ or 32
	local minRailTopTraceZ = parameters.minRailTopTraceZ or 0
	local marginRailTopTrace = parameters.marginRailTopTrace or 3

	local marginRailEdgeBelow = parameters.marginRailEdgeBelow or 4
	local marginRailEdgeAbove = parameters.marginRailEdgeAbove or 2
	local marginStraight = parameters.marginStraight or 2

	local railTopTraceOffsetTop = Vector(0, -marginRailTopTrace, maxRailTopTraceZ)
	local railTopTraceOffsetBottom = Vector(0, -marginRailTopTrace, minRailTopTraceZ)

	local pos = tr.HitPos

	local eyeNormal = tr.Normal

	local normal = tr.HitNormal
	local normalZAbs = math.abs(normal.z)
	local normalZSign = normal.z > 0 and 1 or -1

	local ang = normal:Angle()

	g_yawOffsetAng.y = 0

	if normalZAbs >= g_groundThreshold then
		-- ground surface math
		local eyeAngles = eyeNormal:Angle()

		ang:RotateAroundAxis(ang:Right(), -90)

	 	g_yawOffsetAng.y = math.NormalizeAngle(eyeAngles.y - ang.y) * normalZSign
	end

	g_yawOffsetAng:Normalize()

	g_worldMx:Identity()
	g_layerMx:Identity()
	g_trackMx:Identity()

	g_offsetMx:Identity()
	g_offsetMx:SetTranslation(parameters.offsetPos or CONSTANTS.vecZero)
	g_offsetMx:SetAngles(parameters.offsetAng or CONSTANTS.angZero)

	g_baseMx:Identity()
	g_baseMx:SetTranslation(pos)
	g_baseMx:SetAngles(ang)
	g_baseMx:Rotate(g_yawOffsetAng)

	local foundTrackGauge = nil

	-- Scan in a flat cross pattern so we find tracks in every rotation.
	for _, dir in ipairs(g_dirs) do
		g_dirAng.y = dir
		g_dirAng:Normalize()

		local traceSideHitPosA = nil
		local traceSideHitPosB = nil

		local railSideNormalA = nil
		local railSideNormalB = nil

		local distance = nil

		-- Use multiple layers to be more robust against uneven or patchy surfaces.
		for _, layer in ipairs(layers) do
			g_layerVec.z = layer

			g_layerMx:Identity()
			g_layerMx:SetTranslation(g_layerVec)
			g_layerMx:SetAngles(g_dirAng)

			g_worldMx:Identity()
			g_worldMx:Mul(g_baseMx)
			g_worldMx:Mul(g_layerMx)

			traceSideHitPosA = nil
			traceSideHitPosB = nil

			railSideNormalA = nil
			railSideNormalB = nil

			distance = nil

			local layerCenterPos = g_worldMx:GetTranslation()
			local layerStartPos = g_worldMx * maxRailGaugeDiagonalVecStart
			local layerEndPos = g_worldMx * maxRailGaugeDiagonalVecEnd

			-- Tracer for finding the inner sides of rail tracks
			local traceSideA = LIBTracer.Tracer(ply, layerCenterPos, layerStartPos, nil, g_traceResultBufferA)
			local traceSideB = LIBTracer.Tracer(ply, layerCenterPos, layerEndPos, nil, g_traceResultBufferB)

			if not traceSideA or not traceSideA.Hit or traceSideA.AllSolid then
				continue
			end

			if not traceSideB or not traceSideB.Hit or traceSideB.AllSolid then
				continue
			end

			traceSideHitPosA = traceSideA.HitPos
			traceSideHitPosB = traceSideB.HitPos

			if traceSideHitPosA == traceSideHitPosB then
				continue
			end

			distance = traceSideHitPosA:Distance(traceSideHitPosB)
			if distance < minGauge then
				-- Likely not a valid rail gauge
				continue
			end

			railSideNormalA = traceSideA.HitNormal
			railSideNormalB = traceSideB.HitNormal

			-- Ensure both hit surfaces are parallel and are facing each other
			if railSideNormalA:Dot(railSideNormalB) > -g_railParallelThreshold then
				continue
			end

			break
		end

		if not traceSideHitPosA or not traceSideHitPosB then
			continue
		end

		if not railSideNormalA or not railSideNormalB then
			continue
		end

		local upNormal = g_worldMx:GetUp()

		-- Top tracers for first estimation
		local railTopNormalA = estimateRailTopNormal(ply, g_trackMx, traceSideHitPosA, railSideNormalA, upNormal, railTopTraceOffsetTop, railTopTraceOffsetBottom)
		local railTopNormalB = estimateRailTopNormal(ply, g_trackMx, traceSideHitPosB, railSideNormalB, upNormal, railTopTraceOffsetTop, railTopTraceOffsetBottom)

		if not railTopNormalA then
			continue
		end

		if not railTopNormalB then
			continue
		end

		-- Final top tracers for most precise top surface normals
		local railTopA = nil
		local railTopB = nil

		railTopNormalA, railTopA = finalizeRailTopNormal(ply, g_trackMx, traceSideHitPosA, railSideNormalA, railTopNormalA, railTopTraceOffsetTop, railTopTraceOffsetBottom)
		railTopNormalB, railTopB = finalizeRailTopNormal(ply, g_trackMx, traceSideHitPosB, railSideNormalB, railTopNormalB, railTopTraceOffsetTop, railTopTraceOffsetBottom)

		if not validateTopNormals(railTopNormalA, railTopNormalB) then
			continue
		end

		local playerSidedRailSideNormal, playerSidedRailTopNormal = getPlayerSidedNormals(
			eyeNormal,
			railSideNormalA,
			railSideNormalB,
			railTopNormalA,
			railTopNormalB
		)

		if not playerSidedRailSideNormal then
			continue
		end

		if not playerSidedRailTopNormal then
			continue
		end

		-- Found center and direction of the track
		g_trackMx:Identity()
		g_trackMx:SetTranslation((railTopA + railTopB) / 2)
		setupRailRotationMatrix(g_trackMx, playerSidedRailSideNormal, playerSidedRailTopNormal)

		-- Find track gauge
		local toCenterDir = traceSideHitPosA - (traceSideHitPosA + traceSideHitPosB) / 2
		toCenterDir:Normalize()

		local toCenterDot = toCenterDir:Dot(g_trackMx:GetRight())

		local trackGauge = math.Round(distance * math.abs(toCenterDot))
		if trackGauge < minGauge or trackGauge > maxGauge then
			-- Likely not a valid rail gauge
			continue
		end

		-- Check if the track is straight for at least the given trainLength
		if not checkRailStraightSpace(ply, g_trackMx, trainLength, trackGauge, marginStraight, -marginRailEdgeBelow) then
			continue
		end

		-- Check if the area above the track is not blocked along its width
		-- This ensures were are indeed on a train track and not just in a narrow corridor
		if not checkRailCrossSpace(ply, g_trackMx, trackGauge * 1.5, marginRailEdgeAbove) then
			continue
		end

		foundTrackGauge = trackGauge
		break
	end

	if not foundTrackGauge then
		return nil
	end

	g_trackMx:Mul(g_offsetMx)

	local trackCenter = g_trackMx:GetTranslation()
	local trackAng = g_trackMx:GetAngles()

	local isDebug = LIBDebug.IsDeveloper()

	if isDebug then
		local gaugeString = string.format("Gauge: %i", foundTrackGauge)

		LIBDebug.EntityTextAtPosition(trackCenter, gaugeString, 1)
		LIBDebug.Axis(trackCenter, trackAng, foundTrackGauge / 4)
	end

	return {
		center = trackCenter,
		ang = trackAng,
		gauge = foundTrackGauge,
	}
end

function LIB.Load()
	LIBPosition = SligWolf_Addons.Position
	LIBEntities = SligWolf_Addons.Entities
	LIBTracer = SligWolf_Addons.Tracer
	LIBDebug = SligWolf_Addons.Debug

	-- Test code
	-- local LIBHook = SligWolf_Addons.Hook
	-- LIBHook.Add("Think", "Rail.ScanRail", function()
	-- 	local ply = LIBDebug.GetDebugPlayer()
	-- 	if not IsValid(ply) then
	-- 		return
	-- 	end

	-- 	local tr = LIBTracer.DoTrace(ply, 5000)
	-- 	if not tr or not tr.Hit then
	-- 		return
	-- 	end

	-- 	LIBDebug.SetLifetime(CLIENT and LIBDebug.DEBUG_LIFETIME_FRAME or LIBDebug.DEBUG_LIFETIME_DEFAULT)

	-- 	if ply:KeyDown( IN_USE ) then
	-- 		-- Minitrains
	-- 		LIB.ScanRail(ply, tr, {
	-- 			offsetPos = Vector(0, 0, -1),
	-- 			offsetAng = Angle(0, 0, 0),
	-- 			trainLength = 50,
	-- 			maxGauge = 14,
	-- 			minGauge = 10,
	-- 			maxRailTopTraceZ = 8,
	-- 			minRailTopTraceZ = 0,
	-- 			marginRailTopTrace = 0.5,
	-- 			marginRailEdgeBelow = 1,
	-- 			marginRailEdgeAbove = 2,
	-- 			marginStraight = 1,
	-- 			layers = {
	-- 				0, 1, -1
	-- 			}
	-- 		})
	-- 	else
	-- 		-- PHX, 2feet, 3feet, rsg
	-- 		LIB.ScanRail(ply, tr, {
	-- 			offsetPos = Vector(0, 0, -5),
	-- 			offsetAng = Angle(0, 0, 0),
	-- 			trainLength = 1000,
	-- 			maxGauge = 84,
	-- 			minGauge = 28,
	-- 			maxRailTopTraceZ = 32,
	-- 			minRailTopTraceZ = 0,
	-- 			marginRailTopTrace = 3,
	-- 			marginRailEdgeBelow = 4,
	-- 			marginRailEdgeAbove = 2,
	-- 			marginStraight = 2,
	-- 			layers = {
	-- 				0, -4, 4
	-- 			}
	-- 		})
	-- 	end

	-- 	LIBDebug.ResetLifetime()
	-- end)
end

return true

