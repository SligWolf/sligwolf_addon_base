AddCSLuaFile()

if !SW_Addons then
	return
end

if !SW_ADDON then
	SW_Addons.AutoLoadAddon(function() end)
	return
end

function SW_ADDON:RemoveUTimerOnEnt(ent, name)

	if !IsValid(ent) then return end
	if !ent.GetCreationID then return end

	name = tostring(name or "")
	
	local uname = self.NetworkaddonID.."_"..ent:GetCreationID().."_"..name
	timer.Remove(uname)
end

function SW_ADDON:CreateUTimerOnEnt(ent, name, time, func, repeats)

	if !IsValid(ent) then return end
	if !ent.GetCreationID then return end
	
	name = tostring(name or "")
	time = tonumber(time or 0)
	repeats = tonumber(repeats or 0)
	
	if repeats <= 0 then
		repeats = 1
	end
	
	if time < 0 then
		time = 0
	end
	
	local uname = self.NetworkaddonID.."_"..ent:GetCreationID().."_"..name
	
	timer.Remove(uname)
	timer.Create(uname, time, repeats, function()
	
		if !IsValid(ent) then
			timer.Remove(uname)
			return
		end
	
		func(ent)
	end)
end