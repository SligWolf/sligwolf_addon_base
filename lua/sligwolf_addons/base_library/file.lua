local SligWolf_Addons = _G.SligWolf_Addons
if not SligWolf_Addons then
	return
end

local LIB = SligWolf_Addons:NewLib("File")

local g_dataDirectoryMain = "sligwolf_addons/base"
local g_dataDirectoryAddons = "sligwolf_addons"

local g_dataStaticDirectoryMain = "data_static/" .. g_dataDirectoryMain
local g_dataStaticDirectoryAddons = "data_static/" .. g_dataDirectoryAddons

local g_dataRealm = "DATA"
local g_dataStaticRealm = "GAME"

local g_maxLogSize = 128 * 1024 * 1024 -- 128 MB

LIB.ADDON_NONE = ""
LIB.REALM_DATA = false
LIB.REALM_DATA_STATIC = true

local function sanitizePath(path)
	path = string.lower(path)
	path = string.Trim(path)

	-- Prevent navigation (../)
	path = string.gsub(path, "%.%.%/" , "")
	path = string.gsub(path, "%.%/" , "")

	-- Keep the Path clean from any weird chars
	path = string.gsub(path, "%s+" , "_")
	path = string.gsub(path, "%c+" , "")
	path = string.gsub(path, "[^%w_%-%.%/]" , "-")

	return path
end

local function joinAndNormalizePathsArray(paths)
	local tmp = {}

	for _, path in ipairs(paths) do
		path = tostring(path or "")

		if path == "" then
			continue
		end

		if path == "." then
			continue
		end

		if path == ".." then
			continue
		end

		local subpaths = string.Explode("[%/%\\]+", path, true)

		for _, subpath in ipairs(subpaths) do
			subpath = tostring(subpath or "")

			if subpath == "" then
				continue
			end

			if path == "." then
				continue
			end

			if path == ".." then
				continue
			end

			table.insert(tmp, subpath)
		end
	end

	local path = table.concat(tmp, "/")
	path = sanitizePath(path)

	return path
end

local function joinAndNormalizePaths(...)
	return joinAndNormalizePathsArray({...})
end

function LIB.GetAbsolutePath(fileName, addon, isStatic)
	fileName = tostring(fileName or "")

	if fileName == "" then
		error("missing fileName")
		return
	end

	if istable(addon) and addon.Addonname then
		addon = addon.Addonname
	end

	isStatic = isStatic or LIB.REALM_DATA

	addon = tostring(addon or "")

	if addon == "" then
		addon = LIB.ADDON_NONE
	end

	if isStatic then
		if addon == LIB.ADDON_NONE then
			return joinAndNormalizePaths(g_dataStaticDirectoryMain, fileName), g_dataStaticRealm
		else
			return joinAndNormalizePaths(g_dataStaticDirectoryAddons, addon, fileName), g_dataStaticRealm
		end
	end

	if addon == LIB.ADDON_NONE then
		return joinAndNormalizePaths(g_dataDirectoryMain, fileName), g_dataRealm
	else
		return joinAndNormalizePaths(g_dataDirectoryAddons, addon, fileName), g_dataRealm
	end
end

function LIB.Exists(fileName, addon, isStatic)
	local thisFileName, realm = LIB.GetAbsolutePath(fileName, addon, isStatic)
	return file.Exists(thisFileName, realm)
end

function LIB.IsDir(path, addon, isStatic)
	local thisPath, realm = LIB.GetAbsolutePath(path, addon, isStatic)
	return file.IsDir(thisPath, realm)
end

function LIB.CreateDir(path, addon)
	path = LIB.GetAbsolutePath(path, addon)

	if not file.IsDir(path, g_dataRealm) then
		file.CreateDir(path, g_dataRealm)

		if not file.IsDir(path, g_dataRealm) then
			return false
		end
	end

	return true
end

function LIB.Open(fileName, fileMode, addon, isStatic)
	local thisFileName, realm = LIB.GetAbsolutePath(fileName, addon, isStatic)
	return file.Open(thisFileName, fileMode, realm)
end

function LIB.Read(fileName, addon, isStatic)
	local thisFileName, realm = LIB.GetAbsolutePath(fileName, addon, isStatic)

	if not file.Exists(thisFileName, realm) then
		return nil
	end

	return file.Read(thisFileName, realm)
end

function LIB.Write(fileName, fileContent, addon)
	fileContent = fileContent or ""
	fileName = LIB.GetAbsolutePath(fileName, addon)

	if file.Exists(fileName, g_dataRealm) then
		file.Delete(fileName, g_dataRealm)

		if file.Exists(fileName, g_dataRealm) then
			return false
		end
	else
		local path = string.GetPathFromFilename(fileName)

		if not file.IsDir(path, g_dataRealm) then
			file.CreateDir(path, g_dataRealm)

			if not file.IsDir(path, g_dataRealm) then
				return false
			end
		end
	end

	local ok = file.Write(fileName, fileContent)
	if not ok then
		return false
	end

	if not file.Exists(fileName, g_dataRealm) then
		return false
	end

	return true
end

function LIB.Append(fileName, fileContent, addon)
	fileContent = fileContent or ""
	fileName = LIB.GetAbsolutePath(fileName, addon)

	if not file.Exists(fileName, g_dataRealm) then
		local path = string.GetPathFromFilename(fileName)

		if not file.IsDir(path, g_dataRealm) then
			file.CreateDir(path, g_dataRealm)

			if not file.IsDir(path, g_dataRealm) then
				return false
			end
		end
	end

	local ok = file.Append(fileName, fileContent)
	if not ok then
		return false
	end

	if not file.Exists(fileName, g_dataRealm) then
		return false
	end

	return true
end

function LIB.Delete(fileName, addon)
	fileName = LIB.GetAbsolutePath(fileName, addon)

	if file.Exists(fileName, g_dataRealm) then
		file.Delete(fileName, g_dataRealm)

		if file.Exists(fileName, g_dataRealm) then
			return false
		end
	end

	return true
end

function LIB.Log(fileName, fileContent, addon)
	fileContent = fileContent or ""
	fileName = LIB.GetAbsolutePath(fileName, addon)

	if file.Exists(fileName, g_dataRealm) then
		if file.Size(fileName, g_dataRealm) >= g_maxLogSize then
			-- log auto clean
			file.Delete(fileName, g_dataRealm)
		end
	else
		local path = string.GetPathFromFilename(fileName)

		if not file.IsDir(path, g_dataRealm) then
			file.CreateDir(path, g_dataRealm)

			if not file.IsDir(path, g_dataRealm) then
				return false
			end
		end
	end

	local ok = file.Append(fileName, fileContent)
	if not ok then
		return false
	end

	if not file.Exists(fileName, g_dataRealm) then
		return false
	end

	return true
end

return true

