AddCSLuaFile()

if !SW_Addons then
	return
end

if !SW_ADDON then
	SW_Addons.AutoLoadAddon(function() end)
	return
end

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

local TRACE_RESULT_BUFFER = {}

function SW_ADDON:TracerChain(ent, vectorChain, filterfunc)
	if !IsValid(ent) then return nil end
	
	vectorChain = vectorChain or {}

	if !isfunction(filterfunc) then
		filterfunc = (function()
			return true
		end)
	end
	
	local tr = TRACE_RESULT_BUFFER
	
	local lastVector = nil
	local hasTraced = false
	
	local internalFilterfunc = function(trent, ...)
		if !IsValid(ent) then return false end
		if !IsValid(trent) then return false end
		if trent == ent then return false end
		
		local sp = self:GetSuperParent(ent)
		if IsValid(sp) then
			if trent == sp then return false end
			if self:GetSuperParent(trent) == sp then return false end
		end

		return filterfunc(self, sp, trent, ...)
	end

	for _, thisVector in ipairs(vectorChain) do
		if not lastVector then
			lastVector = thisVector
			
			debugoverlay.EntityTextAtPosition(lastVector, LineOffset_trText, "Start", 0.05, Color_trText)

			continue
		end
		
		util.TraceLine({
			output = tr,
			start = lastVector,
			endpos = thisVector,
			filter = internalFilterfunc,
		})
		
		lastVector = thisVector
		hasTraced = true
		
		local trStart = tr.StartPos
		local trEnd = thisVector
		local trHitPos = tr.HitPos
		local trHit = tr.Hit
		
		debugoverlay.Line(trStart, trHitPos, 0.05, Color_trGreen, true)
		debugoverlay.Line(trHitPos, trEnd, 0.05, Color_trBlue, true)
		debugoverlay.Cross(trEnd, 1, 0.05, Color_trCross, true) 
		
		if trHit then
			debugoverlay.Cross(trHitPos, 1, 0.05, Color_trCross, true) 
			debugoverlay.EntityTextAtPosition(trHitPos, LineOffset_trText, "Hit", 0.05, Color_trTextHit)

			break
		end
	end

	if hasTraced and lastVector then
		debugoverlay.EntityTextAtPosition(lastVector, LineOffset_trText, "End", 0.05, Color_trText)
		return tr
	end

	return nil
end

local TRACER_VECTOR_CHAIN_BUFFER = {}

function SW_ADDON:Tracer(ent, vecStart, vecEnd, filterfunc)
	if !IsValid(ent) then return nil end

	vecStart = vecStart or Vector()
	vecEnd = vecEnd or Vector()
	
	TRACER_VECTOR_CHAIN_BUFFER[1] = vecStart
	TRACER_VECTOR_CHAIN_BUFFER[2] = vecEnd
	
	tr = self:TracerChain(ent, TRACER_VECTOR_CHAIN_BUFFER, filterfunc)
	return tr
end

function SW_ADDON:TracerAttachment(ent, attachment, len, dir, filterfunc)
	len = tonumber(len or 0)
	dir = tostring(dir or "")
	
	if len == 0 then
		len = 1
	end
	
	if dir == "" then
		dir = "Forward"
	end
	
	local pos, ang = self:GetAttachmentPosAng(ent, attachment)
	if !pos then return end
		
	local func = ang[dir]
	if !isfunction(func) then return end

	local endpos = pos + func(ang) * len

	return self:Tracer(ent, pos, endpos, filterfunc)
end

function SW_ADDON:TracerAttachmentToAttachment(ent, attachmentA, attachmentB, filterfunc)
	local posA = self:GetAttachmentPosAng(ent, attachmentA)
	if !posA then return end

	local posB = self:GetAttachmentPosAng(ent, attachmentB)
	if !posB then return end

	debugoverlay.EntityTextAtPosition(posA, LineOffset_trText + 1, attachmentA, 0.05, Color_trText)
	debugoverlay.EntityTextAtPosition(posB, LineOffset_trText + 1, attachmentB, 0.05, Color_trText)

	return self:Tracer(ent, posA, posB, filterfunc)
end

function SW_ADDON:TracerAttachmentChain(ent, attachmentChain, filterfunc)
	local vectorChain = {}

	for _, attachmentChainItem in ipairs(attachmentChain) do
		local pos = self:GetAttachmentPosAng(ent, attachmentChainItem)
		if !pos then return end
		
		vectorChain[#vectorChain + 1] = pos
		debugoverlay.EntityTextAtPosition(pos, LineOffset_trText + 1, attachmentChainItem, 0.05, Color_trText)
	end

	return self:TracerChain(ent, vectorChain, filterfunc)
end

function SW_ADDON:CheckGround(ent, vec1, vec2)
	if !IsValid(ent) then return false end

	vec2 = vec2 or vec1
	vec1 = vec1 or vec2

	if !vec1 then return false end
	if !vec2 then return false end

	local vec1A = ent:LocalToWorld(Vector(vec1.x, vec1.y, vec1.z)) 
	local vec2A = ent:LocalToWorld(Vector(vec2.x, -vec2.y, vec2.z)) 

	local vec1B = ent:LocalToWorld(Vector(-vec1.x, vec1.y, vec1.z)) 
	local vec2B = ent:LocalToWorld(Vector(-vec2.x, -vec2.y, vec2.z)) 

	local tr1 = self:Tracer(ent, vec1A, vec2A)
	local tr2 = self:Tracer(ent, vec1B, vec2B)
	
	if tr1 and tr1.Hit then return true end
	if tr2 and tr2.Hit then return true end
	
	return false
end

local function GetCameraEnt(ply)
	if !IsValid(ply) and CLIENT then
		ply = LocalPlayer()
	end

	if !IsValid(ply) then return nil end
	local camera = ply:GetViewEntity()
	if !IsValid(camera) then return ply end

	return camera
end

function SW_ADDON:DoTrace(ply, maxdist, filter)
	local camera = GetCameraEnt(ply)
	local start_pos, end_pos
	if !IsValid(ply) then return nil end
	if !IsValid(camera) then return nil end
	
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
		if !IsValid(ent) then return false end
		if !IsValid(ply) then return false end
		if !IsValid(camera) then return false end
		if ent == ply then return false end
		if ent == camera then return false end
		
		if ply.GetVehicle and ent == ply:GetVehicle() then return false end
		if camera.GetVehicle and ent == camera:GetVehicle() then return false end

		if filter then
			if isfunction(filter) then
				if !filter(ent, ply, camera, ...) then
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