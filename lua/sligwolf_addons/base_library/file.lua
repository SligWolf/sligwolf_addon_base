AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.File = SligWolf_Addons.File or {}
table.Empty(SligWolf_Addons.File)

local LIB = SligWolf_Addons.File

local g_dataDirectoryMain = "sligwolf_addons/common"
local g_dataDirectoryAddons = "sligwolf_addons/addon"

local g_data = "DATA"

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

function LIB.GetAbsolutePath(fileName, addon)
	fileName = tostring(fileName or "")

	if fileName == "" then
		error("missing fileName")
		return
	end

	if istable(addon) and addon.Addonname then
		addon = addon.Addonname
	end

	addon = tostring(addon or "")

	if addon == "" then
		return joinAndNormalizePaths(g_dataDirectoryMain, fileName)
	else
		return joinAndNormalizePaths(g_dataDirectoryAddons, addon, fileName)
	end
end

function LIB.Exists(fileName, addon)
	fileName = LIB.GetAbsolutePath(fileName, addon)
	return file.Exists(fileName, g_data)
end

function LIB.IsDir(path, addon)
	path = LIB.GetAbsolutePath(path, addon)
	return file.IsDir(path, g_data)
end

function LIB.CreateDir(path, addon)
	path = LIB.GetAbsolutePath(path, addon)

	if not file.IsDir(path, g_data) then
		file.CreateDir(path, g_data)

		if not file.IsDir(path, g_data) then
			return false
		end
	end

	return true
end

function LIB.Open(fileName, fileMode, addon)
	fileName = LIB.GetAbsolutePath(fileName, addon)
	return file.Open(fileName, fileMode, g_data)
end

function LIB.Read(fileName, addon)
	fileName = LIB.GetAbsolutePath(fileName, addon)

	if not file.Exists(fileName, g_data) then
		return nil
	end

	return file.Read(fileName, g_data)
end

function LIB.Write(fileName, fileContent, addon)
	fileContent = tostring(fileContent or "")
	fileName = LIB.GetAbsolutePath(fileName, addon)

	if file.Exists(fileName, g_data) then
		file.Delete(fileName)

		if file.Exists(fileName, g_data) then
			return false
		end
	else
		local path = string.GetPathFromFilename(fileName)

		if not file.IsDir(path, g_data) then
			file.CreateDir(path, g_data)

			if not file.IsDir(path, g_data) then
				return false
			end
		end
	end

	file.Write(fileName, fileContent)

	if not file.Exists(fileName, g_data) then
		return false
	end

	return true
end

function LIB.Delete(fileName, addon)
	fileName = LIB.GetAbsolutePath(fileName, addon)

	if file.Exists(fileName, g_data) then
		file.Delete(fileName)

		if file.Exists(fileName, g_data) then
			return false
		end
	end

	return true
end

return true

