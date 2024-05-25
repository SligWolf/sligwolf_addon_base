AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

DEFINE_BASECLASS("sligwolf_base")

ENT.Spawnable			  = false
ENT.RenderGroup 		  = RENDERGROUP_BOTH
ENT.AutomaticFrameAdvance = false
ENT.DoNotDuplicate		  = true

ENT.sligwolf_allowAnimation	= true

if not SligWolf_Addons then return end
if not SligWolf_Addons.IsLoaded then return end
if not SligWolf_Addons.IsLoaded() then return end

function ENT:InitializePhysics()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
end

