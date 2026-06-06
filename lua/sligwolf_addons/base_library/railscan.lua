local SligWolf_Addons = _G.SligWolf_Addons
if not SligWolf_Addons then
	return
end

local LIB = SligWolf_Addons:NewLib("Railscan")

local CONSTANTS = SligWolf_Addons.Constants

local LIBRail = SligWolf_Addons.Rail
local LIBDebug = SligWolf_Addons.Debug
local LIBTracer = SligWolf_Addons.Tracer

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

local function finalizeRailTopNormal(trainEnt, mx, railSidePos, railSideNormal, estimatedRailTopNormal, railOffsetTop, railOffsetBottom)
	mx:Identity()
	mx:SetTranslation(railSidePos)
	setupRailRotationMatrix(mx, railSideNormal, estimatedRailTopNormal)

	local traceTopStartPos = mx * railOffsetTop
	local traceTopEndPos = mx * railOffsetBottom

	-- Tracer for finding the top sides of rail tracks
	local traceTop = LIBTracer.Tracer(trainEnt, traceTopStartPos, traceTopEndPos, nil, g_traceResultBufferA)

	if not traceTop or not traceTop.Hit or traceTop.StartSolid or traceTop.AllSolid then
		return nil
	end

	return traceTop.HitNormal, traceTop.HitPos
end

local function estimateRailTopNormal(trainEnt, mx, railSidePos, railSideNormal, upNormal, railOffsetTop, railOffsetBottom)
	local railTopNormal = finalizeRailTopNormal(trainEnt, mx, railSidePos, railSideNormal, upNormal, railOffsetTop, railOffsetBottom)
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

local function getPlayerSidedNormals(aimNormal, railSideNormalA, railSideNormalB, railTopNormalA, railTopNormalB)
	local traceEyeDotA = railSideNormalA:Dot(aimNormal)
	local traceEyeDotB = railSideNormalB:Dot(aimNormal)

	if traceEyeDotA > 0 then
		return railSideNormalA, railTopNormalA
	elseif traceEyeDotB > 0 then
		return railSideNormalB, railTopNormalB
	end

	return nil
end

local function checkRailStraightSpace(trainEnt, mx, trainSizeMin, trainSizeMax, trackWidth, marginStraight, heightOffset)
	if trainSizeMin == trainSizeMax then
		return true
	end

	local gaugeEdgeDistanceA = trackWidth / 2 - marginStraight
	local gaugeEdgeDistanceB = trackWidth / 2 - marginStraight * 2

	g_spaceCheckVec.z = heightOffset

	g_spaceCheckVec.y = -gaugeEdgeDistanceA
	g_spaceCheckVec.x = trainSizeMin
	local straightTraceStartA = mx * g_spaceCheckVec

	g_spaceCheckVec.y = -gaugeEdgeDistanceB
	g_spaceCheckVec.x = trainSizeMax
	local straightTraceEndA = mx * g_spaceCheckVec

	g_spaceCheckVec.y = gaugeEdgeDistanceA
	g_spaceCheckVec.x = trainSizeMin
	local straightTraceStartB = mx * g_spaceCheckVec

	g_spaceCheckVec.y = gaugeEdgeDistanceB
	g_spaceCheckVec.x = trainSizeMax
	local straightTraceEndB = mx * g_spaceCheckVec

	local straightTraceA = LIBTracer.Tracer(trainEnt, straightTraceStartA, straightTraceEndA, nil, g_traceResultBufferA)
	local straightTraceB = LIBTracer.Tracer(trainEnt, straightTraceStartB, straightTraceEndB, nil, g_traceResultBufferB)

	if not straightTraceA or straightTraceA.Hit or straightTraceA.StartSolid or straightTraceA.AllSolid then
		return false
	end

	if not straightTraceB or straightTraceB.Hit or straightTraceB.StartSolid or straightTraceB.AllSolid then
		return false
	end

	return true
end

local function checkRailCrossSpace(trainEnt, mx, width, heightOffset)
	g_spaceCheckVec.z = heightOffset
	g_spaceCheckVec.x = 0

	g_spaceCheckVec.y = width / 2
	local crossTraceStart = mx * g_spaceCheckVec

	g_spaceCheckVec.y = -width / 2
	local crossTraceEnd = mx * g_spaceCheckVec

	local crossTrace = LIBTracer.Tracer(trainEnt, crossTraceStart, crossTraceEnd, nil, g_traceResultBufferA)

	if crossTrace and crossTrace.Hit and crossTrace.StartSolid and crossTrace.AllSolid then
		return false
	end

	return true
end

