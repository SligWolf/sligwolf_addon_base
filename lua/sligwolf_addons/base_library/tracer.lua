AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Tracer = SligWolf_Addons.Tracer or {}
table.Empty(SligWolf_Addons.Tracer)

local LIB = SligWolf_Addons.Tracer

local LIBUtil = nil
local LIBPosition = nil
local LIBEntities = nil

local Color_trGreen = Color(50, 255, 50)
local Color_trBlue = Color(50, 50, 255)
local Color_trTextHit = Color(100, 255, 100)

local Color_trText = Color(137, 222, 255)
local Color_trCross = Color(167, 222, 255)

local LineOffset_trText = -2

if CLIENT then
	Color_trText = Color(255, 222, 102)
	Color_trCross = Color(255, 222, 132)
	LineOffset_trText = 0
end

LIB.DEBUG_LIFETIME = 0.20

function LIB.Load()
	LIBUtil = SligWolf_Addons.Util
	LIBPosition = SligWolf_Addons.Position
	LIBEntities = SligWolf_Addons.Entities
end

local TRACE_RESULT_BUFFER = {}
local TRACE_RESULT_PARAMS = {}

function LIB.TracerChain(ent, vectorChain, filterfunc)
	if not IsValid(ent) then return nil end

	vectorChain = vectorChain or {}

	if not isfunction(filterfunc) then
		filterfunc = function()
			return true
		end
	end

	local isDebug = LIBUtil.IsDeveloper()
	local debugLifetime = LIB.DEBUG_LIFETIME

	local tr = TRACE_RESULT_BUFFER
	local params = TRACE_RESULT_PARAMS

	local lastVector = nil
	local hasTraced = false

	local internalFilterfunc = function(trent, ...)
		if not IsValid(ent) then return false end
		if not IsValid(trent) then return false end
		if trent == ent then return false end

		local sp = LIBEntities.GetSuperParent(ent)
		if IsValid(sp) then
			if trent == sp then return false end
			if LIBEntities.GetSuperParent(trent) == sp then return false end
		end

		return filterfunc(sp, trent, ...)
	end

	params.filter = internalFilterfunc
	params.output = tr

	for _, thisVector in ipairs(vectorChain) do
		if not lastVector then
			lastVector = thisVector

			if isDebug then
				debugoverlay.EntityTextAtPosition(lastVector, LineOffset_trText, "Start", debugLifetime, Color_trText)
			end

			continue
		end

		params.start = lastVector
		params.endpos = thisVector

		util.TraceLine(params)

		lastVector = thisVector
		hasTraced = true

		local trStart = tr.StartPos
		local trEnd = thisVector
		local trHitPos = tr.HitPos
		local trHit = tr.Hit

		if isDebug then
			debugoverlay.Line(trStart, trHitPos, debugLifetime, Color_trGreen, true)
			debugoverlay.Line(trHitPos, trEnd, debugLifetime, Color_trBlue, true)
			debugoverlay.Cross(trEnd, 1, debugLifetime, Color_trCross, true)
		end

		if trHit then
			if isDebug then
				debugoverlay.Cross(trHitPos, 1, debugLifetime, Color_trCross, true)
				debugoverlay.EntityTextAtPosition(trHitPos, LineOffset_trText, "Hit", debugLifetime, Color_trTextHit)
			end

			break
		end
	end

	if isDebug then
		if lastVector then
			debugoverlay.EntityTextAtPosition(lastVector, LineOffset_trText, "End", debugLifetime, Color_trText)
		end
	end

	if not hasTraced or not tr or table.IsEmpty(tr) then
		return nil
	end

	return tr
end

local TRACER_VECTOR_CHAIN_BUFFER = {}

function LIB.Tracer(ent, vecStart, vecEnd, filterfunc)
	if not IsValid(ent) then return nil end

	vecStart = vecStart or Vector()
	vecEnd = vecEnd or Vector()

	TRACER_VECTOR_CHAIN_BUFFER[1] = vecStart
	TRACER_VECTOR_CHAIN_BUFFER[2] = vecEnd

	local tr = LIB.TracerChain(ent, TRACER_VECTOR_CHAIN_BUFFER, filterfunc)
	return tr
end

function LIB.TracerAttachment(ent, attachment, len, dir, filterfunc)
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

	return LIB.Tracer(ent, pos, endpos, filterfunc)
