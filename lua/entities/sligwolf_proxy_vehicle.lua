local SligWolf_Addons = SligWolf_Addons

DEFINE_BASECLASS("base_point")

ENT.Spawnable = false
ENT.AdminOnly = true

ENT.DisableDuplicator = true
ENT.DoNotDuplicate = true

ENT.sligwolf_entity			= true
ENT.sligwolf_proxyEntity    = true

if not SligWolf_Addons then return end
if not SligWolf_Addons.IsLoaded then return end
if not SligWolf_Addons.IsLoaded() then return end

local LIBSourceIO = SligWolf_Addons.SourceIO
local LIBTimer = SligWolf_Addons.Timer
local LIBPrint = SligWolf_Addons.Print
local LIBUtil = SligWolf_Addons.Util

local g_tickTime = LIBTimer.TickTime(1)

local g_backlistedKeyValues = {
	classname = true,
	model = true,
	vehiclescript = true,
	origin = true,
	angles = true,
	sligwolf_spawnname = true,
}

function ENT:Initialize()
	self._readyForSpawn = CurTime() + g_tickTime
end

function ENT:KeyValue(key, value)
	self._readyForSpawn = CurTime() + g_tickTime
end

function ENT:AcceptInput(name, activator, caller, param)
	name = tostring(name)
	name = string.lower(name)

	local inputsOrderd = self._inputsOrderd or {}
	self._inputsOrderd = inputsOrderd

	table.insert(inputsOrderd, {
		name = name,
		activator = activator,
		caller = caller,
		param = param,
	})

	return false
end

function ENT:Think()
	local now = CurTime()
	self:NextThink(now + g_tickTime)

	local readyForSpawn = self._readyForSpawn
	if not readyForSpawn then
		return true
	end

	if readyForSpawn <= now then
		self._readyForSpawn = nil
		self:SpawnVehicle()
		self:Remove()
	end

	return true
end

function ENT:SpawnVehicle()
	local spawnname = self:GetSpawnName()
	if spawnname == "" then
		return
	end

	local spawndata = self:GetSpawnData()
	if not spawndata then
		return
	end

	local addon = SligWolf_Addons.GetAddon(spawndata.SLIGWOLF_Addonname)

	local vehicle = addon:MakeVehicle(spawnname)
	if not IsValid(vehicle) then
		return
	end

	vehicle:SetPos(self:GetPos())
	vehicle:SetAngles(self:GetAngles())

	local keyValues = LIBSourceIO.GetKeyValues(self)
	local outputs = LIBSourceIO.GetMapOutputs(self)
	local inputsOrderd = self._inputsOrderd or {}

	-- Copy KeyValues to the new entity
	for key, value in pairs(keyValues) do
		if g_backlistedKeyValues[key] then
			continue
		end

		LIBSourceIO.SetKeyValue(vehicle, key, value)
	end

	-- Copy map outputs to the new entity
	LIBSourceIO.SetMapOutputs(vehicle, outputs)

	-- Trigger IO called before spawn on the new entity
	for _, i in ipairs(inputsOrderd) do
		vehicle:Input(i.name, i.activator, i.caller, i.param)
	end

	-- Reattach children to the new entity 
	local children = self:GetChildren()
	for _, child in ipairs(children) do
		if not IsValid(child) then
			continue
		end

		child:SetParent(vehicle)
	end

	-- @TODO: gauges

	vehicle:Spawn()
	vehicle:Activate()

	addon:HandleSpawnFinishedEvent(vehicle)
end

function ENT:GetSpawnData()
	local spawnname = self:GetSpawnName()
	if spawnname == "" then
		LIBPrint.Warn("Missing spawnname. (Entity: %s)", self)
		return nil
	end

	local tab = LIBUtil.GetList("Vehicles")
	spawndata = tab[spawnname]

	if not spawndata or not spawndata.Is_SLIGWOLF then
		LIBPrint.Warn("The spawnname '%s' is not registered. SligWolf addon not installed? (Entity: %s)", spawnname, self)
		return nil
	end

	local addonid = spawndata.SLIGWOLF_Addonname or ""
	if addonid == "" then
		LIBPrint.Warn("Missing addon id. (Entity: %s, Spawnname: %s)", self, spawnname)
		return nil
	end

	local hasAddon = SligWolf_Addons.HasLoadedAddon(addonid)
	if not hasAddon then
		LIBPrint.Warn("SligWolf addon '%s' is not loaded or installed. (Entity: %s, Spawnname: %s)", addonid, self, spawnname)
		return nil
	end

	return spawndata
end

function ENT:GetSpawnName()
	return LIBSourceIO.GetKeyValue(self, "sligwolf_spawnname") or ""
end