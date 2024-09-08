AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

DEFINE_BASECLASS("sligwolf_base")

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

function ENT:SetParticleSpawnTime(num)
	if CLIENT then return end

	self:SetNetworkRVar("SpawnTime", num)
end

function ENT:GetParticleSpawnTime()
	return self:GetNetworkRVarNumber("SpawnTime", 0.005)
end

function ENT:SetParticleVelocity(vel)
	if CLIENT then return end

	self:SetNetworkRVar("Velocity", vel)
end

function ENT:GetParticleVelocity()
	return self:GetNetworkRVarNumber("Velocity", 20)
end

function ENT:SetParticleLifeTime(num)
	if CLIENT then return end

	self:SetNetworkRVar("LifeTime", num)
end

function ENT:GetParticleLifeTime()
	return self:GetNetworkRVarNumber("LifeTime", 0)
end

function ENT:SetParticleDieTime(num)
	if CLIENT then return end

	self:SetNetworkRVar("DieTime", num)
end

function ENT:GetParticleDieTime()
	return self:GetNetworkRVarNumber("DieTime", 3)
end

function ENT:SetParticleStartAlpha(num)
	if CLIENT then return end

	self:SetNetworkRVar("StartAlpha", num)
end

function ENT:GetParticleStartAlpha()
	return self:GetNetworkRVarNumber("StartAlpha", 50)
end

function ENT:SetParticleEndAlpha(num)
	if CLIENT then return end

	self:SetNetworkRVar("EndAlpha", num)
end

function ENT:GetParticleEndAlpha()
	return self:GetNetworkRVarNumber("EndAlpha", 0)
end

function ENT:SetParticleStartSize(num)
	if CLIENT then return end

	self:SetNetworkRVar("StartSize", num)
end

function ENT:GetParticleStartSize()
	return self:GetNetworkRVarNumber("StartSize", 10)
end

function ENT:SetParticleEndSize(num)
	if CLIENT then return end

	self:SetNetworkRVar("EndSize", num)
end

function ENT:GetParticleEndSize()
	return self:GetNetworkRVarNumber("EndSize", 20)
end

function ENT:SetParticleStartLength(num)
	if CLIENT then return end

	self:SetNetworkRVar("StartLength", num)
end

function ENT:GetParticleStartLength()
	return self:GetNetworkRVarNumber("StartLength", 0)
end

function ENT:SetParticleEndLength(num)
	if CLIENT then return end

	self:SetNetworkRVar("EndLength", num)
end

function ENT:GetParticleEndLength()
	return self:GetNetworkRVarNumber("EndLength", 0)
end

function ENT:ThinkInternal()
	BaseClass.ThinkInternal(self)

	local Delay = self.Delay or 0
	local Time = self:GetParticleSpawnTime() or EmitTime
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

	local E_Vel	 	= self:GetParticleVelocity()
	local E_LTime 	= self:GetParticleLifeTime()
	local E_DTime 	= self:GetParticleDieTime()
	local E_SAlpha 	= self:GetParticleStartAlpha()
	local E_EAlpha 	= self:GetParticleEndAlpha()
	local E_SSize 	= self:GetParticleStartSize()
	local E_ESize 	= self:GetParticleEndSize()
	local E_SLength	= self:GetParticleStartLength()
	local E_ELength	= self:GetParticleEndLength()

	self:Debug(E_SSize, E_Col)
	self:SetUpEmitter(E_Vel, E_LTime, E_DTime, E_SAlpha, E_EAlpha, E_SSize, E_ESize, E_SLength, E_ELength)
end

