AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SLIGWOLF_ADDON then
	SligWolf_Addons.AutoLoadAddon(function() end)
	return
end

local LIBTimer = SligWolf_Addons.Timer

local function getTimerCallbackForAddon(addon, identifier, func)
	return function()
		if not addon.Loaded then
			if not addon.TimerRemove then
				return true
			end

			addon:TimerRemove(identifier)
			return true
		end

		return func(addon)
	end
end

function SLIGWOLF_ADDON:TimerInterval(identifier, delay, repetitions, func)
	identifier = LIBTimer.GetAddonTimerName(self, identifier)
	if not identifier then
		return
	end

	func = getTimerCallbackForAddon(self, identifier, func)

	return LIBTimer.Interval(identifier, delay, repetitions, func)
end

function SLIGWOLF_ADDON:TimerOnce(identifier, delay, func)
	identifier = LIBTimer.GetAddonTimerName(self, identifier)
	if not identifier then
		return
	end

	func = getTimerCallbackForAddon(self, identifier, func)

	return LIBTimer.Once(identifier, delay, func)
end

function SLIGWOLF_ADDON:TimerUntil(identifier, delay, func)
	identifier = LIBTimer.GetAddonTimerName(self, identifier)
	if not identifier then
		return
	end

	func = getTimerCallbackForAddon(self, identifier, func)

	return LIBTimer.Until(identifier, delay, func)
end

function SLIGWOLF_ADDON:TimerNextFrame(identifier, func)
	identifier = LIBTimer.GetAddonTimerName(self, identifier)
	if not identifier then
		return
	end

	func = getTimerCallbackForAddon(self, identifier, func)

	return LIBTimer.NextFrame(identifier, func)
end

function SLIGWOLF_ADDON:TimerRemove(identifier)
	identifier = LIBTimer.GetAddonTimerName(self, identifier)
	if not identifier then
		return
	end

	func = getTimerCallbackForAddon(self, identifier, func)

	return LIBTimer.Remove(identifier)
end

local function getTimerCallbackForEntity(addon, ent, identifier, func)
	return function()
		if not IsValid(ent) then
			if not addon.TimerRemove then
				return true
			end

			addon:TimerRemove(identifier)
			return true
		end

		return func(ent)
	end
end

function SLIGWOLF_ADDON:EntityTimerInterval(ent, identifier, delay, repetitions, func)
	identifier = LIBTimer.GetEntityTimerName(ent, identifier)
	if not identifier then
		return
	end

	func = getTimerCallbackForEntity(self, ent, identifier, func)

	return self:TimerInterval(identifier, delay, repetitions, func)
end

function SLIGWOLF_ADDON:EntityTimerOnce(ent, identifier, delay, func)
	identifier = LIBTimer.GetEntityTimerName(ent, identifier)
	if not identifier then
		return
	end

	func = getTimerCallbackForEntity(self, ent, identifier, func)

	return self:TimerOnce(identifier, delay, func)
end

function SLIGWOLF_ADDON:EntityTimerUntil(ent, identifier, delay, func)
	identifier = LIBTimer.GetEntityTimerName(ent, identifier)
	if not identifier then
		return
	end

	func = getTimerCallbackForEntity(self, ent, identifier, func)

	return self:TimerUntil(identifier, delay, func)
end

function SLIGWOLF_ADDON:EntityTimerNextFrame(ent, identifier, func)
	identifier = LIBTimer.GetEntityTimerName(ent, identifier)
	if not identifier then
		return
	end

	func = getTimerCallbackForEntity(self, ent, identifier, func)

	return self:TimerNextFrame(identifier, func)
end

function SLIGWOLF_ADDON:EntityTimerRemove(ent, identifier)
	identifier = LIBTimer.GetEntityTimerName(ent, identifier)
	if not identifier then
		return
	end

	return self:TimerRemove(identifier)
end

return true

