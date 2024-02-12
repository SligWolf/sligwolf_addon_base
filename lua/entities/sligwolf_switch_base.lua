AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

DEFINE_BASECLASS("sligwolf_phys")

ENT.Spawnable				= false
ENT.AdminOnly				= false
ENT.RenderGroup 			= RENDERGROUP_BOTH
ENT.AutomaticFrameAdvance 	= true
ENT.DoNotDuplicate 			= true

ENT.WireDebugName			= "sligwolf_switch"

if not SligWolf_Addons then return end
if not SligWolf_Addons.IsLoaded then return end
if not SligWolf_Addons.IsLoaded() then return end

local DTR = {
	weld = "",
	remover = "",
}

local function CheckForWireStuff()
	if not WireAddon then return false end

	return true
end

local function AddWireInOutPuts(ent)
	if not IsValid(ent) then return end
	if not CheckForWireStuff() then return end

	ent.Outputs = WireLib.CreateSpecialOutputs(ent, {"Current State"})
	ent.Inputs = WireLib.CreateSpecialInputs(ent, {"Next State"})
end

local function ChangeWireOutputs(ent)
	if not IsValid(ent) then return end
	if not CheckForWireStuff() then return end

	WireLib.TriggerOutput(ent, "Current State", ent.State)
end

function ENT:Initialize()
	BaseClass.Initialize(self)

	self:TurnOn(true)

	self:SetAnim()

	if SERVER then
		self:SetUseType(SIMPLE_USE)

		AddWireInOutPuts(self)
	end

	self.State = 1
	self.StateStates = {1}
	self.Statedata = {}
	self.Statedata[1] = {}

	if SERVER then
		ChangeWireOutputs(self)
	end
end

function ENT:InitializePhysics()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
end

function ENT:TriggerInput(name, value)
	if name == "Next State" and value == 1 then
		self:Switch()
	end
end

function ENT:Use(activator, caller, useType, value)
	if CLIENT then return end
	self:Switch()
end

function ENT:Switch()
	if CLIENT then return end
	if not self.StateStates then return end

	local statecount = #self.StateStates
	if statecount <= 0 then return end

	self.stateindex = self.stateindex or 0
	self.stateindex = ((self.stateindex + 1) % statecount)

	self.State = self.StateStates[self.stateindex + 1] or 1

	ChangeWireOutputs(self)
end

function ENT:SpawnCollision(model, pos, ang)
	if CLIENT then return end

	if IsValid(self.CollisionProp) then
		self.CollisionProp:Remove()
		self.CollisionProp = nil
	end

	if IsValid(self.CollisionPropConst) then
		self.CollisionPropConst:Remove()
		self.CollisionPropConst = nil
	end

	self.CollisionProp = self:MakeEntEnsured("sligwolf_phys", "CollisionProp")
	if not IsValid(self.CollisionProp) then
		return
	end

	local Prop = self.CollisionProp

	Prop.SLIGWOLF_DenyToolReload = DTR
	Prop.DoNotDuplicate = true

	Prop:SetModel(model or "")
	Prop:SetPos(self:LocalToWorld(pos or Vector()))
	Prop:SetAngles(self:LocalToWorldAngles(ang or Angle()))

	Prop:Spawn()
	Prop:Activate()

	local WD = constraint.Weld(Prop, self, 0, 0, 0, 0, true)
	if not IsValid(WD) then
		self:RemoveFaultyEntites(
			{self, Prop},
			"Couldn't create weld constraint 'WD' between %s <===> %s. Removing entities.",
			self,
			Prop
		)

		return
	end

	WD.DoNotDuplicate = true
	self.CollisionPropConst = WD

	self:UpdateBodySystemMotion()
	return Prop
end

function ENT:Think()
	if not self.Statedata then return end

	local state = self.State or 1
	local statedata = self.Statedata[state] or self.Statedata[1]
	if not statedata then return end

	if state == self.oldState then return end
	self.oldState = state

	local model = statedata.model
	local sound = statedata.sound or "phx/hmetal1.wav"
	local soundPitch = statedata.soundPitch or 100
	local soundLevel = statedata.soundLevel or 80
	local pos = statedata.pos
	local ang = statedata.ang
	local sequence = statedata.sequence or "idle"

	local Prop = self:SpawnCollision(model, pos, ang)
	if not IsValid(Prop) then
		self.oldState = nil
		return
	end

	self:EmitSound(sound, soundLevel, soundPitch)
	local seq = self:LookupSequence(sequence) or 0

	self:ResetSequence(seq)
end

function ENT:OnRemove()
	if IsValid(self.CollisionProp) then
		self.CollisionProp:Remove()
		self.CollisionProp = nil
	end

	if IsValid(self.CollisionPropConst) then
		self.CollisionPropConst:Remove()
		self.CollisionPropConst = nil
	end

	BaseClass.OnRemove(self)
end

