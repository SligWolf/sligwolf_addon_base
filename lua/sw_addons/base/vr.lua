AddCSLuaFile()

if !SW_Addons then
	return
end

if !SW_ADDON then
	SW_Addons.AutoLoadAddon(function() end)
	return
end

local SW_Addons = SW_Addons

function SW_Addons.VRExist()
	if !istable(vrmod) then return false end
	
	local Func = vrmod.IsPlayerInVR
	if !isfunction(Func) then return false end
	
	return true
end

function SW_Addons.VRIsPlayerInVR(ply)
	if !SW_Addons.VRExist() then return false end
	if !IsValid(ply) then return false end
	if !vrmod.IsPlayerInVR(ply) then return false end

	return true
end

function SW_ADDON:VRExist()
	return SW_Addons.VRExist()
end

function SW_ADDON:VRIsPlayerInVR(ply)
	return SW_Addons.VRIsPlayerInVR(ply)
end

local g_VRPoll_Delay = nil
local function VRPollInternal()
	local Past = g_VRPoll_Delay or 0
	local Now = CurTime()
	local Delay = Now - Past
	
	if Delay < 0.05 then
		return
	end
	
	for k, ply in ipairs(player.GetHumans()) do
		if !IsValid(ply) then continue end
		
		local LastVRState = ply.__SW_VRState or false
		local VRState = SW_Addons.VRIsPlayerInVR(ply)

		if VRState != LastVRState then
			-- Ensure the vr state change is detected on EVERY client without additional networking
			if VRState then
				SW_Addons.CallFunctionOnAllAddons("OnVRStart", ply)
			else
				SW_Addons.CallFunctionOnAllAddons("OnVRExit", ply)
			end
			
			SW_Addons.CallFunctionOnAllAddons("OnVRStateChange", ply, VRState)
			ply.__SW_VRState = VRState
		end
		
		if VRState then
			SW_Addons.CallFunctionOnAllAddons("OnVRThink", ply)
		end
	end
	
	g_VRPoll_Delay = Now
end

local function VRModStart(ply)
	if SW_Addons.VRExist() then
		g_VRPoll_Delay = nil
		VRPollInternal()
	end
end
hook.Remove("VRMod_Start", "SW_Common_VR_VRMod_Start")
hook.Add("VRMod_Start", "SW_Common_VR_VRMod_Start", VRModStart)

local function VRModExit(ply)
	if SW_Addons.VRExist() then
		g_VRPoll_Delay = nil
		VRPollInternal()
	end
end
hook.Remove("VRMod_Exit", "SW_Common_VR_VRMod_Exit")
hook.Add("VRMod_Exit", "SW_Common_VR_VRMod_Exit", VRModExit)

local function VRModThink()
	if SW_Addons.VRExist() then
		VRPollInternal()
	end
end
hook.Remove("Think", "SW_Common_VR_Think")
hook.Add("Think", "SW_Common_VR_Think", VRModThink)