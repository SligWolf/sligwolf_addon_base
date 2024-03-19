AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SLIGWOLF_ADDON then
	SligWolf_Addons.AutoLoadAddon(function() end)
	return
end

local LIBTrackassambler = SligWolf_Addons.Trackassambler
local LIBPrint = SligWolf_Addons.Print

local function varToExportString(var)
	if not var then
		return nil
	end

	if var == "" then
		return nil
	end

	if isvector(var) then
		return string.format("%f,%f,%f", var.x, var.y, var.z)
	end

	if isangle(var) then
		return string.format("%f,%f,%f", var.p, var.y, var.r)
	end

	return tostring(var)
end

local function varCategoryToArray(var)
	if not var then
		return nil
	end

	if var == "" then
		return nil
	end

	if not istable(var) then
		var = tostring(var)
		var = string.Explode("/", var, false) or {}
	end

	if table.IsEmpty(var) then
		var = nil
	end

	return var
end

local ITEMMETA = {}

function ITEMMETA:GetName()
	return self.name
end

function ITEMMETA:GetModel()
	return self.model
end

function ITEMMETA:GetClass()
	return self.class
end

function ITEMMETA:GetCategory()
	return self.category
end

function ITEMMETA:AddAttachmentPoint(attachmentPoint, ...)
	if attachmentPoint == nil then
		error("attachmentPoint missing!")
		return
	end

	if not istable(attachmentPoint) then
		attachmentPoint = {attachmentPoint, ...}
	end

	local origin = varToExportString(attachmentPoint.origin or attachmentPoint[1])
	local angle = varToExportString(attachmentPoint.angle or attachmentPoint[2])
	local point = varToExportString(attachmentPoint.point or attachmentPoint[3])

	if not origin then
		error("missing origin!")
		return
	end

	local attachmentPoint = {
		origin = origin,
		angle = angle,
		point = point,
	}

	table.insert(self.attachmentPoints, attachmentPoint)
end

function ITEMMETA:GetAttachmentPoints()
	return self.attachmentPoints
end

ITEMMETA.__index = ITEMMETA

local g_taAddon = nil
local g_taType = nil
local g_taPrefix = nil

local g_taError = function(message)
	LIBPrint.Print("%s", message)
end

local g_taSettings = {}

SLIGWOLF_ADDON.TrackAssamblerSettings = g_taSettings
SLIGWOLF_ADDON.TrackAssamblerPieces = SLIGWOLF_ADDON.TrackAssamblerPiece or {}

function SLIGWOLF_ADDON:AddTrackAssamblerItem(model, name, category, class, attachmentPoints)
	model = tostring(model or "")
	name = tostring(name or "")
	class = tostring(class or "")

	if model == "" then
		self:Error("Empty model!")
		return
	end

	if name == "" then
		self:Error("Empty name!")
		return
	end

	if class == "" then
		class = nil
	end

	category = varCategoryToArray(category)

	local item = {}

	item.model = model
	item.name = name
	item.class = class
	item.category = category
	item.attachmentPoints = {}

	setmetatable(item, ITEMMETA)

	self.TrackAssamblerPieces[model] = item

	return item
end

function SLIGWOLF_ADDON:GetTrackAssamblerItem(model)
	model = tostring(model or "")

	if model == "" then
		self:Error("Empty model!")
		return
	end

	local item = self.TrackAssamblerPieces[model]

	if not item then
		return nil
	end

	return item
end

--[[
* Description of the export format from TrackAssemblyTool as from docs:
*
* TYPE   > This string is the name of the type your stuff will reside in the panel.
*          Disabling this, makes it use the value of the /DEFAULT_TYPE/ variable.
*          If it is empty uses the string /TYPE/, so make sure you fill this.
* NAME   > This is the name of your track piece. Put /#/ here to be auto-generated from
*          the model ( from the last slash to the file extension ).
* LINEID > This is the ID of the point that can be selected for building. They must be
*          sequential and mandatory. If provided, the ID must the same as the row index under
*          a given model key. Disabling this, makes it use the the index of the current line.
*          Use that to swap the active points around by only moving the desired row up or down.
*          For the example table definition below, the line ID in the database will be the same.
* POINT  > This is the local position vector that TA searches and selects the related
*          ORIGIN for. An empty or disabled string is treated as taking the ORIGIN.
*          Disabling this using the disable event makes it hidden when the active point is searched for
* ORIGIN > This is the origin relative to which the next track piece position is calculated
*          An empty string is treated as {0,0,0}. Disabling this also makes it use {0,0,0}
*          You can also fill it with attachment event /!/ followed by your attachment name. It's mandatory
* ANGLE  > This is the angle relative to which the forward and up vectors are calculated.
*          An empty string is treated as {0,0,0}. Disabling this also makes it use {0,0,0}
*          You can also fill it with attachment event /!/ followed by your attachment name. It's mandatory
* CLASS  > This string is populated up when your entity class is not /prop_physics/ but something else
*          used by ents.Create of the gmod ents API library. Keep this empty if your stuff is a normal prop.
--]]

