AddCSLuaFile()

if !SW_Addons then
	return
end

if !SW_ADDON then
	SW_Addons.AutoLoadAddon(function() end)
	return
end

function SW_ADDON:ChangePoseParameter(ent, poseName, pose)
	if !IsValid(ent) then return end

	poseName = tostring(poseName or "")
	pose = tonumber(pose or 0)
	
	ent:SetPoseParameter(poseName, pose) 
end

function SW_ADDON:GetBoneArray(ent)
	if !IsValid(ent) then return end
	
	local EntArray = {}
	local BoneArray = {}
	local BoneAngArray = {}
	local BonePosArray = {}
	
	for i = 1, 128 do		
		local Bone = ent:GetBoneName(i)
		if !Bone or Bone == "" or Bone == "__INVALIDBONE__" then continue end
		
		BoneArray[i] = Bone
		BoneAngArray[i] = ent:GetManipulateBoneAngles(i)
		BonePosArray[i] = ent:GetManipulateBonePosition(i)
	end
	
	EntArray = {
		Bones = BoneArray,
		Angles = BoneAngArray,
		Positions = BonePosArray,
	}
	
	ent.__SW_EntArray_Bone_Ang_Pos = EntArray
end

function SW_ADDON:CheckBoneArray(ent)
	if !IsValid(ent) then return false end
	
	local tb0 = ent.__SW_EntArray_Bone_Ang_Pos
	if !istable(tb0) then return false end
	
	local Check = table.GetKeys(tb0)
	local Num0 = table.Count(tb0)
	if !istable(Check) then return false end
	if !Num0 == 3 then return false end
	
	local tb1 = tb0.Bones
	local tb2 = tb0.Angles
	local tb3 = tb0.Positions
	
	if !istable(tb1) or !istable(tb2) or !istable(tb3) then return false end
	
	local Num1 = table.Count(tb1)
	local Num2 = table.Count(tb2)
	local Num3 = table.Count(tb3)
	
	if Num1 != Num2 then return false end
	if Num2 != Num3 then return false end
	if Num3 != Num1 then return false end
	
	return true
end

function SW_ADDON:BoneEdit(ent, name, ang, vec)
	if !IsValid(ent) then return end
	
	local Check = self:CheckBoneArray(ent)
	if !Check then return end
	
	local TB = ent.__SW_EntArray_Bone_Ang_Pos
	
	name = name or nil
	local Bone = ent:LookupBone(name)
	if !Bone then return end
	vec = vec or TB.Positions[Bone] or Vector()
	ang = ang or TB.Angles[Bone] or Angle()
	
	ent:ManipulateBonePosition(Bone, vec) 
	ent:ManipulateBoneAngles(Bone, ang)
end

function SW_ADDON:SetAnim(ent, anim, frame, rate)
	if !IsValid(ent) then return end

	if isstring(anim) then
		anim = ent:LookupSequence(anim)
	end

	ent:ResetSequence(anim or 0)
	ent:SetCycle(frame or 0)
	ent:SetPlaybackRate(rate or 1)
end