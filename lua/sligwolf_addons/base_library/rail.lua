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
local LIBEntities = nil
local LIBDebug = nil
local LIBTracer = nil
local LIBHook = nil

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

	if not IsValid(bogie) then
		if LIB.HasRailCheckAttachments(body) then
			bogie = body
		end
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


local g_layerVec = Vector(0, 0, 0)
local g_straightVec = Vector(0, 0, 0)

local g_dirAng = Angle(0, 0, 0)
local g_yawOffsetAng = Angle(0, 0, 0)

local g_baseMx = Matrix()
local g_layerMx = Matrix()
local g_worldMx = Matrix()
local g_trackMx = Matrix()

local g_traceResultBufferA = {}
local g_traceResultBufferB = {}

local g_layers = {
	0, 4, -4, 8
}

local g_dirs = {
	0, 90
}

function LIB.ScanRail(ply, tr, parameters)
	parameters = parameters or {}

	local layers = parameters.layers or g_layers
	local dirs = parameters.dirs or g_dirs

	if not layers or table.IsEmpty(layers) then
		return nil
	end

	if not dirs or table.IsEmpty(dirs) then
		return nil
	end

	local trainLength = parameters.trainLength or 0

	local maxGauge = parameters.maxGauge or 84
	local minGauge = parameters.minGauge or 16

	local maxGaugeDiagonal = maxGauge * 1.5

	local maxRailGaugeDiagonalVecStart = Vector(maxGaugeDiagonal, 0, 0)
	local maxRailGaugeDiagonalVecEnd = Vector(-maxGaugeDiagonal, 0, 0)

	local minGround = parameters.minGround or -2
	local maxGround = parameters.maxGround or 10
	local marginGround = parameters.marginGround or 2

	local groundVecStart = Vector(0, 0, maxGround)
	local groundVecEnd = Vector(0, 0, minGround)

	local marginStraight = parameters.marginStraight or 2

	local pos = tr.HitPos

	local eyeNormal = tr.Normal

	local normal = tr.HitNormal
	local normalZAbs = math.abs(normal.z)
	local normalZSign = normal.z > 0 and 1 or -1

	local ang = normal:Angle()

	g_yawOffsetAng.y = 0

	if normalZAbs >= g_groundThreshold then
		local eyeAngles = eyeNormal:Angle()

		ang:RotateAroundAxis(ang:Right(), -90)

	 	g_yawOffsetAng.y = math.NormalizeAngle(eyeAngles.y - ang.y) * normalZSign
	end

	g_yawOffsetAng:Normalize()

	g_worldMx:Identity()
	g_layerMx:Identity()
	g_trackMx:Identity()

	g_baseMx:Identity()
	g_baseMx:SetTranslation(pos)
	g_baseMx:SetAngles(ang)
	g_baseMx:Rotate(g_yawOffsetAng)

	local foundTrackGauge = nil

	for _, dir in ipairs(dirs) do
		if foundTrackGauge then
			break
		end

		g_dirAng.y = dir
		g_dirAng:Normalize()

		for _, layer in ipairs(layers) do
			g_layerVec.z = layer

			g_layerMx:Identity()
			g_layerMx:SetTranslation(g_layerVec)
			g_layerMx:SetAngles(g_dirAng)

			g_worldMx:Identity()
			g_worldMx:Mul(g_baseMx)
			g_worldMx:Mul(g_layerMx)

			local layerCenterPos = g_worldMx:GetTranslation()
			local layerStartPos = g_worldMx * maxRailGaugeDiagonalVecStart
			local layerEndPos = g_worldMx * maxRailGaugeDiagonalVecEnd

			-- Tracer for finding the rail tracks
			local traceA = LIBTracer.Tracer(ply, layerCenterPos, layerStartPos, nil, g_traceResultBufferA)
			local traceB = LIBTracer.Tracer(ply, layerCenterPos, layerEndPos, nil, g_traceResultBufferB)

			if not traceA or not traceA.Hit or traceA.AllSolid then
				continue
			end

			if not traceB or not traceB.Hit or traceB.AllSolid then
				continue
			end

			local traceHitPosA = traceA.HitPos
			local traceHitPosB = traceB.HitPos

			local distance = traceHitPosA:Distance(traceHitPosB)
			if distance < minGauge then
				-- Likely not a valid rail gauge
				continue
			end

			local traceHitNormalA = traceA.HitNormal
			local traceHitNormalB = traceB.HitNormal

			-- Ensure both hit surfaces are parallel and are facing each other
			if traceHitNormalA:Dot(traceHitNormalB) > -g_railParallelThreshold then
				continue
			end

			-- Pick the closest hit normal to player, to ensure predictable track direction detection
			local playerSideTraceHitNormal = nil

			local traceEyeDotA = traceHitNormalA:Dot(eyeNormal)
			local traceEyeDotB = traceHitNormalB:Dot(eyeNormal)

			if traceEyeDotA > 0 then
			 	playerSideTraceHitNormal = traceHitNormalA
			elseif traceEyeDotB > 0 then
			 	playerSideTraceHitNormal = traceHitNormalB
			end

			if not playerSideTraceHitNormal then
				continue
			end

			-- Find center and direction of the Rail track
			local trackCenter = (traceHitPosA + traceHitPosB) / 2
			local trackAng = playerSideTraceHitNormal:AngleEx(ang:Up())

			-- Find track gauge
			local traceToCenterDir = traceHitPosA - trackCenter
			traceToCenterDir:Normalize()

			local widthDot = traceToCenterDir:Dot(trackAng:Right())
			local widthRad = math.acos(math.abs(widthDot))

			local trackGauge = math.Round(distance * math.sin(widthRad))
			if trackGauge < minGauge or trackGauge > maxGauge then
				-- Likely not a valid rail gauge
				continue
			end

			g_trackMx:Identity()
			g_trackMx:SetTranslation(trackCenter)
			g_trackMx:SetAngles(trackAng)

			-- Check if the track is straight for at least the given trainLength
			if trainLength > 0 then
				local gaugeEdgeDistanceA = trackGauge / 2 - marginStraight * 2
				local gaugeEdgeDistanceB = gaugeEdgeDistanceA + marginStraight
				local trainLengthEdgeDistance = trainLength / 2

				g_straightVec.x = -gaugeEdgeDistanceA
				g_straightVec.y = trainLengthEdgeDistance
				local straightTraceStartA = g_trackMx * g_straightVec

				g_straightVec.x = -gaugeEdgeDistanceB
				g_straightVec.y = -trainLengthEdgeDistance
				local straightTraceEndA = g_trackMx * g_straightVec

				g_straightVec.x = gaugeEdgeDistanceA
				g_straightVec.y = trainLengthEdgeDistance
				local straightTraceStartB = g_trackMx * g_straightVec

				g_straightVec.x = gaugeEdgeDistanceB
				g_straightVec.y = -trainLengthEdgeDistance
				local straightTraceEndB = g_trackMx * g_straightVec

				local straightTraceA = LIBTracer.Tracer(ply, straightTraceStartA, straightTraceEndA, nil, g_traceResultBufferA)
				local straightTraceB = LIBTracer.Tracer(ply, straightTraceStartB, straightTraceEndB, nil, g_traceResultBufferB)

				if not straightTraceA or straightTraceA.Hit or straightTraceA.StartSolid or straightTraceA.AllSolid then
					continue
				end

				if not straightTraceB or straightTraceB.Hit or straightTraceB.StartSolid or straightTraceB.AllSolid then
					continue
				end
			end

			foundTrackGauge = trackGauge
			break
		end
	end

	if not foundTrackGauge then
		return nil
	end

	if maxGround ~= 0 and minGround ~= 0 then
		-- find the ground below the track, if applicable 
		local groundTraceStart = g_trackMx * groundVecStart
		local groundTraceEnd = g_trackMx * groundVecEnd

		local groundTrace = LIBTracer.Tracer(ply, groundTraceStart, groundTraceEnd, nil, g_traceResultBufferA)

		if groundTrace and groundTrace.Hit and not groundTrace.StartSolid and not groundTrace.AllSolid then
			-- Make sure the found center is close to the ground
			g_trackMx:SetTranslation(groundTrace.HitPos + groundTrace.Normal * -marginGround)
		end
	end

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
	LIBHook = SligWolf_Addons.Hook

	--if SERVER then
		LIBHook.Add("Think", "Rail.ScanRail", function()
			local ply = LIBDebug.GetDebugPlayer()
			if not IsValid(ply) then
				return
			end

			local tr = LIBTracer.DoTrace(ply, 5000)
			if not tr or not tr.Hit then
				return
			end

			if ply:KeyDown( IN_ATTACK ) then
				-- Minitrains
				LIB.ScanRail(ply, tr, {
					trainLength = 50,
					maxGauge = 14,
					minGauge = 10,
					marginStraight = 1,
					marginGround = 0.5,
					minGround = -2,
					maxGround = 2,
					layers = {
						0, 0.5, 0.5
					}
				})
			else
				-- PHX, 2feet, 3feet, rsg
				LIB.ScanRail(ply, tr, {
					trainLength = 1000,
					maxGauge = 84,
					minGauge = 28,
					marginStraight = 2,
					marginGround = 2,
					minGround = -2,
					maxGround = 2,
					layers = {
						0, 4, -4, 8
					}
				})
			end
		end)
	--end
end

return true