local g_gsMissDB = nil
local g_asmlib = nil

function SLIGWOLF_ADDON:ExportTrackAssamblerPiece(modelOrItem)
	local item = modelOrItem

	if not istable(item) then
		item = self:GetTrackAssamblerItem(item)

		if not istable(item) then
			self:Error("No piece data found for model: %s", tostring(modelOrItem))
			return
		end
	end

	if g_asmlib == nil then
		g_asmlib = LIBTrackassambler.GetLib()

		if not g_asmlib then
			self:Error("TrackAssemblyTool was not loaded!")
			return
		end
	end

	if g_gsMissDB == nil then
		g_gsMissDB = g_asmlib.GetOpVar("MISS_NOSQL")
	end

	if not g_taType then
		self:Error("Bad g_taType!")
		return
	end

	local name = item:GetName()
	local class = item:GetClass() or g_gsMissDB
	local attachmentPoints = item:GetAttachmentPoints()

	local piece = {}

	for lineid, attachmentPoint in ipairs(attachmentPoints) do
		local origin = attachmentPoint.origin or g_gsMissDB
		local angle = attachmentPoint.angle or g_gsMissDB
		local point = attachmentPoint.point or g_gsMissDB

		local pieceData = {
			g_taType,  -- TYPE
			name,      -- NAME
			lineid,    -- LINEID
			point,     -- POINT (vector or none)
			origin,    -- ORIGIN (vector or attachment)
			angle,     -- ANGLE (angle, attachment or none)
			class      -- CLASS
		}

		table.insert(piece, pieceData)
	end

	return piece
end

function SLIGWOLF_ADDON:ExportTrackAssamblerPieceCategory(modelOrItem)
	local item = modelOrItem

	if not istable(item) then
		item = self:GetTrackAssamblerItem(item)

		if not istable(item) then
			return nil
		end
	end

	return item:GetCategory()
end

function SLIGWOLF_ADDON:ExportTrackAssamblerPieces()
	local pieces = {}

	for model, item in pairs(self.TrackAssamblerPieces) do
		local piece = self:ExportTrackAssamblerPiece(item)

		pieces[model] = piece
	end

	return pieces
end

function SLIGWOLF_ADDON:ExportTrackAssamblerPieceCategoryCode()
	-- This code needs to be tiny
	local code = [[
		function(m)
			local s, c;

			s = _G.SligWolf_Addons;
			c = s and s.CallFunctionOnAddon("%s", "ExportTrackAssamblerPieceCategory", m);

			return c;
		end
	]]

	code = string.format(code, self.Addonname)
	code = string.gsub(code, "%s+", " ")
	code = string.Trim(code)
	code = code .. "\r\n"

	return code
end

function SLIGWOLF_ADDON:ExportTrackAssamblerCategories()
	if not g_taType then
		self:Error("Bad g_taType!")
		return
	end

	local categories = {}

	categories[g_taType] = {
		Txt = self:ExportTrackAssamblerPieceCategoryCode()
	}

	return categories
end

function SLIGWOLF_ADDON:AutoIncludeTrackAssamblerContent()
	if not self:LuaExists("trackassambler.lua") then
		return
	end

	SligWolf_Addons.AddCSLuaFile("sligwolf_addons/base/trackasmexport.lua")
	self:AddCSLuaFile("trackassambler.lua")

	self:TimerNextFrame("AutoIncludeTrackAssamblerContent", function()
		 -- mare sure the track assambler tool is loaded first
		if not LIBTrackassambler.Exist() then
			return
		end

		g_taAddon = self:GetNiceNameWithAuthor()
		g_taType = g_taAddon
		g_taPrefix = g_taAddon:gsub("[^%w]", "_")

		g_taSettings.Addon = g_taAddon
		g_taSettings.Type = g_taType
		g_taSettings.Error = g_taError
		g_taSettings.Prefix = g_taPrefix

		local TMP_SLIGWOLF_ADDON = SLIGWOLF_ADDON
		SLIGWOLF_ADDON = self

		self:LuaInclude("trackassambler.lua")
		SligWolf_Addons.Include("sligwolf_addons/base/trackasmexport.lua")

		SLIGWOLF_ADDON = TMP_SLIGWOLF_ADDON
	end)
end

return true

