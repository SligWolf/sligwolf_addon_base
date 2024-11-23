AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Hook = SligWolf_Addons.Hook or {}
table.Empty(SligWolf_Addons.Hook)

local LIB = SligWolf_Addons.Hook

local g_namePrefixMain = "SLIGWOLF_mainHook_"
local g_namePrefixCustom = "SLIGWOLF_"
local g_hooks = {}
local g_orderCounter = 0

local function getMainHookIdentifier(eventName)
	local identifier = g_namePrefixMain .. tostring(eventName or "")
	return identifier
end

local function getCustomHookIdentifier(eventName)
	local identifier = g_namePrefixCustom .. tostring(eventName or "")
	return identifier
end

local function CallHooks(hookData, ...)
	-- Called by all hooks the SW addons add to the game, including think and tick.
	-- It is a proxy that distribute calls to all internal SW Base Addon hooks.
	-- This reduces overhead from the native hook library.

	-- Prevent error spams when the addon is not completely loaded
	if not SligWolf_Addons then return nil end
	if not SligWolf_Addons.IsLoaded then return nil end
	if not SligWolf_Addons.IsLoaded() then return nil end

	local byOrder = hookData.byOrder
	if not byOrder then
		return nil
	end

	local r1, r2, r3, r4, r5, r6, r7, r8

	for i, hookItem in ipairs(byOrder) do
		local a, b, c, d, e, f, g, h = hookItem.func(...)

		if a == nil then
			continue
		end

		r1, r2, r3, r4, r5, r6, r7, r8 = a, b, c, d, e, f, g, h
		break
	end

	if r1 == nil then
		return nil
	end

	return r1, r2, r3, r4, r5, r6, r7, r8
end

local function BuildOrder(hookData)
	hookData.byOrder = nil

	local byName = hookData.byName
	if not byName then
		return
	end

	if table.IsEmpty(byName) then
		return
	end

	local byOrder = table.ClearKeys(byName)

	table.SortByMember(byOrder, "order", true)

	hookData.byOrder = byOrder
end

function LIB.Has(eventName, identifier)
	identifier = tostring(identifier or "")
	eventName = tostring(eventName or "")

	local hookData = g_hooks[eventName]
	if not hookData then
		return false
	end

	local byName = hookData.byName
	if not byName then
		return false
	end

	if not byName[identifier] then
		return false
	end

	return true
end

function LIB.Add(eventName, identifier, func, order)
	if not isfunction(func) then return end

	identifier = tostring(identifier or "")
	eventName = tostring(eventName or "")
	order = tonumber(order or 0) or 0

	if order == 0 then
		order = 1000000 + g_orderCounter * 1000
		g_orderCounter = (g_orderCounter % 1000000) + 1
	end

	LIB.Remove(eventName, identifier)

	g_hooks[eventName] = g_hooks[eventName] or {}
	local hookData = g_hooks[eventName]

	hookData.byName = hookData.byName or {}
	local byName = hookData.byName

	byName[identifier] = {
		order = order,
		func = func,
		identifier = identifier,
	}

	BuildOrder(hookData)

	if not hookData.hasHook then
		local hookIdentifier = getMainHookIdentifier(eventName)

		hook.Remove(eventName, hookIdentifier)
		hook.Add(eventName, hookIdentifier, function(...)
			return CallHooks(hookData, ...)
		end)

		hookData.hasHook = true
	end
end

function LIB.Remove(eventName, identifier)
	identifier = tostring(identifier or "")
	eventName = tostring(eventName or "")

	local hookData = g_hooks[eventName]
	if not hookData then
		return
	end

	local byName = hookData.byName
	if not byName then
		return
	end

	byName[identifier] = nil

	BuildOrder(hookData)

	if table.IsEmpty(byName) then
		local hookIdentifier = getMainHookIdentifier(eventName)

		hook.Remove(eventName, hookIdentifier)
		hookData.hasHook = nil
	end
end

function LIB.Run(eventName, ...)
	eventName = tostring(eventName or "")
	return hook.Run(eventName, ...)
end

function LIB.AddCustom(eventName, ...)
	local eventName = getCustomHookIdentifier(eventName)
	return LIB.Add(eventName, ...)
end

function LIB.RemoveCustom(eventName, ...)
	local eventName = getCustomHookIdentifier(eventName)
	return LIB.Remove(eventName, ...)
end

function LIB.RunCustom(eventName, ...)
	local eventName = getCustomHookIdentifier(eventName)
	return LIB.Run(eventName, ...)
end

return true

