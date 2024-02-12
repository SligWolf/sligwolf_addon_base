AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Convar = SligWolf_Addons.Convar or {}
table.Empty(SligWolf_Addons.Convar)

local LIB = SligWolf_Addons.Convar

local g_lastThink = 0

local g_sliderRenderMode = 0
local g_isDebug = false

local cl_calcSliderRenderMode = nil

if CLIENT then
	LIB.ENUM_SLIDER_RENDER_MODE_DISABLED = 0
	LIB.ENUM_SLIDER_RENDER_MODE_PHYSGUN = 1
	LIB.ENUM_SLIDER_RENDER_MODE_ALWAYS = 2

	local g_cvShowSliders = CreateClientConVar(
		"cl_sligwolf_addons_slider_render_mode",
		"1",
		true,
		false,
		"Sets the rendering mode of sliders. 0 = Off, 1 = Render when grapped with Phygun, 2 = Always render, Default: 1",
		0,
		2
	)

	function LIB.GetSliderRenderMode()
		return g_sliderRenderMode
	end

	cl_calcSliderRenderMode = function()
		local showSlidersMode = g_cvShowSliders:GetInt()
		showSlidersMode = math.Clamp(showSlidersMode, 0, 2)

		return showSlidersMode
	end
end

function LIB.IsDebug()
	return g_isDebug
end

local function calcIsDebug()
	local devconvar = GetConVar("developer")
	if not devconvar then
		return false
	end

	if devconvar:GetInt() <= 0 then
		return false
	end

	return true
end

function LIB.Load()
	local LIBHook = SligWolf_Addons.Hook

	LIBHook.Add("Think", "ConvarsUpdate", function()
		local now = RealTime()

		if g_lastThink < now then
			g_isDebug = calcIsDebug()

			if CLIENT then
				g_sliderRenderMode = g_isDebug or cl_calcSliderRenderMode()
			end

			g_lastThink = now + 1 + math.random()
		end
	end)
end

return true

