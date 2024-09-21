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

local g_IsValidModelCache = {}
local g_IsValidModelFileCache = {}

local g_modelInvalid = {}
g_modelInvalid[""] = true
g_modelInvalid["models/error.mdl"] = true

function LIB.IsValidModel(model)
	model = tostring(model or "")

	if g_modelInvalid[model] then
		return false
	end

	if g_IsValidModelCache[model] then
		return true
	end

	g_IsValidModelCache[model] = nil

	if not LIB.IsValidModelFile(model) then
		return false
	end

	util.PrecacheModel(model)

	if not util.IsValidModel(model) then
		return false
	end

	g_IsValidModelCache[model] = true
	return true
end

function LIB.IsValidModelFile(model)
	model = tostring(model or "")

	if g_modelInvalid[model] then
		return false
	end

	if g_IsValidModelFileCache[model] then
		return true
	end

	g_IsValidModelFileCache[model] = nil

	if model == "" then
		return false
	end

	if IsUselessModel(model) then
		return false
	end

	if not file.Exists(model, "GAME") then
		return false
	end

	g_IsValidModelFileCache[model] = true
	return true
end

function LIB.GuessAddonIDByModelName(model)
	if not LIB.IsValidModel(model) then
		return
	end

	local addonid = string.match(model, "^models/sligwolf/([%w%s_]+)/" ) or ""
	if addonid == "" then
		return
	end

	if not SligWolf_Addons.HasLoadedAddon(addonid) then
		return
	end

	return addonid
end

local g_MatCache = {}

function LIB.GetMaterialData(PNGname, RGB, TexX, TexY, W, H)
	local texturedata = g_MatCache[PNGname]

	if texturedata then
		texturedata.color = RGB
		texturedata.x = TexX
		texturedata.y = TexY
		texturedata.w = W
		texturedata.h = H

		return texturedata
	end

	g_MatCache[PNGname] = {Textur = Material(PNGname), color = RGB, x = TexX, y = TexY, w = W, h = H}
	return g_MatCache[PNGname]
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

function LIB.NormalizeNewlines(text, nl)
	nl = tostring(nl or "")
	text = tostring(text or "")

	local replacemap = {
		["\r\n"] = true,
		["\r"] = true,
		["\n"] = true,
	}

	if not replacemap[nl] then
		nl = "\n"
	end

	replacemap[nl] = nil

	for k, v in pairs(replacemap) do
		replacemap[k] = nl
	end

	text = string.gsub(text, "([\r]?[\n]?)", replacemap)

	return text
end

function LIB.IsAdmin(ply)
	if CLIENT and not IsValid(ply) then
		ply = LocalPlayer()
	end

	if not IsValid(ply) then
		return false
	end

	if not ply:IsAdmin() then
		return false
	end

	return true
end

function LIB.IsAdminForCMD(ply)
	if not IsValid(ply) then
		return true
	end

	if not LIB.IsAdmin(ply) then
		return false
	end

	return true
end

local g_listCache = {}

function LIB.GetList(name)
	if g_listCache[name] then
		return g_listCache[name]
	end

	local listItem = list.GetForEdit(name)

	g_listCache[name] = listItem
	return listItem
end

function LIB.CheckSumOfFile(filePath, gamePath)
	local data = file.Read(filePath, gamePath)
	if not data then
		return nil
	end

	if data == "" then
		return nil
	end

	local hash = util.SHA256(data)
	return hash
end

return true

