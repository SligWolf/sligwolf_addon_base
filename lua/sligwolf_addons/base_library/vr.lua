AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.VR = SligWolf_Addons.VR or {}
table.Empty(SligWolf_Addons.VR)

local LIB = SligWolf_Addons.VR
local LIBHook = SligWolf_Addons.Hook

function LIB.Exist()
	if not istable(vrmod) then return false end

	local isPlayerInVRFunc = vrmod.IsPlayerInVR
	if not isfunction(isPlayerInVRFunc) then return false end

	return true
end

function LIB.IsPlayerInVR(ply)
	if not LIB.Exist() then return false end
	if not IsValid(ply) then return false end
	if not vrmod.IsPlayerInVR(ply) then return false end

	return true
end

local g_VRPoll_Delay = nil

local function VRPoll()
	local Past = g_VRPoll_Delay or 0
	local Now = RealTime()
	local Delay = Now - Past

	if Delay < 0.05 then
		return
	end

	for k, ply in ipairs(player.GetHumans()) do
		if not IsValid(ply) then continue end

		local LastVRState = ply.SLIGWOLF_VRState or false
		local VRState = LIB.IsPlayerInVR(ply)

		if VRState ~= LastVRState then
			-- Ensure the vr state change is detected on EVERY client without additional networking
			if VRState then
				SligWolf_Addons.CallFunctionOnAllAddons("OnVRStart", ply)
			else
				SligWolf_Addons.CallFunctionOnAllAddons("OnVRExit", ply)
			end

			SligWolf_Addons.CallFunctionOnAllAddons("OnVRStateChange", ply, VRState)
			ply.SLIGWOLF_VRState = VRState
		end

		if VRState then
			SligWolf_Addons.CallFunctionOnAllAddons("OnVRThink", ply)
		end
	end

	g_VRPoll_Delay = Now
end

local function VRModStatusChange(ply)
	if not LIB.Exist() then
		return
	end

	g_VRPoll_Delay = nil
	VRPoll()
end

LIBHook.Add("VRMod_Start", "Library_VR_VRModStatusChange", VRModStatusChange, 10000)
LIBHook.Add("VRMod_Exit", "Library_VR_VRModStatusChange", VRModStatusChange, 10000)

local function VRModStatusPoll()
	if not LIB.Exist() then
		return
	end

	VRPoll()
end

LIBHook.Add("Think", "Library_VR_Poll", VRModStatusPoll, 10000)

return true

