AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

DEFINE_BASECLASS("sligwolf_base")

ENT.Spawnable			= false
ENT.RenderGroup 		= RENDERGROUP_BOTH
ENT.DoNotDuplicate 		= true

if not SligWolf_Addons then return end
if not SligWolf_Addons.IsLoaded then return end
if not SligWolf_Addons.IsLoaded() then return end

ENT.GlowPoints = {
	{
		pos = Vector(),
		ang = Angle(),
	},
}

local S_Size 			= 1
local S_Enlarge 		= 1
local S_Count 			= 1
local S_Col				= color_white
local S_Alpha 			= 1
local S_LightMat 		= Material("sprites/light_ignorez")

local render 			= render
local util 				= util
local math 				= math
local EyePos 			= EyePos

function ENT:Initialize()
	BaseClass.Initialize(self)

	self:ClearCache()
	self:TurnOn(false)

	if CLIENT then
		self.PixVis = {}
		self:UpdateRenderBounds()
	end
end

function ENT:GetMinMax()
	local glowPoints = self.GlowPoints
	if not glowPoints then
		return
	end

	local mins = Vector()
	local maxs = Vector()

	for i, point in ipairs(glowPoints) do
		if not point then
			continue
		end

		local pos = point.pos
		if not pos then
			continue
		end

		mins.x = math.min(mins.x, pos.x)
		mins.y = math.min(mins.y, pos.y)
		mins.z = math.min(mins.z, pos.z)

		maxs.x = math.max(maxs.x, pos.x)
		maxs.y = math.max(maxs.y, pos.y)
		maxs.z = math.max(maxs.z, pos.z)
	end

	return mins, maxs
end

function ENT:UpdateRenderBounds(size)
	if SERVER then
		return
	end

	local min, max = self:GetMinMax()
	local size = self:GetGlowSize() / 2

	self:SetRenderBounds(min, max, Vector(size, size, size))
end

function ENT:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:AddNetworkRVar("String", "Material")
	self:AddNetworkRVar("Int", "Size")
	self:AddNetworkRVar("Int", "Enlarge")
	self:AddNetworkRVar("Int", "Count")
	self:AddNetworkRVar("Int", "Alpha_Reduce")

	self:GetNetworkRVarNotify("Size", self.UpdateRenderBounds)
end

function ENT:SetGlowSize(num)
	if CLIENT then return end

	self:SetNetworkRVar("Size", num)
end

function ENT:GetGlowSize()
	return self:GetNetworkRVarNumber("Size", 1)
end

function ENT:SetGlowEnlarge(num)
	if CLIENT then return end

	self:SetNetworkRVar("Enlarge", num)
end

function ENT:GetGlowEnlarge()
	return self:GetNetworkRVarNumber("Enlarge", 1)
end

function ENT:SetGlowCount(num)
	if CLIENT then return end

	self:SetNetworkRVar("Count", num)
end

function ENT:GetGlowCount()
	return self:GetNetworkRVarNumber("Count", 1)
end

function ENT:SetGlowAlphaReduce(num)
	if CLIENT then return end

	self:SetNetworkRVar("Alpha_Reduce", num)
end

function ENT:GetGlowAlphaReduce()
	return self:GetNetworkRVarNumber("Alpha_Reduce", 1)
end

function ENT:SetGlowMaterial(mat)
	if CLIENT then return end

	self:SetNetworkRVarMaterial("Material", mat)
end

function ENT:GetGlowMaterial()
	return self:GetNetworkRVarMaterial("Material", "sprites/light_ignorez")
end

function ENT:Debug(Col, Time)
	if not self:IsDeveloper() then
		return
	end

	local pos = self:GetPos()
	local ang = self:GetAngles()

	local min, max = self:GetRenderBounds()

	Col = Col or color_white
	Time = Time or FrameTime()

	debugoverlay.EntityTextAtPosition(pos, 0, tostring(self), Time, color_white)
	debugoverlay.Axis(pos, ang, 4, Time, true)
	debugoverlay.SweptBox(pos, pos, min, max, ang, Time, Col)
end

function ENT:DrawGlow(pixVis, pos, ang, size, enlarge, count, col, AlphaReduce, matLight)
	size = size or S_Size
	enlarge = enlarge or S_Enlarge
	count = count or S_Count
	col = col or S_Col
	AlphaReduce = AlphaReduce or S_Alpha
	matLight = matLight or S_LightMat

	local alpha = col.a

	local L_Nrm = ang:Forward() * -1
	local View_Nrm = pos - EyePos()
	local dist = View_Nrm:Length()
	View_Nrm:Normalize()
	local ViewDot = View_Nrm:Dot(L_Nrm)

	-- @DEBUG: Show a cross for each position a glow sprite could be rendered
	-- if self:IsDeveloper() then
	-- 	debugoverlay.Cross(pos, size / 10, FrameTime(), Col, true)
	-- end

	if ViewDot < 0 then
		return
	end

	local Visibile = util.PixelVisible(pos, 4, pixVis) or 0

	if Visibile < 0.1 then return end
	local Vis = Visibile * ViewDot

	local alphaDist = math.Clamp(dist, 32, 800)
	col.a = math.Clamp((1000 - alphaDist) * Vis, 0, alpha)

	render.SetMaterial(matLight)

	for i = 0, count do
		local spriteSize = math.Clamp(dist * Vis * 2, 1, size)

		render.DrawSprite(pos, spriteSize, spriteSize, col, Vis)

		size = size + enlarge
		col.a = math.Clamp(col.a - AlphaReduce, 0, 255)
	end

	col.a = alpha
end

function ENT:DrawTranslucent(...)
	BaseClass.DrawTranslucent(self, ...)

	if not self:IsOn() then
		return
	end

	local glowPoints = self.GlowPoints
	if not glowPoints then
		return
	end

	local pixVisTable = self.PixVis
	if not pixVisTable then
		return
	end

	local Size = self:GetGlowSize()
	local Enlarge = self:GetGlowEnlarge()
	local Count = self:GetGlowCount()
	local Col = self:GetColor()
	local AlphaReduce = self:GetGlowAlphaReduce()
	local LightMat = self:GetGlowMaterial()

	self:Debug(Col)

	for i, point in ipairs(glowPoints) do
		if not point then
			continue
		end

		local pos = point.pos
		if not pos then
			continue
		end

		local ang = point.ang or angle_zero

		pos = self:LocalToWorld(pos)
		ang = self:LocalToWorldAngles(ang)

		local pixVis = pixVisTable[i]
		if not pixVis then
			pixVis = util.GetPixelVisibleHandle()
			pixVisTable[i] = pixVis
		end

		self:DrawGlow(pixVis, pos, ang, Size, Enlarge, Count, Col, AlphaReduce, LightMat)
	end
end

