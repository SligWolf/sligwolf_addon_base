AddCSLuaFile()
DEFINE_BASECLASS("gmod_sw_base")

ENT.Spawnable			= false
ENT.RenderGroup 		= RENDERGROUP_OPAQUE
ENT.DoNotDuplicate 		= true

function ENT:Initialize()	
	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_NONE)
		self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	end
	
	self:SetAnim(0)
end