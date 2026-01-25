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

local LIBUtil = nil

local g_nameprefix = "SLIGWOLF_ADDONS_Timer_"
local g_time_min = engine.TickInterval() / 2
local g_time_max = 3600

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
	delay = math.max(delay, g_time_min)

	if delay > g_time_max then
		error(string.format("Can not queue timers longer than %d sec, got run time %d sec.", g_time_max, delay))
		return
	end

	timer.Remove(name)
	timer.Create(name, delay, repetitions, func)
end

function LIB.Once(identifier, delay, func)
	if not isfunction(func) then return end
	local name = getName(identifier)

	delay = tonumber(delay or 0)
	delay = math.max(delay, g_time_min)

	if delay > g_time_max then
		error(string.format("Can not queue timers longer than %d sec, got run time %d sec.", g_time_max, delay))
		return
	end

	timer.Remove(name)
	timer.Create(name, delay, 1, function()
		timer.Remove(name)
		func()
	end)
end

function LIB.Until(identifier, delay, func, maxRepeats, maxTime)
	if not isfunction(func) then return end
	local name = getName(identifier)

	delay = tonumber(delay or 0)
	delay = math.max(delay, g_time_min)

	if delay > g_time_max then
		error(string.format("Can not queue timers longer than %d sec, got run time %d sec.", g_time_max, delay))
		return
	end

	maxRepeats = tonumber(maxRepeats or 0)
	maxRepeats = math.max(maxRepeats, 0)

	maxTime = tonumber(maxTime or 0)
	if maxTime <= 0 then
		maxTime = g_time_max
	end

	if maxTime > g_time_max then
		error(string.format("This timer would have a risk to live longer than %d sec, got estimated max run time %d sec.", g_time_max, maxTime))
		return
	end

	delay = tonumber(delay or 0)
	delay = math.max(delay, g_time_min)

	local removeNextTick = false
	local repeatsLeft = maxRepeats
	local timeout = CurTime() + maxTime

	timer.Remove(name)
	timer.Create(name, delay, 0, function()
		if removeNextTick then
			timer.Remove(name)
			return
		end

		local now = CurTime()
		if now > timeout then
			removeNextTick = false
			timer.Remove(name)

			func(false)
			return
		end

		if maxRepeats > 0 then
			if repeatsLeft <= 0 then
				removeNextTick = false
				timer.Remove(name)

				func(false)
				return
			end

			repeatsLeft = repeatsLeft - 1
		end

		local endtimer = func(true)

		if endtimer then
			removeNextTick = true
		end
	end)
end

function LIB.NextFrame(identifier, func)
	LIB.Once(identifier, g_time_min, func)
end

function LIB.Remove(identifier)
	local name = getName(identifier)
	timer.Remove(name)
end

function LIB.Simple(delay, func)
	-- timer.Simple is unrelaible to always run next tick, see this:
	-- https://github.com/Facepunch/garrysmod-issues/issues/6668

	local identifier = LIBUtil.UniqueString("_SimpleThrowAwayTimer_UniqueId")
	LIB.Once(identifier, delay, func)
end

function LIB.SimpleNextFrame(func)
	LIB.Simple(g_time_min, func)
end

function LIB.Load()
	LIBUtil = SligWolf_Addons.Util
end

return true

