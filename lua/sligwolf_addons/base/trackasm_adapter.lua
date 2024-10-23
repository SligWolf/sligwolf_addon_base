AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SLIGWOLF_ADDON then
	SligWolf_Addons.AutoLoadAddon(function() end)
	return
end

local LIBTrackasm = SligWolf_Addons.Trackasm
local LIBPrint = SligWolf_Addons.Print

local function isAttachmentString(var)
	if not var then
		return false
	end

	if var == "" then
		return false
	end

	if var == "!" then
		return nil
	end

	if var[1] ~= "!" then
		return false
	end

	return true
end

local function toAttachmentString(var)
	if not var then
		return nil
	end

	if var == "" then
		return nil
	end

	if var == "!" then
		return nil
	end

	if isAttachmentString(var) then
		return var
	end

	return "!" .. var
end

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

local ITEM_META = {}

function ITEM_META:GetModel()
	return self.model
end

function ITEM_META:GetName()
	return self.name
end

function ITEM_META:GetClass()
	return self.class
end

function ITEM_META:GetCategory()
	return self.category
end

function ITEM_META:SetName(name)
	name = tostring(name or "")

	if name == "" then
		name = nil
	end

	self.name = name
	return self
end

function ITEM_META:SetClass(class)
	class = tostring(class or "")

	if class == "" then
		class = nil
	end

	self.class = class
	return self
end

function ITEM_META:SetCategory(category)
	category = varCategoryToArray(category)

	self.category = category
	return self
end

function ITEM_META:AddPoint(pointItem, ...)
	if not pointItem then
		error("pointItem missing!")
		return
	end

	if not istable(pointItem) then
		pointItem = {pointItem, ...}
	end

	local origin = varToExportString(pointItem.origin or pointItem[1])
	local angle = varToExportString(pointItem.angle or pointItem[2])
	local point = varToExportString(pointItem.point or pointItem[3])

	if not origin then
		error("missing origin!")
		return
	end

	local pointData = {
		origin = origin,
		angle = angle,
		point = point,
	}

	table.insert(self.points, pointData)

	return self
end

function ITEM_META:AddAttachment(originAttachment, pointAttachment)
	originAttachment = tostring(originAttachment or "")
	pointAttachment = tostring(pointAttachment or "")

	originAttachment = toAttachmentString(originAttachment)
	pointAttachment = toAttachmentString(pointAttachment)

	if not originAttachment then
		error("missing originAttachment!")
		return
	end

	if pointAttachment == originAttachment then
		pointAttachment = nil
	end

	self:AddPoint({
		origin = originAttachment,
		angle = originAttachment,
		point = pointAttachment,
	})

	return self
end

function ITEM_META:AddPoints(pointItems, ...)
	if pointItems == nil then
		error("points missing!")
		return
	end

	for i, pointItem in ipairs(pointItems) do
		self:AddPoint(pointItem)
	end

	return self
end

function ITEM_META:GetPoint(index)
	return self.points[index]
end

function ITEM_META:GetPoints()
	return self.points
end

function ITEM_META:Close()
	local model = self:GetModel()
	local points = self.points

	if not model or model == "" then
		error("Unknown model!")
		return
	end

	if not points or table.IsEmpty(points) then
		error(string.format("Empty points for model: %s", model))
		return
	end

	self.closed = true
end

function ITEM_META:IsClosed()
	return self.closed
end

ITEM_META.__index = ITEM_META

local g_taType = nil
local g_taSettings = {}

g_taSettings.Source = "SW_ADDONS"
g_taSettings.Error = function(message)
	LIBPrint.Print("%s", message)
end

SLIGWOLF_ADDON.TrackAssamblerSettings = g_taSettings
SLIGWOLF_ADDON.TrackAssamblerPieces = SLIGWOLF_ADDON.TrackAssamblerPiece or {}

