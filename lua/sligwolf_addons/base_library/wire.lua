AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Wire = SligWolf_Addons.Wire or {}
table.Empty(SligWolf_Addons.Wire)

local LIB = SligWolf_Addons.Wire

local g_HasWiremod = nil
local g_wirelinkName = "wirelink"

function LIB.HasWiremod()
	if g_HasWiremod ~= nil then
		return g_HasWiremod
	end

	g_HasWiremod = false

	local wmod = _G.WireAddon or _G.WIRE_CLIENT_INSTALLED
	if not wmod then return false end
	if not _G.WireLib then return false end

	g_HasWiremod = true
	return true
end

local g_WireLib = nil
local g_Wire_Render = nil
local g_Wire_UpdateRenderBounds = nil

function LIB.Render(ent)
	if not CLIENT then return end
	if not g_HasWiremod then return end

	g_Wire_Render(ent)
end

local g_toolWhiteList = {
	wire = true,
	wire_adv = true,
	wire_debugger = true,
	wire_wirelink = true,
	gui_wiring = true,
	multi_wire = true,
}

function LIB.IsWireTool(toolname)
	if not g_HasWiremod then return false end
	if not g_toolWhiteList[toolname] then return false end

	return true
end

function LIB.UpdateRenderBounds(ent)
	if not CLIENT then return end
	if not g_HasWiremod then return end

	g_Wire_UpdateRenderBounds(ent)
end

function LIB.PollRenderBounds(ent, min, max)
	if not CLIENT then return end
	if not g_HasWiremod then return end

	local now = CurTime()
	local nextUpdate = ent._nextWireRBUpdate or 0

	if now < nextUpdate then
		return
	end

	g_Wire_UpdateRenderBounds(ent)
	ent._nextWireRBUpdate = now + math.Rand(min or 3, max or 10)
end

function LIB.Restore(ent)
	if CLIENT then return end
	if not g_HasWiremod then return end

	return g_WireLib.Restored(ent)
end

function LIB.BuildDupeInfo(ent)
	if CLIENT then return end
	if not g_HasWiremod then return {} end

	return g_WireLib.BuildDupeInfo(ent)
end

function LIB.ApplyDupeInfo(ply, ent, data, entities)
	if CLIENT then return end
	if not g_HasWiremod then return end

	entities = entities or {}
	data = data or {}

	g_WireLib.ApplyDupeInfo(ply, ent, data, function(id, default)
		if id == nil then return default end
		if id == 0 then return game.GetWorld() end

		local ident = entities[id]

		if not IsValid(ident) then
			if isnumber(id) then
				ident = ents.GetByIndex(id)
			end
		end

		if not IsValid(ident) then
			ident = default
		end

		return ident
	end)
end

