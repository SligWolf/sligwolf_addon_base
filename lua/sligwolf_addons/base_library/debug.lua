AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Debug = SligWolf_Addons.Debug or {}
table.Empty(SligWolf_Addons.Debug)

local CONSTANTS = SligWolf_Addons.Constants

local LIB = SligWolf_Addons.Debug

local LIBConvar = nil
local LIBPrint = nil

local g_nextThink = 0
local g_debugModeLock = nil

LIB.DEBUG_LIFETIME_DEFAULT = 0.2
LIB.DEBUG_LIFETIME_SHORT = 1
LIB.DEBUG_LIFETIME_MEDIUM = 3
LIB.DEBUG_LIFETIME_LONG = 10

LIB.DEBUG_SIZE = 8
LIB.DEBUG_MAXDRAW_DISTANCE_SQR = 4096 ^ 2

LIB.DEBUG_REALM_MARKER       = "● "
LIB.DEBUG_REALM_MARKER_SPACE = "  "

if CLIENT then
	LIB.COLOR = Color(255, 222, 132)
	LIB.COLOR_TEXT = Color(255, 222, 102)

	LIB.DEBUG_REALM_MARKER_NC = "● [SV] "
else
	LIB.COLOR = Color(167, 222, 255)
	LIB.COLOR_TEXT = Color(137, 222, 255)

	LIB.DEBUG_REALM_MARKER_NC = "● [CL] "
end

LIB.COLOR_TRACER_LIVE = Color(50, 255, 50)
LIB.COLOR_TRACER_DEAD = Color(50, 50, 255)
LIB.COLOR_TRACER_HIT_TEXT = Color(100, 255, 100)

function LIB.IsDeveloper()
	if not LIBConvar then
		return false
	end

	if not LIBConvar.IsDebug() then
		return false
	end

	local debugMode = LIB.GetDebugMode()
	if debugMode == LIB.ENUM_DEBUG_MODE_DISABLED then
		return false
	elseif debugMode == LIB.ENUM_DEBUG_MODE_CLIENT and SERVER then
		return false
	elseif debugMode == LIB.ENUM_DEBUG_MODE_SERVER and CLIENT then
		return false
	end

	if not LIB.GetDebugPlayer() then
		return false
	end

	return true
end

function LIB.Debug(...)
	if not LIBPrint then
		return
	end

	LIBPrint.Debug(...)
end

LIB.Print = LIB.Debug

function LIB.GetDebugMode()
	if not LIBConvar then
		return 0
	end

	return LIBConvar.GetDebugMode()
end

function LIB.SetDebugMode(mode)
	if not LIBConvar then
		return
	end

	LIBConvar.SetDebugMode(mode)
end

local g_debugPlayer = nil

function LIB.GetDebugPlayer()
	if IsValid(g_debugPlayer) then
		return g_debugPlayer
	end

	g_debugPlayer = nil

	for _, ply in player.Iterator() do
		if not IsValid(ply) then
			continue
		end

		if ply:IsBot() then
			continue
		end

		if not ply:IsListenServerHost() then
			continue
		end

		g_debugPlayer = ply
		return g_debugPlayer
	end

	return nil
end

function LIB.CanDraw(pos)
	if not LIB.IsDeveloper() then
		return false
	end

	local ply = LIB.GetDebugPlayer()
	if ply:GetPos():DistToSqr(pos) > LIB.DEBUG_MAXDRAW_DISTANCE_SQR then
	 	return false
	end

	return true
end

local g_ignoreZ = false
local g_lifetime = LIB.DEBUG_LIFETIME_DEFAULT

function LIB.SetIgnoreZ(ignoreZ)
	if ignoreZ then
		g_ignoreZ = true
	else
		g_ignoreZ = false
	end
end

function LIB.ResetIgnoreZ()
	g_ignoreZ = false
end

function LIB.SetLifetime(lifetime)
	if lifetime and lifetime > 0 then
		g_lifetime = lifetime
	else
		g_lifetime = LIB.DEBUG_LIFETIME_DEFAULT
	end
end

