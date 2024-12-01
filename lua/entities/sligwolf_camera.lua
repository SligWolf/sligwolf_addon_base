AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

DEFINE_BASECLASS("sligwolf_base")

ENT.Spawnable 				= false
ENT.AdminOnly 				= false
ENT.DoNotDuplicate 			= true

ENT.sligwolf_cameraEntity   = true

if not SligWolf_Addons then return end
if not SligWolf_Addons.IsLoaded then return end
if not SligWolf_Addons.IsLoaded() then return end

local CONSTANTS = SligWolf_Addons.Constants

local LIBPosition = SligWolf_Addons.Position
local LIBCamera = SligWolf_Addons.Camera

function ENT:Initialize()
	BaseClass.Initialize(self)
end

function ENT:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:AddNetworkRVar("Bool", "allowThirdperson")
	self:AddNetworkRVar("Bool", "forceThirdperson")
end

function ENT:SetCameraAllowThirdperson(bool)
	if CLIENT then return end

	self:SetNetworkRVar("allowThirdperson", bool)
end

function ENT:GetCameraAllowThirdperson()
	return self:GetNetworkRVar("allowThirdperson", false)
end

function ENT:SetCameraForceThirdperson(bool)
	if CLIENT then return end

	self:SetNetworkRVar("forceThirdperson", bool)
end

function ENT:GetCameraForceThirdperson()
	return self:GetNetworkRVar("forceThirdperson", false)
end

function ENT:SetCameraAllowRotation(bool)
	if CLIENT then return end

	self._allowRotation = bool
end

function ENT:GetCameraAllowRotation()
	return self._allowRotation
end

function ENT:SetCameraDefaultDistance(distance)
	if CLIENT then return end

	if distance ~= nil then
		distance = tonumber(distance or 0)
	end

	self._defaultDistance = distance
end

function ENT:GetCameraDefaultDistance()
	return self._defaultDistance
end

function ENT:GetViewingPlayer()
	return self._viewingPlayer
end

function ENT:ThinkInternal()
	BaseClass.ThinkInternal(self)

	if not SERVER then
		return
	end

	if not self._allowRotation then
		return
	end

	if not self:TurnCamera() then
		return
	end

	self:NextThink(CurTime())
	return true
end

function ENT:TurnCamera()
	if not self._allowRotation then
		return false
	end

	local ply = self._viewingPlayer
	if not IsValid(ply) then
		return false
	end

	local ang = LIBPosition.GetPlayerEyeAngles(ply)

	self:SetAngles(ang)
	return true
end

function ENT:ControlCamera(ply)
	if not SERVER then
		return
	end

	if not IsValid(ply) then
		return
	end

	local plyTable = ply:SligWolf_GetTable()
	local oldCamera = plyTable.camera

	if oldCamera == self then
		return
	end

	LIBCamera.LeaveCamera(self._viewingPlayer)
	LIBCamera.LeaveCamera(ply)

	plyTable.camera = self
	self._viewingPlayer = ply

	ply:SetViewEntity(self)
	self:ApplyCameraThirdperson(false)

	self:TurnCamera()
end

function ENT:ApplyCameraThirdperson(backToPlayer)
	if not SERVER then
		return
	end

	local ply = self._viewingPlayer
	if not IsValid(ply) then
		return
	end

	local vehicle = ply:GetVehicle()
	if not IsValid(vehicle) then
		return
	end

	local plyTable = ply:SligWolf_GetTable()

	local oldThirdperson = plyTable.cameraThirdperson
	local oldCameraLastAngle = plyTable.cameraLastAngle
	local oldCameraDistance = plyTable.cameraDistance

	if backToPlayer then
		if oldThirdperson ~= nil then
			vehicle:SetThirdPersonMode(oldThirdperson)
		end

		if oldCameraLastAngle ~= nil and self._allowRotation then
			ply:SetEyeAngles(oldCameraLastAngle)
		end

		if oldCameraDistance ~= nil and self._defaultDistance then
			vehicle:SetCameraDistance(oldCameraDistance)
		end

		plyTable.cameraThirdperson = nil
		plyTable.cameraLastAngle = nil
		plyTable.cameraDistance = nil
		return
	end

	if plyTable.cameraThirdperson == nil then
		plyTable.cameraThirdperson = vehicle:GetThirdPersonMode()
	end

	if self._allowRotation then
		if plyTable.cameraLastAngle == nil then
			plyTable.cameraLastAngle = LIBPosition.GetPlayerEyeAngles(ply)
		end

		ply:SetEyeAngles(CONSTANTS.angZero)
	end

	if self._defaultDistance then
		if plyTable.cameraDistance == nil then
			plyTable.cameraDistance = vehicle:GetCameraDistance()
		end

		vehicle:SetCameraDistance(self._defaultDistance)
	end

	if not self:GetCameraAllowThirdperson() then
		vehicle:SetThirdPersonMode(false)
		return
	end

	if self:GetCameraForceThirdperson() then
		vehicle:SetThirdPersonMode(true)
	end
end

function ENT:LeaveCamera()
	if not SERVER then
		return
	end

	local ply = self._viewingPlayer
	if not IsValid(ply) then
		return
	end

	local plyTable = ply:SligWolf_GetTable()

	local camEnt = plyTable.camera
	if not IsValid(camEnt) then
		return
	end

	ply:SetViewEntity(ply)
	self:ApplyCameraThirdperson(true)

	plyTable.cameraThirdperson = nil
	plyTable.cameraLastAngle = nil
	plyTable.camera = nil

	self._viewingPlayer = nil
end

function ENT:ToggleCamera(ply)
	if not SERVER then
		return
	end

	if not IsValid(ply) then
		return
	end

	local oldPly = self._viewingPlayer
	if not IsValid(oldPly) then
		self:ControlCamera(ply)
		return
	end

	if oldPly ~= ply then
		self:ControlCamera(ply)
		return
	end

	self:LeaveCamera()
end

function ENT:OnRemove()
	BaseClass.OnRemove(self)

	self:LeaveCamera()
end