AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

DEFINE_BASECLASS("sligwolf_phys")

ENT.Spawnable 				= false
ENT.AdminOnly 				= false
ENT.RenderGroup 			= RENDERGROUP_BOTH
ENT.DoNotDuplicate 			= false

ENT.sligwolf_sliderEntity    = true

if not SligWolf_Addons then return end
if not SligWolf_Addons.IsLoaded then return end
if not SligWolf_Addons.IsLoaded() then return end

local LIBPhysics = SligWolf_Addons.Physics
local LIBConvar = SligWolf_Addons.Convar

function ENT:Initialize()
	BaseClass.Initialize(self)

	if CLIENT then
		self.shouldDrawModel = false
	end
end

function ENT:InitializePhysics()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)

	local phys = self:GetPhysicsObject()
	if LIBPhysics.IsValidPhysObject(phys) then
		phys:SetMaterial("gmod_ice")
	end
end

if CLIENT then
	function ENT:RenderSlider(flags)
		local renderMode = LIBConvar.GetSliderRenderMode()

		if renderMode == LIBConvar.ENUM_SLIDER_RENDER_MODE_DISABLED then
			return
		end

		if renderMode == LIBConvar.ENUM_SLIDER_RENDER_MODE_ALWAYS then
			self:DrawModel(flags)
			return
		end

		if not self:IsPhysgunCarried() then
			return
		end

		self:DrawModel(flags)
	end

	function ENT:Draw(flags)
		self:RenderSlider(flags)
	end

	function ENT:DrawTranslucent(flags)
		self:RenderSlider(flags)
	end
end
