local SligWolf_Addons = _G.SligWolf_Addons
if not SligWolf_Addons then
	return
end

local LIB = SligWolf_Addons:NewLib("Trace")

local CONSTANTS = SligWolf_Addons.Constants

local LIBPosition = SligWolf_Addons.Position
local LIBEntities = SligWolf_Addons.Entities
local LIBCamera = SligWolf_Addons.Camera
local LIBDebug = SligWolf_Addons.Debug

local g_buffer_trace_result = {}
local g_buffer_trace_params = {}
local g_buffer_trace_corners = {}
local g_buffer_trace_axes = {}
local g_buffer_trace_attachments = {}

g_buffer_trace_params.output = g_buffer_trace_result

local g_isDebug = false
local g_currentFilter = nil

local g_edgeIndexes = {
	{1, 2}, {2, 4}, {4, 3}, {3, 1}, -- Bottom face
	{5, 6}, {6, 8}, {8, 7}, {7, 5}, -- Top face
	{1, 5}, {2, 6}, {3, 7}, {4, 8}, -- Vertical edges
}

local g_faceDiagonalIndexes = {
	-- Bottom face (z = min)
	{1, 4}, {2, 3},
	-- Top face (z = max)
	{5, 8}, {6, 7},
	-- Front face (y = min)
	{1, 6}, {2, 5},
	-- Back face (y = max)
	{3, 8}, {4, 7},
	-- Left face (x = min)
	{1, 7}, {3, 5},
	-- Right face (x = max)
	{2, 8}, {4, 6},
}

local g_axisIndexes = {
	-- X
	{1, 2},
	-- Y
	{3, 4},
	-- Z
	{5, 6},
}

local g_allPointIndexes = {}

table.Add(g_allPointIndexes, g_edgeIndexes)
table.Add(g_allPointIndexes, g_faceDiagonalIndexes)

local function traceSimple(vecStart, vecEnd)
	local tr = g_buffer_trace_result
	local params = g_buffer_trace_params

	params.start = vecStart
	params.endpos = vecEnd

	LIB.RawTraceLine(params)

	local vecHit = tr.HitPos
	local hit = tr.Hit

	if g_isDebug then
		local context = LIBDebug.GetCurrentTraceDebugContext()
		local scale = context.scale

		LIBDebug.SetIgnoreZ(true)

		LIBDebug.Line(vecStart, vecHit, context.colorLive)

		if context.drawDead then
			LIBDebug.Line(vecHit, vecEnd, context.colorDead)
			LIBDebug.Cross(vecEnd, scale, context.colorDead)
		end

		LIBDebug.Cross(vecStart, scale, context.colorLive)

		if hit then
			local vecHitNormal = tr.HitNormal or CONSTANTS.vecZero
			local vecHitNormalEnd = vecHit + vecHitNormal * scale * 0.5

			LIBDebug.Cross(vecHit, scale * 1.5, context.colorLive)
			LIBDebug.Line(vecHit, vecHitNormalEnd, context.colorLive)

			LIBDebug.EntityTextAtPosition(vecStart, context.title, context.colorLive)
			LIBDebug.EntityTextAtPosition(vecHit, "Hit", context.colorLive)
		end

		LIBDebug.ResetIgnoreZ()
	end

	if not tr or table.IsEmpty(tr) then
		return nil
	end

	return tr
end

local function traceChain(vectorChain)
	if table.IsEmpty(vectorChain) then
		return nil
	end

	local lasti = #vectorChain
	if lasti <= 1 then
		return nil
	end

	local tr = g_buffer_trace_result
	local params = g_buffer_trace_params

	local hasHit = false
	local context = LIBDebug.GetCurrentTraceDebugContext()

	for i = 2, lasti do
		local isFirst = i <= 2
		local isLast = i >= lasti

		local vecStart = vectorChain[i - 1]
		local vecEnd = vectorChain[i]

		local vecHit = nil
		local hit = false

		if not hasHit then
			params.start = vecStart
			params.endpos = vecEnd

			LIB.RawTraceLine(params)

			vecHit = tr.HitPos
			hit = tr.Hit
		end

		if g_isDebug then
			local scale = context.scale

			LIBDebug.SetIgnoreZ(true)

			if vecHit then
				LIBDebug.Line(vecStart, vecHit, context.colorLive)

				if context.drawDead then
					LIBDebug.Line(vecHit, vecEnd, context.colorDead)

					if isLast then
						LIBDebug.Cross(vecEnd, scale, context.colorDead)
					end
				end

				if isFirst then
					LIBDebug.Cross(vecStart, scale, context.colorLive)
				end

				if hit then
					local vecHitNormal = tr.HitNormal or CONSTANTS.vecZero
					local vecHitNormalEnd = vecHit + vecHitNormal * scale * 0.5

					LIBDebug.Cross(vecHit, scale * 1.5, context.colorLive)
					LIBDebug.Line(vecHit, vecHitNormalEnd, context.colorLive)

					LIBDebug.EntityTextAtPosition(vecStart, context.title, context.colorLive)
					LIBDebug.EntityTextAtPosition(vecHit, "Hit", context.colorLive)
				end
			else
				LIBDebug.Line(vecStart, vecEnd, context.colorUnused)

				if isLast then
					LIBDebug.Cross(vecEnd, scale, context.colorUnused)
				end
			end

			LIBDebug.ResetIgnoreZ()
		end

		if hit then
			if not g_isDebug or not context.drawUnused then
				break
			end

			hasHit = true
		end
	end

	if not tr or table.IsEmpty(tr) then
		return nil
	end

	return tr
