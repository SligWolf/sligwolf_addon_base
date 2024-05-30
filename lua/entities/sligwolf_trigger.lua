AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

DEFINE_BASECLASS("sligwolf_base")

ENT.Spawnable			= false
ENT.AdminOnly			= false
ENT.RenderGroup 		= RENDERGROUP_BOTH
ENT.DoNotDuplicate 		= true

ENT.sligwolf_trigger	= true

if not SligWolf_Addons then return end
if not SligWolf_Addons.IsLoaded then return end
if not SligWolf_Addons.IsLoaded() then return end

function ENT:Initialize()
	BaseClass.Initialize(self)

	self.Entities = {}
end

function ENT:InitializePhysics()
	local mins, maxs = self:GetTriggerAABB()

	self:EnableCustomCollisions(true)
	self:PhysicsInitBox(mins, maxs)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	self:SetTrigger(true)
end

function ENT:SetTriggerAABB(mins, maxs)
	self.TriggerMins = mins
	self.TriggerMaxs = maxs
end

function ENT:GetTriggerAABB()
	local mins = self.TriggerMins or Vector(-4, -4, -4)
	local maxs = self.TriggerMaxs or Vector(4, 4, 4)

	return mins, maxs
end

if SERVER then
	local g_ColorDefault = Color(255, 255, 255)
	local g_ColorTouched = Color(0, 255, 0)

	function ENT:ThinkInternal()
		BaseClass.ThinkInternal(self)

		if self:IsDeveloper() then
			local touched = self:IsTouched()

			self:Debug(touched and g_ColorTouched or g_ColorDefault, 0.2)
		end
	end
end

function ENT:GetEntities()
	return self.Entities
end

function ENT:CleanupEntities()
	for id, ent in pairs(self.Entities) do
		if IsValid(ent) then
			continue
		end

		self.Entities[id] = nil
	end
end

function ENT:PassesTriggerFilters(ent)
	return true
end

function ENT:IsTouched()
	local isDirty = false
	local found = false

	for _, ent in pairs(self.Entities) do
		if not IsValid(ent) then
			isDirty = true
			continue
		end

		found = true
		break
	end

	if isDirty then
		self:CleanupEntities()
	end

	return found
end

function ENT:IsTouchedBy(ent)
	if not IsValid(ent) then return false end
	return self.Entities[ent:EntIndex()] == ent
end

function ENT:StartTouch(ent)
	if not IsValid(ent) then return end
	if not self:PassesTriggerFilters(ent) then return end

	self.Entities[ent:EntIndex()] = ent
end

function ENT:Touch(ent)
	if not IsValid(ent) then return end
	if not self:PassesTriggerFilters(ent) then return end

	self.Entities[ent:EntIndex()] = ent
end

function ENT:EndTouch(ent)
	if IsValid(ent) then
		self.Entities[ent:EntIndex()] = nil
	end

	self:CleanupEntities()
end

function ENT:Debug(Col, Time)
	if not self:IsDeveloper() then
		return
	end

	local pos = self:GetPos()
	local ang = self:GetAngles()

	local min, max = self:GetTriggerAABB()

	Col = Col or color_white
	Time = Time or FrameTime()

	debugoverlay.EntityTextAtPosition(pos, 0, tostring(self), Time, color_white)
	debugoverlay.Axis(pos, ang, 4, Time, true)
	debugoverlay.SweptBox(pos, pos, min, max, ang, Time, Col)
end
