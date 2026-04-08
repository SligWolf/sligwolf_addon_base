AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SLIGWOLF_ADDON then
	SligWolf_Addons:ReloadAddonSystem()
	return
end

local CONSTANTS = SligWolf_Addons.Constants

local LIBEntities = SligWolf_Addons.Entities

local g_skinClasses = {}

function SLIGWOLF_ADDON:SkinAddClass(class, partsData)
	class = tostring(class or "")
	if class == "" then
		return
	end

	local skinClass = g_skinClasses[class] or {}
	g_skinClasses[class] = skinClass

	local parts = {}
	skinClass.parts = parts
	skinClass.themes = {}

	for partPath, partProperties in pairs(partsData) do
		parts[partPath] = {
			path = partPath,
			color = partProperties.color or CONSTANTS.colorDefault,
			skin = partProperties.skin or 0,
			bodygroups = partProperties.bodygroups or {},
		}
	end
end

function SLIGWOLF_ADDON:SkinGetClass(class)
	class = tostring(class or "")
	if class == "" then
		return nil
	end

	return g_skinClasses[class]
end

function SLIGWOLF_ADDON:SkinCopy(superparent, class)
	if not IsValid(superparent) then
		return
	end

	local skinClass = self:SkinGetClass(class)
	if not skinClass then
		return
	end

	local parts = skinClass.parts
	local skinData = {}

	for _, partProperties in pairs(parts) do
		local path = partProperties.path

		local ent = nil

		if path ~= "" then
			ent = superparent
		else
			ent = LIBEntities.GetChildFromPath(superparent, path)
		end

		if not IsValid(ent) then
			skinData[path] = {
				color = partProperties.color,
				skin = partProperties.skin,
				--bodygroups = partProperties.bodygroups,
			}

			continue
		end

		skinData[path] = {
			color = ent:GetColor(),
			skin = ent:GetSkin(),
			--bodygroups = ent:GetBodyGroups(),
		}
	end

	return skinData
end

function SLIGWOLF_ADDON:SkinPaste(superparent, class, skinData)
	if not IsValid(superparent) then
		return
	end

	local skinClass = self:SkinGetClass(class)
	if not skinClass then
		return
	end

	local parts = skinClass.parts

	for _, partProperties in pairs(parts) do
		local path = partProperties.path

		local defaultColor = partProperties.color
		local defaultSkin = partProperties.skin
		--local defaultBodygroups = partProperties.bodygroups

		local skinDataItem = skinData[path] or {}

		local itemColor = skinDataItem.color or defaultColor
		local itemSkin = skinDataItem.skin or defaultSkin
		--local itemBodygroups = skinDataItem.bodygroups or defaultBodygroups

		local ent = nil

		if path ~= "" then
			ent = superparent
		else
			ent = LIBEntities.GetChildFromPath(superparent, path)
		end

		if not IsValid(ent) then
			continue
		end

		ent:SetColor(itemColor)
		ent:SetSkin(itemSkin)

		-- for bodygroupName, bodygroup in pairs(itemBodygroups) do
		-- 	LIBEntities.SetBodygroupSubId(ent, bodygroup.index, bodygroup.mesh)
		-- end
	end
end

function SLIGWOLF_ADDON:SkinAddTheme(class, themeName, themeData)
	local skinClass = self:SkinGetClass(class)
	if not skinClass then
		return
	end

	local themes = class.themes
	if not themes then
		return
	end

	themeName = tostring(themeName or "")
	if themeName == "" then
		return nil
	end

	themes[themeName] = themeData
end

return true

