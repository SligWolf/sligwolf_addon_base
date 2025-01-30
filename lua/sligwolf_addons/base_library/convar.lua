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

local CONSTANTS = SligWolf_Addons.Constants

local g_nextThink = 0

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

	local function getToolMode()
		local ply = LocalPlayer()

		local toolgun = ply:GetActiveWeapon()
		if not IsValid(toolgun) then
			return
		end

		if toolgun:GetClass() ~= "gmod_tool" then
			return
		end

		return toolgun:GetMode()
	end

	cl_calcSliderRenderMode = function()
		if g_isDebug then
			return LIB.ENUM_SLIDER_RENDER_MODE_ALWAYS
		end

		local showSlidersMode = g_cvShowSliders:GetInt()
		showSlidersMode = math.Clamp(showSlidersMode, 0, 2)

		if showSlidersMode == LIB.ENUM_SLIDER_RENDER_MODE_DISABLED then
			return showSlidersMode
		end

		if getToolMode() == CONSTANTS.toolRubatsEasyInspector then
			return LIB.ENUM_SLIDER_RENDER_MODE_ALWAYS
		end

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

local function doDelayedThink()
	g_isDebug = calcIsDebug()

	if SERVER then
		return
	end

	g_sliderRenderMode = cl_calcSliderRenderMode()
end

function LIB.Load()
	local LIBHook = SligWolf_Addons.Hook

	LIBHook.Add("Think", "ConvarsUpdate", function()
		local now = RealTime()

		if g_nextThink < now then
			doDelayedThink()
			g_nextThink = now + 1 + math.random()
		end
	end)
end

return true

