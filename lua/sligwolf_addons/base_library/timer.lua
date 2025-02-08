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

function LIB.GetEntityTimerName(ent, identifier)
	if not IsValid(ent) then return nil end

	identifier = ent:GetCreationID() .. "_" .. tostring(identifier or "")
	return identifier
end

function LIB.GetAddonTimerName(addon, identifier)
	local id = addon.Addonname
	if not id then
		return nil
	end

	identifier = id .. "_" .. tostring(identifier or "")
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

function LIB.Until(identifier, delay, func, maxRepeats)
	if not isfunction(func) then return end
	local name = getName(identifier)

	delay = tonumber(delay or 0)
	delay = math.max(delay, g_epsilon)

	if maxRepeats then
		maxRepeats = math.max(maxRepeats, 1)
	end

	local removeNextTick = false

	timer.Remove(name)
	timer.Create(name, delay, 0, function()
		if removeNextTick then
			timer.Remove(name)
			return
		end

		if maxRepeats then
			if maxRepeats <= 0 then
				removeNextTick = true
				timer.Remove(name)
				return
			end

			maxRepeats = maxRepeats - 1
		end

		local endtimer = func()

		if endtimer then
			removeNextTick = true
		end
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

