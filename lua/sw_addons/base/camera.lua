AddCSLuaFile()

if !SW_Addons then
	return
end

if !SW_ADDON then
	SW_Addons.AutoLoadAddon(function() end)
	return
end

function SW_ADDON:CamControl(ply, ent)

	if !IsValid(ply) then return end
	if !IsValid(ent) then return end
	
	if ply:GetViewEntity() == ent then
		ply:SetViewEntity(ply)
		ply.__SW_Cam_Mode = false
		return
	end
	ply:SetViewEntity(ent)
	ply.__SW_Cam_Mode = true
end

function SW_ADDON:ViewEnt(ply)
	if !IsValid(ply) then return end
	
	local Old_Cam = ply:GetViewEntity()
	ply.__SW_Old_Cam = Old_Cam
	local Cam = ply.__SW_Old_Cam
	
	if !IsValid(Cam) then return end
	if !ply.__SW_Cam_Mode then return end
	
	ply:SetViewEntity(ply)
	ply.__SW_Cam_Mode = false
end