function LIB.ResetLifetime()
	g_lifetime = LIB.DEBUG_LIFETIME_DEFAULT
end

function LIB.Cross(pos, size, color)
	if not pos then
		pos = CONSTANTS.vecZero
		LIB.Debug("Debug.Cross: Missing 'pos'")
	end

	if not LIB.CanDraw(pos) then
		return
	end

	if not size or size <= 0 then
		size = LIB.DEBUG_SIZE
	end

	if not color then
		color = LIB.COLOR
	end

	debugoverlay.Cross(pos, size, g_lifetime, color, g_ignoreZ)
end

function LIB.Line(pos1, pos2, color)
	if not pos1 then
		pos1 = CONSTANTS.vecPOne
		LIB.Debug("Debug.Line: Missing 'pos1'")
	end

	if not pos2 then
		pos2 = CONSTANTS.vecNOne
		LIB.Debug("Debug.Line: Missing 'pos2'")
	end

	if not LIB.CanDraw(pos1) and not LIB.CanDraw(pos2) then
		return
	end

	if not color then
		color = LIB.COLOR
	end

	debugoverlay.Line(pos1, pos2, g_lifetime, color, g_ignoreZ)
end

function LIB.Axis(pos, ang, size)
	if not pos then
		pos = CONSTANTS.vecZero
		LIB.Debug("Debug.Axis: Missing 'pos'")
	end

	if not LIB.CanDraw(pos) then
		return
	end

	if not ang then
		ang = CONSTANTS.angZero
	end

	if not size or size <= 0 then
		size = LIB.DEBUG_SIZE
	end

	debugoverlay.Axis(pos, ang, size, g_lifetime, g_ignoreZ)
end

function LIB.EntityTextAtPosition(pos, text, lineOrColor, color)
	if istable(lineOrColor) then
		return LIB.EntityTextAtPosition(pos, text, nil, lineOrColor)
	end

	if not pos then
		pos = CONSTANTS.vecZero
		LIB.Debug("Debug.EntityTextAtPosition: Missing 'pos'")
	end

	if not LIB.CanDraw(pos) then
		return
	end

	text = tostring(text or "")
	if text == "" then
		return
	end

	local line = tonumber(lineOrColor or 0) or 0
	line = math.floor(line)

	if not color then
		color = LIB.COLOR_TEXT
	end

	text = LIB.DEBUG_REALM_MARKER_SPACE .. text

	local lineoffset = line

	if SERVER then
		lineoffset = (line + 1) * -1
	end

	debugoverlay.EntityTextAtPosition(pos, lineoffset, text, g_lifetime, color)
	debugoverlay.EntityTextAtPosition(pos, lineoffset, LIB.DEBUG_REALM_MARKER, g_lifetime, LIB.COLOR_TEXT)
end

function LIB.ScreenText(x, y, text, color)
	if not LIB.IsDeveloper() then
		return
	end

	text = tostring(text or "")
	if text == "" then
		return
	end

	x = x or 0
	y = y or 0

	if not color then
		color = LIB.COLOR_TEXT
	end

	text = LIB.DEBUG_REALM_MARKER_SPACE .. text

	debugoverlay.ScreenText(x, y, text, g_lifetime, color)
	debugoverlay.ScreenText(x, y, LIB.DEBUG_REALM_MARKER, g_lifetime, LIB.COLOR_TEXT)
end

function LIB.Text(pos, text)
	if not pos then
		pos = CONSTANTS.vecZero
		LIB.Debug("Debug.Text: Missing 'pos'")
	end

	if not LIB.CanDraw(pos) then
		return
	end

	text = tostring(text or "")
	if text == "" then
		return
	end

	text = LIB.DEBUG_REALM_MARKER_NC .. text

	debugoverlay.Text(pos, text, g_lifetime, not g_ignoreZ)
end

local g_tmpMin = Vector()
local g_tmpMax = Vector()