function SLIGWOLF_ADDON:AddTrackAssamblerItem(model)
	model = tostring(model or "")

	if model == "" then
		self:Error("Empty model!")
		return
	end

	local item = {}

	item.model = model
	item.closed = false
	item.points = {}

	setmetatable(item, ITEM_META)

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
 * https://github.com/dvdvideo1234/TrackAssemblyTool/blob/master/data/trackassembly/set/z_autorun_%5Btrackassembly%5D.txt
 *
 * MODEL  > This string contains the path to your /*.mdl/ file. It is mandatory and
 *          taken in pairs with LINEID, it forms the unique identifier of every record.
 *          When used in /DSV/ mode ( like seen below ) it is used as a hash index.
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
 * POINT  > This is the location vector that TA searches and selects the related ORIGIN for.
 *          An empty string is treated as taking the ORIGIN when assuming player traces can hit the origin
 *          Disabling via /#/ makes it take the ORIGIN. Used to disable a point but keep original data
 *          You can also fill it with attachment event /!/ followed by your attachment name.
 * ORIGIN > This is the origin relative to which the next track piece position is calculated
 *          An empty string is treated as {0,0,0}. Disabling via /#/ also makes it use {0,0,0}
 *          You can also fill it with attachment event /!/ followed by your attachment name. It's mandatory
 * ANGLE  > This is the angle relative to which the forward and up vectors are calculated.
 *          An empty string is treated as {0,0,0}. Disabling via /#/ also makes it use {0,0,0}
 *          You can also fill it with attachment event /!/ followed by your attachment name. It's mandatory
 * CLASS  > This string is populated up when your entity class is not /prop_physics/ but something else
 *          used by ents.Create of the gmod ents API library. Keep this empty if your stuff is a normal prop.
 *          Disabling via /#/ makes it take the NULL value. In this case the model is spawned as a prop
--]]

local g_asmlib = nil
local g_gsMissDB = nil
local g_gsSymOff = nil

function SLIGWOLF_ADDON:TrackAssamblerExportPiece(modelOrItem)
	if not g_taType then
		self:Error("Bad g_taType!")
		return
	end

	if not g_asmlib then
		self:Error("TrackAssemblyTool was not loaded!")
		return
	end

	local item = modelOrItem

	if not istable(item) then
		item = self:GetTrackAssamblerItem(item)

		if not istable(item) then
			self:Error("No piece data found for model: %s", tostring(modelOrItem))
			return
		end
	end

	local model = item:GetModel() -- MODEL
	local name = item:GetName() or g_gsSymOff
	local class = item:GetClass() or g_gsMissDB
	local points = item:GetPoints()

	if not model or model == "" then
		self:Error("Piece data with unknown model!")
		return
	end

	if not item:IsClosed() then
		self:Error("Unclosed piece data for model: %s", model)
		return
	end

	if not points or table.IsEmpty(points) then
		self:Error("No points given for model: %s", model)
		return
	end


	local piece = {}

	for lineid, pointItem in ipairs(points) do
		local origin = pointItem.origin or g_gsMissDB
		local angle = pointItem.angle or g_gsMissDB
		local point = pointItem.point or g_gsMissDB

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

function SLIGWOLF_ADDON:TrackAssamblerCategory(modelOrItem)
	local item = modelOrItem

	if not istable(item) then
		item = self:GetTrackAssamblerItem(item)

		if not istable(item) then
			return nil
		end
	end

	return item:GetCategory()
end

function SLIGWOLF_ADDON:TrackAssamblerExportPieces()
	local pieces = {}

	for model, item in pairs(self.TrackAssamblerPieces) do
		local piece = self:TrackAssamblerExportPiece(item)

		pieces[model] = piece
	end

	return pieces
end

function SLIGWOLF_ADDON:TrackAssamblerExportCategoryCode()
	-- This code needs to be tiny
	local code = [[
		function(m)
			local s, c;

			s = _G.SligWolf_Addons;
			c = s and s.CallFunctionOnAddon("%s", "TrackAssamblerCategory", m);

			return c;
		end
	]]

	code = string.format(code, self.Addonname)
	code = string.gsub(code, "%s+", " ")
	code = string.Trim(code)
	code = code .. "\r\n"

	return code
end

function SLIGWOLF_ADDON:TrackAssamblerExportCategories()
	if not g_taType then
		self:Error("Bad g_taType!")
		return
	end

	local categories = {}

	categories[g_taType] = {
		Txt = self:TrackAssamblerExportCategoryCode()
	}

	return categories
end

SLIGWOLF_ADDON.HasTrackAssamblerContent = false

function SLIGWOLF_ADDON:TrackAssamblerAddContent()
	if not self:LuaExists("trackasm_content.lua") then
		return
	end

	self:LuaInclude("trackasm_content.lua")

	self.HasTrackAssamblerContent = true
end

function SLIGWOLF_ADDON:TrackAssamblerContentAutoInclude()
	if not LIBTrackasm.Exist() then
		return
	end

	if not self.HasTrackAssamblerContent then
		return
	end

	g_asmlib = LIBTrackasm.GetLib()

	g_gsMissDB = g_asmlib.GetOpVar("MISS_NOSQL")
	g_gsSymOff = g_asmlib.GetOpVar("OPSYM_DISABLE")

	local addonName = self:GetNiceNameWithAuthor()
	g_taType = addonName

	g_taSettings.Addon = addonName
	g_taSettings.Type = g_taType

	self:CallAddonFunctionWithAddonEnvironment(function()
		SligWolf_Addons.Include("sligwolf_addons/base/trackasm_export.lua")
	end)
end

return true

