AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

DEFINE_BASECLASS("sligwolf_phys")

ENT.Spawnable				= false
ENT.AdminOnly				= false
ENT.RenderGroup 			= RENDERGROUP_BOTH
ENT.DoNotDuplicate 			= true

ENT.sligwolf_allowAnimation	= true

if not SligWolf_Addons then return end
if not SligWolf_Addons.IsLoaded then return end
if not SligWolf_Addons.IsLoaded() then return end

local LIBWire = SligWolf_Addons.Wire

LIBWire.ApplyWiremodTrait(ENT)

local dtr = {
	weld = "",
	remover = "",
}

function ENT:Initialize()
	BaseClass.Initialize(self)

	self:TurnOn(true)
	self:SetAnim()

	if SERVER then
		self:SetUseType(SIMPLE_USE)
		self:AddWireInOutPuts()
		self:ResetState()
	end
end

function ENT:PostInitialize()
	BaseClass.PostInitialize(self)

	if SERVER then
		self:SetupSwitchStatesInternal()
	end
end

function ENT:InitializePhysics()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
end

function ENT:SetupSwitchStatesInternal()
	local states = self:SetupSwitchStates()
	if not states then
		return
	end

	local printName = tostring(states.printName or "")

	if printName ~= "" then
		self.PrintName = printName
		self.WireDebugName = printName
	end

	self.States = states
	self._oldStateId = nil

	local setStateId = self._setStateId
	local setStateName = self._setStateName

	self._setStateId = nil
	self._setStateName = nil

	if setStateId then
		self:SetStateByID(setStateId)
	else
		if setStateName then
			self:SetStateByName(setStateName)
		end
	end
end

function ENT:SetupSwitchStates()
	-- override me
end

function ENT:AddWireInOutPuts()
	self:AddWireInput("Switch", "NORMAL")
	self:AddWireInput("Reset", "NORMAL")
	self:AddWireInput("State Id", "NORMAL")
	self:AddWireInput("State Name", "STRING")

	self:AddWireOutput("State Id", "NORMAL")
	self:AddWireOutput("State Name", "STRING")

	self:InitWirePorts()
end

function ENT:ApplyWireOutputs()
	if not LIBWire.HasWiremod() then return end

	local state = self._state
	if not state then return end

	self:TriggerWireOutput("State Id", state.id)
	self:TriggerWireOutput("State Name", state.name)
end

function ENT:OnWireInputTrigger(name, value, wired)
	if name == "Switch" and value == 1 then
		self:SwitchState()
	end

	if name == "Reset" and value == 1 then
		self:ResetState()
	end

	if name == "State Id" and value > 0 then
		self:SetStateByID(value)
	end

	if name == "State Name" and value ~= "" then
		self:SetStateByName(value)
	end
end

function ENT:Use(activator, caller, useType, value)
	if CLIENT then return end
	self:SwitchState()
end

function ENT:ApplyState(state)
	if CLIENT then return end

	self._state = state
	self:ApplyWireOutputs()
end

function ENT:SetStateByID(stateId)
	if CLIENT then return end

	local states = self.States
	if not states then
		self._setStateId = stateId
		return
	end

	stateId = stateId or -1

	if stateId == -1 then
		self:ResetState()
		return
	end

	local state = states.ordered[stateId]
	if not state then
		self:ResetState()
		return
	end

	self:ApplyState(state)
end

function ENT:SetStateByName(stateName)
	if CLIENT then return end

	local states = self.States
	if not states then
		self._setStateName = stateName
		return
	end

	stateName = stateName or "default"

	if stateName == "default" then
		self:ResetState()
		return
	end

	local state = states.indexed[stateName]
	if not state then
		self:ResetState()
		return
	end

	self:ApplyState(state)
end

function ENT:SwitchState()
	if CLIENT then return end

	local states = self.States
	if not states then
		return
	end

	local state = self._state or {}

	local statecount = states.count
	local stateid = math.Clamp(state.id or 0, 1, statecount)

	local nextstateid = stateid + 1

	if nextstateid > statecount then
		nextstateid = 1
	end

	self:SetStateByID(nextstateid)
end

function ENT:ResetState()
	if CLIENT then return end

	local states = self.States
	if not states then
		self._setStateName = "default"
		return
	end

	local state = states.indexed["default"]
	if not state then
		return
	end

	self:ApplyState(state)
