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

local CONSTANTS = SligWolf_Addons.Constants

local LIBPosition = nil
local LIBEntities = nil
local LIBUtil = nil
local LIBTimer = nil

local g_maxTraceDistance = 96
local g_maxAttachmentDistanceSqr = 16 * 16

local g_trace = {}
local g_traceResult = {}

g_trace.output = g_traceResult

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

function LIB.TraceSeatAttachment(ply)
	if not IsValid(ply) then return nil end

	local dir = ply:GetAimVector()

	g_trace.start = ply:EyePos()
	g_trace.endpos = g_trace.start + dir * g_maxTraceDistance
	g_trace.filter = ply

	util.TraceLine(g_trace)

	if not g_traceResult.Hit then
		return nil
	end

	local pos = g_traceResult.HitPos
	if not pos then
		return nil
	end

	local ent = g_traceResult.Entity
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

	if LIBUtil.IsDeveloper() then
		local angPos = nearstAttachment.angPos
		local text = string.format("Nearst Seat: %s, %0.3f units away", nearstAttachment.name, math.sqrt(dist))

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

	local nearstAttachment = LIB.TraceSeatAttachment(ply)
	if not nearstAttachment then return nil end

	local ent = nearstAttachment.ent
	if not ent.sligwolf_seatGroupEntity then return nil end

	local name = nearstAttachment.name

	return ent:TakeSeat(ply, name)
end

function LIB.TakeSeat(ply, seatGroup, attachmentName)
	if not IsValid(ply) then return nil end
	if not IsValid(seatGroup) then return nil end

	local seat = LIB.GetOrSpawnSeat(seatGroup, attachmentName)
	if not IsValid(seat) then
		return nil
	end

	LIBTimer.SimpleNextFrame(function()
		if not IsValid(ply) then return end
		if not IsValid(seat) then return end
		if seat:IsMarkedForDeletion() then return end

		local canEnter = hook.Run("CanPlayerEnterVehicle", ply, seat, 1)
		if not canEnter then
			LIB.RemoveSeat(seat)
			return
		end

		ply:EnterVehicle(seat)
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

	seat:SetModel(seatGroup:GetSeatModel())

	if not LIBPosition.SetEntAngPosViaAttachment(seatGroup, seat, attachmentName) then
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

	LIBEntities.RemoveEntity(seat)

	LIBEntities.ClearChildrenCache(seatGroup)
	LIBEntities.ClearChildrenCache(root)
end

function LIB.RemoveSeatByAttachment(seatGroup, attachmentName)
	local seat = LIB.GetSeat(seatGroup, attachmentName)
	LIB.RemoveSeat(seat)
end

function LIB.ExitSeatTrace(ply)
	if not IsValid(ply) then return end
end

function LIB.ExitSeat(ply)
	if not IsValid(ply) then return end
end

function LIB.Load()
	LIBPosition = SligWolf_Addons.Position
	LIBEntities = SligWolf_Addons.Entities
	LIBUtil = SligWolf_Addons.Util
	LIBTimer = SligWolf_Addons.Timer

	if SERVER then
		local LIBHook = SligWolf_Addons.Hook

		local function PlayerLeaveSeat(ply, seat)
			if not IsValid(seat) then return end

			if not seat:IsValidVehicle() then return end

			if not seat.sligwolf_vehicle then return end
			if not seat.sligwolf_Addonname then return end
			if not seat.sligwolf_vehicleDynamicSeat then return end

			LIB.ExitSeat(ply)
			LIB.RemoveSeat(seat)
		end

		LIBHook.Add("PlayerLeaveVehicle", "Library_Seat_PlayerLeaveSeat", PlayerLeaveSeat, 21000)

		-- local function test(ply, key)
		-- 	local ply = Entity(1)

		-- 	LIB.ExitSeatTrace(ply)
		-- end

		-- LIBHook.Add("Think", "Library_Seat_Test", test, 10000)
	end
end

return true

