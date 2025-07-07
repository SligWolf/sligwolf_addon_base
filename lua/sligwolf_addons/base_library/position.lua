AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Position = SligWolf_Addons.Position or {}
table.Empty(SligWolf_Addons.Position)

local CONSTANTS = SligWolf_Addons.Constants

local LIB = SligWolf_Addons.Position

local LIBPrint = nil
local LIBModel = nil
local LIBTimer = nil

local g_asyncPositioningTimerName = "asyncPositioning"
local g_asyncPositioningPollTime = 0.033
local g_asyncPositioningAttachment = 1
local g_asyncPositioningDistanceToleranceSqr = 0.01 ^ 2
local g_asyncPositioningDistanceAngle = 0.01
local g_asyncPositioningLifetime = 50

local function pollAsyncPositioning(ent, entTable, timerName, force)
	if not IsValid(ent) then
		return true
	end

	local asyncPositioning = entTable.asyncPositioning or {}
	entTable.asyncPositioning = asyncPositioning

	local callbacks = asyncPositioning.callbacks or {}
	asyncPositioning.callbacks = callbacks

	local callbacksIdx = asyncPositioning.callbacksIdx or {}
	asyncPositioning.callbacksIdx = callbacksIdx

	local lifetime = asyncPositioning.lifetime or g_asyncPositioningLifetime
	asyncPositioning.lifetime = lifetime - 1
	asyncPositioning.active = true

	if lifetime <= 0 then
		LIBTimer.Remove(timerName)

		table.Empty(callbacks)
		table.Empty(callbacksIdx)

		asyncPositioning.active = false
		asyncPositioning.lifetime = g_asyncPositioningLifetime

		LIBPrint.ErrorNoHaltWithStack("Position.SetPosAng: Async positioning did not return after %i attempts at %s.", g_asyncPositioningLifetime, ent)
		return true
	end

	local hasPos = asyncPositioning.hasPos
	local hasAng = asyncPositioning.hasAng

	local attTargetData = asyncPositioning.attTargetData
	local curAttPos, curAttAng = LIB.GetAttachmentPosAng(ent, g_asyncPositioningAttachment)

	if not force then
		-- Check if the attachment has moved to its SetPos()-target yet.
		-- If it hasn't, we assume the position might not have been properly set yet
		-- and the model attachments are outdated.

		local posHasArrived = not hasPos or curAttPos:DistToSqr(attTargetData.pos) < g_asyncPositioningDistanceToleranceSqr
		local angHasArrived = not hasAng or LIB.GetAnglesDifference(curAttAng, attTargetData.ang) < g_asyncPositioningDistanceAngle

		if not posHasArrived then
			return false
		end

		if not angHasArrived then
			return false
		end
	end

	local callbacksCopy = table.Copy(callbacks)

	table.Empty(callbacks)
	table.Empty(callbacksIdx)

	for i, thisCallback in ipairs(callbacksCopy) do
		thisCallback(ent)
	end

	asyncPositioning.active = false
	asyncPositioning.lifetime = g_asyncPositioningLifetime

	LIBTimer.Remove(timerName)
	return true
end

function LIB.SetPosAng(ent, pos, ang, callback)
	if not IsValid(ent) then
		return false
	end

	local timerName = LIBTimer.GetEntityTimerName(ent, g_asyncPositioningTimerName)
	if not timerName then
		return false
	end

	LIBTimer.Remove(timerName)

	if not pos and not ang then
		return false
	end

	if not isfunction(callback) then
		if pos then
			ent:SetPos(pos)
		end

		if ang then
			ent:SetAngles(ang)
		end

		return false
	end

	local entTable = ent:SligWolf_GetTable()

	local attPos, attAng = LIB.GetAttachmentPosAng(ent, g_asyncPositioningAttachment)

	attPos = ent:WorldToLocal(attPos)
	attAng = ent:WorldToLocalAngles(attAng)

	attPos, attAng = LocalToWorld(attPos, attAng, pos or CONSTANTS.vecZero, ang or CONSTANTS.angZero)

	local asyncPositioning = entTable.asyncPositioning or {}
	entTable.asyncPositioning = asyncPositioning

	local attTargetData = asyncPositioning.attTargetData or {}
	asyncPositioning.attTargetData = attTargetData

	attTargetData.pos = attPos
	attTargetData.ang = attAng

	asyncPositioning.active = true
	asyncPositioning.hasPos = nil
	asyncPositioning.hasAng = nil
	asyncPositioning.lifetime = g_asyncPositioningLifetime

	LIB.AddPositioningCallback(ent, callback)

	if pos then
		asyncPositioning.hasPos = true
		ent:SetPos(pos)
	end

	if ang then
		asyncPositioning.hasAng = true
		ent:SetAngles(ang)
	end

	-- Sometimes attachment lag behind the actual entity.
	-- So we need to check them to have moved with it before actual using them.
	-- This function calls the given callback when the attachments are ready to be used.

	if pollAsyncPositioning(ent, entTable, timerName) then
		return false
	end

	LIBTimer.Until(timerName, g_asyncPositioningPollTime, function()
		return pollAsyncPositioning(ent, entTable, timerName)
	end)

	return true