end

local function traceOBBPointIndexes(points, pointIndexes)
	if table.IsEmpty(pointIndexes) then
		return nil
	end

	local tr = g_buffer_trace_result
	local params = g_buffer_trace_params

	local hasHit = false
	local context = LIBDebug.GetCurrentTraceDebugContext()

	for _, pointIndex in ipairs(pointIndexes) do
		local vecStart = points[pointIndex[1]]
		local vecEnd = points[pointIndex[2]]

		local vecHit = nil
		local hit = false

		if not hasHit then
			params.start = vecStart
			params.endpos = vecEnd

			LIB.RawTraceLine(params)

			vecHit = tr.HitPos
			hit = tr.Hit
		end

		if g_isDebug then
			local scale = context.scale

			LIBDebug.SetIgnoreZ(true)

			if vecHit then
				LIBDebug.Line(vecStart, vecHit, context.colorLive)

				if context.drawDead then
					LIBDebug.Line(vecHit, vecEnd, context.colorDead)
				end

				if hit then
					local vecHitNormal = tr.HitNormal or CONSTANTS.vecZero
					local vecHitNormalEnd = vecHit + vecHitNormal * scale * 0.5

					LIBDebug.Cross(vecHit, scale * 1.5, context.colorLive)
					LIBDebug.Line(vecHit, vecHitNormalEnd, context.colorLive)

					LIBDebug.EntityTextAtPosition(vecStart, context.title, context.colorLive)
					LIBDebug.EntityTextAtPosition(vecHit, "Hit", context.colorLive)
				end
			else
				LIBDebug.Line(vecStart, vecEnd, context.colorUnused)
			end

			LIBDebug.ResetIgnoreZ()
		end

		if hit then
			if not g_isDebug or not context.drawUnused then
				break
			end

			hasHit = true
		end
	end

	if not tr or table.IsEmpty(tr) then
		return nil
	end

	return tr
end

local function copyResult(tr, copyToResult)
	if not tr then
		return nil
	end

	if copyToResult then
		table.CopyFromTo(tr, copyToResult)
		return copyToResult
	end

	return tr
end

function LIB.SetFilter(funcOrTable)
	g_currentFilter = funcOrTable
end

function LIB.ResetFilter()
	g_currentFilter = nil
end

function LIB.GetFilter()
	return g_currentFilter
end

function LIB.GetFilterApplied(ent, filter)
	local funcOrTable = LIB.GetFilter()

	if not funcOrTable then
		return nil
	end

	if isfunction(funcOrTable) then
		if not filter or not istable(filter) then
			filter = {}
		end

		filter = funcOrTable(ent, filter)

		if not filter then
			filter = {}
		end

		return filter
	end

	if istable(funcOrTable) then
		return funcOrTable
	end

	return nil
end

function LIB.GetPlayerFilter(ply, filter)
	ply = ply or false

	local camera = LIBCamera.GetCameraEnt(ply) or false

	local plyVehicle = IsValid(ply) and ply.GetVehicle and ply:GetVehicle() or false
	local cameraVehicle = IsValid(camera) and camera.GetVehicle and camera:GetVehicle() or false

	local tmp = {}

	tmp[ply] = ply
	tmp[camera] = camera
	tmp[plyVehicle] = plyVehicle
	tmp[cameraVehicle] = cameraVehicle

	if not filter or not istable(filter) then
		filter = {}
	else
		table.Empty(filter)
	end

	for _, filterEnt in pairs(tmp) do
		if not IsValid(filterEnt) then
			continue
		end

		table.insert(filter, filterEnt)
	end

	return filter
end

function LIB.GetSystemEntitiesWithOwnerFilter(ent, filter)
	if not filter or not istable(filter) then
		filter = {}
	else
		table.Empty(filter)
	end

	local owner = LIBEntities.GetOwner(ent)
	filter = LIB.GetPlayerFilter(owner, filter)

	local entResult = LIBEntities.GetSystemEntities(ent)

	table.Add(filter, entResult)

	return filter