end

function LIB.TracerAttachmentToAttachment(ent, attachmentA, attachmentB, filterfunc)
	local posA = LIBPosition.GetAttachmentPosAng(ent, attachmentA)
	if not posA then return end

	local posB = LIBPosition.GetAttachmentPosAng(ent, attachmentB)
	if not posB then return end

	local isDebug = LIBUtil.IsDeveloper()
	local debugLifetime = LIB.DEBUG_LIFETIME

	if isDebug then
		debugoverlay.EntityTextAtPosition(posA, LineOffset_trText + 1, attachmentA, debugLifetime, Color_trText)
		debugoverlay.EntityTextAtPosition(posB, LineOffset_trText + 1, attachmentB, debugLifetime, Color_trText)
	end

	return LIB.Tracer(ent, posA, posB, filterfunc)
end

local TRACER_ATTACHMENT_CHAIN_BUFFER = {}

function LIB.TracerAttachmentChain(ent, attachmentChain, filterfunc)
	table.Empty(TRACER_ATTACHMENT_CHAIN_BUFFER)

	local isDebug = LIBUtil.IsDeveloper()
	local debugLifetime = LIB.DEBUG_LIFETIME

	for _, attachmentChainItem in ipairs(attachmentChain) do
		local pos = LIBPosition.GetAttachmentPosAng(ent, attachmentChainItem)
		if not pos then return end

		table.insert(TRACER_ATTACHMENT_CHAIN_BUFFER, pos)

		if isDebug then
			debugoverlay.EntityTextAtPosition(pos, LineOffset_trText + 1, attachmentChainItem, debugLifetime, Color_trText)
		end
	end

	return LIB.TracerChain(ent, TRACER_ATTACHMENT_CHAIN_BUFFER, filterfunc)
end

function LIB.CheckGround(ent, vec1, vec2)
	-- if 1 then
	-- 	return false -- @todo replace
	-- end

	if not IsValid(ent) then return false end

	vec2 = vec2 or vec1
	vec1 = vec1 or vec2

	if not vec1 then return false end
	if not vec2 then return false end

	local vec1A = ent:LocalToWorld(Vector(vec1.x, vec1.y, vec1.z))
	local vec2A = ent:LocalToWorld(Vector(vec2.x, -vec2.y, vec2.z))

	local vec1B = ent:LocalToWorld(Vector(-vec1.x, vec1.y, vec1.z))
	local vec2B = ent:LocalToWorld(Vector(-vec2.x, -vec2.y, vec2.z))

	local tr1 = LIB.Tracer(ent, vec1A, vec2A)
	if tr1 and tr1.Hit then return true end

	local tr2 = LIB.Tracer(ent, vec1B, vec2B)
	if tr2 and tr2.Hit then return true end

	return false
end

local function GetCameraEnt(ply)
	if not IsValid(ply) and CLIENT then
		ply = LocalPlayer()
	end

	if not IsValid(ply) then return nil end
	local camera = ply:GetViewEntity()
	if not IsValid(camera) then return ply end

	return camera
end

function LIB.DoTrace(ply, maxdist, filter)
	local camera = GetCameraEnt(ply)
	local start_pos, end_pos
	if not IsValid(ply) then return nil end
	if not IsValid(camera) then return nil end

	maxdist = tonumber(maxdist or 500)

	if camera:IsPlayer() then
		start_pos = camera:EyePos()
		end_pos = start_pos + camera:GetAimVector() * maxdist
	else
		start_pos = camera:GetPos()
		end_pos = start_pos + ply:GetAimVector() * maxdist
	end

	local trace = {}
	trace.start = start_pos
	trace.endpos = end_pos

	trace.filter = function(ent, ...)
		if not IsValid(ent) then return false end
		if not IsValid(ply) then return false end
		if not IsValid(camera) then return false end
		if ent == ply then return false end
		if ent == camera then return false end

		if ply.GetVehicle and ent == ply:GetVehicle() then return false end
		if camera.GetVehicle and ent == camera:GetVehicle() then return false end

		if filter then
			if isfunction(filter) then
				if not filter(ent, ply, camera, ...) then
					return false
				end
			end

			if istable(filter) then
				if filter[ent] then
					return false
				end
			end

			if filter == ent then
				return false
			end
		end

		return true
	end

	return util.TraceLine(trace)
end

return true