end

function LIB.SetPos(ent, pos, callback)
	return LIB.SetPosAng(ent, pos, nil, callback)
end

function LIB.SetAng(ent, ang, callback)
	return LIB.SetPosAng(ent, nil, ang, callback)
end

function LIB.IsAsyncPositioning(ent)
	if not IsValid(ent) then
		return false
	end

	local entTable = ent:SligWolf_GetTable()

	local asyncPositioning = entTable.asyncPositioning
	if not asyncPositioning then
		return false
	end

	local active = asyncPositioning.active
	if not active then
		return false
	end

	return true
end

function LIB.AddPositioningCallback(ent, callback)
	if not IsValid(ent) then
		return
	end

	if not isfunction(callback) then
		return
	end

	local entTable = ent:SligWolf_GetTable()

	local asyncPositioning = entTable.asyncPositioning or {}
	entTable.asyncPositioning = asyncPositioning

	local callbacks = asyncPositioning.callbacks or {}
	asyncPositioning.callbacks = callbacks

	local callbacksIdx = asyncPositioning.callbacksIdx or {}
	asyncPositioning.callbacksIdx = callbacksIdx

	if not callbacksIdx[callback] then
		callbacksIdx[callback] = true
		table.insert(callbacks, callback)
	end
end

function LIB.VectorToLocalToWorld(ent, vec)
	if not IsValid(ent) then return nil end

	vec = vec or Vector()
	vec = ent:LocalToWorld(vec)

	return vec
end

function LIB.DirToLocalToWorld(ent, ang, dir)
	if not IsValid(ent) then return nil end

	dir = tostring(dir or "")

	if dir == "" then
		dir = "Forward"
	end

	ang = ang or Angle()
	ang = ent:LocalToWorldAngles(ang)

	local func = ang[dir]
	if not isfunction(func) then return end

	return func(ang)
end

function LIB.GetAttachmentCache(ent, forceRebuild)
	if not LIBModel.IsValidModelEntity(ent) then
		return nil
	end

	local entTable = ent:SligWolf_GetTable()

	if not entTable.attachmentIdCache then
		entTable.attachmentIdCache = {}
		forceRebuild = true
	end

	if not entTable.attachmentNameCache then
		entTable.attachmentNameCache = {}
		forceRebuild = true
	end

	local attachmentIdCache = entTable.attachmentIdCache
	local attachmentNameCache = entTable.attachmentNameCache

	if forceRebuild then
		local attachments = ent:GetAttachments()
		if not attachments then
			return nil
		end

		table.Empty(attachmentIdCache)
		table.Empty(attachmentNameCache)

		for i, item in ipairs(attachments) do
			if not item then
				continue
			end

			local id = item.id
			local name = item.name

			if id <= 0 then
				continue
			end

			if name == "" then
				continue
			end

			attachmentIdCache[id] = id
			attachmentIdCache[name] = id

			attachmentNameCache[id] = name
			attachmentNameCache[name] = name
		end
	end

	return attachmentIdCache, attachmentNameCache
end

function LIB.GetAttachmentId(ent, attachment)
	if not attachment then
		return nil
	end

	local attachmentIdCache = LIB.GetAttachmentCache(ent, false)
	if not attachmentIdCache then
		return nil
	end

	if istable(attachment) then
		attachment = attachment.id
	end

	attachment = attachmentIdCache[attachment]
	return attachment
end

function LIB.GetAttachmentName(ent, attachment)
	if not attachment then
		return nil
	end

	local _, attachmentNameCache = LIB.GetAttachmentCache(ent, false)
	if not attachmentNameCache then
		return nil
	end

	if istable(attachment) then
		attachment = attachment.id
	end

	attachment = attachmentNameCache[attachment]
	return attachment
end

function LIB.GetAttachmentPosAng(ent, attachment)
	attachment = LIB.GetAttachmentId(ent, attachment)

	if not attachment then
		local pos = ent:GetPos()
		local ang = ent:GetAngles()

		return pos, ang, false
	end

	local attachmentData = ent:GetAttachment(attachment)
	if not attachmentData then
		local pos = ent:GetPos()
		local ang = ent:GetAngles()

		return pos, ang, false
	end

	local pos = attachmentData.Pos
	local ang = attachmentData.Ang

	return pos, ang, true
