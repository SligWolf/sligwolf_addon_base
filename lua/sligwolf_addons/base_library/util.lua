AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Util = SligWolf_Addons.Util or {}
table.Empty(SligWolf_Addons.Util)

local LIB = SligWolf_Addons.Util

local LIBConvar = nil
local LIBPrint = nil

function LIB.Load()
	LIBConvar = SligWolf_Addons.Convar
	LIBPrint = SligWolf_Addons.Print
end

function LIB.IsDeveloper()
	return LIBConvar.IsDebug()
end

function LIB.ValidateName(name)
	name = tostring(name or "")
	name = string.gsub(name, "^!", "", 1)
	name = string.gsub(name, "[\\/]", "")
	return name
end

function LIB.IsValidModelEntity(ent)
	if not IsValid(ent) then return false end

	local model = tostring(ent:GetModel() or "")
	if model == "" then return false end

	if not LIB.IsValidModel(model) then return false end
	return true
end

LIB._IsValidModelCache = {}
LIB._IsValidModelFileCache = {}

local g_modelInvalid = {}
g_modelInvalid[""] = true
g_modelInvalid["models/error.mdl"] = true

function LIB.IsValidModel(model)
	model = tostring(model or "")

	if g_modelInvalid[model] then
		return false
	end

	if LIB._IsValidModelCache[model] then
		return true
	end

	LIB._IsValidModelCache[model] = nil

	if not LIB.IsValidModelFile(model) then
		return false
	end

	util.PrecacheModel(model)

	if not util.IsValidModel(model) then
		return false
	end

	LIB._IsValidModelCache[model] = true
	return true
end

function LIB.IsValidModelFile(model)
	model = tostring(model or "")

	if g_modelInvalid[model] then
		return false
	end

	if LIB._IsValidModelFileCache[model] then
		return true
	end

	LIB._IsValidModelFileCache[model] = nil

	if model == "" then
		return false
	end

	if IsUselessModel(model) then
		return false
	end

	if not file.Exists(model, "GAME") then
		return false
	end

	LIB._IsValidModelFileCache[model] = true
	return true
end

LIB._MatCache = {}

function LIB.GetMaterialData(PNGname, RGB, TexX, TexY, W, H)
	local texturedata = LIB._MatCache[PNGname]

	if texturedata then
		texturedata.color = RGB
		texturedata.x = TexX
		texturedata.y = TexY
		texturedata.w = W
		texturedata.h = H

		return texturedata
	end

	LIB._MatCache[PNGname] = {Textur = Material(PNGname), color = RGB, x = TexX, y = TexY, w = W, h = H}
	return LIB._MatCache[PNGname]
end

function LIB.DrawMaterial(texturedata)
	surface.SetMaterial(texturedata.Textur)
	surface.DrawTexturedRect(texturedata.x, texturedata.y, texturedata.w, texturedata.h)
end

function LIB.ChangeSubMaterial(ent, num, mat)
	if not IsValid(ent) then return end
	num = tonumber(num or 0)
	mat = tostring(mat or "")

	ent:SetSubMaterial(num, mat)
end

function LIB.SetDFrameButtonProperties(ent, posx, posy, sizex, sizey, text, cmd, target)
	if not IsValid(ent) then return end

	posx = tonumber(posx or 0)
	posy = tonumber(posy or 0)
	sizex = tonumber(sizex or 0)
	sizey = tonumber(sizey or 0)
	text = tostring(text or "")
	cmd = tostring(cmd or "")

	ent:SetPos(posx, posy)
	ent:SetSize(sizex, sizey)
	ent:SetText(text)

	if ent:GetClassName() ~= "Label" then return end
	if not isfunction(ent.SetConsoleCommand) then return end
	ent:SetConsoleCommand("say", cmd)
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

local function debugText(pos, lineoffset, textTop, textBottom, lifetime, color)
	if text ~= "" then
		debugoverlay.EntityTextAtPosition(pos, lineoffset, textTop, lifetime, color)
		debugoverlay.EntityTextAtPosition(pos, lineoffset + 1, textBottom, lifetime, color)
	else
		debugoverlay.EntityTextAtPosition(pos, lineoffset, textBottom, lifetime, color)
	end
end

function LIB.DebugTrace(trace, traceResult, text, lifetime)
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

function LIB.DebugHullTrace(traceHull, traceHullResult, text, lifetime)
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

function LIB.DebugColorEntities(entities, color)
	if not LIB.IsDeveloper() then
		return
	end

	color = color or ColorRand()

	if not istable(entities) then
		entities = {entities}
	end

	local count = 0
	local lastEnt = nil

	for entK, entV in pairs(entities) do
		local tmp = {entK, entV}

		for i, ent in ipairs(tmp) do
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
		LIBPrint.Debug("Util.DebugColorEntities: No Entity to highlight")
	elseif count == 1 then
		LIBPrint.Debug("Util.DebugColorEntities: Highlighting 1 Entity:\n  %s", lastEnt)
	else
		LIBPrint.Debug("Util.DebugColorEntities: Highlighting %i Entities", count)
	end
end

return true

