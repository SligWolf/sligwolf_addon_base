AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Bones = SligWolf_Addons.Bones or {}
table.Empty(SligWolf_Addons.Bones)

local LIB = SligWolf_Addons.Bones

function LIB.ChangePoseParameter(ent, poseName, pose)
	if not IsValid(ent) then return end

	poseName = tostring(poseName or "")
	pose = tonumber(pose or 0)

	ent:SetPoseParameter(poseName, pose)
end

function LIB.GetBoneArray(ent)
	if not IsValid(ent) then return end

	local EntArray = {}
	local BoneArray = {}
	local BoneAngArray = {}
	local BonePosArray = {}

	for i = 1, 128 do
		local Bone = ent:GetBoneName(i)
		if not Bone or Bone == "" or Bone == "__INVALIDBONE__" then continue end

		BoneArray[i] = Bone
		BoneAngArray[i] = ent:GetManipulateBoneAngles(i)
		BonePosArray[i] = ent:GetManipulateBonePosition(i)
	end

	EntArray = {
		Bones = BoneArray,
		Angles = BoneAngArray,
		Positions = BonePosArray,
	}

	local entTable = ent:SligWolf_GetTable()
	entTable.Bone_Ang_Pos = EntArray
end

function LIB.CheckBoneArray(ent)
	if not IsValid(ent) then return false end

	local entTable = ent:SligWolf_GetTable()

	local tb0 = entTable.Bone_Ang_Pos
	if not istable(tb0) then return false end

	local Check = table.GetKeys(tb0)
	local Num0 = table.Count(tb0)
	if not istable(Check) then return false end
	if Num0 ~= 3 then return false end

	local tb1 = tb0.Bones
	local tb2 = tb0.Angles
	local tb3 = tb0.Positions

	if not istable(tb1) or not istable(tb2) or not istable(tb3) then return false end

	local Num1 = table.Count(tb1)
	local Num2 = table.Count(tb2)
	local Num3 = table.Count(tb3)

	if Num1 ~= Num2 then return false end
	if Num2 ~= Num3 then return false end
	if Num3 ~= Num1 then return false end

	return true
end

function LIB.BoneEdit(ent, name, ang, vec)
	if not IsValid(ent) then return end

	local Check = LIB.CheckBoneArray(ent)
	if not Check then return end

	local entTable = ent:SligWolf_GetTable()
	local TB = entTable.Bone_Ang_Pos

	name = name or nil
	local Bone = ent:LookupBone(name)
	if not Bone then return end
	vec = vec or TB.Positions[Bone] or Vector()
	ang = ang or TB.Angles[Bone] or Angle()

	ent:ManipulateBonePosition(Bone, vec)
	ent:ManipulateBoneAngles(Bone, ang)
end

function LIB.SetAnim(ent, anim, frame, rate)
	if not IsValid(ent) then return end

	if isstring(anim) then
		anim = ent:LookupSequence(anim)
	end

	ent:ResetSequence(anim or 0)
	ent:SetCycle(frame or 0)
	ent:SetPlaybackRate(rate or 1)
end

return true

