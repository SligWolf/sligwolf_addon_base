local SligWolf_Addons = _G.SligWolf_Addons
if not SligWolf_Addons then
	return
end

local LIB = SligWolf_Addons:NewLib("Thirdperson")

local CONSTANTS = SligWolf_Addons.Constants

local LIBEntities = nil
local LIBCamera = nil
local LIBDebug = nil
local LIBHook = nil

local g_trace = {}
local g_traceResult = {}

g_trace.output = g_traceResult

local col_calcViewOrigin = Color(64, 0, 192)

local function thirdpersonCalcVehicleView(vehicle, ply, view)
	if not vehicle then
		return
	end

	if not vehicle.sligwolf_entity and not vehicle:GetNWBool("sligwolf_entity") then
		return
	end

	if not vehicle.GetThirdPersonMode then
		return
	end

	local camera = LIBCamera.GetCameraEnt(ply)
	if not IsValid(camera) then
		return
	end

	local isCamera = ply ~= camera
	local forceThirdperson = false

	if isCamera then
		if not camera.sligwolf_cameraEntity then
			return
		end

		forceThirdperson = camera:GetCameraForceThirdperson()

		if not forceThirdperson and not camera:GetCameraAllowThirdperson() then
			return
		end
	end

	if not forceThirdperson and not vehicle:GetThirdPersonMode() then
		return
	end

	local mn, mx = vehicle:GetRenderBounds()
	local radius = (mn - mx):Length()
	radius = radius + radius * vehicle:GetCameraDistance()

	local origin = view.origin or CONSTANTS.vecZero
	local angles = view.angles or CONSTANTS.angZero

	if not isCamera then
		local thirdpersonParameters = LIB.GetThirdpersonParameters(vehicle)

		if thirdpersonParameters then
			local originOffset = thirdpersonParameters.originOffset or CONSTANTS.vecZero
			local anglesOffset = thirdpersonParameters.anglesOffset or CONSTANTS.angZero

			local _, newAngles = LocalToWorld(CONSTANTS.vecZero, anglesOffset, CONSTANTS.vecZero, angles)
			local newOrigin = LocalToWorld(originOffset, CONSTANTS.angZero, origin, vehicle:GetAngles())

			origin = newOrigin
			angles = newAngles
		end
	end

	angles:Normalize()

	LIBDebug.Cross(origin, 20, col_calcViewOrigin)

	local TargetOrigin = origin + (-angles:Forward() * radius)
	local WallOffset = 4

	local root = LIBEntities.GetSuperParent(vehicle)

	g_trace.start = origin
	g_trace.endpos = TargetOrigin

	g_trace.filter = function(ent)
		if not ent.sligwolf_entity and not ent:GetNWBool("sligwolf_entity") then
			return true
		end

		if LIBEntities.GetSuperParent(ent) == root then
			return false
		end

		return true
	end

	g_trace.mins = Vector(-WallOffset, -WallOffset, -WallOffset)
	g_trace.maxs = Vector(WallOffset, WallOffset, WallOffset)

	util.TraceHull(g_trace)

	view.origin = g_traceResult.HitPos
	view.angles = angles
	view.drawviewer = true

	if g_traceResult.Hit and not g_traceResult.StartSolid then
		view.origin = view.origin + g_traceResult.HitNormal * WallOffset
	end

	return view
end

function LIB.SetThirdpersonParameters(vehicle, parameters)
	if not parameters then
		return
	end

	local vehicleTable = vehicle:SligWolf_GetTable()

	local thirdpersonParameters = vehicleTable.thirdpersonParameters or {}
	vehicleTable.thirdpersonParameters = thirdpersonParameters

	local anglesOffset = parameters.anglesOffset or CONSTANTS.angZero
	local originOffset = parameters.originOffset or CONSTANTS.vecZero

	thirdpersonParameters.anglesOffset = anglesOffset
	thirdpersonParameters.originOffset = originOffset
end

function LIB.GetThirdpersonParameters(vehicle)
	local vehicleTable = vehicle:SligWolf_GetTable()

	local thirdpersonParameters = vehicleTable.thirdpersonParameters
	if not thirdpersonParameters then
		return
	end

	return thirdpersonParameters
end

function LIB.Load()
	LIBEntities = SligWolf_Addons.Entities
	LIBCamera = SligWolf_Addons.Camera
	LIBHook = SligWolf_Addons.Hook
	LIBDebug = SligWolf_Addons.Debug

	if SERVER then
		return
	end

	LIBHook.Add("CalcVehicleView", "Library_Thirdperson_CalcVehicleView", thirdpersonCalcVehicleView, 11000)
end

return true

