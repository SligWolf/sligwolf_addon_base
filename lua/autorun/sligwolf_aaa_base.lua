-- It is named "sligwolf_aaa_base" so it loads first among all sligwolf addons.
-- https://wiki.facepunch.com/gmod/Lua_Loading_Order

local g_reloadAddonTimerName = "SLIGWOLF_ADDONS_Timer_ReloadAddons"

local init = nil

local function unloadSublib(sublib)
	if not istable(sublib) then
		return
	end

	if not sublib.__isLib then
		return
	end

	local unload = sublib.Unload
	if isfunction(unload) then
		xpcall(unload, ErrorNoHaltWithStack, sublib)
		sublib.Unload = nil
	end
end

local function emptySublib(sublib)
	if not istable(sublib) then
		return
	end

	if not sublib.__isLib then
		return
	end

	unloadSublib(sublib)

	-- Sublib, e.g. SligWolf_Addons.Timer
	for sublibKey, sublibValue in pairs(sublib) do
		-- Sublib values, e.g. SligWolf_Addons.Timer.NextFrame

		if istable(sublibValue) then
			-- keep tables in case we want to pass them on
			continue
		end

		if sublibKey == "__isLib" then
			continue
		end

		sublib[sublibKey] = nil
	end
end

local function emptyLib(lib)
	-- Mainlib, e.g. SligWolf_Addons

	for key, sublib in pairs(lib) do
		unloadSublib(sublib)
	end

	for key, sublib in pairs(lib) do
		if istable(sublib) then
			emptySublib(sublib)
			continue
		end

		lib[key] = nil
	end
end

local function initLibGlobal()
	timer.Remove(g_reloadAddonTimerName)

	local lib = _G.SligWolf_Addons or {}
	_G.SligWolf_Addons = lib

	local oldIsManuallyReloading = lib.IsManuallyReloading or false

	emptyLib(lib)

	lib.IsManuallyReloading = oldIsManuallyReloading

	lib.Loaded = nil
	lib.Loading = true

	lib.NewLib = function(thislib, name)
		name = tostring(name or "")

		local sublib = thislib[name] or {}
		thislib[name] = sublib

		sublib.__isLib = true

		emptySublib(sublib)

		if thislib.ReloadAddonSystem then
			thislib:ReloadAddonSystem()
		end

		return sublib
	end

	lib.ReloadAddonSystem = function(thislib, force)
		if thislib.Loading and not force then
			-- already loading, this prevents recursive reloads
			return false
		end

		local isManuallyReloading = thislib.IsManuallyReloading or false

		print("ReloadAddonSystem 1")

		-- debounce rapid reload calls
		timer.Remove(g_reloadAddonTimerName)
		timer.Create(g_reloadAddonTimerName, 0.25, 1, function()
			timer.Remove(g_reloadAddonTimerName)

			print("ReloadAddonSystem 2")

			if thislib.Loading and not force then
				return
			end

			if not init then
				return
			end

			thislib.IsManuallyReloading = isManuallyReloading
			init()
			thislib.IsManuallyReloading = false
		end)

		-- we are reloading, if we return true here, the caller should return immediately
		return true
	end
end

init = function()
	initLibGlobal()

	local status, loaded = xpcall(function()
		AddCSLuaFile("sligwolf_addons/main.lua")
		return include("sligwolf_addons/main.lua")
	end, ErrorNoHaltWithStack)

	if not _G.SligWolf_Addons then
		initLibGlobal()
	end

	local SligWolf_Addons = _G.SligWolf_Addons

	SligWolf_Addons.Loading = nil
	SligWolf_Addons.IsManuallyReloading = false

	if not status then
		SligWolf_Addons.Loaded = nil
	end

	if not loaded then
		SligWolf_Addons.Loaded = nil
	end
end

init()