end

function LIB.GetSolidPropFilter(ent, filter)
	if not IsValid(ent) then return nil end

	local blacklistIndex = {}

	for _, filterEnt in ipairs(LIB.GetSystemEntitiesWithOwnerFilter(ent)) do
		blacklistIndex[filterEnt] = true
	end

	local unfilteredCollisionGroups = {
		[COLLISION_GROUP_NONE] = true,
		[COLLISION_GROUP_INTERACTIVE_DEBRIS] = true,
		[COLLISION_GROUP_INTERACTIVE] = true,
		[COLLISION_GROUP_VEHICLE] = true,
		[COLLISION_GROUP_WEAPON] = true,
	}

	filter = function(thisEnt)
		if not IsValid(thisEnt) then
			return false
		end

		if blacklistIndex[thisEnt] then
			return false
		end

		if thisEnt:GetSolid() == SOLID_NONE then
			return false
		end

		local collisionGroup = thisEnt:GetCollisionGroup()
		if not unfilteredCollisionGroups[collisionGroup] then
			return false
		end

		return true
	end

	return filter
end

function LIB.TraceSimple(ent, vecStart, vecEnd, copyToResult)
	if not IsValid(ent) then return nil end

	vecStart = vecStart or CONSTANTS.vecZero
	vecEnd = vecEnd or CONSTANTS.vecZero

	g_isDebug = LIBDebug.IsDeveloper() and LIBDebug.GetDebugTraceEnabled()

	local params = g_buffer_trace_params

	local filter = LIB.GetFilterApplied(ent, params.filter) or LIBEntities.GetSystemEntities(ent)
	params.filter = filter

	local tr = traceSimple(vecStart, vecEnd)

	return copyResult(tr, copyToResult)
end

function LIB.TraceChain(ent, vectorChain, copyToResult)
	if not IsValid(ent) then return nil end

	vectorChain = vectorChain or {}

	g_isDebug = LIBDebug.IsDeveloper() and LIBDebug.GetDebugTraceEnabled()

	local params = g_buffer_trace_params

	local filter = LIB.GetFilterApplied(ent, params.filter) or LIBEntities.GetSystemEntities(ent)
	params.filter = filter

	local tr = traceChain(vectorChain)

	return copyResult(tr, copyToResult)
end

function LIB.TraceAttachment(ent, attachment, len, copyToResult)
	if not IsValid(ent) then return nil end

	len = tonumber(len or 0)

	if len == 0 then
		len = 1
	end

	local vecStart, ang = LIBPosition.GetAttachmentPosAng(ent, attachment)
	if not vecStart then
		return nil
	end

	local vecEnd = vecStart + ang:Forward() * len

	g_isDebug = LIBDebug.IsDeveloper() and LIBDebug.GetDebugTraceEnabled()

	local params = g_buffer_trace_params

	local filter = LIB.GetFilterApplied(ent, params.filter) or LIBEntities.GetSystemEntities(ent)
	params.filter = filter

	local tr = traceSimple(vecStart, vecEnd)

	return copyResult(tr, copyToResult)
end

function LIB.TraceAttachmentToAttachment(ent, attachmentA, attachmentB, copyToResult)
	if not IsValid(ent) then return nil end

	local posA = LIBPosition.GetAttachmentPosAng(ent, attachmentA)
	if not posA then return end

	local posB = LIBPosition.GetAttachmentPosAng(ent, attachmentB)
	if not posB then return end

	g_isDebug = LIBDebug.IsDeveloper() and LIBDebug.GetDebugTraceEnabled()

	if g_isDebug then
		local attachmentNameA = LIBPosition.GetAttachmentName(ent, attachmentA)
		local attachmentNameB = LIBPosition.GetAttachmentName(ent, attachmentB)

		LIBDebug.EntityTextAtPosition(posA, attachmentNameA, 1)
		LIBDebug.EntityTextAtPosition(posB, attachmentNameB, 1)
	end

	local params = g_buffer_trace_params

	local filter = LIB.GetFilterApplied(ent, params.filter) or LIBEntities.GetSystemEntities(ent)
	params.filter = filter

	local tr = traceSimple(posA, posB)

	return copyResult(tr, copyToResult)
end

