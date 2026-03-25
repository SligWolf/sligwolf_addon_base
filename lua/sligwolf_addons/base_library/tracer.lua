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

local LIBPosition = nil
local LIBEntities = nil
local LIBCamera = nil
local LIBDebug = nil

local Color_trGreen = Color(50, 255, 50)
local Color_trBlue = Color(50, 50, 255)
local Color_trCross = Color(200, 200, 200)
local Color_trTextHit = Color(100, 255, 100)

local TRACE_RESULT_BUFFER = {}
local TRACE_RESULT_PARAMS = {}

function LIB.TracerChain(ent, vectorChain, filterfunc, result)
	if not IsValid(ent) then return nil end

	vectorChain = vectorChain or {}

	if not isfunction(filterfunc) then
		filterfunc = function()
			return true
		end
	end

	local isDebug = LIBDebug.IsDeveloper()

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
				LIBDebug.EntityTextAtPosition(lastVector, "Start")
			end

			continue
		end

		params.start = lastVector
		params.endpos = thisVector

		util.TraceLine(params)

		local trStart = lastVector
		local trEnd = thisVector
		local trHitPos = tr.HitPos
		local trHit = tr.Hit

		lastVector = thisVector
		hasTraced = true

		if isDebug then
			LIBDebug.SetIgnoreZ(true)
			LIBDebug.Line(trStart, trHitPos, Color_trGreen)
			LIBDebug.Line(trHitPos, trEnd, Color_trBlue)
			LIBDebug.Cross(trStart, 1, Color_trGreen)

			if not trHit then
				LIBDebug.Cross(trEnd, 1, Color_trBlue)
			end

			LIBDebug.ResetIgnoreZ()
		end

		if trHit then
			if isDebug then
				LIBDebug.SetIgnoreZ(true)
				LIBDebug.Cross(trHitPos, 1, Color_trGreen)
				LIBDebug.EntityTextAtPosition(trHitPos, "Hit", Color_trTextHit)
				LIBDebug.ResetIgnoreZ()
			end

			break
		end
	end

	if isDebug and lastVector then
		LIBDebug.EntityTextAtPosition(lastVector, "End")
	end

	if not hasTraced or not tr or table.IsEmpty(tr) then
		return nil
	end

	if result then
		table.Empty(result)
		table.CopyFromTo(tr, result)

		return result
	end

	return tr
end

local TRACER_VECTOR_CHAIN_BUFFER = {}

function LIB.Tracer(ent, vecStart, vecEnd, filterfunc, result)
	if not IsValid(ent) then return nil end

	vecStart = vecStart or Vector()
	vecEnd = vecEnd or Vector()

	TRACER_VECTOR_CHAIN_BUFFER[1] = vecStart
	TRACER_VECTOR_CHAIN_BUFFER[2] = vecEnd

	local tr = LIB.TracerChain(ent, TRACER_VECTOR_CHAIN_BUFFER, filterfunc, result)
	return tr
end

function LIB.TracerAttachment(ent, attachment, len, dir, filterfunc, result)
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

	return LIB.Tracer(ent, pos, endpos, filterfunc, result)
end

function LIB.TracerAttachmentToAttachment(ent, attachmentA, attachmentB, filterfunc, result)
	local posA = LIBPosition.GetAttachmentPosAng(ent, attachmentA)
	if not posA then return end

	local posB = LIBPosition.GetAttachmentPosAng(ent, attachmentB)
	if not posB then return end

	local isDebug = LIBDebug.IsDeveloper()

	if isDebug then
		LIBDebug.EntityTextAtPosition(posA, attachmentA, 1)
		LIBDebug.EntityTextAtPosition(posB, attachmentB, 1)
	end

	return LIB.Tracer(ent, posA, posB, filterfunc, result)
end

local TRACER_ATTACHMENT_CHAIN_BUFFER = {}

function LIB.TracerAttachmentChain(ent, attachmentChain, filterfunc, result)
	table.Empty(TRACER_ATTACHMENT_CHAIN_BUFFER)

	local isDebug = LIBDebug.IsDeveloper()

	for _, attachmentChainItem in ipairs(attachmentChain) do
		local pos = LIBPosition.GetAttachmentPosAng(ent, attachmentChainItem)
		if not pos then return end

		table.insert(TRACER_ATTACHMENT_CHAIN_BUFFER, pos)

		if isDebug then
			LIBDebug.EntityTextAtPosition(pos, attachmentChainItem, 1)
		end
	end

	return LIB.TracerChain(ent, TRACER_ATTACHMENT_CHAIN_BUFFER, filterfunc, result)
end

function LIB.DoTrace(ply, maxdist, filter)
	local camera = LIBCamera.GetCameraEnt(ply)

	if not IsValid(ply) then return nil end
	if not IsValid(camera) then return nil end

	maxdist = tonumber(maxdist or 500)

	local start_pos, end_pos

	if camera:IsPlayer() then
		start_pos = LIBPosition.GetPlayerEyePos(camera)
		end_pos = start_pos + LIBPosition.GetPlayerAimVector(camera) * maxdist
	else
		start_pos = camera:GetPos()
		end_pos = start_pos + LIBPosition.GetPlayerAimVector(ply) * maxdist
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

function LIB.Load()
	LIBPosition = SligWolf_Addons.Position
	LIBEntities = SligWolf_Addons.Entities
	LIBCamera = SligWolf_Addons.Camera
	LIBDebug = SligWolf_Addons.Debug
end

return true

