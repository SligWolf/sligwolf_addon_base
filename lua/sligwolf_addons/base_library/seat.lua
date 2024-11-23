AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Seat = SligWolf_Addons.Seat or {}
table.Empty(SligWolf_Addons.Seat)

local LIB = SligWolf_Addons.Seat

local LIBPosition = nil
local LIBEntities = nil
local LIBDebug = nil
local LIBTimer = nil
local LIBModel = nil
local LIBHook = nil

local g_maxAttachmentTraceDistance = 96
local g_maxAttachmentDistanceSqr = 40 * 40

local g_seatSpawnTrace = {}
local g_seatSpawnTraceResult = {}

g_seatSpawnTrace.output = g_seatSpawnTraceResult

local function seatAttachmentFilter(seatGroup, attId, attName)
	if not string.StartsWith(attName, "seat_") then
		return false
	end

	if seatGroup.sligwolf_seatGroupEntity and seatGroup:IsSeatOccupied(attName) then
		return false
	end

	return true
end

local function seatAttachmentToName(attachmentName)
	local name = "DynamicSeat_" .. tostring(attachmentName or "")
	return name
end

function LIB.DebounceSeatGroupUsage(ply)
	if not IsValid(ply) then return end

	ply.sligwolf_seatGroup_nextUse = RealTime() + 0.25
end

function LIB.SeatGroupUsageBounced(ply)
	if not IsValid(ply) then
		return false
	end

	if not ply.sligwolf_seatGroup_nextUse then
		return false
	end

	if ply.sligwolf_seatGroup_nextUse < RealTime() then
		return false
	end

	return true
end

function LIB.TraceSeatAttachment(ply)
	if not IsValid(ply) then return nil end
	if ply:InVehicle() then return nil end

	local data = LIBPosition.GetPlayerPosData(ply)
	if not data then return end

	local eyePos = data.eyePos
	local aimVector = data.aimVectorNoCursor

	g_seatSpawnTrace.start = eyePos
	g_seatSpawnTrace.endpos = g_seatSpawnTrace.start + aimVector * g_maxAttachmentTraceDistance
	g_seatSpawnTrace.filter = ply

	util.TraceLine(g_seatSpawnTrace)

	if not g_seatSpawnTraceResult.Hit then
		return nil
	end

	local pos = g_seatSpawnTraceResult.HitPos
	if not pos then
		return nil
	end

	local ent = g_seatSpawnTraceResult.Entity
	if not IsValid(ent) then
		return nil
	end

	if not ent.sligwolf_entity then
		return nil
	end

	if not ent.sligwolf_seatGroupEntity then
		return nil
	end

	local nearstAttachment = LIBPosition.GetNearestAttachment(ent, pos, seatAttachmentFilter)
	if not nearstAttachment then
		return nil
	end

	local dist = nearstAttachment.distanceSqr

	if LIBDebug.IsDeveloper() then
		local angPos = nearstAttachment.angPos
		local text = string.format("Nearst found seat: %s, %0.3f units away", nearstAttachment.name, math.sqrt(dist))

		debugoverlay.Axis(angPos.Pos, angPos.Ang, 16, 2, true)
		debugoverlay.EntityTextAtPosition(angPos.Pos, 0, text, 2, color_white)
	end

	if dist > g_maxAttachmentDistanceSqr then
		return nil
	end

	return nearstAttachment
end

function LIB.TraceAndTakeSeat(ply)
	if not IsValid(ply) then return nil end
	if ply:InVehicle() then return nil end

	local nearstAttachment = LIB.TraceSeatAttachment(ply)
	if not nearstAttachment then return nil end

	local ent = nearstAttachment.ent
	if not ent.sligwolf_seatGroupEntity then return nil end

	local name = nearstAttachment.name

	return ent:TakeSeat(ply, name)
end

function LIB.TakeSeat(ply, seatGroup, attachmentName)
	if not IsValid(ply) then return nil end
	if ply:InVehicle() then return nil end

	if not IsValid(seatGroup) then return nil end

	local seat = LIB.GetOrSpawnSeat(seatGroup, attachmentName)
	if not IsValid(seat) then
		return nil
	end

	LIBTimer.SimpleNextFrame(function()
		if not IsValid(ply) then return end

		if LIBEntities.IsMarkedForDeletion(seat) then
			return
		end

		LIB.DebounceSeatGroupUsage(ply)

		local canEnter = LIBHook.Run("CanPlayerEnterVehicle", ply, seat, 1)
		if not canEnter then
			LIB.RemoveSeat(seat)
			return
		end

		ply:EnterVehicle(seat)

		-- @TODO: check view attachment in seat model?
		ply:SetEyeAngles(Angle(0, 90, 0))
	end)

	return seat
