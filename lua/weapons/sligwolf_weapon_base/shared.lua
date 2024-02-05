AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

DEFINE_BASECLASS("weapon_base")

SWEP.Spawnable				= false
SWEP.AdminOnly				= false

SWEP.sligwolf_entity		= true
SWEP.sligwolf_baseWeapon	= true

if not SligWolf_Addons then return end
if not SligWolf_Addons.IsLoaded then return end
if not SligWolf_Addons.IsLoaded() then return end

local LIBBase = SligWolf_Addons.Base
local LIBBones = SligWolf_Addons.Bones

if not LIBBase.ExtendBaseObjectTable(SWEP) then
	return
end

function SWEP:Initialize()
	BaseClass.Initialize(self)

	self:RunPostInitialize()
end

function SWEP:PostInitialize()
	-- override me
end

function SWEP:SetupDataTables()
	self:AddNetworkRVar("String", "AddonID")

	self:GetNetworkRVarNotify("AddonID", self.ClearAddonCache)
end

function SWEP:ActToTime(act)
	local owner = self:GetOwner()
	if not IsValid(owner) then return 0 end

	local vm = owner:GetViewModel(0)
	if not IsValid(vm) then return 0 end

	local seq = vm:SelectWeightedSequence(act)
	local time = vm:SequenceDuration(seq)

	return time
end

function SWEP:Pose(name, pose)
	local Owner = self:GetOwner()
	if not IsValid(Owner) then return end

	LIBBones.ChangePoseParameter(self, name, pose)
	self:FrameAdvance()

	local VM = Owner:GetViewModel(0)
	if not IsValid(VM) then return end

	LIBBones.ChangePoseParameter(VM, name, pose)
end

function SWEP:MakeEnt(classname, name, parent)
	if CLIENT then return end

	local addon = self:GetAddon()
	if not addon then
		return
	end

	local plyOwner = self:GetOwner()

	return addon:MakeEnt(classname, plyOwner, parent, name)
end

