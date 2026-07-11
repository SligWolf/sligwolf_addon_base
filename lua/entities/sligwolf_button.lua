AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

DEFINE_BASECLASS("sligwolf_phys")

ENT.Spawnable 				= false
ENT.AdminOnly 				= false
ENT.DoNotDuplicate 			= true

ENT.sligwolf_buttonEntity     = true
ENT.sligwolf_buttonBaseEntity = true

if not SligWolf_Addons then return end
if not SligWolf_Addons.IsLoaded then return end
if not SligWolf_Addons.IsLoaded() then return end

local LIBEntities = SligWolf_Addons.Entities

function ENT:Initialize()
	BaseClass.Initialize(self)

	self._triggeredNames = {}
	self._triggeredEntities = nil
end

function ENT:SetTriggeredNames(names)
	self._triggeredNames = names or {}
	self._triggeredEntities = nil
end

function ENT:GetTriggeredNames()
	return self._triggeredNames
end

function ENT:GetTriggeredEntities()
	if self._triggeredEntities then
		return self._triggeredEntities
	end

	self._triggeredEntities = nil
	local names = self:GetTriggeredNames()

	local superparent = LIBEntities.GetSuperParent(self)
	if not IsValid(superparent) then
		return nil
	end

	local entities = {}
	local found = false

	for _, name in ipairs(names) do
		local triggeredEnt = LIBEntities.GetChildFromPath(superparent, name)

		if not IsValid(triggeredEnt) then
			continue
		end

		entities[triggeredEnt] = true
		found = true
	end

	if not found then
		return nil
	end

	entities = table.GetKeys(entities)

	self._triggeredEntities = entities
	return entities
end

function ENT:TriggerEntities(params)
	local entities = self:GetTriggeredEntities()
	if not entities then
		return
	end

	for _, ent in ipairs(entities) do
		if ent.OnSWTrigger then
			ent:OnSWTrigger(self, params)
		end
	end
end

function ENT:SetCustomOnPressFunction(func)
	self._customOnPressFunction = func
end

function ENT:GetCustomOnPressFunction()
	return self._customOnPressFunction
end

function ENT:OnPress(ply)
	self:TriggerEntities()

	local func = self:GetCustomOnPressFunction()
	if func then
		func(self, ply)
	end
end

