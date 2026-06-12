local SligWolf_Addons = _G.SligWolf_Addons
if not SligWolf_Addons then
	return
end

local LIB = SligWolf_Addons:NewLib("Tracer")

local CONSTANTS = SligWolf_Addons.Constants

local LIBPosition = SligWolf_Addons.Position
local LIBEntities = SligWolf_Addons.Entities
local LIBCamera = SligWolf_Addons.Camera
local LIBDebug = SligWolf_Addons.Debug

local g_buffer_tracer_result = {}
local g_buffer_tracer_params = {}
local g_buffer_tracer_corners = {}
local g_buffer_tracer_axles = {}
local g_buffer_tracer_attachments = {}

g_buffer_tracer_params.output = g_buffer_tracer_result

local g_isDebug = false

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
	local tr = g_buffer_tracer_result
	local params = g_buffer_tracer_params

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

	local tr = g_buffer_tracer_result
	local params = g_buffer_tracer_params

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

	local tr = g_buffer_tracer_result
	local params = g_buffer_tracer_params

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

function LIB.TracerChain(ent, vectorChain, copyToResult)
	if not IsValid(ent) then return nil end

	vectorChain = vectorChain or {}

	g_isDebug = LIBDebug.IsDeveloper() and LIBDebug.GetDebugTraceEnabled()
	g_buffer_tracer_params.filter = LIBEntities.GetSystemEntities(ent)

	local tr = traceChain(vectorChain)

	return copyResult(tr, copyToResult)
end

function LIB.Tracer(ent, vecStart, vecEnd, copyToResult)
	if not IsValid(ent) then return nil end

	vecStart = vecStart or CONSTANTS.vecZero
	vecEnd = vecEnd or CONSTANTS.vecZero

	g_isDebug = LIBDebug.IsDeveloper() and LIBDebug.GetDebugTraceEnabled()
	g_buffer_tracer_params.filter = LIBEntities.GetSystemEntities(ent)

	local tr = traceSimple(vecStart, vecEnd)

	return copyResult(tr, copyToResult)
end

function LIB.TracerAttachment(ent, attachment, len, dir, copyToResult)
	if not IsValid(ent) then return nil end

	len = tonumber(len or 0)
	dir = tostring(dir or "")

	if len == 0 then
		len = 1
	end

	if dir == "" then
		dir = "Forward"
	end

	local pos, ang = LIBPosition.GetAttachmentPosAng(ent, attachment)
	if not pos then return end

	local func = ang[dir]
	if not isfunction(func) then return end

	local endpos = pos + func(ang) * len

	g_isDebug = LIBDebug.IsDeveloper() and LIBDebug.GetDebugTraceEnabled()
	g_buffer_tracer_params.filter = LIBEntities.GetSystemEntities(ent)

	local tr = traceSimple(pos, endpos)

	return copyResult(tr, copyToResult)
end

function LIB.TracerAttachmentToAttachment(ent, attachmentA, attachmentB, copyToResult)
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

	g_buffer_tracer_params.filter = LIBEntities.GetSystemEntities(ent)

	local tr = traceSimple(posA, posB)

	return copyResult(tr, copyToResult)
end

function LIB.TracerAttachmentChain(ent, attachmentChain, copyToResult)
	if not IsValid(ent) then return nil end

	table.Empty(g_buffer_tracer_attachments)

	g_isDebug = LIBDebug.IsDeveloper() and LIBDebug.GetDebugTraceEnabled()

	for _, attachmentChainItem in ipairs(attachmentChain) do
		local pos = LIBPosition.GetAttachmentPosAng(ent, attachmentChainItem)
		if not pos then return end

		table.insert(g_buffer_tracer_attachments, pos)

		if g_isDebug then
			local attachmentName = LIBPosition.GetAttachmentName(ent, attachmentChainItem)
			LIBDebug.EntityTextAtPosition(pos, attachmentName, 1)
		end
	end

	g_buffer_tracer_params.filter = LIBEntities.GetSystemEntities(ent)

	local tr = traceChain(g_buffer_tracer_attachments)

	return copyResult(tr, copyToResult)
end

function LIB.TraceOBB(ent, obb, copyToResult)
	if not IsValid(ent) then return nil end

	local min = obb.min or CONSTANTS.vecZero
	local max = obb.max or CONSTANTS.vecZero

	g_isDebug = LIBDebug.IsDeveloper() and LIBDebug.GetDebugTraceEnabled()
	g_buffer_tracer_params.filter = LIBEntities.GetSystemEntities(ent)

	local mx = ent:GetWorldTransformMatrix()

	local center = (min + max) / 2

	local axles = g_buffer_tracer_axles
	axles[1] = mx * Vector(   min.x, center.y, center.z)
	axles[2] = mx * Vector(   max.x, center.y, center.z)
	axles[3] = mx * Vector(center.x,    min.y, center.z)
	axles[4] = mx * Vector(center.x,    max.y, center.z)
	axles[5] = mx * Vector(center.x, center.y,    min.z)
	axles[6] = mx * Vector(center.x, center.y,    max.z)

	-- Trace along the center on each axis
	local tr = traceOBBPointIndexes(axles, g_axisIndexes)
	if not tr then
		return nil
	end

	if tr.Hit then
		return copyResult(tr, copyToResult)
	end

	local corners = g_buffer_tracer_corners
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

function LIB.PlayerAimTrace(ply, maxdist, filter, copyToResult)
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

	local tr = g_buffer_tracer_result
	local params = g_buffer_tracer_params

	params.filter = function(ent, ...)
		if not IsValid(ent) then return false end
		if not IsValid(ply) then return false end
		if not IsValid(camera) then return false end
		if ent == ply then return false end
		if ent == camera then return false end

		if ply.GetVehicle and ent == ply:GetVehicle() then return false end
		if camera.GetVehicle and ent == camera:GetVehicle() then return false end

		if filter then
			if isfunction(filter) and not filter(ent, ply, camera, ...) then
				return false
			end

			if istable(filter) and filter[ent] then
				return false
			end

			if filter == ent then
				return false
			end
		end

		return true
	end

	params.start = vecStart
	params.endpos = vecEnd

	LIB.RawTraceLine(params)

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

	local trB = util.TraceHull(params)
	local tr = trA or trB

	tr.EndPos = vecEnd

	return tr
end

function LIB.Load()
	LIBPosition = SligWolf_Addons.Position
	LIBEntities = SligWolf_Addons.Entities
	LIBCamera = SligWolf_Addons.Camera
	LIBDebug = SligWolf_Addons.Debug
end

return true

