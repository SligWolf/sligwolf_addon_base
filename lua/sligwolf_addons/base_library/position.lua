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

local LIB = SligWolf_Addons.Position

local LIBUtil = nil
local LIBPrint = nil

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
	if not LIBUtil.IsValidModelEntity(ent) then
		return nil
	end

	local entTable = ent:SligWolf_GetTable()
	if not entTable then
		return nil
	end

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
	if not LIBUtil.IsValidModelEntity(parentEnt) then return nil end
	if not LIBUtil.IsValidModelEntity(selfEnt) then return nil end

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

function LIB.SetEntAngPosViaAttachment(parentEnt, selfEnt, parentAttachment, selfAttachment)
	local pos, ang = LIB.GetAngPosViaAttachmentMount(parentEnt, selfEnt, parentAttachment, selfAttachment)

	if not pos then
		return false
	end

	if not ang then
		return false
	end

	selfEnt:SetPos(pos)
	selfEnt:SetAngles(ang)

	return true
end

function LIB.MountToAttachment(parentEnt, selfEnt, parentAttachment, selfAttachment)
	if not LIBUtil.IsValidModelEntity(parentEnt) then return false end
	if not LIBUtil.IsValidModelEntity(selfEnt) then return false end

	local selfEntTable = selfEnt:SligWolf_GetTable()
	if not selfEntTable then
		return nil
	end

	local mountPoint = selfEntTable.mountPoint

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

	if not LIB.SetEntAngPosViaAttachment(parentEnt, selfEnt, parentAttachment, selfAttachment) then
		return false
	end

	if not mountPoint then
		mountPoint = {}
		selfEntTable.mountPoint = mountPoint
	end

	mountPoint.parentEnt = parentEnt
	mountPoint.parentAttachment = parentAttachment
	mountPoint.selfAttachment = selfAttachment

	return true
end

function LIB.GetMountPoint(selfEnt)
	local selfEntTable = selfEnt:SligWolf_GetTable()
	if not selfEntTable then
		return nil
	end

	local mountPoint = selfEntTable.mountPoint
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
	if not LIBUtil.IsValidModelEntity(ent) then return nil end
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
		return
	end

	if data.skipNextUpdate then
		return data
	end

	data.ply = ply

	data.pos = ply:GetPos()
	data.eyePos = ply:EyePos()

	data.aimVector = ply:GetAimVector()

	local eyeAngles = ply:LocalEyeAngles()
	local parent = ply:GetParent()

	if IsValid(parent) then
		-- fix for wongy angles in vehicles
		eyeAngles = parent:LocalToWorldAngles(eyeAngles)
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
	if not plyTable then
		return nil
	end

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

	return data.eyeVector
end

function LIB.Load()
	LIBUtil = SligWolf_Addons.Util
	LIBPrint = SligWolf_Addons.Print

	local LIBHook = SligWolf_Addons.Hook

	local function UpdatePlayerPos_SkipNextUpdate(ply, vehicle)
		local data = LIB.GetPlayerPosData(ply)
		if not data then
			return
		end

		-- do not update the pos data with broken data, better use old data instead
		data.skipNextUpdate = true
	end

	LIBHook.Add("PlayerLeaveVehicle", "Library_Position_UpdatePlayerPos_SkipNextUpdate", UpdatePlayerPos_SkipNextUpdate, 1000000)
	LIBHook.Add("PlayerEnteredVehicle", "Library_Position_UpdatePlayerPos_SkipNextUpdate", UpdatePlayerPos_SkipNextUpdate, 1000000)

	local function UpdatePlayerPos(ply, key)
		for i, ply in player.Iterator() do
			local data = LIB.UpdatePlayerPosData(ply)
			if not data then
				continue
			end

			data.skipNextUpdate = nil
		end
	end

	LIBHook.Add("Think", "Library_Position_UpdatePlayerPos", UpdatePlayerPos, 1000000)
end

return true