end

function LIB.GetAngPosViaAttachmentMount(parentEnt, selfEnt, parentAttachment, selfAttachment)
	if not LIBModel.IsValidModelEntity(parentEnt) then return nil end
	if not LIBModel.IsValidModelEntity(selfEnt) then return nil end

	local PosA, AngA, HasAttA = LIB.GetAttachmentPosAng(parentEnt, parentAttachment)
	local PosB, AngB, HasAttB = LIB.GetAttachmentPosAng(selfEnt, selfAttachment)

	if not HasAttA and not HasAttB then
		return PosA, AngA
	end

	if not HasAttB then
		return PosA, AngA
	end

	local localPosA = parentEnt:WorldToLocal(PosA)
	local localAngA = parentEnt:WorldToLocalAngles(AngA)

	local localPosB = selfEnt:WorldToLocal(PosB)
	local localAngB = selfEnt:WorldToLocalAngles(AngB)

	local M = Matrix()

	M:SetAngles(localAngA)
	M:SetTranslation(localPosA)

	local M2 = Matrix()
	M2:SetAngles(localAngB)
	M2:SetTranslation(localPosB)

	M = M * M2:GetInverseTR()

	local ang = M:GetAngles()
	local pos = M:GetTranslation()

	pos = parentEnt:LocalToWorld(pos)
	ang = parentEnt:LocalToWorldAngles(ang)

	return pos, ang
end

function LIB.SetEntAngPosViaAttachment(parentEnt, selfEnt, parentAttachment, selfAttachment, callback)
	local pos, ang = LIB.GetAngPosViaAttachmentMount(parentEnt, selfEnt, parentAttachment, selfAttachment)

	if not pos then
		return false
	end

	if not ang then
		return false
	end

	LIB.SetPosAng(selfEnt, pos, ang, callback)
	return true
end

function LIB.MountToAttachment(parentEnt, selfEnt, parentAttachment, selfAttachment, callback)
	if not LIBModel.IsValidModelEntity(parentEnt) then return false end
	if not LIBModel.IsValidModelEntity(selfEnt) then return false end

	local entTable = selfEnt:SligWolf_GetTable()
	local mountPoint = entTable.mountPoint

	if mountPoint and IsValid(mountPoint.parentEnt) then
		local parentAttachmentName = LIB.GetAttachmentName(ent, mountPoint.parentAttachment)
		local selfAttachmentName = LIB.GetAttachmentName(ent, mountPoint.selfAttachment)

		LIBPrint.ErrorNoHaltWithStack(
			"Entities already mounted %s <===> %s. Attachments %s <===> %s.",
			selfEnt,
			mountPoint.parentEnt,
			tostring(selfAttachmentName or "<origin>"),
			tostring(parentAttachmentName or "<origin>")
		)

		return false
	end

	local parentAttachment = LIB.GetAttachmentId(parentEnt, parentAttachment)
	local selfAttachment = LIB.GetAttachmentId(selfEnt, selfAttachment)

	if not LIB.SetEntAngPosViaAttachment(parentEnt, selfEnt, parentAttachment, selfAttachment, callback) then
		return false
	end

	if not mountPoint then
		mountPoint = {}
		entTable.mountPoint = mountPoint
	end

	mountPoint.parentEnt = parentEnt
	mountPoint.parentAttachment = parentAttachment
	mountPoint.selfAttachment = selfAttachment

	return true
end

function LIB.GetMountPoint(selfEnt)
	local entTable = selfEnt:SligWolf_GetTable()

	local mountPoint = entTable.mountPoint
	if not mountPoint then
		return nil
	end

	local parentEnt = mountPoint.parentEnt
	if not IsValid(parentEnt) then
		return nil
	end

	return mountPoint
end

function LIB.RemountToMountPoint(selfEnt, mountPoint)
	mountPoint = mountPoint or LIB.GetMountPoint(selfEnt)
	if not mountPoint then
		return false
	end

	local parentEnt = mountPoint.parentEnt
	local parentAttachment = mountPoint.parentAttachment
	local selfAttachment = mountPoint.selfAttachment

	if not LIB.SetEntAngPosViaAttachment(parentEnt, selfEnt, parentAttachment, selfAttachment) then
		return false
	end

	return true
end

function LIB.GetNearestAttachment(ent, pos, filter)
	if not LIBModel.IsValidModelEntity(ent) then return nil end
	if not pos then return nil end

	local attachments = ent:GetAttachments()
	if not attachments then return nil end

	local nearstAttachment = nil
	local nearstDist = nil

	for i, attachment in ipairs(attachments) do
		local id = attachment.id
		local name = attachment.name

		if filter and not filter(ent, id, name) then
			continue
		end

		local attAngPos = ent:GetAttachment(id)
		if not attAngPos then
			continue
		end

		local attPos = attAngPos.Pos
		if not attPos then
			continue
		end

		local attDist = attPos:DistToSqr(pos)

		if nearstDist and nearstAttachment and nearstDist <= attDist then
			continue
		end

		nearstAttachment = {
			id = id,
			name = name,
			angPos = attAngPos,
			distanceSqr = attDist,
			ent = ent,
		}

		nearstDist = attDist
	end

	return nearstAttachment
