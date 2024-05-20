local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SLIGWOLF_BASE_OBJ then
	SligWolf_Addons.ReloadAllAddons()
	return
end

local LIBEntities = SligWolf_Addons.Entities
local LIBSpamprotection = SligWolf_Addons.Spamprotection
local LIBPrint = SligWolf_Addons.Print
local LIBDebug = SligWolf_Addons.Debug

function SLIGWOLF_BASE_OBJ:IsDeveloper()
	return LIBDebug.IsDeveloper()
end

function SLIGWOLF_BASE_OBJ:RunPostInitialize()
	self:TimerNextFrame("PostInitialize", function()
		self:TimerNextFrame("PostInitialize", function()
			-- Make sure we have a delay of at least 2 frames.

			self:PostInitialize()
			self.PostInitialized = true
		end)
	end)
end

function SLIGWOLF_BASE_OBJ:DelayNextSpawnForOwner()
	LIBSpamprotection.DelayNextSpawnForOwner(self)
end

function SLIGWOLF_BASE_OBJ:KeyValue(key, value)
	if not string.StartsWith(key, "sligwolf_") then return end

	local entTable = self:SligWolf_GetTable()

	entTable.keyValues = entTable.keyValues or {}
	entTable.keyValues[key] = value
end

local function extendErrorFormat(format, obj)
	format = tostring(format or "")
	format = string.format("[%s] %s", LIBPrint.FormatSafe(obj), format)

	return format
end

function SLIGWOLF_BASE_OBJ:Error(format, ...)
	format = extendErrorFormat(format, self)
	LIBPrint.Error(format, ...)
end

function SLIGWOLF_BASE_OBJ:ErrorNoHalt(format, ...)
	format = extendErrorFormat(format, self)
	LIBPrint.ErrorNoHalt(format, ...)
end

function SLIGWOLF_BASE_OBJ:ErrorNoHaltWithStack(format, ...)
	format = extendErrorFormat(format, self)
	LIBPrint.ErrorNoHaltWithStack(format, ...)
end

function SLIGWOLF_BASE_OBJ:RemoveFaultyEntites(entities, format, ...)
	format = extendErrorFormat(format, self)
	LIBEntities.RemoveFaultyEntites(entities, format, ...)
end

function SLIGWOLF_BASE_OBJ:MakeEntEnsured(classname, name, parent)
	local ent = self:MakeEnt(classname, name, parent)
	if not IsValid(ent) then
		self:RemoveFaultyEntites(
			{parent},
			"Couldn't create '%s' entity named '%s' for %s. Removing entities.",
			tostring(classname),
			tostring(name or "<unnamed>"),
			parent
		)

		return
	end

	return ent
end

function SLIGWOLF_BASE_OBJ:MakeVehicleEnsured(spawnname, name, parent)
	local ent = self:MakeVehicle(spawnname, name, parent)
	if not IsValid(ent) then
		self:RemoveFaultyEntites(
			{parent},
			"Couldn't create '%s' vehicle entity named '%s' for %s. Removing entities.",
			tostring(classname),
			tostring(name or "<unnamed>"),
			parent
		)

		return
	end

	return ent
end

function SLIGWOLF_BASE_OBJ:AddNetworkRVar(datatype, name, ...)
	datatype = tostring(datatype or "")
	if datatype == "" then return end

	name = tostring(name or "")
	if name == "" then return end

	self.NWVarAdded = self.NWVarAdded or {}
	if self.NWVarAdded[name] then return end
	self.NWVarAdded[name] = true

	self.NWVarCount = self.NWVarCount or {}
	local count = self.NWVarCount[datatype] or 0
	self.NWVarCount[datatype] = count + 1

	return self:NetworkVar(datatype, count, "NWVR_" .. name, ...)
end

function SLIGWOLF_BASE_OBJ:GetNetworkRFunc(name, setter)
	name = tostring(name or "")
	if name == "" then return end
	setter = setter and "Set" or "Get"

	local NW = self[setter .. "NWVR_" .. name]
	if not NW then return end

	return NW
end

function SLIGWOLF_BASE_OBJ:GetNetworkRVarNotify(name, func)
	name = tostring(name or "")
	if name == "" then return end

	local nwname = "NWVR_" .. name

	self:NetworkVarNotify(nwname, function(thisent, _, oldVar, newVar)
		func(thisent, name, oldVar, newVar)
	end)
end

function SLIGWOLF_BASE_OBJ:GetNetworkRVar(name, ...)
	local NW = self:GetNetworkRFunc(name, false)
	if not NW then return end

	return NW(self, ...)
end

function SLIGWOLF_BASE_OBJ:SetNetworkRVar(name, ...)
	name = tostring(name or "")
	if name == "" then return end

	local NW = self:GetNetworkRFunc(name, true)
	if not NW then return end

	return NW(self, ...)
end

function SLIGWOLF_BASE_OBJ:GetNetworkRVarNumber(name, fallback, ...)
	fallback = tonumber(fallback or 0) or 0

	local value = self:GetNetworkRVar(name, fallback, ...)

	value = tonumber(value or 0) or 0
	if value == 0 then
		value = fallback
	end

	return value
end

function SLIGWOLF_BASE_OBJ:GetNetworkRVarString(name, fallback, ...)
	fallback = tostring(fallback or "")

	local value = self:GetNetworkRVar(name, fallback, ...)

	value = tostring(value or "")
	if value == "" then
		value = fallback
	end

	return value
end

function SLIGWOLF_BASE_OBJ:SetNetworkRVarMaterial(name, material, ...)
	material = tostring(material or "")
	return self:SetNetworkRVar(name, material, ...)
