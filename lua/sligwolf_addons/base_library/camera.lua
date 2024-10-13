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

	if not IsValid(camEnt) then
		ply:SetViewEntity(ply)
		ply.sligwolf_camera = nil
		return
	end

	if camEnt == ply then
		ply:SetViewEntity(ply)
		ply.sligwolf_camera = nil
		return
	end

	if ply:GetViewEntity() == camEnt then
		-- toggle view back
		ply:SetViewEntity(ply)
		ply.sligwolf_camera = nil
		return
	end

	ply:SetViewEntity(camEnt)
	ply.sligwolf_camera = camEnt
end

function LIB.ResetCamera(ply)
	if not IsValid(ply) then return end

	local swCamEnt = ply.sligwolf_camera
	if not IsValid(swCamEnt) then return end

	if ply.sligwolf_camera == ply then
		ply.sligwolf_camera = nil
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

