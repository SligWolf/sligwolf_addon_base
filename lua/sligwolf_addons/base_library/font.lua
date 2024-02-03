AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Font = SligWolf_Addons.Font or {}
table.Empty(SligWolf_Addons.Font)

local LIB = SligWolf_Addons.Font

local g_font_template = {
	font = "Arial",
	size = 0,
	weight = 0,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false
}

LIB._CreatedFonts = {}

function LIB.AddFont(size, weight, baseFontName, additionalData)
	if SERVER then
		return nil
	end

	local ft = g_font_template

	size = tonumber(size) or ft.size
	weight = tonumber(weight) or ft.weight
	baseFontName = tostring(baseFontName or ft.font)
	additionalData = additionalData or {}

	local additionalDataName = {}
	local additionalDataNameEmpty = true

	for k, v in SortedPairs(additionalData or {}) do
		if v == g_font_template[k] then
			continue
		end

		local name = string.format("[%s=%s]", tostring(k), tostring(v))
		table.insert(additionalDataName, name)

		additionalDataNameEmpty = false
	end

	if additionalDataNameEmpty then
		additionalDataName = ""
	else
		additionalDataName = table.concat(additionalDataName)
		additionalDataName = util.MD5(additionalDataName)
	end

	local ID = string.format("SLIGWOLF_Font_[%s][%d][%d][%s]", baseFontName, size, weight, additionalDataName)

	if LIB._CreatedFonts[ID] then
		return ID
	end

	local font = table.Copy(ft)

	for k, v in pairs(additionalData or {}) do
		font[k] = v
	end

	font.size = size
	font.weight = weight
	font.font = base

	surface.CreateFont(ID, font)

	LIB._CreatedFonts[ID] = true
	return ID
end

return true