function LIB.ScanRail(trainEnt, aimTrace, parameters)
	parameters = parameters or {}

	local layers = parameters.layers
	if not layers or table.IsEmpty(layers) then
		return nil
	end

	local trainSizeMin = parameters.trainSizeMin or 0
	local trainSizeMax = parameters.trainSizeMax or 0

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

	local pos = aimTrace.HitPos

	local aimNormal = aimTrace.Normal

	local normal = aimTrace.HitNormal
	local normalZAbs = math.abs(normal.z)
	local normalZSign = normal.z > 0 and 1 or -1

	local ang = normal:Angle()

	g_yawOffsetAng.y = 0

	if normalZAbs >= g_groundThreshold then
		-- ground surface math
		local aimAngles = aimNormal:Angle()

		ang:RotateAroundAxis(ang:Right(), -90)

	 	g_yawOffsetAng.y = math.NormalizeAngle(aimAngles.y - ang.y) * normalZSign
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

	local foundTrackWidth = nil

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
			local traceSideA = LIBTracer.Tracer(trainEnt, layerCenterPos, layerStartPos, nil, g_traceResultBufferA)
			local traceSideB = LIBTracer.Tracer(trainEnt, layerCenterPos, layerEndPos, nil, g_traceResultBufferB)

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
		local railTopNormalA = estimateRailTopNormal(trainEnt, g_trackMx, traceSideHitPosA, railSideNormalA, upNormal, railTopTraceOffsetTop, railTopTraceOffsetBottom)
		local railTopNormalB = estimateRailTopNormal(trainEnt, g_trackMx, traceSideHitPosB, railSideNormalB, upNormal, railTopTraceOffsetTop, railTopTraceOffsetBottom)

		if not railTopNormalA then
			continue
		end

		if not railTopNormalB then
			continue
		end

		-- Final top tracers for most precise top surface normals
		local railTopA = nil
		local railTopB = nil

		railTopNormalA, railTopA = finalizeRailTopNormal(trainEnt, g_trackMx, traceSideHitPosA, railSideNormalA, railTopNormalA, railTopTraceOffsetTop, railTopTraceOffsetBottom)
		railTopNormalB, railTopB = finalizeRailTopNormal(trainEnt, g_trackMx, traceSideHitPosB, railSideNormalB, railTopNormalB, railTopTraceOffsetTop, railTopTraceOffsetBottom)

		if not validateTopNormals(railTopNormalA, railTopNormalB) then
			continue
		end

		local playerSidedRailSideNormal, playerSidedRailTopNormal = getPlayerSidedNormals(
			aimNormal,
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

		local trackWidth = math.Round(distance * math.abs(toCenterDot))
		if trackWidth < minGauge or trackWidth > maxGauge then
			-- Likely not a valid rail gauge
			continue
		end

		-- Check if the track is straight for at least the given size
		if not checkRailStraightSpace(trainEnt, g_trackMx, trainSizeMin, trainSizeMax, trackWidth, marginStraight, -marginRailEdgeBelow) then
			continue
		end

		-- Check if the area above the track is not blocked along its width
		-- This ensures were are indeed on a train track and not just in a narrow corridor
		if not checkRailCrossSpace(trainEnt, g_trackMx, trackWidth * 1.5, marginRailEdgeAbove) then
			continue
		end

		foundTrackWidth = trackWidth
		break
	end

	if not foundTrackWidth then
		return nil
	end

	g_trackMx:Mul(g_offsetMx)

	local trackPos = g_trackMx:GetTranslation()
	local trackAng = g_trackMx:GetAngles()

	local isDebug = LIBDebug.IsDeveloper()

	if isDebug then
		local widthString = string.format("Width: %i", foundTrackWidth)

		LIBDebug.SetIgnoreZ(true)

		LIBDebug.EntityTextAtPosition(trackPos, widthString, 1)
		LIBDebug.Axis(trackPos, trackAng, foundTrackWidth / 4)

		LIBDebug.ResetIgnoreZ()
	end

	return {
		pos = trackPos,
		ang = trackAng,
		width = foundTrackWidth,
	}
end

function LIB.ScanRailWithGauge(trainEnt, aimTrace, gaugename, trainParams)
	gaugename = tostring(gaugename or "")
	if gaugename == "" then
		return nil
	end

	if gaugename == LIBRail.ENUM_GAUGE_AUTO then
		return LIB.ScanRailAutoGauge(trainEnt, aimTrace, trainParams)
	end

	local gauge = LIBRail.GetGaugeByName(gaugename)
	if not gauge then
		return nil
	end

	if not gauge.isReal then
		return nil
	end

	trainParams = trainParams or {}

	local width = gauge.width
	local defaultTrainParams = gauge.defaultTrainParams
	local scanParams = gauge.scanParams

	local trainSizeMin = trainParams.trainSizeMin or defaultTrainParams.trainSizeMin or 0
	local trainSizeMax = trainParams.trainSizeMax or defaultTrainParams.trainSizeMax or 0

	local result = LIB.ScanRail(trainEnt, aimTrace, {
		offsetPos = scanParams.offsetPos,
		offsetAng = scanParams.offsetAng,
		trainSizeMin = trainSizeMin,
		trainSizeMax = trainSizeMax,
		minGauge = width - 1,
		maxGauge = width + 1,
		maxRailTopTraceZ = scanParams.maxRailTopTraceZ,
		minRailTopTraceZ = scanParams.minRailTopTraceZ,
		marginRailTopTrace = scanParams.marginRailTopTrace,
		marginRailEdgeBelow = scanParams.marginRailEdgeBelow,
		marginRailEdgeAbove = scanParams.marginRailEdgeAbove,
		marginStraight = scanParams.marginStraight,
		layers = scanParams.layers
	})

	if not result then
		return nil
	end

	if result.width ~= width then
		return nil
	end

	result.gauge = gauge

	local isDebug = LIBDebug.IsDeveloper()

	if isDebug then
		local title = gauge.title
		local titleShort = gauge.titleShort
		local gaugeString = nil

		if title == titleShort then
			gaugeString = string.format("Gauge: %s", gauge.title)
		else
			gaugeString = string.format("Gauge: %s (%s)", gauge.title, gauge.titleShort)
		end

		LIBDebug.EntityTextAtPosition(result.pos, gaugeString, 2)
	end

	return result
end

function LIB.ScanRailAutoGauge(trainEnt, aimTrace, trainParams)
	trainParams = trainParams or {}

	local trainSizeMin = trainParams.trainSizeMin or 0
	local trainSizeMax = trainParams.trainSizeMax or 0

	local result = nil

	-- Large rails, such as: PHX, rsg, rsg3ft, ron2ft
	result = LIB.ScanRail(trainEnt, aimTrace, {
		offsetPos = Vector(0, 0, -5),
		offsetAng = Angle(0, 0, 0),
		trainSizeMin = trainSizeMin,
		trainSizeMax = trainSizeMax,
		maxGauge = 100,
		minGauge = 30,
		maxRailTopTraceZ = 32,
		minRailTopTraceZ = 0,
		marginRailTopTrace = 3,
		marginRailEdgeBelow = 4,
		marginRailEdgeAbove = 2,
		marginStraight = 2,
		layers = {
			0, -4, 4
		}
	})

	if not result then
		-- Small rails, such as: Minitrains (mt12)
		result = LIB.ScanRail(trainEnt, aimTrace, {
			offsetPos = Vector(0, 0, -1),
			offsetAng = Angle(0, 0, 0),
			trainSizeMin = trainSizeMin,
			trainSizeMax = trainSizeMax,
			maxGauge = 16,
			minGauge = 8,
			maxRailTopTraceZ = 8,
			minRailTopTraceZ = 0,
			marginRailTopTrace = 0.5,
			marginRailEdgeBelow = 1,
			marginRailEdgeAbove = 2,
			marginStraight = 1,
			layers = {
				0, 1, -1
			}
		})
	end

	if not result then
		return nil
	end

	local width = result.width

	local gauge = LIBRail.GetGaugeByWidth(width)
	if not gauge then
		return nil
	end

	result.gauge = gauge

	local isDebug = LIBDebug.IsDeveloper()

	if isDebug then
		local title = gauge.title
		local titleShort = gauge.titleShort
		local gaugeString = nil

		if title == titleShort then
			gaugeString = string.format("Gauge: %s", gauge.titleShort)
		else
			gaugeString = string.format("Gauge: %s (%s)", gauge.titleShort, gauge.title)
		end

		LIBDebug.EntityTextAtPosition(result.pos, gaugeString, 2)
	end

	return result
end

function LIB.Load()
	LIBTracer = SligWolf_Addons.Tracer
	LIBDebug = SligWolf_Addons.Debug
	LIBRail = SligWolf_Addons.Rail

	-- -- Test code
	-- local lastAimTrace = nil
	-- local LIBHook = SligWolf_Addons.Hook
	-- LIBHook.Add("Think", "RailScan_Test", function()
	-- 	local ply = LIBDebug.GetDebugPlayer()
	-- 	if not IsValid(ply) then
	-- 		return
	-- 	end

	-- 	if ply:KeyDown(IN_USE) then
	-- 		local aimTrace = LIBTracer.PlayerAimTrace(ply, 5000)
	-- 		if aimTrace and aimTrace.Hit then
	-- 			lastAimTrace = aimTrace
	-- 		end
	-- 	end

	-- 	if lastAimTrace then
	-- 		LIBDebug.SetLifetime(CLIENT and LIBDebug.DEBUG_LIFETIME_FRAME or LIBDebug.DEBUG_LIFETIME_DEFAULT)

	-- 		LIB.ScanRailWithGauge(ply, lastAimTrace, LIBRail.ENUM_GAUGE_AUTO)

	-- 		LIBDebug.ResetLifetime()
	-- 	end
	-- end)
end

return true

