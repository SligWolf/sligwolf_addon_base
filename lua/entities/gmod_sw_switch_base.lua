AddCSLuaFile()
DEFINE_BASECLASS("gmod_sw_base")

ENT.Spawnable				= false
ENT.AdminOnly				= false
ENT.RenderGroup 			= RENDERGROUP_BOTH
ENT.AutomaticFrameAdvance 	= true
ENT.DoNotDuplicate 			= true
ENT.WireDebugName			= "sw_switch"

local DTR = {
	weld = "",
	remover = "",
}

local function CheckForWireStuff()
	if !WireAddon then return false end
	
	return true
end

local function AddWireInOutPuts(ent)
	if !IsValid(ent) then return end
	if !CheckForWireStuff() then return end
	
	ent.Outputs = WireLib.CreateSpecialOutputs(ent, {"GetState"})
	ent.Inputs = WireLib.CreateSpecialInputs(ent, {"SetState"})
end

local function ChangeWireOutputs(ent)
	if !IsValid(ent) then return end
	if !CheckForWireStuff() then return end
	
	WireLib.TriggerOutput(ent, "GetState", ent.State)
end

function ENT:Initialize()	
	self:TurnOn(true)

	self:SetAnim()

	if SERVER then
		self:SetUseType(SIMPLE_USE)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetCollisionGroup(COLLISION_GROUP_NONE)
		
		AddWireInOutPuts(self)
	end
	
	self.State = "default"
	self.StateStates = {"default"}
	self.Statedata = {}
	self.Statedata["default"] = {}
	
	timer.Simple(0.5, function()
		if !IsValid(self) then return end
		if !IsValid(self.CollisionProp) then return end
		
		ChangeWireOutputs(self)
		
		local phys = self.CollisionProp:GetPhysicsObject()
		if !IsValid(phys) then return end
		phys:EnableMotion(true)
	end)
end

function ENT:TriggerInput(name, value)
	if name == "SetState" and value == 1 then
		self:Switch()
	
		ChangeWireOutputs(self)
	end
end

function ENT:Use(activator, caller, useType, value)
	if CLIENT then return end
	self:Switch()
	
	ChangeWireOutputs(self)
end

function ENT:Switch()
	if CLIENT then return end
	if !self.StateStates then return end
	
	local statecount = #self.StateStates
	if statecount <= 0 then return end

	self.stateindex = self.stateindex or 0
	self.stateindex = ((self.stateindex + 1) % statecount)
	
	self.State = self.StateStates[self.stateindex + 1] or "default"
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
	
	local id = self:GetAddonID()
	local addon = SW_Addons.Addondata[id]
	if !addon then return end
	
	local Owner = nil
	
	if self.CPPIGetOwner then
		Owner = self:CPPIGetOwner()
	end
	
	self.CollisionProp = addon:MakeEnt("prop_physics", Owner, self, "CollisionProp")
	if !IsValid(self.CollisionProp) then return end
	
	local Prop = self.CollisionProp
	
	Prop.__SW_DenyToolReload = DTR
	Prop.DoNotDuplicate = true

	Prop:SetModel(model or "")
	Prop:SetPos(self:LocalToWorld(pos or Vector()))
	Prop:SetAngles(self:LocalToWorldAngles(ang or Angle()))
	Prop:Spawn()
	
	local WD = constraint.Weld(Prop, self, 0, 0, 0, 0, true)
	if !IsValid(WD) then
		ErrorNoHalt("Invalid constraint, removed entity : '" .. tostring(self) .. "'")
		self:Remove()
		return
	end
	
	WD.DoNotDuplicate = true
	self.CollisionPropConst = WD
	
	local phys = Prop:GetPhysicsObject()
	if !IsValid(phys) then return Prop end
	phys:EnableMotion(false)
	
	return Prop
end

function ENT:Think()
	if !self.Statedata then return end

	local state = self.State or "default"
	local statedata = self.Statedata[state] or self.Statedata["default"]
	if !statedata then return end

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
	if !IsValid(Prop) then
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