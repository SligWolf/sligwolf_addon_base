AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SLIGWOLF_ADDON then
	SligWolf_Addons.AutoLoadAddon(function() end)
	return
end

function SLIGWOLF_ADDON:GetNiceNameWithAuthor()
	local author = self.Author
	local name = self.NiceName

	if not author then
		self:Error("Missing Author!")
		return
	end

	if not name then
		self:Error("Missing NiceName!")
		return
	end

	return string.format("%s's %s", author, name)
end

function SLIGWOLF_ADDON:GetLuaPath(luafile)
	local directory = self.LuaDirectory

	luafile = tostring(luafile or "")
	luafile = string.lower(luafile or "")

	return directory .. "/" .. luafile
end

function SLIGWOLF_ADDON:LuaInclude(luafile)
	luafile = self:GetLuaPath(luafile)
	return SligWolf_Addons.Include(luafile)
end

function SLIGWOLF_ADDON:LuaIncludeSimple(luafile)
	luafile = self:GetLuaPath(luafile)
	return SligWolf_Addons.IncludeSimple(luafile)
end

function SLIGWOLF_ADDON:AddCSLuaFile(luafile)
	luafile = self:GetLuaPath(luafile)
	return SligWolf_Addons.AddCSLuaFile(luafile)
end

function SLIGWOLF_ADDON:LuaExists(luafile)
	luafile = self:GetLuaPath(luafile)
	return SligWolf_Addons.LuaExists(luafile)
end

function SLIGWOLF_ADDON:CallAddonFunctionWithAddonEnvironment(func, ...)
	local TMP_SLIGWOLF_ADDON = SLIGWOLF_ADDON
	SLIGWOLF_ADDON = self

	local status, result = self:CallAddonFunctionWithErrorNoHalt(func, ...)

	SLIGWOLF_ADDON = TMP_SLIGWOLF_ADDON

	return status, result
end

return true

