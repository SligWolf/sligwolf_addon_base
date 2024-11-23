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

local LIBConstraints = SligWolf_Addons.Constraints
local LIBEntities = SligWolf_Addons.Entities
local LIBModel = SligWolf_Addons.Model
local LIBWire = SligWolf_Addons.Wire

LIBWire.ApplyWiremodTrait(ENT)

function ENT:Initialize()
	BaseClass.Initialize(self)
	self:SetApplyDupe(false)

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
	local states = self:SetupSwitchStates() or {}
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

	self:SetApplyDupe(true)
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

function ENT:ApplyHammerOutputs()
	local state = self._state
	if not state then return end

	local activator = self._lastActivator

	if not IsValid(activator) then
		activator = self
	end

	if self._reset then
		self:TriggerOutput("onreset", activator)
	end

	self:TriggerOutput("onswitch", activator)
	self:TriggerOutput("onswitchbyid", activator, state.id)
	self:TriggerOutput("onswitchbyname", activator, state.name)
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

	self._lastActivator = activator
	self._lastCaller = caller

	self:SwitchState()

	self._lastActivator = nil
	self._lastCaller = nil
end

function ENT:KeyValue(key, value)
	BaseClass.Initialize(self, key, value)

	key = string.lower(tostring(key or ""))
	value = tostring(value or "")

	if key == "onswitch" then
		self:StoreOutput(key, value)
	end

	if key == "onreset" then
		self:StoreOutput(key, value)
	end

	if key == "onswitchbyid" then
		self:StoreOutput(key, value)
	end

	if key == "onswitchbyname" then
		self:StoreOutput(key, value)
	end
end

function ENT:ApplyState(state)
	if CLIENT then return end

	self._state = state
	self:ApplyWireOutputs()

	if self._oldStateId then
		self:ApplyHammerOutputs()
	end
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

	self._reset = true
	self:ApplyState(state)
	self._reset = nil
end

function ENT:GetCollisionEntity()
	if not IsValid(self._collisionProp) then
		return
	end

	return self._collisionProp
end

function ENT:SpawnCollisionEntity(mdl, pos, ang)
	if CLIENT then return end

	LIBEntities.RemoveEntityWithNoCallback(self._collisionProp)
	LIBEntities.RemoveEntityWithNoCallback(self._collisionPropConst)

	self._collisionProp = nil
	self._collisionPropConst = nil

	local Prop = self:MakeEntEnsured("sligwolf_phys", "CollisionProp")
	if not IsValid(Prop) then
		return
	end

	Prop.DoNotDuplicate = true

	Prop.sligwolf_blockAllTools = true
	Prop:SetNWBool("sligwolf_blockAllTools", true)

	LIBModel.SetModel(Prop, model)
	Prop:SetPos(self:LocalToWorld(pos or Vector()))
	Prop:SetAngles(self:LocalToWorldAngles(ang or Angle()))

	Prop:Spawn()
	Prop:Activate()
	Prop:DrawShadow(false)

	local WD = LIBConstraints.Weld(Prop, self, {nocollide = true})
	if not IsValid(WD) then
		self:RemoveFaultyEntities(
			{self, Prop},
			"Couldn't create weld constraint 'WD' between %s <===> %s. Removing entities.",
			self,
			Prop
		)

		return
	end

	local respawn = function(thisent, withEffect)
		if withEffect then
			return
		end

		if LIBEntities.IsMarkedForDeletion(self) then
			return
		end

		self._oldStateId = nil
	end

	LIBEntities.RemoveEntitiesOnDelete(self, Prop)
	LIBEntities.RemoveEntitiesOnDelete(WD, Prop)

	LIBEntities.CallOnRemove(Prop, "RespawnCollision", respawn)

	self._collisionProp = Prop
	self._collisionPropConst = WD

	self:UpdateBodySystemMotion()

	self:OnSpawnedCollision(Prop)

	return Prop
end

function ENT:OnSpawnedCollision(prop)
	-- override me
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

	local Prop = self:SpawnCollisionEntity(model, pos, ang)
	if not IsValid(Prop) then
		return
	end

	if self._oldStateId then
		self:EmitSound(soundName, soundLevel, soundPitch)
	end

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

	self:RunCurrentState()

	self._oldStateId = stateid
end

if CLIENT then
	function ENT:DrawTranslucent(flags)
		BaseClass.DrawTranslucent(self, flags)
		LIBWire.Render(self)
	end
end

function ENT:AcceptInputInteral(name, activator, caller, data)
	if name == "switch" then
		self:SwitchState()
		return true
	end

	if name == "reset" then
		self:ResetState()
		return true
	end

	if name == "setstatebyId" then
		data = tonumber(data or 0) or 0

		if data > 0 then
			self:SetStateByID(data)
		end

		return true
	end

	if name == "setstatebyname" then
		if data ~= "" then
			self:SetStateByName(data)
		end

		return true
	end

	return false
end

function ENT:AcceptInput(name, activator, caller, data)
	name = string.lower(tostring(name or ""))
	if name == "" then return false end

	data = tostring(data or "")

	self._lastActivator = activator
	self._lastCaller = caller

	local result = self:AcceptInputInteral(name, activator, caller, data)

	self._lastActivator = nil
	self._lastCaller = nil

	return result
end

function ENT:OnRestore()
	LIBWire.Restore(self)
end

function ENT:PreDupeCopy(dupedata)
	local state = self._state or {}

	dupedata.Wire = LIBWire.BuildDupeInfo(self)
	dupedata.State = {
		name = state.name,
	}
end

function ENT:PostDupePaste(ply, ent, entities, dupedata)
	local wire = dupedata.Wire
	local state = dupedata.State or {}

	LIBWire.ApplyDupeInfo(ply, ent, wire, entities)

	self._oldStateId = nil
	self:SetStateByName(state.name)
end

