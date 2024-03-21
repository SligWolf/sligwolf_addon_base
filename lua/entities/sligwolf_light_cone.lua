AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

DEFINE_BASECLASS("sligwolf_base")

ENT.Spawnable			= false
ENT.RenderGroup 		= RENDERGROUP_BOTH
ENT.DoNotDuplicate 		= true

if not SligWolf_Addons then return end
if not SligWolf_Addons.IsLoaded then return end
if not SligWolf_Addons.IsLoaded() then return end

local LIBCamera = SligWolf_Addons.Camera

function ENT:Initialize()
	BaseClass.Initialize(self)
	self:TurnOn(false)
end

function ENT:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:AddNetworkRVar("String", "Texture")
	self:AddNetworkRVar("Int", "FarZ")
	self:AddNetworkRVar("Int", "NearZ")
	self:AddNetworkRVar("Int", "ShadowRenderDist")
	self:AddNetworkRVar("Float", "Brightness")
	self:AddNetworkRVar("Float", "FOV")
end

function ENT:Set_Texture(text)
	if CLIENT then return end

	self:SetNetworkRVar("Texture", text)
end

function ENT:Get_Texture()
	return self:GetNetworkRVarString("Texture", "effects/flashlight001")
end

function ENT:Set_Brightness(num)
	if CLIENT then return end

	self:SetNetworkRVar("Brightness", num)
end

function ENT:Get_Brightness()
	return self:GetNetworkRVarNumber("Brightness", 4)
end

function ENT:Set_FOV(num)
	if CLIENT then return end

	self:SetNetworkRVar("FOV", num)
end

function ENT:Get_FOV()
	return self:GetNetworkRVarNumber("FOV", 90)
end

function ENT:Set_FarZ(num)
	if CLIENT then return end

	self:SetNetworkRVar("FarZ", num)
end

function ENT:Get_FarZ()
	return self:GetNetworkRVarNumber("FarZ", 1024)
end

function ENT:Set_NearZ(num)
	if CLIENT then return end

	self:SetNetworkRVar("NearZ", num)
end

function ENT:Get_NearZ()
	return self:GetNetworkRVarNumber("NearZ", 8)
end

function ENT:Set_ShadowRenderDist(num)
	if CLIENT then return end

	self:SetNetworkRVar("ShadowRenderDist", num)
end

function ENT:Get_ShadowRenderDist()
	return self:GetNetworkRVarNumber("ShadowRenderDist", 0)
end

function ENT:RemoveProjectedTexture()
	if not CLIENT then return end
	if not IsValid(self.flashlighttex) then return end

	self.flashlighttex:Remove()
end

function ENT:CreateProjectedTexture()
	if not CLIENT then return end
	self:RemoveProjectedTexture()

	self.flashlighttex = ProjectedTexture()
end

function ENT:Think()
	local isON = self:IsOn()

	if not IsValid(self.flashlighttex) and isON then
		self:CreateProjectedTexture()
	end

	if IsValid(self.flashlighttex) and not isON then
		self:RemoveProjectedTexture()
	end

	local flashlighttex = self.flashlighttex
	if not IsValid(flashlighttex) then return end

	local pos = self:GetPos()
	local ang = self:GetAngles()
	local col = self:GetColor()
	local bright = self:Get_Brightness()
	local fov = self:Get_FOV()
	local farz = self:Get_FarZ()
	local nearz = self:Get_NearZ()
	local maxdist = self:Get_ShadowRenderDist()
	local maxdistSqr = maxdist * maxdist

	if maxdist > 0 then
		local campos = LIBCamera.GetCameraPos()

		if campos then
			local distSqr = pos:DistToSqr(campos)
			flashlighttex:SetEnableShadows(distSqr <= maxdistSqr)
		else
			flashlighttex:SetEnableShadows(false)
		end
	else
		flashlighttex:SetEnableShadows(true)
	end

	flashlighttex:SetPos(pos)
	flashlighttex:SetAngles(ang)
	flashlighttex:SetTexture(self:Get_Texture())
	flashlighttex:SetColor(col)
	flashlighttex:SetBrightness(bright)
	flashlighttex:SetFOV(fov)
	flashlighttex:SetFarZ(farz)
	flashlighttex:SetNearZ(nearz)

	self:Debug(10, col)
	flashlighttex:Update()
end

function ENT:OnRemove()
	BaseClass.OnRemove(self)

	self:RemoveProjectedTexture()
end

function ENT:Update()
	local flashlighttex = self.flashlighttex
	if not IsValid(flashlighttex) then return end

	flashlighttex:Update()
end

