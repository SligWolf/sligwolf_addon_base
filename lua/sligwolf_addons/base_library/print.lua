AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Print = SligWolf_Addons.Print or {}
table.Empty(SligWolf_Addons.Print)

local LIB = SligWolf_Addons.Print

local LIBVehicle = nil
local LIBEntities = nil
local LIBDebug = nil
local LIBNet = nil

function LIB.Load()
	LIBVehicle = SligWolf_Addons.Vehicle
	LIBEntities = SligWolf_Addons.Entities
	LIBDebug = SligWolf_Addons.Debug
	LIBNet = SligWolf_Addons.Net

	LIBNet.AddNetworkString("Notify")

	if CLIENT then
		LIBNet.Receive("Notify", function()
			local mode = net.ReadUInt(8)
			local message = net.ReadString()
			local len = net.ReadFloat()

			LIB.Notify(mode, message, len)
		end)
	end
end

local function formatEntity(ent)
	local format = nil

	if ent:IsVehicle() then
		format = LIBVehicle.ToString(ent)
	else
		format = LIBEntities.ToString(ent)
	end

	return format
end

local function formatMessage(format, ...)
	local addSpace = format[1] ~= "["

	if addSpace then
		format = "[SW-ADDONS] " .. format
	else
		format = "[SW-ADDONS]" .. format
	end

	local args = {...}

	if table.IsEmpty(args) then
		return format
	end

	for i, v in ipairs(args) do
		if v == nil then
			continue
		end

		if isentity(v) then
			v = formatEntity(v)
		elseif istable(v) and v.Addonname and v.ToString then
			v = v:ToString()
		elseif not isnumber(v) then
			v = tostring(v)
		end

		args[i] = v
	end

	local err = string.format(format, unpack(args))
	return err
end

function LIB.FormatSafe(format)
	if isentity(format) then
		format = formatEntity(format)
	elseif istable(v) and v.Addonname and v.ToString then
		v = v:ToString()
	else
		format = tostring(format)
	end

	format = string.Replace(format, "%", "$")
	return format
end

function LIB.FormatMessage(format, ...)
	return formatMessage(format, ...)
end

function LIB.Error(format, ...)
	format = tostring(format or "")

	if format == "" then
		format = "Unknown error!"
	end

	local err = formatMessage(format, ...)
	error(err)
end

function LIB.ErrorNoHalt(format, ...)
	format = tostring(format or "")

	if format == "" then
		format = "Unknown error!"
	end

	local err = formatMessage(format, ...)
	ErrorNoHalt(err)
end

function LIB.ErrorNoHaltWithStack(format, ...)
	format = tostring(format or "")

	if format == "" then
		format = "Unknown error!"
	end

	local err = formatMessage(format, ...)
	ErrorNoHaltWithStack(err)
end

function LIB.Print(format, ...)
	format = tostring(format or "")

	if format == "" then
		format = "Empty message!"
	end

	local message = formatMessage(format, ...)
	MsgN(message)
end

function LIB.Debug(format, ...)
	if not LIBDebug then
		return
	end

	if not LIBDebug.IsDeveloper() then
		return
	end

	format = tostring(format or "")

	if format == "" then
		format = "Empty message!"
	end

	local message = formatMessage("[DEBUG] " .. format, ...)
	MsgN(message)
end

if CLIENT then
	local g_soundMap = {
		[NOTIFY_ERROR] = Sound("buttons/button10.wav"),
	}

	function LIB.Notify(mode, message, len)
		mode = mode or 1

		message = tostring(message or "")
		if message == "" then
			message = "Empty message!"
		end

		len = tonumber(len or 0) or 0
		if len <= 0 then
			len = 3
		end

		notification.AddLegacy(message, mode, len)

		local soundName = g_soundMap[mode]
		if soundName then
			surface.PlaySound(soundName)
		end
	end
else
	function LIB.Notify(mode, message, len, recipientFilterOrPly)
		mode = mode or 1

		message = tostring(message or "")
		if message == "" then
			message = "Empty message!"
		end

		len = tonumber(len or 0) or 0
		if len <= 0 then
			len = 3
		end

		LIBNet.Start("Notify")

		net.WriteUInt(mode, 8)
		net.WriteString(message)
		net.WriteFloat(len)

		if recipientFilterOrPly then
			LIBNet.Send(recipientFilterOrPly)
		else
			LIBNet.SendAll()
		end
	end
end

return true