function LIB.Box(pos, size, angOrColor, color)
	if not pos then
		pos = CONSTANTS.vecZero
		LIB.Debug("Debug.Box: Missing 'pos'")
	end

	if not LIB.CanDraw(pos) then
		return
	end

	if not size or size <= 0 then
		size = LIB.DEBUG_SIZE
	end

	size = size / 2

	g_tmpMin.x = -size
	g_tmpMin.y = -size
	g_tmpMin.z = -size

	g_tmpMax.x = size
	g_tmpMax.y = size
	g_tmpMax.z = size

	LIB.BoxEx(pos, g_tmpMin, g_tmpMax, angOrColor, color)
end

function LIB.BoxEx(pos, min, max, angOrColor, color)
	if istable(angOrColor) then
		return LIB.BoxEx(pos, min, max, nil, angOrColor)
	end

	if not pos then
		pos = CONSTANTS.vecZero
		LIB.Debug("Debug.BoxEx: Missing 'pos'")
	end

	if not LIB.CanDraw(pos) then
		return
	end

	if not min then
		min = CONSTANTS.vecNOne
		LIB.Debug("Debug.BoxEx: Missing 'min'")
	end

	if not max then
		max = CONSTANTS.vecPOne
		LIB.Debug("Debug.BoxEx: Missing 'max'")
	end

	if not angOrColor then
		angOrColor = CONSTANTS.angZero
	end

	if not color then
		color = LIB.COLOR_TEXT
	end

	debugoverlay.SweptBox(pos, pos, min, max, angOrColor, g_lifetime, color)
end

function LIB.SweptBox(pos1, pos2, min, max, angOrColor, color)
	if istable(angOrColor) then
		return LIB.SweptBox(pos1, pos2, min, max, nil, angOrColor)
	end

	if not pos1 then
		pos1 = CONSTANTS.vecPOne
		LIB.Debug("Debug.SweptBox: Missing 'pos1'")
	end

	if not pos2 then
		pos2 = CONSTANTS.vecNOne
		LIB.Debug("Debug.SweptBox: Missing 'pos2'")
	end

	if not LIB.CanDraw(pos1) and not LIB.CanDraw(pos2) then
		return
	end

	if not min then
		min = CONSTANTS.vecNOne
		LIB.Debug("Debug.SweptBox: Missing 'min'")
	end

	if not max then
		max = CONSTANTS.vecPOne
		LIB.Debug("Debug.SweptBox: Missing 'max'")
	end

	if not angOrColor then
		angOrColor = CONSTANTS.angZero
	end

	if not color then
		color = LIB.COLOR_TEXT
	end

	debugoverlay.SweptBox(pos1, pos2, min, max, angOrColor, g_lifetime, color)
end


local function debugText(pos, textTop, textBottom)
	if textTop ~= "" then
		LIB.EntityTextAtPosition(pos, textTop)
		LIB.EntityTextAtPosition(pos, textBottom, 1)
	else
		LIB.EntityTextAtPosition(pos, textBottom)
	end
end

function LIB.DrawLineTrace(traceLineParams, traceLineResult, text)
	if not LIB.IsDeveloper() then
		return
	end

	if not traceLineParams then
		LIB.Debug("Debug.DrawLineTrace: Missing 'traceLineParams'")
		return
	end

	text = tostring(text or "")
	traceLineParams = traceLineParams or {}

	local trStart = traceLineParams.start
	local trEnd = traceLineParams.endpos

	if not trStart then
		LIB.Debug("Debug.DrawLineTrace: Missing 'traceLineParams.start'")
		return
	end

	if not trEnd then
		LIB.Debug("Debug.DrawLineTrace: Missing 'traceLineParams.endpos'")
		return
	end

	if not LIB.CanDraw(trStart) and not LIB.CanDraw(trEnd) then
		return
	end

	local trHitPos = traceLineResult.HitPos or trEnd
	local trHit = traceLineResult.Hit or false
	local trHitNormal = traceLineResult.HitNormal or CONSTANTS.vecZero
	local trHitNormalEnd = trHitPos + trHitNormal * 8

	debugText(trStart, text, "Start")

	LIB.Cross(trStart, 1, LIB.COLOR_TRACER_LIVE)
	LIB.Line(trStart, trHitPos, LIB.COLOR_TRACER_LIVE)
	LIB.Line(trHitPos, trEnd, LIB.COLOR_TRACER_DEAD)
	LIB.Cross(trEnd, 1, LIB.COLOR_TRACER_DEAD)

	if trHit then
		LIB.Cross(trHitPos, 1, LIB.COLOR_TRACER_LIVE)
		LIB.Line(trHitPos, trHitNormalEnd, LIB.COLOR_TRACER_LIVE)

		debugText(trHitPos, text, "Hit", LIB.COLOR_TRACER_HIT_TEXT)
	else
		LIB.Cross(trHitPos, 1, LIB.COLOR_TRACER_DEAD)

		debugText(trEnd, text, "End")
	end