end

function LIB.GetOrSpawnSeat(seatGroup, attachmentName)
	if not IsValid(seatGroup) then return nil end
	if not seatGroup.sligwolf_seatGroupEntity then return nil end

	local name = seatAttachmentToName(attachmentName)
	local seat = LIBEntities.GetChild(seatGroup, name)

	if IsValid(seat) then
		return seat
	end

	local seat = seatGroup:MakeEnt("prop_vehicle_prisoner_pod", name)
	if not IsValid(seat) then
		return nil
	end

	LIBModel.SetModel(seat, seatGroup:GetSeatModel())

	if not LIBPosition.MountToAttachment(seatGroup, seat, attachmentName) then
		LIB.RemoveSeat(seat)
		return nil
	end

	seat.sligwolf_physEntity = true
	seat.sligwolf_vehicle = true
	seat.sligwolf_vehicleDynamicSeat = true

	seat.sligwolf_noPickup = true
	seat.sligwolf_blockedprop = true
	seat.sligwolf_blockAllTools = true

	seat:SetNWBool("sligwolf_blockedprop", true)
	seat:SetNWBool("sligwolf_blockAllTools", true)
	seat:SetNWBool("sligwolf_noPickup", true)

	local keyValues = seatGroup:GetSeatKeyValues()

	for k, v in pairs(keyValues) do
		seat:SetKeyValue(tostring(k), v)
	end

	seat:Spawn()
	seat:Activate()

	LIBEntities.SetupChildEntity(seat, seatGroup, COLLISION_GROUP_IN_VEHICLE, attachmentName)

	return seat
end

function LIB.GetSeat(seatGroup, attachmentName)
	if not IsValid(seatGroup) then return nil end

	local name = seatAttachmentToName(attachmentName)
	local seat = LIBEntities.GetChild(seatGroup, name)

	if not IsValid(seat) then
		return nil
	end

	return seat
end

function LIB.IsSeatOccupied(seatGroup, attachmentName)
	local seat = LIB.GetSeat(seatGroup, attachmentName)

	if not seat then
		return false
	end

	local driver = seat:GetDriver()

	if not IsValid(driver) then
		return false
	end

	return true
end

function LIB.RemoveSeat(seat)
	if not IsValid(seat) then return end

	local seatGroup = LIBEntities.GetParent(seat)
	local root = LIBEntities.GetSuperParent(seat)

	LIBEntities.SetParent(seat, nil)

	LIBEntities.RemoveEntity(seat, false)

	LIBEntities.ClearChildrenCache(seatGroup)
	LIBEntities.ClearChildrenCache(root)
end

function LIB.RemoveSeatByAttachment(seatGroup, attachmentName)
	local seat = LIB.GetSeat(seatGroup, attachmentName)
	LIB.RemoveSeat(seat)
end



local g_exitSeatTrace = {}
local g_exitSeatTraceResult = {}

g_exitSeatTrace.output = g_exitSeatTraceResult
g_exitSeatTrace.mask = MASK_PLAYERSOLID
g_exitSeatTrace.filter = function(ent)
	if not IsValid(ent) then return false end
	if g_exitSeatTrace.ply == ent then return false end

	if ent.sligwolf_vehicleDynamicSeat then return false end
	if ent.sligwolf_seatGroupEntity then return false end

	return true
end

local g_exitSeatTraceHull = {}
local g_exitSeatTraceHullResult = {}

g_exitSeatTraceHull.output = g_exitSeatTraceHullResult
g_exitSeatTraceHull.mask = MASK_PLAYERSOLID
g_exitSeatTraceHull.filter = function(ent)
	if not IsValid(ent) then return false end
	if g_exitSeatTraceHull.ply == ent then return false end

	if ent.sligwolf_vehicleDynamicSeat then return false end
	if ent.sligwolf_seatGroupEntity then return false end

	return true
end

local function buildSearchPattern(pos, mins, maxs, dir)
	local searchPattern = {}

	for x = -2, 2 do
		for y = -2, 2 do
			local v = Vector(x, y, 0)
			local dist = v:LengthSqr()

			table.insert(searchPattern, {
				v = v,
				dist = dist
			})
		end
	end

	table.SortByMember(searchPattern, "dist", true)

	return searchPattern
end

local g_exitSeatSearchTracePattern = buildSearchPattern()

local function traceGround(pos, mins, maxs, dir)
	if not pos then
		return nil
	end

	dir = dir or Vector(0, 0, -1)

	g_exitSeatTrace.start = pos
	g_exitSeatTrace.endpos = g_exitSeatTrace.start + dir * 128 * 2

	util.TraceLine(g_exitSeatTrace)

	if not g_exitSeatTraceResult.Hit then
		return nil
	end

	if not g_exitSeatTraceResult.HitPos then
		return nil
	end

	return g_exitSeatTraceResult
