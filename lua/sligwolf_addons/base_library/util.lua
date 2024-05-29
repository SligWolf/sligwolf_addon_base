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

return true