end

function ENT:SpawnCollision(model, pos, ang)
	if CLIENT then return end

	if IsValid(self._collisionProp) then
		self._collisionProp:Remove()
	end

	if IsValid(self._collisionPropConst) then
		self._collisionPropConst:Remove()
	end

	self._collisionProp = nil
	self._collisionPropConst = nil

	local Prop = self:MakeEntEnsured("sligwolf_phys", "CollisionProp")
	if not IsValid(Prop) then
		return
	end

	Prop.sligwolf_denyToolReload = dtr
	Prop.DoNotDuplicate = true

	Prop:SetModel(model or "")
	Prop:SetPos(self:LocalToWorld(pos or Vector()))
	Prop:SetAngles(self:LocalToWorldAngles(ang or Angle()))

	Prop:Spawn()
	Prop:Activate()
	Prop:DrawShadow(false)

	local WD = constraint.Weld(Prop, self, 0, 0, 0, 0, true)
	if not IsValid(WD) then
		self:RemoveFaultyEntities(
			{self, Prop},
			"Couldn't create weld constraint 'WD' between %s <===> %s. Removing entities.",
			self,
			Prop
		)

		return
	end

	WD.DoNotDuplicate = true

	self._collisionProp = Prop
	self._collisionPropConst = WD

	self:UpdateBodySystemMotion()
	return Prop
end

function ENT:RunCurrentState()
	if CLIENT then return end

	local state = self._state
	if not state then return end
	if not state.id then return end
	if not state.name then return end

	local model = state.model
	local soundName = state.sound or "phx/hmetal1.wav"
	local soundPitch = state.soundPitch or 100
	local soundLevel = state.soundLevel or 80
	local pos = state.pos
	local ang = state.ang
	local sequence = state.sequence or "idle"

	local Prop = self:SpawnCollision(model, pos, ang)
	if not IsValid(Prop) then
		return
	end

	self:EmitSound(soundName, soundLevel, soundPitch)
	local seq = self:LookupSequence(sequence) or 0

	self:ResetSequence(seq)
end

function ENT:ThinkInternal()
	BaseClass.ThinkInternal(self)

	LIBWire.PollRenderBounds(self)

	if CLIENT then return end

	local state = self._state
	if not state then return end

	local stateid = state.id
	if not stateid then return end
	if not state.name then return end

	if self._oldStateId and stateid == self._oldStateId then
		return
	end

	self._oldStateId = stateid

	self:RunCurrentState()
end

if CLIENT then
	function ENT:DrawTranslucent(flags)
		BaseClass.DrawTranslucent(self, flags)
		LIBWire.Render(self)
	end
end

function ENT:OnRemove()
	if IsValid(self._collisionProp) then
		self._collisionProp:Remove()
	end

	if IsValid(self._collisionPropConst) then
		self._collisionPropConst:Remove()
	end

	self._collisionProp = nil
	self._collisionPropConst = nil

	BaseClass.OnRemove(self)
end

function ENT:AcceptInput(name, activator, caller, data)
	name = string.lower(tostring(name or ""))
	if name == "" then return false end

	data = tostring(data or "")

	if name == "switch" then
		self:SwitchState()
		return true
	end

	if name == "reset" then
		self:ResetState()
		return true
	end

	if name == "setstateId" then
		data = tonumber(data or 0) or 0

		if data > 0 then
			self:SetStateByID(data)
		end

		return true
	end

	if name == "setstatename" then
		if data ~= "" then
			self:SetStateByName(data)
		end

		return true
	end

	return false
end

function ENT:OnRestore()
	LIBWire.Restore(self)
end

function ENT:PreEntityCopy()
	local state = self._state or {}

	duplicator.StoreEntityModifier(self, "Wire", LIBWire.BuildDupeInfo(self))
	duplicator.StoreEntityModifier(self, "State", {
		name = state.name,
	})
end

function ENT:PostEntityPaste(ply, ent, entities)
	if not IsValid(ent) then return end
	if not ent.EntityMods then return end

	local dupeData = table.Copy(ent.EntityMods or {})
	local wire = dupeData.Wire
	local state = dupeData.State

	LIBWire.ApplyDupeInfo(ply, ent, wire, entities)
	self:SetStateByName(state.name)
end

