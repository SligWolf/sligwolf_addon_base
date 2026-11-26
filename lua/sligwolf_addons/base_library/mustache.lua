local SligWolf_Addons = _G.SligWolf_Addons
if not SligWolf_Addons then
	return
end

local LIB = SligWolf_Addons:NewLib("Mustache")

local LIBPrint = SligWolf_Addons.Print

-- This library uses a thirdparty library called Lustache, by Olivine-Labs.
-- https://github.com/Olivine-Labs/lustache

if SERVER then
	SligWolf_Addons.AddCSLuaFile("sligwolf_addons/thirdparty/lustache/lustache.lua")
	SligWolf_Addons.AddCSLuaFile("sligwolf_addons/thirdparty/lustache/context.lua")
	SligWolf_Addons.AddCSLuaFile("sligwolf_addons/thirdparty/lustache/renderer.lua")
	SligWolf_Addons.AddCSLuaFile("sligwolf_addons/thirdparty/lustache/scanner.lua")
end

local g_libPaths = {
	["lustache.scanner"] = "sligwolf_addons/thirdparty/lustache/scanner.lua",
	["lustache.context"] = "sligwolf_addons/thirdparty/lustache/context.lua",
	["lustache.renderer"] = "sligwolf_addons/thirdparty/lustache/renderer.lua",
	["lustache"] = "sligwolf_addons/thirdparty/lustache/lustache.lua",
}

local g_libCache = {}

function LIB.Require(name)
	if g_libCache[name] then
		return g_libCache[name]
	end

	local path = g_libPaths[name]
	if not path then
		LIBPrint.Error("Invalid module '%s'.", name)
		return nil
	end

	g_libCache[name] = nil

	local mod = SligWolf_Addons.IncludeSimple(path)

	if not mod then
		LIBPrint.Error("Could not load module '%s'.", name)
		return nil
	end

	g_libCache[name] = mod
	return mod
end

function LIB.Render(template, view, partials)
	template = tostring(template or "")

	if template == "" then
		return ""
	end

	local lustache = LIB.Require("lustache")

	local output = lustache:render(template, view, partials)
	lustache.partials = nil

	return output
end

function LIB.ClearCache()
	local lustache = LIB.Require("lustache")
	lustache.renderer:clear_cache()
end

function LIB.Load()
	LIBPrint = SligWolf_Addons.Print

	LIB.Require("lustache")
end

return true

