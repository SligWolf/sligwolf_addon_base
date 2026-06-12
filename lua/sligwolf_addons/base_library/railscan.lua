local SligWolf_Addons = _G.SligWolf_Addons
if not SligWolf_Addons then
	return
end

local LIB = SligWolf_Addons:NewLib("Railscan")

local CONSTANTS = SligWolf_Addons.Constants

local LIBRail = SligWolf_Addons.Rail
local LIBDebug = SligWolf_Addons.Debug
local LIBTracer = SligWolf_Addons.Tracer

local g_sqrtTwo = math.sqrt(2)
local g_tinyMargin = 0.1
local g_tinyMarginFactor = 0.01

local g_groundThreshold = math.cos(math.rad(64))
local g_dotTolerance = math.cos(math.rad(1))

local g_layerVec = Vector()
local g_spaceCheckVec = Vector()

local g_dirAng = Angle()
local g_yawOffsetAng = Angle()
local g_yaw180Ang = Angle(0, 180, 0)

local g_tmpMx = Matrix()
local g_baseMx = Matrix()
local g_layerMx = Matrix()
local g_worldMx = Matrix()
local g_trackMxTop = Matrix()
local g_trackMxBottom = Matrix()
local g_offsetMx = Matrix()

local g_traceResultBufferA = {}
local g_traceResultBufferB = {}

local g_dirs = {
	0, 90
}

local g_dirsMono = {
	0, -45, 45, 90
}

