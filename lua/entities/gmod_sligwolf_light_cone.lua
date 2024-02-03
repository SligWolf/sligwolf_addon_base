AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

DEFINE_BASECLASS("gmod_sligwolf_base")

ENT.Spawnable			= false
ENT.RenderGroup 		= RENDERGROUP_BOTH
ENT.DoNotDuplicate 		= true

if not SligWolf_Addons then return end
if not SligWolf_Addons.IsLoaded then return end
if not SligWolf_Addons.IsLoaded() then return end

local CamPos
local InRenderScene = false

function ENT:Initialize()
	BaseClass.Initialize(self)
	self:TurnOn(false)

	if CLIENT then
		hook.Remove("RenderScene", "SLIGWOLF_CamInfo")
		hook.Add("RenderScene", "SLIGWOLF_CamInfo", function(origin, angles, fov)
			if (InRenderScene) then return end
			InRenderScene = true
			CamPos = origin
			InRenderScene = false
		end)
	end
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

function ENT:GetCameraEnt(ply)
	if (not IsValid(ply) and CLIENT) then
		ply = LocalPlayer()
	end

	if (not IsValid(ply)) then return nil end
	local camera = ply:GetViewEntity()
	if (not IsValid(camera)) then return ply end

	return camera
end

function ENT:GetCameraPos(ply)
	local viewpos

	if (not CamPos) then
		local camera = self:GetCameraEnt(ply)
		if (not IsValid(camera)) then return EmtyVec end

		if (camera:IsPlayer()) then
			viewpos = camera:EyePos()
		else
			viewpos = camera:GetPos()
		end
	end

	return CamPos or viewpos or Vector()
end

function ENT:Think()
	local isON = self:IsOn()

	if not IsValid(self.flashlighttex) and isON then
		self:CreateProjectedTexture()
	end

	if IsValid(self.flashlighttex) and not isON then
		self:RemoveProjectedTexture()
	end

	if not IsValid(self.flashlighttex) then return end

	local pos = self:GetPos()
	local ang = self:GetAngles()
	local col = self:GetColor()
	local bright = self:Get_Brightness()
	local fov = self:Get_FOV()
	local farz = self:Get_FarZ()
	local nearz = self:Get_NearZ()
	local maxdist = self:Get_ShadowRenderDist()

	if maxdist > 0 then
		local campos = self:GetCameraPos()
		local dist = pos:Distance(campos)
		self.flashlighttex:SetEnableShadows(dist <= maxdist)
	else
		self.flashlighttex:SetEnableShadows(true)
	end

	self.flashlighttex:SetPos(pos)
	self.flashlighttex:SetAngles(ang)
	self.flashlighttex:SetTexture(self:Get_Texture())
	self.flashlighttex:SetColor(col)
	self.flashlighttex:SetBrightness(bright)
	self.flashlighttex:SetFOV(fov)
	self.flashlighttex:SetFarZ(farz)
	self.flashlighttex:SetNearZ(nearz)

	self:Debug(10, col)
	self.flashlighttex:Update()
end

function ENT:OnRemove()
	BaseClass.OnRemove(self)

	self:RemoveProjectedTexture()
end

function ENT:Update()
	if not IsValid(self.flashlighttex) then return end
	self.flashlighttex:Update()
end

