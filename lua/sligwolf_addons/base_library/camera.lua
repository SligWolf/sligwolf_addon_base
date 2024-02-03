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

function LIB.CamControl(ply, camEnt)
	if not IsValid(ply) then return end

	if not IsValid(camEnt) then
		ply:SetViewEntity(ply)
		ply.SLIGWOLF_Camera = nil
		return
	end

	if camEnt == ply then
		ply:SetViewEntity(ply)
		ply.SLIGWOLF_Camera = nil
		return
	end

	if ply:GetViewEntity() == camEnt then
		-- toggle view back
		ply:SetViewEntity(ply)
		ply.SLIGWOLF_Camera = nil
		return
	end

	ply:SetViewEntity(camEnt)
	ply.SLIGWOLF_Camera = camEnt
end

function LIB.ResetCamera(ply)
	if not IsValid(ply) then return end

	local swCamEnt = ply.SLIGWOLF_Camera
	if not IsValid(swCamEnt) then return end

	if ply.SLIGWOLF_Camera == ply then
		ply.SLIGWOLF_Camera = nil
		return
	end

	local camEnt = ply:GetViewEntity()
	if not IsValid(camEnt) then return end

	if camEnt ~= swCamEnt then return end
	LIB.CamControl(ply)
end

return true