local g_dirsZero = {
	0
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

local function finalizeRailTopNormal(trainEnt, railSidePos, railSideNormal, estimatedRailTopNormal, railOffsetTop, railOffsetBottom)
	g_tmpMx:Identity()
	g_tmpMx:SetTranslation(railSidePos)
	setupRailRotationMatrix(g_tmpMx, railSideNormal, estimatedRailTopNormal)

	local traceTopStartPos = g_tmpMx * railOffsetTop
	local traceTopEndPos = g_tmpMx * railOffsetBottom

	-- Tracer for finding the top sides of rail tracks
	local traceTop = LIBTracer.Tracer(trainEnt, traceTopStartPos, traceTopEndPos, g_traceResultBufferA)

	if not traceTop or not traceTop.Hit or traceTop.StartSolid or traceTop.AllSolid then
		return nil
	end

	return traceTop.HitNormal, traceTop.HitPos
end

local function estimateRailTopNormal(trainEnt, railSidePos, railSideNormal, upNormal, railOffsetTop, railOffsetBottom)
	local railTopNormal = finalizeRailTopNormal(trainEnt, railSidePos, railSideNormal, upNormal, railOffsetTop, railOffsetBottom)
	return railTopNormal
end

local function getMonoRailSides(trainEnt, frontPos, backPos)
	local center = (frontPos + backPos) / 2

	-- Finding the rail 1st pass
	local traceSideFront = LIBTracer.Tracer(trainEnt, frontPos, center, g_traceResultBufferA)
	local traceSideBack = LIBTracer.Tracer(trainEnt, backPos, center, g_traceResultBufferB)

	if not traceSideFront or traceSideFront.StartSolid or traceSideFront.AllSolid then
		return nil
	end

	if not traceSideBack or traceSideBack.StartSolid or traceSideFront.AllSolid then
		return nil
	end

	if not traceSideFront.Hit and not traceSideBack.Hit then
		return nil
	end

	local traceSideHitPosFront = traceSideFront.HitPos
	local traceSideHitPosBack = traceSideBack.HitPos

	local railSideNormalFront = traceSideFront.Hit and traceSideFront.HitNormal or -traceSideFront.Normal
	local railSideNormalBack = traceSideBack.Hit and traceSideBack.HitNormal or -traceSideBack.Normal

	if traceSideHitPosFront == traceSideHitPosBack then
		return nil
	end

	-- Ensure both hit surfaces are parallel and are facing away from each other
	if railSideNormalFront:Dot(railSideNormalBack) > -g_dotTolerance then
		return nil
	end

	return traceSideHitPosFront, traceSideHitPosBack, railSideNormalFront, railSideNormalBack
end

local function validateTopNormals(railTopNormalA, railTopNormalB)
	if not railTopNormalA then
		return false
	end

	if not railTopNormalB then
		return false
	end

	-- Ensure both hit surfaces are pointing in the same direction (usually upwarts)
	if railTopNormalA:Dot(railTopNormalB) < g_dotTolerance then
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

	local straightTraceA = LIBTracer.Tracer(trainEnt, straightTraceStartA, straightTraceEndA, g_traceResultBufferA)
	local straightTraceB = LIBTracer.Tracer(trainEnt, straightTraceStartB, straightTraceEndB, g_traceResultBufferB)

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
	local traceStart = mx * g_spaceCheckVec

	g_spaceCheckVec.y = -width / 2
	local traceEnd = mx * g_spaceCheckVec

	local crossTrace = LIBTracer.Tracer(trainEnt, traceStart, traceEnd, g_traceResultBufferA)
	if not crossTrace or crossTrace.Hit or crossTrace.StartSolid or crossTrace.AllSolid then
		return false
	end

	return true
end

local function checkRailSideSpace(trainEnt, mxTop, mxBottom, heightOffsetTop, heightOffsetBottom, sideOffset)
	g_spaceCheckVec.y = sideOffset
	g_spaceCheckVec.x = 0

	g_spaceCheckVec.z = heightOffsetTop
	local traceStart = mxTop * g_spaceCheckVec

	g_spaceCheckVec.z = heightOffsetBottom
	local traceEnd = mxBottom * g_spaceCheckVec

	local sideTrace = LIBTracer.Tracer(trainEnt, traceStart, traceEnd, g_traceResultBufferA)
	if not sideTrace or sideTrace.Hit or sideTrace.StartSolid or sideTrace.AllSolid then
		return false
	end

	return true
end

function LIB.ScanRail(trainEnt, aimTrace, parameters)
	parameters = parameters or {}

	local layersFlat = parameters.layersFlat
	if not layersFlat or table.IsEmpty(layersFlat) then
		return nil
	end

	local layersWall = parameters.layersWall
	if not layersWall or table.IsEmpty(layersWall) then
		return nil
	end

	local maxGauge = parameters.maxGauge or 0
	local minGauge = parameters.minGauge or 0

	if maxGauge <= 0 then
		return nil
	end

	if minGauge <= 0 then
		return nil
	end

	if minGauge > maxGauge then
		return nil
	end

	local minDistance = minGauge - 1

	local trainSizeMin = parameters.trainSizeMin or 0
	local trainSizeMax = parameters.trainSizeMax or 0


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

	local dirs = g_dirsZero
	local layers = layersWall

	local tinyMargin = maxGauge * g_tinyMarginFactor + g_tinyMargin
	local maxGaugeDiagonalFront = maxGauge
	local maxGaugeDiagonalBack = 0

	g_yawOffsetAng.y = 0

	if normalZAbs >= g_groundThreshold then
		-- ground surface math
		local aimAngles = aimNormal:Angle()

		ang:RotateAroundAxis(ang:Right(), -90)

		g_yawOffsetAng.y = math.NormalizeAngle(aimAngles.y - ang.y) * normalZSign

		dirs = g_dirs
		layers = layersFlat

		maxGaugeDiagonalFront = maxGauge * g_sqrtTwo
		maxGaugeDiagonalBack = maxGaugeDiagonalFront
	end

	maxGaugeDiagonalFront = maxGaugeDiagonalFront + tinyMargin
	maxGaugeDiagonalBack = maxGaugeDiagonalBack + tinyMargin

	local maxRailGaugeDiagonalVecStart = Vector(maxGaugeDiagonalFront, 0, 0)
	local maxRailGaugeDiagonalVecEnd = Vector(-maxGaugeDiagonalBack, 0, 0)

	g_yawOffsetAng:Normalize()

	g_worldMx:Identity()
	g_layerMx:Identity()
	g_trackMxTop:Identity()

	g_offsetMx:Identity()
	g_offsetMx:SetTranslation(parameters.offsetPos or CONSTANTS.vecZero)
	g_offsetMx:SetAngles(parameters.offsetAng or CONSTANTS.angZero)

	g_baseMx:Identity()
	g_baseMx:SetTranslation(pos)
	g_baseMx:SetAngles(ang)
	g_baseMx:Rotate(g_yawOffsetAng)

	local foundTrackWidth = nil

	-- Scan in a flat cross pattern so we find tracks in every rotation.
	for _, dir in ipairs(dirs) do
		g_dirAng.y = dir
		g_dirAng:Normalize()

		local traceSideHitPosA = nil
		local traceSideHitPosB = nil

		local railSideNormalA = nil
		local railSideNormalB = nil

		local distance = nil

		LIBDebug.SetCurrentTraceDebugContext("Railscan.ScanRail.Layers")

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
			local traceSideA = LIBTracer.Tracer(trainEnt, layerCenterPos, layerStartPos, g_traceResultBufferA)
			local traceSideB = LIBTracer.Tracer(trainEnt, layerCenterPos, layerEndPos, g_traceResultBufferB)

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
			if distance < minDistance then
				-- Likely not a valid rail gauge
				continue
			end

			railSideNormalA = traceSideA.HitNormal
			railSideNormalB = traceSideB.HitNormal

			-- Ensure both hit surfaces are parallel and are facing each other
			if railSideNormalA:Dot(railSideNormalB) > -g_dotTolerance then
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

		LIBDebug.SetCurrentTraceDebugContext("Railscan.ScanRail.TopNormals")

		local upNormal = g_worldMx:GetUp()

		-- Top tracers for first estimation
		local railTopNormalA = estimateRailTopNormal(trainEnt, traceSideHitPosA, railSideNormalA, upNormal, railTopTraceOffsetTop, railTopTraceOffsetBottom)
		local railTopNormalB = estimateRailTopNormal(trainEnt, traceSideHitPosB, railSideNormalB, upNormal, railTopTraceOffsetTop, railTopTraceOffsetBottom)

		if not railTopNormalA then
			continue
		end

		if not railTopNormalB then
			continue
		end

		-- Final top tracers for most precise top surface normals
		local railTopA = nil
		local railTopB = nil

		railTopNormalA, railTopA = finalizeRailTopNormal(trainEnt, traceSideHitPosA, railSideNormalA, railTopNormalA, railTopTraceOffsetTop, railTopTraceOffsetBottom)
		railTopNormalB, railTopB = finalizeRailTopNormal(trainEnt, traceSideHitPosB, railSideNormalB, railTopNormalB, railTopTraceOffsetTop, railTopTraceOffsetBottom)

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

		LIBDebug.SetCurrentTraceDebugContext("Railscan.ScanRail.SpaceCheck")

		-- Found center and direction of the track
		g_trackMxTop:Identity()
		g_trackMxTop:SetTranslation((railTopA + railTopB) / 2)
		setupRailRotationMatrix(g_trackMxTop, playerSidedRailSideNormal, playerSidedRailTopNormal)

		-- Find track gauge
		local toCenterDir = traceSideHitPosA - (traceSideHitPosA + traceSideHitPosB) / 2
		toCenterDir:Normalize()

		local toCenterDot = toCenterDir:Dot(g_trackMxTop:GetRight())

		local trackWidth = math.Round(distance * math.abs(toCenterDot))
		if trackWidth < minGauge or trackWidth > maxGauge then
			-- Likely not a valid rail gauge
			continue
		end

		-- Check if the track is straight for at least the given size
		if not checkRailStraightSpace(trainEnt, g_trackMxTop, trainSizeMin, trainSizeMax, trackWidth, marginStraight, -marginRailEdgeBelow) then
			continue
		end

		-- Check if the area above the track is not blocked along its width
		-- This ensures were are indeed on a train track and not just in a narrow corridor
		if not checkRailCrossSpace(trainEnt, g_trackMxTop, trackWidth * 1.5, marginRailEdgeAbove) then
			break
		end

		foundTrackWidth = trackWidth
		break
	end

	LIBDebug.ResetTraceDebugContext()

	if not foundTrackWidth then
		return nil
	end

	g_trackMxTop:Mul(g_offsetMx)

	local trackPos = g_trackMxTop:GetTranslation()
	local trackAng = g_trackMxTop:GetAngles()

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

function LIB.ScanMonoRail(trainEnt, aimTrace, parameters)
	parameters = parameters or {}

	local layersFlat = parameters.layersFlat
	if not layersFlat or table.IsEmpty(layersFlat) then
		return nil
	end

	local layersWall = parameters.layersWall
	if not layersWall or table.IsEmpty(layersWall) then
		return nil
	end


	local maxGauge = parameters.maxGauge or 0
	local minGauge = parameters.minGauge or 0

	if maxGauge <= 0 then
		return nil
	end

	if minGauge <= 0 then
		return nil
	end

	if minGauge > maxGauge then
		return nil
	end

	local minDistance = minGauge - 1

	local trainSizeMin = parameters.trainSizeMin or 0
	local trainSizeMax = parameters.trainSizeMax or 0

	local maxRailTopTraceZ = parameters.maxRailTopTraceZ or 32
	local minRailTopTraceZ = parameters.minRailTopTraceZ or -32

	local maxRailHeight = parameters.maxRailHeight or 0
	local minRailHeight = parameters.minRailHeight or 0

	local marginRailEdgeBelow = parameters.marginRailEdgeBelow or 4
	local marginRailEdgeAbove = parameters.marginRailEdgeAbove or 2
	local marginRailOuterWidth = parameters.marginRailOuterWidth or 16
	local marginStraight = parameters.marginStraight or 2

	local railTopTraceOffsetTop = Vector(0, 0, maxRailTopTraceZ)
	local railTopTraceOffsetBottom = Vector(0, 0, minRailTopTraceZ)


	local pos = aimTrace.HitPos

	local aimNormal = aimTrace.Normal

	local normal = aimTrace.HitNormal
	local normalZAbs = math.abs(normal.z)
	local normalZSign = normal.z > 0 and 1 or -1

	local ang = normal:Angle()

	local dirs = g_dirsZero
	local layers = layersWall

	local tinyMargin = maxGauge * g_tinyMarginFactor + g_tinyMargin
	local maxRailThicknessFront = 1
	local maxRailThicknessBack = maxGauge + 1

	g_yawOffsetAng.y = 0

	if normalZAbs >= g_groundThreshold then
		-- ground surface math
		local aimAngles = aimNormal:Angle()

		ang:RotateAroundAxis(ang:Right(), -90)

	 	g_yawOffsetAng.y = math.NormalizeAngle(aimAngles.y - ang.y) * normalZSign

		dirs = g_dirsMono
		layers = layersFlat

		maxRailThicknessFront = maxGauge
		maxRailThicknessBack = maxRailThicknessFront
	end

	maxRailThicknessFront = maxRailThicknessFront + tinyMargin
	maxRailThicknessBack = maxRailThicknessBack + tinyMargin

	local maxRailThicknessVecFront = Vector(maxRailThicknessFront, 0, 0)
	local maxRailThicknessVecBack = Vector(-maxRailThicknessBack, 0, 0)

	g_yawOffsetAng:Normalize()

	g_worldMx:Identity()
	g_layerMx:Identity()
	g_trackMxTop:Identity()
	g_trackMxBottom:Identity()

	g_offsetMx:Identity()
	g_offsetMx:SetTranslation(parameters.offsetPos or CONSTANTS.vecZero)
	g_offsetMx:SetAngles(parameters.offsetAng or CONSTANTS.angZero)

	g_baseMx:Identity()
	g_baseMx:SetTranslation(pos)
	g_baseMx:SetAngles(ang)
	g_baseMx:Rotate(g_yawOffsetAng)

	local foundRailWidth = nil
	local hasPlayerFacingOpening = true

	-- Scan in a flat cross pattern so we find tracks in every rotation.
	for _, dir in ipairs(dirs) do
		g_dirAng.y = dir
		g_dirAng:Normalize()

		local railSideHitPosFront = nil
		local railSideHitPosBack = nil

		local railSideNormalFront = nil
		local railSideNormalBack = nil

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

			railSideHitPosFront = nil
			railSideHitPosBack = nil

			railSideNormalFront = nil
			railSideNormalBack = nil

			distance = nil

			LIBDebug.SetCurrentTraceDebugContext("Railscan.ScanMonoRail.Layers")

			-- Finding the rail 1st pass
			local frontPos = g_worldMx * maxRailThicknessVecFront -- Facing to player
			local backPos = g_worldMx * maxRailThicknessVecBack -- Facing away player

			railSideHitPosFront, railSideHitPosBack, railSideNormalFront, railSideNormalBack = getMonoRailSides(trainEnt, frontPos, backPos)
			if not railSideHitPosFront then
				continue
			end

			distance = railSideHitPosFront:Distance(railSideHitPosBack)
			if distance < minDistance then
				-- Likely not a valid rail gauge
				continue
			end

			break
		end

		if not railSideHitPosFront or not railSideHitPosBack then
			continue
		end

		if not railSideNormalFront or not railSideNormalBack then
			continue
		end

		if not distance then
			continue
		end

		local toCenterDir = railSideHitPosFront - (railSideHitPosFront + railSideHitPosBack) / 2
		toCenterDir:Normalize()

		local toCenterDot = toCenterDir:Dot(railSideNormalFront)

		local railWidth = math.Round(distance * math.abs(toCenterDot))
		if railWidth < minGauge or railWidth > maxGauge then
			-- Likely not a valid rail gauge
			continue
		end

		LIBDebug.SetCurrentTraceDebugContext("Railscan.ScanMonoRail.TopNormals")

		local upNormal = g_worldMx:GetUp()
		local toCenter = -railWidth / 2

		railTopTraceOffsetTop.y = toCenter
		railTopTraceOffsetBottom.y = toCenter

		-- Top tracer for first estimation
		local railTopNormal = estimateRailTopNormal(trainEnt, railSideHitPosFront, railSideNormalFront, upNormal, railTopTraceOffsetTop, railTopTraceOffsetBottom)
		if not railTopNormal then
			continue
		end

		-- Final top tracer for most precise top surface normal
		local railTop = nil

		railTopNormal, railTop = finalizeRailTopNormal(trainEnt, railSideHitPosFront, railSideNormalFront, railTopNormal, railTopTraceOffsetTop, railTopTraceOffsetBottom)

		if not railTopNormal then
			continue
		end

		-- Get bottom surface
		local railBottom = nil

		railBottomNormal, railBottom = finalizeRailTopNormal(trainEnt, railSideHitPosFront, railSideNormalFront, railTopNormal, railTopTraceOffsetBottom, railTopTraceOffsetTop)

		if not railBottomNormal then
			continue
		end

		-- Make sure the rail is not too high
		local trackHeight = railTop:Distance(railBottom)
		trackHeight = math.Round(trackHeight)

		if trackHeight < minRailHeight or trackHeight > maxRailHeight then
			continue
		end

		LIBDebug.SetCurrentTraceDebugContext("Railscan.ScanMonoRail.SpaceCheck")

		-- Found center and direction of the track
		g_trackMxTop:Identity()
		g_trackMxTop:SetTranslation(railTop)
		setupRailRotationMatrix(g_trackMxTop, railSideNormalFront, railTopNormal)

		g_trackMxBottom:Set(g_trackMxTop)
		g_trackMxBottom:SetTranslation(railBottom)

		-- Check if the rail is straight for at least the given size
		if not checkRailStraightSpace(trainEnt, g_trackMxTop, trainSizeMin, trainSizeMax, railWidth + marginStraight, 0, -marginRailEdgeBelow) then
			continue
		end

		local heightOffsetTop = marginRailEdgeAbove
		local heightOffsetBottom = -marginRailEdgeAbove

		-- Check if the area above the rail is not blocked along its width
		-- This ensures were are indeed on a rail and not just in a narrow corridor
		if not checkRailCrossSpace(trainEnt, g_trackMxTop, marginRailOuterWidth, heightOffsetTop) then
		 	break
		end

		-- Also check if the area below the rail is not blocked along its width
		if not checkRailCrossSpace(trainEnt, g_trackMxBottom, marginRailOuterWidth, heightOffsetBottom) then
		 	break
		end

		-- Find which side is open
		local openFrontSide = checkRailSideSpace(trainEnt, g_trackMxTop, g_trackMxBottom, heightOffsetTop, heightOffsetBottom, -marginRailOuterWidth / 2)
		local openBackSide = checkRailSideSpace(trainEnt, g_trackMxTop, g_trackMxBottom, heightOffsetTop, heightOffsetBottom, marginRailOuterWidth / 2)

		if not openFrontSide and not openBackSide then
			-- No side is open, likely an invalid geometry
			break
		end

		hasPlayerFacingOpening = true

		if not openFrontSide then
			hasPlayerFacingOpening = false
		end

		foundRailWidth = railWidth
		break
	end

	LIBDebug.ResetTraceDebugContext()

	if not foundRailWidth then
		return nil
	end

	if not hasPlayerFacingOpening then
		-- Turn around the direction 180° if the front (player facing) side is closed
		g_trackMxTop:Rotate(g_yaw180Ang)
	end

	g_trackMxTop:Mul(g_offsetMx)

	local trackPos = g_trackMxTop:GetTranslation()
	local trackAng = g_trackMxTop:GetAngles()

	local isDebug = LIBDebug.IsDeveloper()

	if isDebug then
		local widthString = string.format("Width: %i", foundRailWidth)

		LIBDebug.SetIgnoreZ(true)

		LIBDebug.EntityTextAtPosition(trackPos, widthString, 1)
		LIBDebug.Axis(trackPos, trackAng, foundRailWidth / 2)

		LIBDebug.ResetIgnoreZ()
	end

	return {
		pos = trackPos,
		ang = trackAng,
		width = foundRailWidth,
	}
end

function LIB.ScanRailWithGauge(trainEnt, aimTrace, gaugeName, trainParams)
	local gauge = LIBRail.GetGaugeByName(gaugeName)
	if not gauge then
		return nil
	end

	local trainClass = LIBRail.TrainClassByName(gauge.trainClass)

	local scanFunction = nil
	local scanParams = nil
	local defaultTrainParams = nil

	if trainClass then
		scanFunction = trainClass.scanFunction or gauge.scanFunction
		scanParams = trainClass.scanParams or gauge.scanParams
		defaultTrainParams = trainClass.defaultTrainParams or gauge.defaultTrainParams
	else
		scanFunction = gauge.scanFunction
		scanParams = gauge.scanParams
		defaultTrainParams = gauge.defaultTrainParams
	end

	if not scanFunction then
		scanFunction = LIB.ScanRailInternal
	end

	if not scanParams then
		return nil
	end

	local result = scanFunction(gauge, trainEnt, aimTrace, scanParams, trainParams or defaultTrainParams)
	if not result then
		return nil
	end

	local newgauge = LIBRail.GetGaugeByWidth(result.width)
	if not newgauge then
		return nil
	end

	if gauge ~= newgauge and not gauge.isReal then
		gauge = newgauge
	end

	result.gauge = gauge

	trainClass = LIBRail.TrainClassByName(gauge.trainClass)
	result.trainClass = trainClass

	local isDebug = LIBDebug.IsDeveloper()

	if isDebug then
		local pos = result.pos

		local titleShort = gauge.titleShort
		local debugString = string.format("Gauge: %s", titleShort)

		LIBDebug.EntityTextAtPosition(pos, debugString, 2)

		titleShort = trainClass and trainClass.titleShort or "UNKNOWN"
		debugString = string.format("Train Class: %s", titleShort)

		LIBDebug.EntityTextAtPosition(pos, debugString, 3)
	end

	return result
end

function LIB.ScanRailAutoInternal(trainEnt, aimTrace, scanParams, trainParams)
	local items = scanParams.items

	for _, item in ipairs(items) do
		local trainClass = LIBRail.TrainClassByName(item.trainClass)
		if not trainClass then
			continue
		end

		local trainClassScanParams = trainClass.scanParams
		if not trainClassScanParams then
			continue
		end

		local thisTrainParams = trainParams or trainClass.defaultTrainParams

		trainClassScanParams.trainSizeMin = thisTrainParams.trainSizeMin
		trainClassScanParams.trainSizeMax = thisTrainParams.trainSizeMax

		trainClassScanParams.maxGauge = item.maxGauge
		trainClassScanParams.minGauge = item.minGauge

		local result = LIB.ScanRail(trainEnt, aimTrace, trainClassScanParams)
		if result then
			return result
		end
	end

	return nil
end

function LIB.ScanRailInternal(gauge, trainEnt, aimTrace, scanParams, trainParams)
	local minGauge = gauge.width
	local maxGauge = minGauge + gauge.tolerance

	scanParams.trainSizeMin = trainParams.trainSizeMin
	scanParams.trainSizeMax = trainParams.trainSizeMax
	scanParams.minGauge = minGauge
	scanParams.maxGauge = maxGauge

	local result = LIB.ScanRail(trainEnt, aimTrace, scanParams)

	if not result then
		return nil
	end

	return result
end

function LIB.ScanMonoRailInternal(gauge, trainEnt, aimTrace, scanParams, trainParams)
	local minGauge = gauge.width
	local maxGauge = minGauge + gauge.tolerance

	scanParams.trainSizeMin = trainParams.trainSizeMin
	scanParams.trainSizeMax = trainParams.trainSizeMax
	scanParams.minGauge = minGauge
	scanParams.maxGauge = maxGauge

	local result = LIB.ScanMonoRail(trainEnt, aimTrace, scanParams)
	if not result then
		return nil
	end

	return result
end

function LIB.Load()
	LIBTracer = SligWolf_Addons.Tracer
	LIBDebug = SligWolf_Addons.Debug
	LIBRail = SligWolf_Addons.Rail

	LIBDebug.AddTraceDebugContext("Railscan.ScanRail.Layers", {
		title = "Layers",
		colorLive = Color(140, 220, 140),
		colorDead = Color(160, 160, 0),
	})

	LIBDebug.AddTraceDebugContext("Railscan.ScanRail.TopNormals", {
		title = "Top Normals",
		colorLive = Color(128, 128, 128),
		colorDead = Color(48, 48, 48),
	})

	LIBDebug.AddTraceDebugContext("Railscan.ScanRail.SpaceCheck", {
		title = "Space Check",
		colorLive = Color(255, 120, 50),
		colorDead = Color(150, 0, 0),
	})

	LIBDebug.AddTraceDebugContext("Railscan.ScanMonoRail.Layers", {
		title = "Layers",
		scale = 0.25,
		colorLive = Color(140, 220, 140),
		colorDead = Color(160, 160, 0),
	})

	LIBDebug.AddTraceDebugContext("Railscan.ScanMonoRail.TopNormals", {
		title = "Top Normals",
		colorLive = Color(128, 128, 128),
		colorDead = Color(0, 0, 0, 0),
	})

	LIBDebug.AddTraceDebugContext("Railscan.ScanMonoRail.SpaceCheck", {
		title = "Space Check",
		colorLive = Color(255, 120, 50),
		colorDead = Color(150, 0, 0),
	})

	-- Test code
	local lastAimTrace = LIB._lastAimTrace or {}
	LIB._lastAimTrace = lastAimTrace

	local mode = LIBRail.TRAIN_GAUGE_WP

	local LIBHook = SligWolf_Addons.Hook
	LIBHook.Add("Think", "RailScan_Test", function()
		local ply = LIBDebug.GetDebugPlayer()
		if not IsValid(ply) then
			return
		end

		local retrace = false

		if ply:KeyDown(IN_USE) then
			retrace = true
		end

		if ply:KeyDown(IN_WALK) and ply:KeyDown(IN_JUMP) then
			mode = LIBRail.TRAIN_GAUGE_AUTO
		end

		if ply:KeyDown(IN_WALK) and ply:KeyDown(IN_DUCK) then
			mode = LIBRail.TRAIN_GAUGE_PHX
		end

		if ply:KeyDown(IN_WALK) and ply:KeyDown(IN_SPEED) then
			mode = LIBRail.TRAIN_GAUGE_WP
		end

		if retrace then
			local aimTrace = LIBTracer.PlayerAimTrace(ply, 5000)
			if aimTrace and aimTrace.Hit then
				table.CopyFromTo(aimTrace, lastAimTrace)
			end
		end

		if lastAimTrace.Hit and mode then
			LIBDebug.SetLifetime(CLIENT and LIBDebug.DEBUG_LIFETIME_FRAME or LIBDebug.DEBUG_LIFETIME_DEFAULT)

			LIB.ScanRailWithGauge(ply, lastAimTrace, mode)

			LIBDebug.ResetLifetime()
		end
	end)
end

return true

