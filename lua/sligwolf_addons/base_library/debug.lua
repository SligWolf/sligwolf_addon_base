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

local LIB = SligWolf_Addons.Debug

local LIBConvar = nil
local LIBPrint = nil

local g_nextThink = 0
local g_debugModeLock = nil

LIB.DEBUG_SIZE = 8
LIB.DEBUG_LIFETIME = 0.20
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

local Color_trGreen = Color(50, 255, 50)
local Color_trBlue = Color(50, 50, 255)
local Color_trTextHit = Color(100, 255, 100)

local Color_trText = Color(137, 222, 255)
local Color_trCross = Color(167, 222, 255)

local LineOffset_trText = -3

if CLIENT then
	Color_trText = Color(255, 222, 102)
	Color_trCross = Color(255, 222, 132)
	LineOffset_trText = 0
end

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
local g_lifetime = LIB.DEBUG_LIFETIME

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
		g_lifetime = LIB.DEBUG_LIFETIME
	end
end

function LIB.ResetLifetime()
	g_lifetime = LIB.DEBUG_LIFETIME
end

function LIB.Cross(pos, size, color)
	if not pos then
		pos = Vector()
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
		pos1 = Vector(0, 0, -1)
		LIB.Debug("Debug.Line: Missing 'pos1'")
	end

	if not pos2 then
		pos2 = Vector(0, 0, 1)
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
		pos = Vector()
		LIB.Debug("Debug.Axis: Missing 'pos'")
	end

	if not LIB.CanDraw(pos) then
		return
	end

	if not ang then
		ang = Angle()
	end

	if not size or size <= 0 then
		size = LIB.DEBUG_SIZE
	end

	debugoverlay.Axis(pos, ang, size, g_lifetime, g_ignoreZ)
end

function LIB.EntityTextAtPosition(pos, text, lineOrColor, color)
	if not pos then
		pos = Vector()
		LIB.Debug("Debug.EntityTextAtPosition: Missing 'pos'")
	end

	if not LIB.CanDraw(pos) then
		return
	end

	text = tostring(text or "")
	if text == "" then
		return
	end

	if istable(lineOrColor) then
		return LIB.EntityTextAtPosition(pos, text, nil, lineOrColor)
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
		pos = Vector()
		LIB.Debug("Debug.EntityTextAtPosition: Missing 'pos'")
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


local function debugText(pos, lineoffset, textTop, textBottom, lifetime, color)
	if textTop ~= "" then
		debugoverlay.EntityTextAtPosition(pos, lineoffset, textTop, lifetime, color)
		debugoverlay.EntityTextAtPosition(pos, lineoffset + 1, textBottom, lifetime, color)
	else
		debugoverlay.EntityTextAtPosition(pos, lineoffset, textBottom, lifetime, color)
	end
end

function LIB.ShowTrace(trace, traceResult, text, lifetime)
	if not LIB.IsDeveloper() then
		return
	end

	if not trace then
		return
	end

	if not traceResult then
		return
	end

	text = tostring(text or "")
	lifetime = lifetime or 1

	local trStart = traceResult.StartPos
	local trEnd = trace.endpos
	local trHitPos = traceResult.HitPos
	local trHit = traceResult.Hit
	local trHitNormal = traceResult.HitNormal
	local trHitNormalEnd = trHitPos + trHitNormal * 8

	debugText(trStart, LineOffset_trText, text, "Start", lifetime, Color_trText)

	debugoverlay.Cross(trStart, 1, lifetime, Color_trGreen, true)
	debugoverlay.Line(trStart, trHitPos, lifetime, Color_trGreen, true)
	debugoverlay.Line(trHitPos, trEnd, lifetime, Color_trBlue, true)
	debugoverlay.Cross(trEnd, 1, lifetime, Color_trBlue, true)

	if trHit then
		debugoverlay.Cross(trHitPos, 1, lifetime, Color_trCross, true)
		debugoverlay.Line(trHitPos, trHitNormalEnd, lifetime, Color_trCross, true)
		debugText(trHitPos, LineOffset_trText, text, "Hit", lifetime, Color_trTextHit)

	else
		debugText(trEnd, LineOffset_trText, text, "End", lifetime, Color_trText)
	end
end

function LIB.ShowHullTrace(traceHull, traceHullResult, text, lifetime)
	if not LIB.IsDeveloper() then
		return
	end

	if not traceHull then
		return
	end

	if not traceHullResult then
		return
	end

	text = tostring(text or "")
	lifetime = lifetime or 1

	local trStart = traceHullResult.StartPos
	local trEnd = traceHull.endpos
	local trHitPos = traceHullResult.HitPos
	local trHit = traceHullResult.Hit
	local trHitNormal = traceHullResult.HitNormal
	local trHitNormalEnd = trHitPos + trHitNormal * 8

	local trMins = traceHull.mins
	local trMaxs = traceHull.maxs

	local trMinsHit = trMins + Vector(1, 1, 0)
	local trMaxsHit = trMaxs - Vector(1, 1, 1)

	debugText(trStart, LineOffset_trText, text, "Start", lifetime, Color_trText)

	debugoverlay.Cross(trStart, 1, lifetime, Color_trGreen, true)
	debugoverlay.SweptBox(trStart, trHitPos, trMins, trMaxs, Angle(), lifetime, Color_trGreen)
	debugoverlay.Line(trHitPos, trEnd, lifetime, Color_trBlue, true)
	debugoverlay.Cross(trEnd, 1, lifetime, Color_trBlue, true)

	if trHit then
		debugoverlay.Cross(trHitPos, 1, lifetime, Color_trCross, true)
		debugoverlay.Line(trHitPos, trHitNormalEnd, lifetime, Color_trCross, true)
		debugoverlay.SweptBox(trHitPos, trHitPos, trMinsHit, trMaxsHit, Angle(), lifetime, Color_trCross)

		debugText(trHitPos, LineOffset_trText, text, "Hit", lifetime, Color_trTextHit)
	else
		debugText(trEnd, LineOffset_trText, text, "End", lifetime, Color_trText)
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

