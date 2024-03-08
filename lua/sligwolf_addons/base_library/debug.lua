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

function LIB.Load()
	LIBConvar = SligWolf_Addons.Convar
	LIBPrint = SligWolf_Addons.Print
end

function LIB.IsDeveloper()
	if not LIBConvar then
		return false
	end

	return LIBConvar.IsDebug()
end

function LIB.Debug(...)
	if not LIBPrint then
		return
	end

	LIBPrint.Debug(...)
end

LIB.Print = LIB.Debug

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

local function debugText(pos, lineoffset, textTop, textBottom, lifetime, color)
	if text ~= "" then
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
		return
	end

	local hue = 0
	local stepSize = 15

	while true do
		hue = math.Round(math.Rand(0, 360) / stepSize) * stepSize

		local delta = math.abs(hue - g_lastHue)
		delta = math.min(delta, 360 - delta);

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

	local count = 0
	local lastEnt = nil

	for entK, entV in pairs(entities) do
		local tmp = {}

		tmp[entV] = true
		tmp[entK] = true

		for ent, _ in pairs(tmp) do
			if not isentity(ent) then
				continue
			end

			if not IsValid(ent) then
				continue
			end

			ent:SetMaterial("models/debug/debugwhite")
			ent:SetColor(color)

			count = count + 1
			lastEnt = ent
		end
	end

	if count <= 0 then
		LIB.Print("Debug.HighlightEntities: No Entities to highlight")
	elseif count == 1 then
		LIB.Print("Debug.HighlightEntities: Highlighting 1 Entity:\n  %s", lastEnt)
	else
		LIB.Print("Debug.HighlightEntities: Highlighting %i Entities", count)
	end
end

return true