function LIB.ApplyWiremodTrait(SENT)
	function SENT:AddWireInput(name, ptype, desc)
		if CLIENT then return end
		if not g_HasWiremod then return end

		name = string.Trim(tostring(name or ""))
		ptype = string.upper(string.Trim(tostring(ptype or "NORMAL")))
		desc = string.Trim(tostring(desc or ""))

		self._wirePorts = self._wirePorts or {}
		local wireports = self._wirePorts

		wireports.In = wireports.In or {}
		local inputs = wireports.In

		inputs.names = inputs.names or {}
		inputs.types = inputs.types or {}
		inputs.descs = inputs.descs or {}

		inputs.once = inputs.once or {}
		if inputs.once[name] then return end

		inputs.names[#inputs.names + 1] = name
		inputs.types[#inputs.types + 1] = ptype
		inputs.descs[#inputs.descs + 1] = desc
		inputs.once[name] = true
	end

	function SENT:AddWireOutput(name, ptype, desc)
		if CLIENT then return end
		if not g_HasWiremod then return end

		name = string.Trim(tostring(name or ""))
		ptype = string.upper(string.Trim(tostring(ptype or "NORMAL")))
		desc = string.Trim(tostring(desc or ""))

		self._wirePorts = self._wirePorts or {}
		local wireports = self._wirePorts

		wireports.Out = wireports.Out or {}
		local outputs = wireports.Out

		outputs.names = outputs.names or {}
		outputs.types = outputs.types or {}
		outputs.descs = outputs.descs or {}

		outputs.once = outputs.once or {}
		if outputs.once[name] then return end

		outputs.names[#outputs.names + 1] = name
		outputs.types[#outputs.types + 1] = ptype
		outputs.descs[#outputs.descs + 1] = desc
		outputs.once[name] = true
	end

	function SENT:InitWirePorts()
		if CLIENT then return end
		if not g_HasWiremod then return end

		local wireports = self._wirePorts
		if not wireports then
			return
		end

		local inputs = wireports.In
		if inputs then
			self.Inputs = g_WireLib.CreateSpecialInputs(
				self,
				inputs.names,
				inputs.types,
				inputs.descs
			)
		end

		local outputs = wireports.Out
		if outputs then
			self.Outputs = g_WireLib.CreateSpecialOutputs(
				self,
				outputs.names,
				outputs.types,
				outputs.descs
			)
		end

		self._wireOutputCache = {}
		self._wirePorts = nil
	end

	function SENT:IsConnectedInputWire(name)
		if CLIENT then return false end
		if not g_HasWiremod then return false end

		local wireinputs = self.Inputs
		if not istable(wireinputs) then return false end

		local wireinput = wireinputs[name]
		if not istable(wireinput) then return false end
		if not IsValid(wireinput.Src) then return false end

		return true
	end

	function SENT:IsConnectedOutputWire(name)
		if CLIENT then return false end
		if not g_HasWiremod then return false end

		local wireoutputs = self.Outputs
		if not istable(wireoutputs) then return false end

		local wireoutput = wireoutputs[name]
		if not istable(wireoutput) then return false end
		if not istable(wireoutput.Connected) then return false end
		if not istable(wireoutput.Connected[1]) then return false end
		if not IsValid(wireoutput.Connected[1].Entity) then return false end

		return true
	end

	function SENT:HasWirelink(name)
		if CLIENT then return false end
		if not g_HasWiremod then return false end

		local wireoutputs = self.Outputs
		if not istable(wireoutputs) then return false end

		local wireoutput = wireoutputs[name]
		if not istable(wireoutput) then return false end

		local value = wireoutput.Value
		if not isentity(value) then return false end
		if not IsValid(value) then return false end

		return true
	end

	function SENT:IsConnectedWirelink()
		if CLIENT then return false end
		if not g_HasWiremod then return false end

		if not self.extended then
			-- wirelink had not been created yet
			return false
		end

		if self:HasWirelink(g_wirelinkName) then
			-- wirelink had been triggered via E2 code
			return true
		end

		if self:IsConnectedOutputWire(g_wirelinkName) then
			-- wirelink had been connected via Wire Tool
			return true
		end

		return false
	end

	function SENT:TriggerWireOutput(name, value)
		if CLIENT then return end
		if not g_HasWiremod then return end

		if isbool(value) or value == nil then
			value = value and 1 or 0
		end

		if value == self._wireOutputCache[name] and not istable(value) then return end
		self._wireOutputCache[name] = value

		WireLib.TriggerOutput(self, name, value)
	end

	function SENT:TriggerInput(name, value, ext)
		local wired = self:IsConnectedInputWire(name) or self:IsConnectedWirelink() or istable(ext) and ext.wirelink
		self:OnWireInputTrigger(name, value, wired)
	end

	function SENT:OnWireInputTrigger(name, value, wired)
		-- Override me
	end
end

function LIB.AllAddonsLoaded()
	g_HasWiremod = nil

	if not LIB.HasWiremod() then
		-- ensure the WireMod has been loaded
		return
	end

	g_WireLib = WireLib
	g_Wire_Render = Wire_Render
	g_Wire_UpdateRenderBounds = Wire_UpdateRenderBounds
end

return true

