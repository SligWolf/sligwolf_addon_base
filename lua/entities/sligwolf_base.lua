AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

DEFINE_BASECLASS("base_anim")

ENT.Spawnable				= false
ENT.AdminOnly				= false
ENT.RenderGroup 			= RENDERGROUP_BOTH
ENT.AutomaticFrameAdvance 	= true
ENT.DoNotDuplicate 			= true

ENT.sligwolf_entity			= true
ENT.sligwolf_baseEntity		= true

if not SligWolf_Addons then return end
if not SligWolf_Addons.IsLoaded then return end
if not SligWolf_Addons.IsLoaded() then return end

local LIBBase = SligWolf_Addons.Base

if not LIBBase.ExtendBaseObjectTable(ENT) then
	return
end

local CONSTANTS = SligWolf_Addons.Constants

local LIBEntities = SligWolf_Addons.Entities
local LIBBones = SligWolf_Addons.Bones
local LIBUtil = SligWolf_Addons.Util

ENT.FailbackModel = CONSTANTS.mdlCube1

function ENT:Initialize()
	self:InitializeModel()

	if SERVER then
		self:InitializePhysics()
		self:SetUseType(SIMPLE_USE)
	end

	self:RunPostInitialize()

	if CLIENT then
		self:TimerNextFrame("UpdateChildren", function()
			self:UpdateChildren(nil, nil, LIBEntities.GetParent(self))
		end)
	end
end

function ENT:InitializePhysics()
	self:PhysicsInit(SOLID_NONE)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
end

function ENT:PostInitialize()
	self:HandleSpawnFinishedEvent()
end

function ENT:InitializeModel()
	local model = self:GetModel()

	if not LIBUtil.IsValidModel(model) then
		self:SetModel(self.FailbackModel or CONSTANTS.mdlCube1)
	end
end

function ENT:HandleSpawnFinishedEvent()
	if self:IsMarkedForDeletion() then
		return
	end

	local addon = self:GetAddon()
	if not addon then
		return
	end

	local superparent = LIBEntities.GetSuperParent(self)
	if not IsValid(superparent) then
		return
	end

	if superparent:IsMarkedForDeletion() then
		return
	end

	if self == superparent then
		return
	end

	addon:HandleSpawnFinishedEvent(superparent)
end

function ENT:UpdateTransmitState()
	return TRANSMIT_PVS
end

function ENT:SetupDataTables()
	self:AddNetworkRVar("String", "AddonID")
	self:AddNetworkRVar("Bool", "Enabled")
	self:AddNetworkRVar("Entity", "OwningPlayer")
	self:AddNetworkRVar("Entity", "ParentEntity")

	self:GetNetworkRVarNotify("AddonID", self.ClearAddonCache)
	self:GetNetworkRVarNotify("ParentEntity", self.UpdateChildren)
end

function ENT:UpdateChildren(_, oldparent, newparent)
	local name = LIBEntities.GetName(self)

	if IsValid(oldparent) and oldparent ~= self then
		LIBEntities.UnregisterChild(oldParent, name)
		LIBEntities.ClearChildrenCache(oldparent)
	end

	if IsValid(newparent) and newparent ~= self then
		LIBEntities.RegisterChild(newparent, name, self)
		LIBEntities.ClearChildrenCache(newparent)
	end

	LIBEntities.ClearChildrenCache(self)
end

function ENT:SetColorBaseEntity(colorBaseEntity)
	if CLIENT then return end
	self.ColorBaseEntity = colorBaseEntity
end

function ENT:GetColorBaseEntity()
	if CLIENT then return end
	return self.ColorBaseEntity
end

function ENT:AttachToEnt(parent, ...)
	if not IsValid(parent) then return end

	self:SetParent(parent, ...)
	parent:DeleteOnRemove(self)

	self.parent = parent
end

function ENT:TurnOn(set)
	if CLIENT then return end

	self:SetNetworkRVar("Enabled", set)
end

