AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

DEFINE_BASECLASS("sligwolf_phys")

ENT.Spawnable 				= false
ENT.AdminOnly 				= false
ENT.DoNotDuplicate 			= false

if not SligWolf_Addons then return end
if not SligWolf_Addons.IsLoaded then return end
if not SligWolf_Addons.IsLoaded() then return end

function ENT:Initialize()
	BaseClass.Initialize(self)

	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetCollisionGroup(COLLISION_GROUP_NONE)

		self:SetNoDraw(true)

		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:SetMaterial("gmod_ice")
		end
	end
end

function ENT:OnPhysgunPickup()
	self:SetNoDraw(false)
end

function ENT:OnPhysgunDrop()
	self:SetNoDraw(true)
end

