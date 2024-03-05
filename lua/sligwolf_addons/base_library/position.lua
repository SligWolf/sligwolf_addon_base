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

function LIB.GetAttachmentPosAng(ent, attachment)
	if not LIBUtil.IsValidModelEntity(ent) then return nil end
	attachment = tostring(attachment or "")

	if attachment == "" then
		local pos = ent:GetPos()
		local ang = ent:GetAngles()

		return pos, ang, false
	end

	local Num = ent:LookupAttachment(attachment) or 0
	if Num <= 0 then
		local pos = ent:GetPos()
		local ang = ent:GetAngles()

		return pos, ang, false
	end

	local Att = ent:GetAttachment(Num)
	if not Att then
		local pos = ent:GetPos()
		local ang = ent:GetAngles()

		return pos, ang, false
	end

	local pos = Att.Pos
	local ang = Att.Ang

	return pos, ang, true
end

function LIB.SetEntAngPosViaAttachment(entA, entB, attA, attB)
	if not LIBUtil.IsValidModelEntity(entA) then return false end
	if not LIBUtil.IsValidModelEntity(entB) then return false end

	attA = tostring(attA or "")
	attB = tostring(attB or "")

	local PosA, AngA, HasAttA = LIB.GetAttachmentPosAng(entA, attA)
	local PosB, AngB, HasAttB = LIB.GetAttachmentPosAng(entB, attB)

	if not HasAttA and not HasAttB then
		entB:SetPos(PosA)
		entB:SetAngles(AngA)

		return true
	end

	if not HasAttB then
		entB:SetPos(PosA)
		entB:SetAngles(AngA)

		return true
	end

	local localPosA = entA:WorldToLocal(PosA)
	local localAngA = entA:WorldToLocalAngles(AngA)

	local localPosB = entB:WorldToLocal(PosB)
	local localAngB = entB:WorldToLocalAngles(AngB)

	local M = Matrix()

	M:SetAngles(localAngA)
	M:SetTranslation(localPosA)

	local M2 = Matrix()
	M2:SetAngles(localAngB)
	M2:SetTranslation(localPosB)

	M = M * M2:GetInverseTR()

	local ang = M:GetAngles()
	local pos = M:GetTranslation()

	pos = entA:LocalToWorld(pos)
	ang = entA:LocalToWorldAngles(ang)

	entB:SetAngles(ang)
	entB:SetPos(pos)

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

	local getTable = ply.GetTable
	if not getTable then
		return nil
	end

	local plyTable = getTable(ply)

	local data = plyTable.sligwolf_lastPlyPosData or {}
	plyTable.sligwolf_lastPlyPosData = data

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