end

function LIB.DrawHullTrace(traceHullParams, traceHullResult, text)
	if not LIB.IsDeveloper() then
		return
	end

	if not traceHullParams then
		LIB.Debug("Debug.DrawHullTrace: Missing 'traceHullParams'")
		return
	end

	text = tostring(text or "")
	traceHullResult = traceHullResult or {}

	local trStart = traceHullParams.start
	local trEnd = traceHullParams.endpos

	if not trStart then
		LIB.Debug("Debug.DrawHullTrace: Missing 'traceHullParams.start'")
		return
	end

	if not trEnd then
		LIB.Debug("Debug.DrawHullTrace: Missing 'traceHullParams.endpos'")
		return
	end

	if not LIB.CanDraw(trStart) and not LIB.CanDraw(trEnd) then
		return
	end

	local trMins = traceHullParams.mins or CONSTANTS.vecZero
	local trMaxs = traceHullParams.maxs or CONSTANTS.vecZero

	local trHitPos = traceHullResult.HitPos or trEnd
	local trHit = traceHullResult.Hit or false
	local trHitNormal = traceHullResult.HitNormal or CONSTANTS.vecZero
	local trHitNormalEnd = trHitPos + trHitNormal * 8

	local trMinsHit = trMins + Vector(1, 1, 0)
	local trMaxsHit = trMaxs - Vector(1, 1, 1)

	debugText(trStart, text, "Start")

	LIB.Cross(trStart, 1, LIB.COLOR_TRACER_LIVE)
	LIB.SweptBox(trStart, trHitPos, trMins, trMaxs, LIB.COLOR_TRACER_LIVE)
	LIB.Line(trHitPos, trEnd, LIB.COLOR_TRACER_DEAD)
	LIB.Cross(trEnd, 1, LIB.COLOR_TRACER_DEAD)

	if trHit then
		LIB.Cross(trHitPos, 1, LIB.COLOR_TRACER_LIVE)
		LIB.Line(trHitPos, trHitNormalEnd, LIB.COLOR_TRACER_LIVE)

		LIB.BoxEx(trHitPos, trMinsHit, trMaxsHit, LIB.COLOR_TRACER_LIVE)

		debugText(trHitPos, text, "Hit", LIB.COLOR_TRACER_HIT_TEXT)
	else
		LIB.Cross(trHitPos, 1, LIB.COLOR_TRACER_DEAD)

		debugText(trEnd, text, "End")
	end
end

local g_lastHue = 0

function LIB.GetRandomDistinguishableColor()
	if not LIB.IsDeveloper() then
		return nil
	end

	local hue = 0
	local stepSize = 15

	while true do
		hue = math.Round(math.Rand(0, 360) / stepSize) * stepSize

		local delta = math.abs(hue - g_lastHue)
		delta = math.min(delta, 360 - delta)

		if delta < stepSize * 4 then
			continue
		end

		break
	end

	g_lastHue = hue

	local color = HSLToColor(hue, 1, 0.75)
	color = Color(color.r, color.g, color.b)

	return color
end

