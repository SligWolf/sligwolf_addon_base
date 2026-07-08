local SligWolf_Addons = _G.SligWolf_Addons
if not SligWolf_Addons then
	return
end

local LIB = SligWolf_Addons:NewLib("Player")

local LIBHook = SligWolf_Addons.Hook

function LIB.IsAdmin(ply)
	if CLIENT and ply == nil then
		ply = LocalPlayer()
	end

	if not IsValid(ply) then
		return false
	end

	if not ply:IsAdmin() then
		return false
	end

	return true
end

function LIB.IsAdminForCMD(ply)
	if ply == nil then
		return true
	end

	if not LIB.IsAdmin(ply) then
		return false
	end

	return true
end

function LIB.IsHostPlayer(ply)
	if game.IsDedicated() then
		return false
	end

	if CLIENT and ply == nil then
		ply = LocalPlayer()
	end

	if not IsValid(ply) then
		return false
	end

	if not ply:IsPlayer() then
		return false
	end

	if ply:IsBot() then
		return false
	end

	if not ply:IsAdmin() then
		return false
	end

	if ply:IsListenServerHost() then
		return true
	end
end

function LIB.IsHostPlayerForCMD(ply)
	if ply == nil then
		return true
	end

	if not LIB.IsHostPlayer(ply) then
		return false
	end

	return true
end

local g_hostPlayer = nil

function LIB.GetHostPlayer()
	if game.IsDedicated() then
		return nil
	end

	if g_hostPlayer and LIB.IsHostPlayer(g_hostPlayer) then
		return g_hostPlayer
	end

	g_hostPlayer = nil

	for _, ply in player.Iterator() do
		if not ply then
			continue
		end

		if not LIB.IsHostPlayer(ply) then
			continue
		end

		g_hostPlayer = ply
		return g_hostPlayer
	end

	return nil
end

local g_failbackPlayer = nil

function LIB.GetFailbackPlayer()
	if IsValid(g_failbackPlayer) then
		return g_failbackPlayer
	end

	g_failbackPlayer = nil

	local hostPly = LIB.GetHostPlayer()
	if IsValid(hostPly) then
		g_failbackPlayer = hostPly
		return g_failbackPlayer
	end

	for _, ply in player.Iterator() do
		if not IsValid(ply) then
			continue
		end

		if ply:IsSuperAdmin() then
			g_failbackPlayer = ply
			return g_failbackPlayer
		end
	end

	for _, ply in player.Iterator() do
		if not IsValid(ply) then
			continue
		end

		if ply:IsAdmin() then
			g_failbackPlayer = ply
			return g_failbackPlayer
		end
	end

	for _, ply in player.Iterator() do
		if not IsValid(ply) then
			continue
		end

		g_failbackPlayer = ply
		return g_failbackPlayer
	end

	return nil
end

function LIB.InvalidateFailbackPlayer()
	g_failbackPlayer = nil
end

function LIB.Load()
	LIBHook = SligWolf_Addons.Hook

	LIBHook.Add("PlayerDisconnected", "Library_Player_InvalidateFailbackPlayer", LIB.InvalidateFailbackPlayer, -1000000)
	LIBHook.Add("PlayerInitialSpawn", "Library_Player_InvalidateFailbackPlayer", LIB.InvalidateFailbackPlayer, -1000000)
end


return true

