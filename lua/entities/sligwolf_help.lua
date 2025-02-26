AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

DEFINE_BASECLASS("sligwolf_phys")

-- Tell the user something is wrong ("Broken") with the addons in case they see the usually hidden placeholder node.
-- This item is moved to a different custom build category if everything is fine and the "Broken" one is hidden.
ENT.Category				= "SligWolf's Addons (Broken)"

ENT.PrintName 				= "Railway Switch"
ENT.Spawnable 			= false
ENT.AdminOnly 			= false
ENT.DoNotDuplicate 		= false

ENT.sligwolf_helpEntity = true

ENT.defaultSpawnProperties = {
	helpName = "",
}

if not SligWolf_Addons then return end
if not SligWolf_Addons.IsLoaded then return end
if not SligWolf_Addons.IsLoaded() then return end

ENT.Spawnable 				= true

local LIBHelp = SligWolf_Addons.Help

function ENT:Initialize()
	BaseClass.Initialize(self)

	if SERVER then
		self:SetUseType(SIMPLE_USE)
	end

	self:SetHelpName("")
	self:TurnOn(true)
end

function ENT:PostInitialize()
	BaseClass.PostInitialize(self)

	if self:HasSpawnProperties() then
		local helpName = self:GetSpawnProperty("helpName")
		self:SetHelpName(helpName)
	end
end

function ENT:InitializePhysics()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
end

function ENT:SetHelpName(name)
	if CLIENT then return end
	self._helpName = tostring(name or "")
end

function ENT:GetHelpName()
	if CLIENT then return end
	return self._helpName or ""
end

function ENT:Use(activator, caller, useType, value)
	if CLIENT then return end

	if not self:IsOn() then
		return
	end

	local name = self:GetHelpName()
	LIBHelp.CallHelp(name, activator)
end