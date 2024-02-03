AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

DEFINE_BASECLASS("gmod_sligwolf_base")

ENT.Spawnable		= false
ENT.RenderGroup 	= RENDERGROUP_BOTH
ENT.DoNotDuplicate 	= true

if not SligWolf_Addons then return end
if not SligWolf_Addons.IsLoaded then return end
if not SligWolf_Addons.IsLoaded() then return end

local Emitter 		= nil
local EmitTime 		= 0.005
local S_Vel 		= Vector(0, 0, 20)
local S_Ltime 		= 0
local S_Dtime 		= 3
local S_Salpha 		= 50
local S_Ealpha 		= 0
local S_Ssize 		= 10
local S_Esize 		= 20
local S_Slength 	= 0
local S_Elength 	= 0

function ENT:Initialize()
	BaseClass.Initialize(self)

	self:ClearCache()
	self:TurnOn(false)

	if CLIENT then
		Emitter = ParticleEmitter(self:GetPos(), false)
	end
end

function ENT:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:AddNetworkRVar("Int", "StartAlpha")
	self:AddNetworkRVar("Int", "EndAlpha")
	self:AddNetworkRVar("Int", "StartSize")
	self:AddNetworkRVar("Int", "EndSize")
	self:AddNetworkRVar("Int", "StartLength")
	self:AddNetworkRVar("Int", "EndLength")
	self:AddNetworkRVar("Float", "SpawnTime")
	self:AddNetworkRVar("Float", "LifeTime")
	self:AddNetworkRVar("Float", "DieTime")
	self:AddNetworkRVar("Float", "Velocity")
end

function ENT:Set_SpawnTime(num)
	if CLIENT then return end

	self:SetNetworkRVar("SpawnTime", num)
end

function ENT:Get_SpawnTime()
	return self:GetNetworkRVarNumber("SpawnTime", 0.005)
end

function ENT:Set_Velocity(vel)
	if CLIENT then return end

	self:SetNetworkRVar("Velocity", vel)
end

function ENT:Get_Velocity()
	return self:GetNetworkRVarNumber("Velocity", 20)
end

function ENT:Set_LifeTime(num)
	if CLIENT then return end

	self:SetNetworkRVar("LifeTime", num)
end

function ENT:Get_LifeTime()
	return self:GetNetworkRVarNumber("LifeTime", 0)
end

function ENT:Set_DieTime(num)
	if CLIENT then return end

	self:SetNetworkRVar("DieTime", num)
end

function ENT:Get_DieTime()
	return self:GetNetworkRVarNumber("DieTime", 3)
end

function ENT:Set_StartAlpha(num)
	if CLIENT then return end

	self:SetNetworkRVar("StartAlpha", num)
end

function ENT:Get_StartAlpha()
	return self:GetNetworkRVarNumber("StartAlpha", 50)
end

function ENT:Set_EndAlpha(num)
	if CLIENT then return end

	self:SetNetworkRVar("EndAlpha", num)
end

function ENT:Get_EndAlpha()
	return self:GetNetworkRVarNumber("EndAlpha", 0)
end

function ENT:Set_StartSize(num)
	if CLIENT then return end

	self:SetNetworkRVar("StartSize", num)
end

function ENT:Get_StartSize()
	return self:GetNetworkRVarNumber("StartSize", 10)
end

function ENT:Set_EndSize(num)
	if CLIENT then return end

	self:SetNetworkRVar("EndSize", num)
end

function ENT:Get_EndSize()
	return self:GetNetworkRVarNumber("EndSize", 20)
end

function ENT:Set_StartLength(num)
	if CLIENT then return end

	self:SetNetworkRVar("StartLength", num)
end

function ENT:Get_StartLength()
	return self:GetNetworkRVarNumber("StartLength", 0)
end

function ENT:EndLength(num)
	if CLIENT then return end

	self:SetNetworkRVar("EndLength", num)
end

function ENT:Get_EndLength()
	return self:GetNetworkRVarNumber("EndLength", 0)
end

function ENT:Think()

	local Delay = self.Delay or 0
	local Time = self:Get_SpawnTime() or EmitTime
	if (CurTime() - Delay) < Time then return end

	self.Delay = CurTime()
	self:EmitterThink()
	self:NextThink(CurTime())

	return true
end

function ENT:Draw()
	return false
end

local mats = {}

for i = 0, 8 do
	mats[i] = Material("particle/smokesprites_000" .. (i + 1))
end

function ENT:SetUpEmitter(vel, ltime, dtime, salpha, ealpha, ssize, esize, slength, elength)

	local mat = mats[math.ceil(math.Rand(0, 8))]

	local pos 	= self:GetPos()
	local ang 	= self:GetAngles()
	local col 	= self:GetColor()
	vel 	= vel or S_Vel
	ltime 	= ltime or S_Ltime
	dtime 	= dtime or S_Dtime
	salpha 	= salpha or S_Salpha
	ealpha 	= ealpha or S_Ealpha
	ssize	= ssize or S_Ssize
	esize 	= esize or S_Esize
	slength = slength or S_Slength
	elength = elength or S_Elength

	local particle = Emitter:Add(mat, pos)
	if not particle then return end

	particle:SetAngles(ang)
	particle:SetVelocity(ang:Forward() * vel)
	particle:SetColor(col.r, col.g, col.b)
	particle:SetLifeTime(ltime)
	particle:SetDieTime(dtime)
	particle:SetStartAlpha(salpha)
	particle:SetEndAlpha(ealpha)
	particle:SetStartSize(ssize)
	particle:SetEndSize(esize)
	particle:SetStartLength(slength)
	particle:SetEndLength(elength)
end

function ENT:EmitterThink()

	if SERVER then return end
	if not self:IsOn() then return end

	local E_Vel	 	= self:Get_Velocity()
	local E_LTime 	= self:Get_LifeTime()
	local E_DTime 	= self:Get_DieTime()
	local E_SAlpha 	= self:Get_StartAlpha()
	local E_EAlpha 	= self:Get_EndAlpha()
	local E_SSize 	= self:Get_StartSize()
	local E_ESize 	= self:Get_EndSize()
	local E_SLength	= self:Get_StartLength()
	local E_ELength	= self:Get_EndLength()

	self:Debug(E_SSize, E_Col)
	self:SetUpEmitter(E_Vel, E_LTime, E_DTime, E_SAlpha, E_EAlpha, E_SSize, E_ESize, E_SLength, E_ELength)
end

