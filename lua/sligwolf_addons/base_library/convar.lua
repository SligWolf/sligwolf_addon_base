local SligWolf_Addons = _G.SligWolf_Addons
if not SligWolf_Addons then
	return
end

local LIB = SligWolf_Addons:NewLib("Convar")

local CONSTANTS = SligWolf_Addons.Constants

local LIBDebug = nil
local LIBUtil = nil

local g_callbacks = {}
local g_varModifier = {}

local g_nextThink = nil

function LIB.AddConvar(convarName, parameters)
	convarName = tostring(convarName or "")
	parameters = parameters or {}

	local default = parameters.default
	local min = parameters.min
	local max = parameters.max
	local modifier = parameters.modifier

	if isbool(default) then
		default = default and "1" or "0"
		min = 0
		max = 1
		modifier = modifier or tobool
	elseif isnumber(default) then
		if not modifier then
			local toLimitedNumber = nil

			if min and max then
				toLimitedNumber = function(num)
					num = tonumber(num or 0) or 0
					num = math.Clamp(num, min, max)

					return num
				end
			elseif min and not max then
				toLimitedNumber = function(num)
					num = tonumber(num or 0) or 0
					num = math.max(num, min)

					return num
				end
			elseif not min and max then
				toLimitedNumber = function(num)
					num = tonumber(num or 0) or 0
					num = math.min(num, max)

					return num
				end
			else
				toLimitedNumber = function(num)
					return tonumber(num or 0) or 0
				end
			end

			modifier = toLimitedNumber
		end
	end

	default = tostring(default)
	local help = tostring(parameters.help or "")

	local convar = CreateConVar(
		convarName,
		default,
		parameters.flags or 0,
		help,
		min,
		max
	)

	if modifier then
		LIB.AddVarModifier(convarName, modifier)
	end

	return convar
end

function LIB.AddClientConvar(convarName, parameters)
	if SERVER then
		return nil
	end

	convarName = tostring(convarName or "")
	parameters = parameters or {}

	local default = parameters.default
	local min = parameters.min
	local max = parameters.max
	local modifier = parameters.modifier

	if isbool(default) then
		default = default and "1" or "0"
		min = 0
		max = 1
		modifier = modifier or tobool
	elseif isnumber(default) then
		if not modifier then
			local toLimitedNumber = nil

			if min and max then
				toLimitedNumber = function(num)
					num = tonumber(num or 0) or 0
					num = math.Clamp(num, min, max)

					return num
				end
			elseif min and not max then
				toLimitedNumber = function(num)
					num = tonumber(num or 0) or 0
					num = math.max(num, min)

					return num
				end
			elseif not min and max then
				toLimitedNumber = function(num)
					num = tonumber(num or 0) or 0
					num = math.min(num, max)

					return num
				end
			else
				toLimitedNumber = function(num)
					return tonumber(num or 0) or 0
				end
			end

			modifier = toLimitedNumber
		end
	end

	default = tostring(default)
	local help = tostring(parameters.help or "")

	local convar = CreateClientConVar(
		convarName,
		default,
		tobool(parameters.shouldsave),
		tobool(parameters.userinfo),
		help,
		min,
		max
	)

	if modifier then
		LIB.AddVarModifier(convarName, modifier)
	end

	return convar
end

function LIB.AddVarModifier(convarName, modifier)
	convarName = tostring(convarName or "")
	g_varModifier[convarName] = modifier
end

function LIB.AddChangeCallback(convarName, callback, identifier)
	convarName = tostring(convarName or "")
	identifier = tostring(identifier or "")

	if not isfunction(callback) then
		return
	end

	if identifier == "" then
		identifier = LIBUtil.UniqueString("_UnnamedAddChangeCallback_UniqueId")
	end

	local convarCallbacks = g_callbacks[convarName] or {}
	g_callbacks[convarName] = convarCallbacks

	local convarCallback = convarCallbacks[identifier] or {}
	convarCallbacks[identifier] = convarCallback

	convarCallback.callback = callback
	convarCallback.convar = GetConVar(convarName)
	convarCallback.oldValue = nil
end

function LIB.GetValue(convarName)
	convarName = tostring(convarName or "")

	local convar = GetConVar(convarName)
	if not convar then
		return nil
	end

	local value = convar:GetString() or ""

	local modifier = g_varModifier[convarName]
	if modifier then
		value = modifier(value)
	end

	return value
end

function LIB.Refresh()
	g_nextThink = nil
end

local g_sliderRenderMode = 0
local cl_calcSliderRenderMode = nil

if CLIENT then
	LIB.ENUM_SLIDER_RENDER_MODE_DISABLED = 0
	LIB.ENUM_SLIDER_RENDER_MODE_PHYSGUN = 1
	LIB.ENUM_SLIDER_RENDER_MODE_ALWAYS = 2

	LIB.AddClientConvar("cl_sligwolf_addons_slider_render_mode", {
		default = LIB.ENUM_SLIDER_RENDER_MODE_DISABLED,
		shouldsave = true,
		userinfo = false,
		help = "Sets the rendering mode of sliders. 0 = Disabled, 1 = Render when grapped with Phygun, 2 = Always render, Default: 1",
		min = 0,
		max = 2,
	})

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
		if LIBDebug.IsDeveloper() then
			return LIB.ENUM_SLIDER_RENDER_MODE_ALWAYS
		end

		local showSlidersMode = LIB.GetValue("cl_sligwolf_addons_slider_render_mode")

		if showSlidersMode == LIB.ENUM_SLIDER_RENDER_MODE_DISABLED then
			return showSlidersMode
		end

		if getToolMode() == CONSTANTS.toolRubatsEasyInspector then
			return LIB.ENUM_SLIDER_RENDER_MODE_ALWAYS
		end

		return showSlidersMode
	end
end

local function pollChangeCallbacks()
	for convarName, convarCallbacks in pairs(g_callbacks) do
		for identifier, convarCallback in pairs(convarCallbacks) do
			local convar = convarCallback.convar

			if not convar then
				convar = GetConVar(convarName)
				convarCallback.convar = convar

				if not convar then
					continue
				end
			end

			local oldValue = convarCallback.oldValue
			local newValue = convar:GetString() or ""

			local modifier = g_varModifier[convarName]
			if modifier then
				newValue = modifier(newValue)
			end

			if oldValue and newValue == oldValue then
				continue
			end

			convarCallback.callback(newValue, convarName)
			convarCallback.oldValue = newValue
		end
	end
end

local function doDelayedThink()
	pollChangeCallbacks()

	if SERVER then
		return
	end

	g_sliderRenderMode = cl_calcSliderRenderMode()
end

function LIB.Load()
	LIBDebug = SligWolf_Addons.Debug
	LIBUtil = SligWolf_Addons.Util

	local LIBHook = SligWolf_Addons.Hook

	LIBHook.Add("Think", "ConvarsUpdate", function()
		local now = RealTime()

		if not g_nextThink or g_nextThink < now then
			doDelayedThink()
			g_nextThink = now + 1 + math.random()
		end
	end)
end

return true

