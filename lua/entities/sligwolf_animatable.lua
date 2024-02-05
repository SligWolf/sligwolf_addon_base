AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

DEFINE_BASECLASS("sligwolf_base")

ENT.Spawnable			= false
ENT.RenderGroup 		= RENDERGROUP_OPAQUE
ENT.DoNotDuplicate 		= true

if not SligWolf_Addons then return end
if not SligWolf_Addons.IsLoaded then return end
if not SligWolf_Addons.IsLoaded() then return end

function ENT:Initialize()
	BaseClass.Initialize(self)

	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_NONE)
		self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	end

	self:SetAnim(0)
end