end

local function traceGroundHull(pos, mins, maxs, dir)
	if not pos then
		return nil
	end

	dir = dir or Vector(0, 0, -1)

	g_exitSeatTraceHull.start = pos
	g_exitSeatTraceHull.endpos = pos + dir * 128

	g_exitSeatTraceHull.mins = mins
	g_exitSeatTraceHull.maxs = maxs

	util.TraceHull(g_exitSeatTraceHull)

	if not g_exitSeatTraceHullResult.Hit then
		return nil
	end

	if not g_exitSeatTraceHullResult.HitPos then
		return nil
	end

	return g_exitSeatTraceHullResult
end

local function tracePlayerPlace(pos, mins, maxs)
	g_exitSeatTraceHull.start = pos
	g_exitSeatTraceHull.endpos = pos

	g_exitSeatTraceHull.mins = mins
	g_exitSeatTraceHull.maxs = maxs

	util.TraceHull(g_exitSeatTraceHull)

	if g_exitSeatTraceHullResult.Hit then
		return nil
	end

	return g_exitSeatTraceHullResult
end

local function traceGroundPattern(groundTrace, mins, maxs, size2D)
	local hitPos = groundTrace.HitPos
	local hitNormal = groundTrace.HitNormal

	local size = maxs - mins
	local gridSize = math.max(size.x, size.y) / 2

	for i, item in ipairs(g_exitSeatSearchTracePattern) do
		local gridpos = item.v * gridSize

		local tr = traceGroundHull(hitPos + gridpos + hitNormal * size2D / 4, mins, maxs, -hitNormal)
		if not tr then
			continue
		end

		local tr = tracePlayerPlace(tr.HitPos, mins, maxs)
		if not tr then
			continue
		end

		return tr
	end

	return nil
end

function LIB.ExitSeatTrace(ply)
	if not IsValid(ply) then return end

	local data = LIBPosition.GetPlayerPosData(ply)
	if not data then return end

	local eyePos = data.eyePos
	local aimVector = data.aimVectorNoCursor

	local mins, maxs = ply:GetHull()

	mins = mins - Vector(2, 2, 0)
	maxs = maxs + Vector(2, 2, 2)

	local size2D = maxs:Distance2D(mins) / 2 + 4
	local len = math.max(size2D * 1.4, 64)

	g_exitSeatTrace.ply = ply
	g_exitSeatTraceHull.ply = ply

	g_exitSeatTrace.start = eyePos
	g_exitSeatTrace.endpos = eyePos + aimVector * len

	util.TraceLine(g_exitSeatTrace)

	local pos = g_exitSeatTraceResult.HitPos
	if not pos then
		return nil
	end

	local hitNormal = g_exitSeatTraceResult.HitNormal

	if math.abs(hitNormal.z) > 0.95 then
		hitNormal = vector_origin
	end

	local tr = traceGround(pos + hitNormal * size2D, mins, maxs)
	if not tr then
		return nil
	end

	local tr = traceGroundPattern(tr, mins, maxs, size2D)
	if not tr then
		return nil
	end

	LIBDebug.ShowHullTrace(g_exitSeatTraceHull, tr, nil, 1)

	return tr
end

function LIB.ExitSeat(ply)
	if not IsValid(ply) then return end

	local eyePos = LIBPosition.GetPlayerEyePos(ply)
	if not eyePos then return end

	LIB.DebounceSeatGroupUsage(ply)

	local tr = LIB.ExitSeatTrace(ply)
	if not tr then
		return
	end

	local exitPos = tr.HitPos
	local exitAng = (exitPos - eyePos):Angle()

	ply:SetPos(exitPos)
	ply:SetEyeAngles(exitAng)
end

function LIB.Load()
	LIBPosition = SligWolf_Addons.Position
	LIBEntities = SligWolf_Addons.Entities
	LIBDebug = SligWolf_Addons.Debug
	LIBTimer = SligWolf_Addons.Timer
	LIBModel = SligWolf_Addons.Model
	LIBHook = SligWolf_Addons.Hook

	if SERVER then
		local function PlayerLeaveSeat(ply, seat)
			if not IsValid(seat) then return end

			if not seat:IsValidVehicle() then return end

			if not seat.sligwolf_vehicle then return end
			if not seat.sligwolf_addonname then return end
			if not seat.sligwolf_vehicleDynamicSeat then return end

			LIB.RemoveSeat(seat)
			LIB.ExitSeat(ply)
		end

		LIBHook.Add("PlayerLeaveVehicle", "Library_Seat_PlayerLeaveSeat", PlayerLeaveSeat, 21000)
	end
end

return true