function LIB.HighlightEntities(entities, color)
	if not LIB.IsDeveloper() then
		return
	end

	if not color then
		color = LIB.GetRandomDistinguishableColor()
	end

	if not istable(entities) then
		entities = {entities}
	end

	local uniqueEntities = {}

	for entK, entV in pairs(entities) do
		if isentity(entV) and IsValid(entV) then
			uniqueEntities[entV] = entV
		end

		if entK ~= entV and isentity(entK) and IsValid(entK) then
			uniqueEntities[entK] = entK
		end
	end

	local count = 0
	local lastEnt = nil

	for _, ent in pairs(uniqueEntities) do
		ent:SetMaterial("models/debug/debugwhite")
		ent:SetColor(color)

		count = count + 1
		lastEnt = ent
	end

	if count <= 0 then
		LIB.Print("Debug.HighlightEntities: No Entities to highlight")
	elseif count == 1 then
		LIB.Print("Debug.HighlightEntities: Highlighting 1 Entity:\n  %s", lastEnt)
	else
		LIB.Print("Debug.HighlightEntities: Highlighting %i Entities", count)
	end
end

function LIB.Load()
	LIBConvar = SligWolf_Addons.Convar
	LIBPrint = SligWolf_Addons.Print

	LIB.ENUM_DEBUG_MODE_DISABLED = LIBConvar.ENUM_DEBUG_MODE_DISABLED
	LIB.ENUM_DEBUG_MODE_SHARED = LIBConvar.ENUM_DEBUG_MODE_SHARED
	LIB.ENUM_DEBUG_MODE_SERVER = LIBConvar.ENUM_DEBUG_MODE_SERVER
	LIB.ENUM_DEBUG_MODE_CLIENT = LIBConvar.ENUM_DEBUG_MODE_CLIENT

	if SERVER then
		local LIBHook = SligWolf_Addons.Hook

		local function playSwitchSound(ply, soundFile, recipientFilter)
			ply:EmitSound(
				soundFile,
				75, 100, 1,
				CHAN_AUTO,
				0, 1,
				recipientFilter
			)
		end

		local function doModeSwitcherThink()
			if not LIBConvar.IsDebug() then
				return
			end

			local ply = LIB.GetDebugPlayer()
			if not IsValid(ply) then
				g_debugModeLock = nil
				return
			end

			-- Switch debug mode by holding ALT and E (default)
			if not ply:KeyDown(IN_WALK) then
				g_debugModeLock = nil
				return
			end

			if not ply:KeyDown(IN_USE) then
				g_debugModeLock = nil
				return
			end

			local now = RealTime()

			if g_debugModeLock and g_debugModeLock > now then
				return
			end

			local debugMode = LIB.GetDebugMode()

			local sendThisPlayerOnly = RecipientFilter()
			sendThisPlayerOnly:RemoveAllPlayers()
			sendThisPlayerOnly:AddPlayer(ply)

			local message = nil

			if debugMode == LIB.ENUM_DEBUG_MODE_DISABLED then
				LIB.SetDebugMode(LIB.ENUM_DEBUG_MODE_SHARED)
				message = LIBPrint.FormatMessage("Debug Mode: Shared")
			elseif debugMode == LIB.ENUM_DEBUG_MODE_SHARED then
				LIB.SetDebugMode(LIB.ENUM_DEBUG_MODE_SERVER)
				message = LIBPrint.FormatMessage("Debug Mode: Server")
			elseif debugMode == LIB.ENUM_DEBUG_MODE_SERVER then
				LIB.SetDebugMode(LIB.ENUM_DEBUG_MODE_CLIENT)
				message = LIBPrint.FormatMessage("Debug Mode: Client")
			elseif debugMode == LIB.ENUM_DEBUG_MODE_CLIENT then
				LIB.SetDebugMode(LIB.ENUM_DEBUG_MODE_DISABLED)
				message = LIBPrint.FormatMessage("Debug Mode: Off")
			end

			LIBPrint.Notify(LIBPrint.NOTIFY_GENERIC, message, 3, sendThisPlayerOnly)
			playSwitchSound(ply, "eli_lab.al_buttonmash", sendThisPlayerOnly)

			g_debugModeLock = now + 1
		end

		LIBHook.Add("Think", "DebugUpdate", function()
			local now = RealTime()

			if g_nextThink < now then
				doModeSwitcherThink()
				g_nextThink = now + 0.20
			end
		end)
	end
end

return true