end

function SLIGWOLF_BASE_OBJ:GetNetworkRVarMaterial(name, fallback, ...)
	fallback = fallback or ""
	local matname = self:GetNetworkRVarString(name, fallback, ...)

	self.materials = self.materials or {}
	self.materials[name] = self.materials[name] or {}

	if self.materials[name][matname] then
		return self.materials[name][matname]
	end

	local mat = Material(matname)

	if not mat then
		mat = Material(fallback)
	end

	if mat:IsError() then
		mat = Material(fallback)
	end

	if mat:IsError() then
		mat = nil
	end

	self.materials[name][matname] = mat
	return mat
end

function SLIGWOLF_BASE_OBJ:SetNetworkRVarColor(name, color, ...)
	if CLIENT then return end

	color = color or color_white

	local r = bit.lshift(color.r or 0, 24)
	local g = bit.lshift(color.g or 0, 16)
	local b = bit.lshift(color.b or 0, 8)
	local a = color.a or 0

	local col32 = bit.bor(r, g, b, a)
	col32 = bit.tobit(col32)

	self:SetNetworkRVar(name, col32, ...)
end

function SLIGWOLF_BASE_OBJ:GetNetworkRVarColor(name, fallback, ...)
	local col32 = self:GetNetworkRVarNumber(name, fallback, ...)
	col32 = bit.tobit(col32)

	self.colors = self.colors or {}
	self.colors[name] = self.colors[name] or {}

	if self.colors[name][col32] then
		return self.colors[name][col32]
	end

	local r = bit.rshift(bit.band(col32, 0xFF000000), 24)
	local g = bit.rshift(bit.band(col32, 0x00FF0000), 16)
	local b = bit.rshift(bit.band(col32, 0x0000FF00), 8)
	local a = bit.band(col32, 0x000000FF)

	local color = Color(r, g, b, a)
	self.colors[name][col32] = color

	return color
end

function SLIGWOLF_BASE_OBJ:SetAddonID(addonid)
	if CLIENT then return end

	addonid = tostring(addonid or "")
	addonid = string.lower(addonid)

	if addonid == "" then
		self:Error("Empty addonid given!")
		return false
	end

	local hasAddon = SligWolf_Addons.HasLoadedAddon(addonid)

	if not hasAddon then
		self:ErrorNoHaltWithStack("SligWolf addon '%s' is not loaded or installed.", addonid)
		return false
	end

	self:SetNetworkRVar("AddonID", addonid)
	self:ClearAddonCache()

	return true
end

function SLIGWOLF_BASE_OBJ:GetAddonID()
	if self.addonIdCache then
		return self.addonIdCache
	end

	self.addonIdCache = nil

	local addonid = self:GetNetworkRVarString("AddonID", "")

	if addonid == "" then
		if SERVER then
			self:ErrorNoHaltWithStack("AddonID was not set yet!")
		end

		return nil
	end

	addonid = string.lower(addonid)

	local hasAddon = SligWolf_Addons.HasLoadedAddon(addonid)
	if not hasAddon then
		self:ErrorNoHaltWithStack("SligWolf addon '%s' is not loaded or installed.", addonid)
		return nil
	end

	self.addonIdCache = addonid
	return self.addonIdCache
end

function SLIGWOLF_BASE_OBJ:GetAddon()
	if self.addonCache then
		return self.addonCache
	end

	self.addonCache = nil

	if not SligWolf_Addons then
		return nil
	end

	local addonid = self:GetAddonID()
	if not addonid then
		return nil
	end

	local addon = SligWolf_Addons.GetAddon(addonid)
	if not addon then
		return nil
	end

	self.addonCache = addon
	return self.addonCache
end

function SLIGWOLF_BASE_OBJ:ClearAddonCache()
	self.addonIdCache = nil
	self.addonCache = nil
end

function SLIGWOLF_BASE_OBJ:ClearCache()
	self:ClearAddonCache()

	self.materials = {}
	self.colors = {}
end

function SLIGWOLF_BASE_OBJ:TimerInterval(identifier, delay, repetitions, func)
	local addon = self:GetAddon()
	if not addon then
		return
	end

	return addon:EntityTimerInterval(self, identifier, delay, repetitions, func)
end

function SLIGWOLF_BASE_OBJ:TimerOnce(identifier, delay, func)
	local addon = self:GetAddon()
	if not addon then
		return
	end

	return addon:EntityTimerOnce(self, identifier, delay, func)
end

function SLIGWOLF_BASE_OBJ:TimerUntil(identifier, delay, func)
	local addon = self:GetAddon()
	if not addon then
		return
	end

	return addon:EntityTimerUntil(self, identifier, delay, func)
end

function SLIGWOLF_BASE_OBJ:TimerNextFrame(identifier, func)
	local addon = self:GetAddon()
	if not addon then
		return
	end

	return addon:EntityTimerNextFrame(self, identifier, func)
end

function SLIGWOLF_BASE_OBJ:TimerRemove(identifier)
	local addon = self:GetAddon()
	if not addon then
		return
	end

	return addon:EntityTimerRemove(self, identifier)
end

function SLIGWOLF_BASE_OBJ:CallMethodWithErrorNoHalt(method, ...)
	if isstring(method) then
		method = self[method]
	end

	if not isfunction(method) then
		return false, nil
	end

	local addon = self:GetAddon()
	if not addon then
		return false, nil
	end

	return addon:CallFunctionWithErrorNoHalt(method, self, ...)
end

function SLIGWOLF_BASE_OBJ:ToString()
	return LIBEntities.ToString(self)
end

return true

