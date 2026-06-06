local SligWolf_Addons = SligWolf_Addons

DEFINE_BASECLASS("base_point")

ENT.Spawnable = false
ENT.AdminOnly = true

ENT.DisableDuplicator = true
ENT.DoNotDuplicate = true

-- Make sure there is no way to mess around with tools, especially dublicator tools.
ENT.m_tblToolsAllowed = {}

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

	key = string.lower(key)

	if key == "sligwolf_spawnname" or key == "sligwolf_railgauge" then
		self._spawnData = nil
		self._spawnName = nil
	end
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
	local proxyEntities = LIBSourceIO.GetProxyEntitiesRegister()

	local spawnid = LIBSourceIO.GetMapCreationHash(self)
	if proxyEntities:Has(spawnid) then
		-- Vehicle already exists so don't spawn a 2nd one, e.g. when it was duped.
		return
	end

	local spawndata = self:GetSpawnData()
	if not spawndata then
		return
	end

	local spawnname = self:GetSpawnName()
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

	LIBSourceIO.SetProxySpawnID(vehicle, spawnid)
	proxyEntities:Add(vehicle)

	vehicle:Spawn()
	vehicle:Activate()
end

function ENT:GetSpawnData()
	if self._spawnData and self._spawnName then
		return self._spawnData
	end

	self._spawnData = nil
	self._spawnName = nil

	local spawnname = self:GetSpawnNameInternal()
	if spawnname == "" then
		return nil
	end

	if self.sligwolf_trainProxyEntity then
		spawnname = self:GetFullSpawnnameFromGauge(spawnname)

		if not spawnname then
			return nil
		end
	end

	local spawnlist = LIBUtil.GetList("Vehicles")
	local spawndata = spawnlist[spawnname]

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

	self._spawnData = spawndata
	self._spawnName = spawnname

	return spawndata
end

function ENT:GetSpawnNameInternal()
	return LIBSourceIO.GetKeyValue(self, "sligwolf_spawnname") or ""
end

function ENT:GetSpawnName()
	if not self._spawnName then
	 	return self:GetSpawnNameInternal()
	end

	return self._spawnName
end