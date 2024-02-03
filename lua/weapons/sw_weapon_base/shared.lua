AddCSLuaFile()
DEFINE_BASECLASS("weapon_base")

SWEP.Spawnable				= false
SWEP.AdminOnly				= false
SWEP.__IsSW_Entity 			= true

function SWEP:AddNetworkRVar(datatype, name, ...)
	datatype = tostring(datatype or "")
	if datatype == "" then return end

	name = tostring(name or "")
	if name == "" then return end
	
	self.NWVarNames = self.NWVarNames or {}
	self.NWVarNames[name] = datatype
	
	if !self.NWVarSetupDataTableMode then return end

	self.NWVarAdded = self.NWVarAdded or {}
	if self.NWVarAdded[name] then return end
	self.NWVarAdded[name] = true
	
	self.NWVarCount = self.NWVarCount or {}
	local count = self.NWVarCount[datatype] or 0
	self.NWVarCount[datatype] = count + 1

	return self:NetworkVar(datatype, count, "NWVR_" .. name, ...)
end

function SWEP:GetNetworkRFunc(name, setter)
	name = tostring(name or "")
	if name == "" then return end
	setter = setter and "Set" or "Get"

	local NW = self[setter .. "NWVR_" .. name]
	if !NW then return end
	
	return NW
end

function SWEP:GetNetworkRVar(name, ...)
	if !self.NWVarReady then return end

	local NW = self:GetNetworkRFunc(name, false)
	if !NW then return end
	
	return NW(self, ...)
end

function SWEP:SetNetworkRVar(name, ...)
	name = tostring(name or "")
	if name == "" then return end

	self.NWVarAdded = self.NWVarAdded or {}
	self.NWVarValues = self.NWVarValues or {}
	if !self.NWVarAdded[name] then
		self.NWVarValues[name] = {...}
		return
	end

	local NW = self:GetNetworkRFunc(name, true)
	if !NW then return end
	
	return NW(self, ...)
end

function SWEP:GetNetworkRVarNumber(name, fallback, ...)
	fallback = tonumber(fallback or 0) or 0

	local value = self:GetNetworkRVar(name, fallback, ...)

	value = tonumber(value or 0) or 0
	if value == 0 then
		value = fallback
	end
	
	return value
end

function SWEP:GetNetworkRVarString(name, fallback, ...)
	fallback = tostring(fallback or "")

	local value = self:GetNetworkRVar(name, fallback, ...)

	value = tostring(value or "")
	if value == "" then
		value = fallback
	end
	
	return value
end

function SWEP:SetNetworkRVarMaterial(name, material, ...)
	material = tostring(material or "")
	return self:SetNetworkRVar(name, material, ...)
end

function SWEP:GetNetworkRVarMaterial(name, fallback, ...)
	fallback = fallback or ""
	local matname = self:GetNetworkRVarString(name, fallback, ...)
	
	self.materials = self.materials or {}
	self.materials[name] = self.materials[name] or {}
	
	if self.materials[name][matname] then
		return self.materials[name][matname]
	end
	
	local mat = Material(matname)
	
	if !mat then 
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

function SWEP:SetNetworkRVarColor(name, color, ...)
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

function SWEP:GetNetworkRVarColor(name, fallback, ...)
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

function SWEP:SetupDataTables()
	self.NWVarReady = false
	self.NWVarSetupDataTableMode = true

	self:AddNetworkRVar("String", "AddonID")
	self:AddNetworkRVar("Bool", "Enabled")
	
	for k,v in pairs(self.NWVarNames or {}) do
		self:AddNetworkRVar(v, k)
	end

	timer.Simple(0.1, function()
		if !IsValid(self) then return end
		
		for k,v in pairs(self.NWVarValues or {}) do
			self:SetNetworkRVar(k, unpack(v))
			self.NWVarValues[k] = nil
		end
		
		self.NWVarReady = true
	end)
end

function SWEP:SetAddonID(id)
	if CLIENT then return end

	id = tostring(id or "")
	id = string.lower(id)
	self:SetNetworkRVar("AddonID", id)
end

function SWEP:GetAddonID()
	return string.lower(self:GetNetworkRVarString("AddonID", ""))
end

function SWEP:SetAddon(addon)
	self.addon = addon
end

function SWEP:GetAddon()
	if self.addon then
		return self.addon
	end
	
	if !SW_Addons then
		self.addon = nil
		return nil
	end
	
	if !SW_Addons.Addondata then
		self.addon = nil
		return nil
	end
	
	local id = self:GetAddonID()
	local addon = SW_Addons.Addondata[id]
	
	if !addon then
		self.addon = nil
		return nil
	end
	
	self.addon = addon
	return self.addon
end

function SWEP:ClearCache()
	self.materials = {}
	self.colors = {}
end

function SWEP:CallMethodWithErrorNoHalt(method, ...)
	if isstring(method) then
		method = self[method]
	end

	if !isfunction(method) then
		return false, nil
	end
	
	local addon = self:GetAddon()
	if !addon then
		return false, nil
	end
	
	addon:CallFunctionWithErrorNoHalt(method, self, ...)
end