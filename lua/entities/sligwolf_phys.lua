AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

DEFINE_BASECLASS("sligwolf_base")

ENT.Spawnable 				= false
ENT.AdminOnly 				= false
ENT.DoNotDuplicate 			= false

ENT.sligwolf_physEntity     = true
ENT.sligwolf_physBaseEntity = true

if not SligWolf_Addons then return end
if not SligWolf_Addons.IsLoaded then return end
if not SligWolf_Addons.IsLoaded() then return end

local LIBEntities = SligWolf_Addons.Entities

function ENT:Initialize()
	BaseClass.Initialize(self)

	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetCollisionGroup(COLLISION_GROUP_NONE)
	end
end

function ENT:IsPickedUp()
	return LIBEntities.IsPickedUp(self)
end

local g_getClassActedAsProp = nil
g_getClassActedAsProp = function(this)
	if not this.sligwolf_physBaseEntity and this.SLIGWOLF_oldGetClass and this.SLIGWOLF_oldGetClass ~= g_getClassActedAsProp then
		return this:SLIGWOLF_oldGetClass()
	end

	return "prop_physics"
end

function ENT:CallActingAsPropPhysics(func, ...)
	-- Some function only work if the target entity is a prop_physics despite there is no real reasion to do so. For example: constraint.Keepupright().
	-- So we temporarily override the _R.Entity:GetClass() function in a as safe as possible manner to always return "prop_physics" for our phys entities.
	-- _R.Entity:GetClass() is ensured to be reverted back to original, even if the callback errors.

	if not isfunction(func) then
		return
	end

	local meta = debug.getmetatable(self)
	local swOldGetClass = meta.SLIGWOLF_oldGetClass

	if swOldGetClass or swOldGetClass == g_getClassActedAsProp then
		meta.SLIGWOLF_oldGetClass = nil
		swOldGetClass = nil
	end

	local oldGetClass = swOldGetClass or meta.GetClass

	if not oldGetClass or oldGetClass == g_getClassActedAsProp then
		oldGetClass = swOldGetClass
	end

	if not oldGetClass or oldGetClass == g_getClassActedAsProp then
		self:Error("Entity metatable is currupted, please report this and restart the game!")
		return
	end

	if not meta.SLIGWOLF_oldGetClass then
		meta.SLIGWOLF_oldGetClass = oldGetClass
	end

	meta.GetClass = g_getClassActedAsProp

	local result = {}
	local status, errOrResult = pcall(function(...)
		result = {func(...)}
	end, self, ...)

	meta.GetClass = oldGetClass
	meta.SLIGWOLF_oldGetClass = nil

	if not status then
		errOrResult = tostring(errOrResult or "")
		if errOrResult == "" then
			return
		end

		self:Error(errOrResult)
		return
	end

	return unpack(result)
end

function ENT:OnPhysgunPickup()
	-- override me
end

function ENT:OnPhysgunDrop()
	-- override me
end

