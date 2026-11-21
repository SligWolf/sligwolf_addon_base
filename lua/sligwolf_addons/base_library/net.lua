local SligWolf_Addons = _G.SligWolf_Addons
if not SligWolf_Addons then
	return
end

local LIB = SligWolf_Addons:NewLib("Net")

local g_nameprefix = "SLIGWOLF_"
local g_maxIdentifierLen = 44

local function getName(identifier)
	identifier = g_nameprefix .. tostring(identifier or "")

	local len = #identifier
	assert(len < g_maxIdentifierLen, string.format("identifier '%s' must shorter than %i chars, got %i chars", identifier, g_maxIdentifierLen, len))

	return identifier
end

function LIB.GetName(identifier)
	return getName(identifier)
end

function LIB.AddNetworkString(identifier)
	if CLIENT then return end

	local name = getName(identifier)

	util.AddNetworkString(name)
end

function LIB.Start(identifier, ...)
	local name = getName(identifier)

	if SERVER then
		util.AddNetworkString(name)
	end

	return net.Start(name, ...)
end

function LIB.Receive(identifier, ...)
	local name = getName(identifier)

	if SERVER then
		util.AddNetworkString(name)
	end

	return net.Receive(name, ...)
end

function LIB.WriteInt(...)
	return net.WriteInt(...)
end

function LIB.ReadInt(...)
	return net.ReadInt(...)
end

function LIB.WriteTable(data, compressed)
	if compressed == nil then
		compressed = true
	end

	if not data then
		data = {}
	end

	if not istable(data) then
		data = {data}
	end

	local json = util.TableToJSON(data, false)

	if compressed then
		json = util.Compress(json)
	end

	local len = #json

	net.WriteUInt(len, 16)
	net.WriteData(json, len)
end

function LIB.ReadTable(compressed)
	if compressed == nil then
		compressed = true
	end

	local len = net.ReadUInt(16)
	local json = net.ReadData(len)

	if not json or json == "" then
		return nil
	end

	if compressed then
		json = util.Decompress(json, 1024 * 1024)

		if not json or json == "" then
			return nil
		end
	end

	local data = util.JSONToTable(json)
	if not data then
		return nil
	end

	return data
end

function LIB.Send(...)
	return net.Send(...)
end

function LIB.SendOmit(...)
	return net.SendOmit(...)
end

function LIB.SendPAS(...)
	return net.SendPAS(...)
end

function LIB.SendPVS(...)
	return net.SendPVS(...)
end

function LIB.SendAll(...)
	return net.Broadcast(...)
end

function LIB.SendToServer(...)
	return net.SendToServer(...)
end

return true

