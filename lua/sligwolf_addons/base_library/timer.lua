AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Timer = SligWolf_Addons.Timer or {}
table.Empty(SligWolf_Addons.Timer)

local LIB = SligWolf_Addons.Timer

local g_nameprefix = "SLIGWOLF_ADDONS_Timer_"
local g_epsilon = 0.001

local function getName(identifier)
	identifier = g_nameprefix .. tostring(identifier or "")
	return identifier
end

function LIB.Interval(identifier, delay, repetitions, func)
	if not isfunction(func) then return end
	local name = getName(identifier)

	repetitions = tonumber(repetitions or 0)
	delay = tonumber(delay or 0)
	delay = math.max(delay, g_epsilon)

	timer.Remove(name)
	timer.Create(name, delay, repetitions, func)
end

function LIB.Once(identifier, delay, func)
	if not isfunction(func) then return end
	local name = getName(identifier)

	delay = tonumber(delay or 0)
	delay = math.max(delay, g_epsilon)

	timer.Remove(name)
	timer.Create(name, delay, 1, function()
		timer.Remove(name)
		func()
	end)
end

function LIB.Until(identifier, delay, func)
	if not isfunction(func) then return end
	local name = getName(identifier)

	delay = tonumber(delay or 0)
	delay = math.max(delay, g_epsilon)

	timer.Remove(name)
	timer.Create(name, delay, 0, function()
		local endtimer = func()
		if not endtimer then
			return
		end

		timer.Remove(name)
	end)
end

function LIB.NextFrame(identifier, func)
	LIB.Once(identifier, g_epsilon, func)
end

function LIB.Remove(identifier)
	local name = getName(identifier)
	timer.Remove(name)
end

function LIB.Simple(delay, func)
	timer.Simple(delay, func)
end

function LIB.SimpleNextFrame(func)
	LIB.Simple(g_epsilon, func)
end

return true

