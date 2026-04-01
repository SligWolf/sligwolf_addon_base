AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

DEFINE_BASECLASS("sligwolf_railway_switch_base")

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

local LIBRail = SligWolf_Addons.Rail

function ENT:SetupSwitchStates()
	return LIBRail.GetSwitchModelStates(self:GetModel())
end
