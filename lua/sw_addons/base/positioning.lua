AddCSLuaFile()

if !SW_Addons then
	return
end

if !SW_ADDON then
	SW_Addons.AutoLoadAddon(function() end)
	return
end

function SW_ADDON:VectorToLocalToWorld(ent, vec)
	if !IsValid(ent) then return nil end
	
	vec = vec or Vector()
	vec = ent:LocalToWorld(vec)
	
	return vec
end

function SW_ADDON:DirToLocalToWorld(ent, ang, dir)
	if !IsValid(ent) then return nil end
	
	dir = tostring(dir or "")
	
	if dir == "" then
		dir = "Forward"
	end
	
	ang = ang or Angle()
	ang = ent:LocalToWorldAngles(ang)
		
		
	local func = ang[dir]
	if !isfunction(func) then return end

	return func(ang)
end

function SW_ADDON:GetAttachmentPosAng(ent, attachment)
	if !self:IsValidModel(ent) then return nil end
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

function SW_ADDON:SetEntAngPosViaAttachment(entA, entB, attA, attB)
	if !self:IsValidModel(entA) then return false end
	if !self:IsValidModel(entB) then return false end

	attA = tostring(attA or "")
	attB = tostring(attB or "")
	
	local PosA, AngA, HasAttA = self:GetAttachmentPosAng(entA, attA)
	local PosB, AngB, HasAttB = self:GetAttachmentPosAng(entB, attB)
	
	if !HasAttA and !HasAttB then
		entB:SetPos(PosA)
		entB:SetAngles(AngA)

		return true
	end

	if !HasAttB then
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