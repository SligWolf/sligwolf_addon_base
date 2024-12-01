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


function LIB.ControlCamera(camEnt, ply)
	if not IsValid(ply) then return end
	if not IsValid(camEnt) then return end
	if not camEnt.sligwolf_cameraEntity then return end

	camEnt:ControlCamera(ply)
end

function LIB.ToggleCamera(camEnt, ply)
	if not IsValid(ply) then return end
	if not IsValid(camEnt) then return end
	if not camEnt.sligwolf_cameraEntity then return end

	camEnt:ToggleCamera(ply)
end

function LIB.LeaveCamera(plyOrCam)
	if not IsValid(plyOrCam) then return end

	local camEnt = nil

	if plyOrCam:IsPlayer() then
		camEnt = plyOrCam:SligWolf_GetTable().camera
	else
		camEnt = plyOrCam
	end

	if not IsValid(camEnt) then
		return
	end

	if not camEnt.sligwolf_cameraEntity then
		return
	end

	camEnt:LeaveCamera()
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

