AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

DEFINE_BASECLASS("weapon_base")

SWEP.Spawnable				= false
SWEP.AdminOnly				= false

SWEP.sligwolf_entity		= true
SWEP.sligwolf_weapon		= true
SWEP.sligwolf_baseWeapon	= true

if not SligWolf_Addons then return end
if not SligWolf_Addons.IsLoaded then return end
if not SligWolf_Addons.IsLoaded() then return end

local LIBSpawnmenu = SligWolf_Addons.Spawnmenu
local LIBBones = SligWolf_Addons.Bones
local LIBBase = SligWolf_Addons.Base

if not LIBBase.ExtendBaseObjectTable(SWEP) then
	return
end

function SWEP:Initialize()
	BaseClass.Initialize(self)

	self:RunPostInitialize()

	self:Reset()
end

function SWEP:PostInitialize()
	-- override me
end

function SWEP:Reset(isPredicted)
	if not isPredicted then
		self:OnReset()
		return
	end

	if CLIENT then
		if IsFirstTimePredicted() then
			self:OnReset()
		end

		return
	end

	self:OnReset()

	if game.SinglePlayer() then
		self:ResetOnClient()
	end
end

function SWEP:ResetOnClient()
	if not SERVER then
		self:Reset()
		return
	end

	local owner = self:GetOwner()

	if IsValid(owner) and owner:IsPlayer() and not owner:IsBot() then
		self:CallOnClient("ResetOnClient")
	end
end

function SWEP:OnReset()
	-- Override me
end

function SWEP:OnDeploy()
	-- Override me
	return true
end

function SWEP:OnHolster()
	-- Override me
	return true
end

function SWEP:OnEquip()
	-- Override me
end

function SWEP:OnUnwield()
	-- Override me
end

function SWEP:SetupDataTables()
	self:AddNetworkRVar("String", "AddonID")

	self:RegisterNetworkRVarNotify("AddonID", self.ClearAddonCache)
end

function SWEP:Deploy(...)
	BaseClass.Deploy(self, ...)

	self:Reset(true)

	local result = self:OnDeploy(...)
	return result
end

function SWEP:Holster(...)
	BaseClass.Holster(self, ...)

	if SERVER or (CLIENT and not IsFirstTimePredicted()) then
		-- Holster has a not pretedicted client call
		self:Reset()
	end

	local result = self:OnHolster(...)
	return result
end

function SWEP:Equip(...)
	BaseClass.Equip(self, ...)

	self:Reset()
	self:ResetOnClient()

	self:OnEquip(...)
end

function SWEP:OnDrop(...)
	BaseClass.OnDrop(self, ...)

	self:Reset()
	self:ResetOnClient()

	self:OnUnwield(...)
end

function SWEP:OnReloaded()
	LIBSpawnmenu.RequestReloadSpawnmenu()
	LIBSpawnmenu.InitSpawnmenuContent()

	-- script reloaded, not to be confused with ammo reload
	self:Reset()
end

function SWEP:OnRemove(...)
	self:Reset()

	BaseClass.OnRemove(self, ...)
end

function SWEP:SlowThink()
	-- override me
end

function SWEP:FastThink()
	-- override me
end

function SWEP:Think()
	BaseClass.Think(self)

	local result = self:FastThink()

	local nextSlowThink = self._nextSlowThink or 0
	local now = CurTime()

	if nextSlowThink < now then
		self:SlowThink()
		self._nextSlowThink = now + 0.5
	end

	if result then
		return true
	end
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

function SWEP:MakeVehicle(spawnname, name, parent)
	if CLIENT then return end

	local addon = self:GetAddon()
	if not addon then
		return
	end

	local plyOwner = self:GetOwner()

	return addon:MakeVehicle(spawnname, plyOwner, parent, name)
end

function SWEP:AddClientCallForPredictionHook(hookName)
	if CLIENT then
		return
	end

	local originalHook = self[hookName]
	if not originalHook then
		return
	end

	self.clientCallForPredictionOriginalHook = self.clientCallForPredictionOriginalHook or {}
	if not self.clientCallForPredictionOriginalHook[hookName] then
		self.clientCallForPredictionOriginalHook[hookName] = originalHook
	end

	self[hookName] = function(this, ...)
		local thisOriginalHook = this.clientCallForPredictionOriginalHook[hookName]
		if not thisOriginalHook then
			return
		end

		local a, b, c, d, e, f, g, h = thisOriginalHook(this, ...)

		if SERVER then
			local owner = self:GetOwner()

			if IsValid(owner) and owner:IsPlayer() and not owner:IsBot() then
				self:CallOnClient(hookName .. "Client")
			end
		end

		return a, b, c, d, e, f, g, h
	end
end
