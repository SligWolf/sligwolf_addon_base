AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

DEFINE_BASECLASS("sligwolf_railway_switch_phys")

-- Tell the user something is wrong ("Broken") with the addons in case they see the usually hidden placeholder node.
-- This item is moved to a different custom build category if everything is fine and the "Broken" one is hidden.
ENT.Category				= "SligWolf's Addons (Broken)"

ENT.PrintName 				= "Railway Switch"
ENT.Spawnable 				= false
ENT.AdminOnly 				= false
ENT.DoNotDuplicate 			= false

ENT.WireDebugName			= "Railway Switch"

if not SligWolf_Addons then return end
if not SligWolf_Addons.IsLoaded then return end
if not SligWolf_Addons.IsLoaded() then return end

local LIBEntities = SligWolf_Addons.Entities
local LIBProtection = SligWolf_Addons.Protection

LIBProtection.ApplyStaticEntityTrait(ENT)

function ENT:OnSpawnedCollision(prop)
	LIBEntities.EnableMotion(self, false)
	LIBEntities.EnableMotion(prop, false)

	prop.sligwolf_blockAllTools  = true
	prop.sligwolf_blockedprop    = true
	prop.sligwolf_noPickup       = true
	prop.sligwolf_denyToolReload = true
	prop.sligwolf_noUnfreeze     = true
	prop.sligwolf_noFreeze       = true

	prop:SetNWBool("sligwolf_blockAllTools", true)
	prop:SetNWBool("sligwolf_blockedprop", true)
	prop:SetNWBool("sligwolf_noPickup", true)
end

