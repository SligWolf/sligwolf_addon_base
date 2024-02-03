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
local LIBUtil = SligWolf_Addons.Util

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

return true

