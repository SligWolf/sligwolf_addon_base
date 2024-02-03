AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

DEFINE_BASECLASS("gmod_sligwolf_base")

ENT.Spawnable			= false
ENT.RenderGroup 		= RENDERGROUP_BOTH
ENT.DoNotDuplicate 		= true

if not SligWolf_Addons then return end
if not SligWolf_Addons.IsLoaded then return end
if not SligWolf_Addons.IsLoaded() then return end

local S_Size 			= 1
local S_Enlarge 		= 1
local S_Count 			= 1
local S_Col				= color_white
local S_Alpha 			= 1
local S_LightMat 		= Material("sprites/light_ignorez")

local render 			= render
local util 				= util
local EyePos 			= EyePos

function ENT:Initialize()
	BaseClass.Initialize(self)

	self:ClearCache()
	self:TurnOn(false)

	if CLIENT then
		self.PixVis = util.GetPixelVisibleHandle()
	end
end

function ENT:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:AddNetworkRVar("String", "Material")
	self:AddNetworkRVar("Int", "Size")
	self:AddNetworkRVar("Int", "Enlarge")
	self:AddNetworkRVar("Int", "Count")
	self:AddNetworkRVar("Int", "Alpha_Reduce")
end

function ENT:Set_Size(num)
	if CLIENT then return end

	self:SetNetworkRVar("Size", num)
end

function ENT:Get_Size()
	return self:GetNetworkRVarNumber("Size", 1)
end

function ENT:Set_Enlarge(num)
	if CLIENT then return end

	self:SetNetworkRVar("Enlarge", num)
end

function ENT:Get_Enlarge()
	return self:GetNetworkRVarNumber("Enlarge", 1)
end

function ENT:Set_Count(num)
	if CLIENT then return end

	self:SetNetworkRVar("Count", num)
end

function ENT:Get_Count()
	return self:GetNetworkRVarNumber("Count", 1)
end

function ENT:Set_Alpha_Reduce(num)
	if CLIENT then return end

	self:SetNetworkRVar("Alpha_Reduce", num)
end

function ENT:Get_Alpha_Reduce()
	return self:GetNetworkRVarNumber("Alpha_Reduce", 1)
end

function ENT:Set_Material(mat)
	if CLIENT then return end

	self:SetNetworkRVarMaterial("Material", mat)
end

function ENT:Get_Material()
	return self:GetNetworkRVarMaterial("Material", "sprites/light_ignorez")
end

function ENT:DrawGlow(size, enlarge, count, col, AlphaReduce, matLight)
	if not self.PixVis then return end

	size = size or S_Size
	enlarge = enlarge or S_Enlarge
	count = count or S_Count
	col = col or S_Col
	AlphaReduce = AlphaReduce or S_Alpha
	matLight = matLight or S_LightMat

	local L_Pos = self:GetPos()
	local L_Nrm = self:GetAngles():Forward()
	local View_Nrm = L_Pos - EyePos()
	local Distance = View_Nrm:Length()
	View_Nrm:Normalize()
	local ViewDot = View_Nrm:Dot(L_Nrm * -1)

	if ViewDot >= 0 then
		render.SetMaterial(matLight)
		local Visibile = util.PixelVisible(L_Pos, 4, self.PixVis) or 0
		if Visibile < 0.1 then return end
		local Vis = Visibile * ViewDot

		local Size = math.Clamp(Distance * Vis * 2, 1, size)
		Distance = math.Clamp(Distance, 32, 800)

		col.a = math.Clamp((1000 - Distance) * Vis, 0, col.a)

		for i = 0, count do
			render.DrawSprite(L_Pos, Size, Size, col, Vis)

			size = size + enlarge
			col.a = math.Clamp(col.a - AlphaReduce, 0, 255)
		end
	end
end

function ENT:DrawTranslucent()
	BaseClass.DrawTranslucent(self)
	if (not self:IsOn()) then return end

	local Size = self:Get_Size()
	local Enlarge = self:Get_Enlarge()
	local Count = self:Get_Count()
	local Col = self:GetColor()
	local AlphaReduce = self:Get_Alpha_Reduce()
	local LightMat = self:Get_Material()

	self:Debug(Size, Col)
	self:DrawGlow(Size, Enlarge, Count, Col, AlphaReduce, LightMat)
end

