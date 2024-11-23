AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Camera = SligWolf_Addons.Camera or {}
table.Empty(SligWolf_Addons.Camera)

local LIB = SligWolf_Addons.Camera

local LIBPosition = nil

local g_CamPos = nil
local g_InRenderScene = false

function LIB.CamControl(ply, camEnt)
	if not IsValid(ply) then return end

	local plyTable = ply:SligWolf_GetTable()
	local oldCamera = plyTable.camera

	if not IsValid(camEnt) then
		camEnt = ply
	end

	if ply:GetViewEntity() == camEnt then
		-- toggle view back
		camEnt = ply
	end

	if oldCamera == camEnt then
		return
	end

	if camEnt == ply then
		plyTable.camera = nil
	else
		plyTable.camera = camEnt
	end

	ply:SetViewEntity(camEnt)

	LIB.ApplyCameraThirdperson(ply, camEnt)
end

function LIB.ApplyCameraThirdperson(ply, camEnt)
	local cameraParameters = LIB.GetCameraParameters(camEnt)
	if not cameraParameters then
		return
	end

	if not cameraParameters.forceThirdperson then
		return
	end

	local vehicle = ply:GetVehicle()
	if not IsValid(vehicle) then
		return
	end

	local plyTable = ply:SligWolf_GetTable()

	local backToPlayer = camEnt == ply
	local oldThirdperson = plyTable.cameraThirdperson or false

	if backToPlayer then
		vehicle:SetThirdPersonMode(oldThirdperson)
		plyTable.cameraThirdperson = nil
	else
		if plyTable.cameraThirdperson == nil then
			plyTable.cameraThirdperson = vehicle:GetThirdPersonMode()
		end

		vehicle:SetThirdPersonMode(true)
	end
end

function LIB.SetCameraParameters(camera, parameters)
	if not parameters then
		return
	end

	local cameraTable = camera:SligWolf_GetTable()

	local cameraParameters = cameraTable.cameraParameters or {}
	cameraTable.cameraParameters = cameraParameters

	cameraParameters.forceThirdperson = parameters.forceThirdperson or false
	cameraParameters.allowThirdperson = parameters.allowThirdperson or false

	if cameraParameters.forceThirdperson then
		cameraParameters.allowThirdperson = true
	end
end

function LIB.GetCameraParameters(camera)
	local cameraTable = camera:SligWolf_GetTable()

	local cameraParameters = cameraTable.cameraParameters
	if not cameraParameters then
		return
	end

	return cameraParameters
end

function LIB.ResetCamera(ply)
	if not IsValid(ply) then return end

	local plyTable = ply:SligWolf_GetTable()

	plyTable.cameraThirdperson = nil

	local swCamEnt = plyTable.camera
	if not IsValid(swCamEnt) then return end

	if plyTable.camera == ply then
		plyTable.camera = nil
		return
	end

	local camEnt = ply:GetViewEntity()
	if not IsValid(camEnt) then return end

	if camEnt ~= swCamEnt then return end
	LIB.CamControl(ply)
end

function LIB.GetCameraEnt(ply)
	if not IsValid(ply) and CLIENT then
		ply = LocalPlayer()
	end

	if not IsValid(ply) then
		return nil
	end

	local camera = ply:GetViewEntity()
	if not IsValid(camera) then
		return ply
	end

	return camera
end

function LIB.GetCameraPos(ply)
	if g_CamPos then
		return g_CamPos
	end

	local camera = LIB.GetCameraEnt(ply)
	if not IsValid(camera) then
		return nil
	end

	local viewpos

	if camera:IsPlayer() then
		viewpos = LIBPosition.GetPlayerEyePos(camera)
	else
		viewpos = camera:GetPos()
	end

	return viewpos
end

function LIB.GetCameraDistance(targetPos, ply)
	local cameraPos = LIB.GetCameraPos(ply)
	if not cameraPos then
		return nil
	end

	local dist = cameraPos:Distance(targetPos)
	return dist
end

function LIB.GetCameraDistanceSqr(targetPos, ply)
	local cameraPos = LIB.GetCameraPos(ply)
	if not cameraPos then
		return nil
	end

	local distSqr = cameraPos:DistToSqr(targetPos)
	return distSqr
end

function LIB.Load()
	local LIBHook = SligWolf_Addons.Hook
	LIBPosition = SligWolf_Addons.Position

	if CLIENT then
		local function UpdateCamInfo(origin, angles, fov)
			if g_InRenderScene then
				return
			end

			g_InRenderScene = true
			g_CamPos = origin
			g_InRenderScene = false
		end

		LIBHook.Add("RenderScene", "Library_Position_UpdatePlayerPos_CamInfo", UpdateCamInfo, 1000)
	end
end


return true