function ENT:IsOn()
	return self:GetNetworkRVar("Enabled") or false
end

function ENT:Toggle()
	self:TurnOn(not self:IsOn())
end

function ENT:OnRemove()
	self:TurnOn(false)
end

function ENT:Debug(Size, Col, Time)
	if not self:IsDeveloper() then
		return
	end

	local pos = self:GetPos()
	local ang = self:GetAngles()

	Size = Size or 10
	Col = Col or color_white
	Time = Time or FrameTime()

	debugoverlay.EntityTextAtPosition(pos, 0, tostring(self), Time, color_white)
	debugoverlay.Axis(pos, ang, Size, Time, true)
	debugoverlay.Cross(pos, Size / 10, Time, Col, true)
end

function ENT:SetAnim(anim, frame, rate)
	if not self.Animated then
		self.Animated = true

		local oldThink = self.Think
		local newThink = nil

		if oldThink then
			newThink = function(this)
				oldThink(this)
				this:NextThink(CurTime())
				return true
			end
		else
			newThink = function(this)
				this:NextThink(CurTime())
				return true
			end
		end

		self.Think = newThink
	end

	LIBBones.SetAnim(self, anim, frame, rate)
end

function ENT:Think()
	BaseClass.Think(self)

	local nextSlowThink = self.NextSlowThink or 0
	local now = CurTime()

	if nextSlowThink < now then
		self:SlowThink()
		self.NextSlowThink = now + 0.5
	end
end

function ENT:UpdateColorFromBaseEntity()
	local colorBaseEnt = self:GetColorBaseEntity()
	if not IsValid(colorBaseEnt) then return end

	local baseEntColor = colorBaseEnt:GetColor()
	local baseEntRenderMode = colorBaseEnt:GetRenderMode()
	local baseEntRenderFX = colorBaseEnt:GetRenderFX()

	if baseEntColor.a < 255 and baseEntRenderMode == RENDERMODE_NORMAL then
		baseEntRenderMode = RENDERMODE_TRANSCOLOR
	end

	self:SetColor(baseEntColor)
	self:SetRenderMode(baseEntRenderMode)
	self:SetRenderFX(baseEntRenderFX)
end

function ENT:SlowThink()
	if CLIENT then return end

	self:UpdateColorFromBaseEntity()
end

function ENT:MakeEnt(classname, name, parent)
	if CLIENT then return end

	local addon = self:GetAddon()
	if not addon then
		return
	end

	if not parent then
		parent = self
	end

	local plyOwner = self:GetOwningPlayer()

	return addon:MakeEnt(classname, plyOwner, parent, name)
end

function ENT:GetParentEntity()
	local parentEntity = self:GetNetworkRVar("ParentEntity")

	if not IsValid(parentEntity) then
		return nil
	end

	if parentEntity == self then
		parentEntity = nil
	end

	return parentEntity
end

function ENT:SetParentEntity(parentEntity)
	if CLIENT then return end

	if not IsValid(parentEntity) then
		parentEntity = NULL
	end

	if parentEntity == self then
		parentEntity = NULL
	end

	self:SetNetworkRVar("ParentEntity", parentEntity)
end

function ENT:SetOwningPlayer(plyOwner)
	if CLIENT then
		return
	end

	if not IsValid(plyOwner) then
		plyOwner = NULL
	end

	self:SetNetworkRVar("OwningPlayer", plyOwner)

	if not self.CPPISetOwner then
		return
	end

	self:CPPISetOwner(plyOwner)
end

function ENT:GetOwningPlayer()
	local plyOwner = nil

	if self.CPPIGetOwner then
		plyOwner = self:CPPIGetOwner()
	end

	if not IsValid(plyOwner) then
		plyOwner = self:GetNetworkRVar("OwningPlayer")
	end

	if not IsValid(plyOwner) then
		return nil
	end

	return plyOwner
end

function ENT:EnableMotion(bool)
	LIBEntities.EnableMotion(self, bool)
end