function LIB.TraceAttachmentChain(ent, attachmentChain, copyToResult)
	if not IsValid(ent) then return nil end

	table.Empty(g_buffer_trace_attachments)

	g_isDebug = LIBDebug.IsDeveloper() and LIBDebug.GetDebugTraceEnabled()

	for _, attachmentChainItem in ipairs(attachmentChain) do
		local pos = LIBPosition.GetAttachmentPosAng(ent, attachmentChainItem)
		if not pos then return end

		table.insert(g_buffer_trace_attachments, pos)

		if g_isDebug then
			local attachmentName = LIBPosition.GetAttachmentName(ent, attachmentChainItem)
			LIBDebug.EntityTextAtPosition(pos, attachmentName, 1)
		end
	end

	local params = g_buffer_trace_params

	local filter = LIB.GetFilterApplied(ent, params.filter) or LIBEntities.GetSystemEntities(ent)
	params.filter = filter

	local tr = traceChain(g_buffer_trace_attachments)

	return copyResult(tr, copyToResult)
end

function LIB.TraceOBB(ent, obb, copyToResult)
	if not IsValid(ent) then return nil end

	local min = obb.min or CONSTANTS.vecZero
	local max = obb.max or CONSTANTS.vecZero

	g_isDebug = LIBDebug.IsDeveloper() and LIBDebug.GetDebugTraceEnabled()

	local params = g_buffer_trace_params

	local filter = LIB.GetFilterApplied(ent, params.filter) or LIBEntities.GetSystemEntities(ent)
	params.filter = filter

	local mx = ent:GetWorldTransformMatrix()

	local center = (min + max) / 2

	local axes = g_buffer_trace_axes
	axes[1] = mx * Vector(   min.x, center.y, center.z)
	axes[2] = mx * Vector(   max.x, center.y, center.z)
	axes[3] = mx * Vector(center.x,    min.y, center.z)
	axes[4] = mx * Vector(center.x,    max.y, center.z)
	axes[5] = mx * Vector(center.x, center.y,    min.z)
	axes[6] = mx * Vector(center.x, center.y,    max.z)

	-- Trace along the center on each axis
	local tr = traceOBBPointIndexes(axes, g_axisIndexes)
	if not tr then
		return nil
	end

	if tr.Hit then
		return copyResult(tr, copyToResult)
	end

	local corners = g_buffer_trace_corners
	corners[1] = mx * Vector(min.x, min.y, min.z)
	corners[2] = mx * Vector(max.x, min.y, min.z)
	corners[3] = mx * Vector(min.x, max.y, min.z)
	corners[4] = mx * Vector(max.x, max.y, min.z)
	corners[5] = mx * Vector(min.x, min.y, max.z)
	corners[6] = mx * Vector(max.x, min.y, max.z)
	corners[7] = mx * Vector(min.x, max.y, max.z)
	corners[8] = mx * Vector(max.x, max.y, max.z)

	-- Trace the border and face centers
	tr = traceOBBPointIndexes(corners, g_allPointIndexes)

	return copyResult(tr, copyToResult)
end

function LIB.PlayerAimTrace(ply, maxdist, copyToResult)
	local camera = LIBCamera.GetCameraEnt(ply)

	if not IsValid(ply) then return nil end
	if not IsValid(camera) then return nil end

	maxdist = tonumber(maxdist or 500)

	local vecStart, vecEnd

	if camera:IsPlayer() then
		vecStart = LIBPosition.GetPlayerEyePos(camera)
		vecEnd = vecStart + LIBPosition.GetPlayerAimVector(camera) * maxdist
	else
		vecStart = camera:GetPos()
		vecEnd = vecStart + LIBPosition.GetPlayerAimVector(ply) * maxdist
	end

	local params = g_buffer_trace_params

	local filter = LIB.GetFilterApplied(ent, params.filter) or LIB.GetPlayerFilter(ply, params.filter)
	params.filter = filter

	local context = LIBDebug.GetCurrentTraceDebugContext()

	if context.name == LIBDebug.TRACE_DEBUG_CONTEXT_DEFAULT then
		LIBDebug.SetCurrentTraceDebugContext(LIBDebug.TRACE_DEBUG_CONTEXT_PLAYER)
	end

	local tr = traceSimple(vecStart, vecEnd)

	LIBDebug.ResetTraceDebugContext()

	return copyResult(tr, copyToResult)
end

function LIB.RawTraceLine(params)
	local trA = params.output

	local vecEnd = params.endpos

	local trB = util.TraceLine(params)
	local tr = trA or trB

	tr.EndPos = vecEnd

	return tr
end

function LIB.RawTraceHull(params)
	local trA = params.output

	local vecEnd = params.endpos
	local mins = params.mins
	local maxs = params.maxs

	local trB = util.TraceHull(params)
	local tr = trA or trB

	tr.EndPos = vecEnd
	tr.mins = mins
	tr.maxs = maxs

	return tr
end

function LIB.Load()
	LIBPosition = SligWolf_Addons.Position
	LIBEntities = SligWolf_Addons.Entities
	LIBCamera = SligWolf_Addons.Camera
	LIBDebug = SligWolf_Addons.Debug
end

return true