end

function LIB.GetNearestAttachmentInEntities(entities, pos, filter)
	if not pos then return nil end

	entities = entities or {}

	if not istable(entities) then
		entities = {entities}
	end

	local nearstAttachment = nil
	local nearstDist = nil

	for i, ent in ipairs(entities) do
		local attachment = LIB.GetNearestAttachment(ent, pos, filter)
		if not attachment then
			continue
		end

		local attDist = attachment.distanceSqr

		if nearstDist and nearstAttachment and nearstDist <= attDist then
			continue
		end

		nearstAttachment = attachment
	end

	return nearstAttachment
end

function LIB.UpdatePlayerPosData(ply)
	local data = LIB.GetPlayerPosData(ply)
	if not data then
		return nil
	end

	if data.skipNextUpdate then
		return data
	end

	data.ply = ply

	data.pos = ply:GetPos()
	data.eyePos = ply:EyePos()

	data.aimVector = ply:GetAimVector()

	local eyeAngles = ply:LocalEyeAngles()
	local vehicle = ply:GetVehicle()

	if IsValid(vehicle) then
		-- fix for wonky angles in vehicles
		eyeAngles = vehicle:LocalToWorldAngles(eyeAngles)
	end

	data.eyeAngles = eyeAngles
	data.aimVectorNoCursor = eyeAngles:Forward()

	return data
end

function LIB.GetPlayerPosData(ply)
	if not ply then
		return nil
	end

	local plyTable = ply:SligWolf_GetTable()

	local data = plyTable.lastPlyPosData or {}
	plyTable.lastPlyPosData = data

	return data
end

function LIB.GetPlayerPos(ply)
	local data = LIB.GetPlayerPosData(ply)
	if not data then
		return
	end

	return data.pos
end

function LIB.GetPlayerEyePos(ply)
	local data = LIB.GetPlayerPosData(ply)
	if not data then
		return
	end

	return data.eyePos
end

function LIB.GetPlayerEyeAngles(ply)
	local data = LIB.GetPlayerPosData(ply)
	if not data then
		return
	end

	return data.eyeAngles
end

function LIB.GetPlayerAimVectorNoCursor(ply)
	local data = LIB.GetPlayerPosData(ply)
	if not data then
		return
	end

	return data.aimVectorNoCursor
end

function LIB.GetPlayerAimVector(ply)
	local data = LIB.GetPlayerPosData(ply)
	if not data then
		return
	end

	return data.aimVector
end

function LIB.GetAnglesDifference(angA, angB)
	local normalA = angA:Up()
	local normalB = angB:Up()

	local cross = normalA:Cross(normalB):Length()
	local dot = normalA:Dot(normalB)

	local diff = math.atan2(cross, dot)

	diff = math.deg(diff)
	return diff
end

function LIB.Load()
	LIBPrint = SligWolf_Addons.Print
	LIBModel = SligWolf_Addons.Model
	LIBTimer = SligWolf_Addons.Timer
	LIBUtil = SligWolf_Addons.Util

	local LIBHook = SligWolf_Addons.Hook

	local function UpdatePlayerPos_SkipNextUpdate(ply, vehicle)
		local data = LIB.GetPlayerPosData(ply)
		if not data then
			return
		end

		-- do not update the pos data with broken data, better use old data instead
		data.skipNextUpdate = true
	end

	LIBHook.Add("PlayerLeaveVehicle", "Library_Position_UpdatePlayerPos_SkipNextUpdate", UpdatePlayerPos_SkipNextUpdate, 1000)
	LIBHook.Add("PlayerEnteredVehicle", "Library_Position_UpdatePlayerPos_SkipNextUpdate", UpdatePlayerPos_SkipNextUpdate, 1000)

	local function UpdatePlayerPos(ply, key)
		local badState = false

		for i, ply in LIBUtil.GetPlayerIterator() do
			local data = LIB.UpdatePlayerPosData(ply)
			if not data then
				badState = true
				continue
			end

			data.skipNextUpdate = nil
		end

		if badState then
			LIB.InvalidatePlayerIteratorCache()
			error("Bad state in player iterator detected!")
		end
	end

	LIBHook.Add("Think", "Library_Position_UpdatePlayerPos", UpdatePlayerPos, 1000)
end

return true

