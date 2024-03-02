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

local function seatAttachmentFilter(parentEnt, attId, attName)
	return string.StartsWith(attName, "seat_")
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

	if ent.sligwolf_vehicleDynamicSeat then
		return nil
	end

	if ent.sligwolf_buttonEntity then
		return nil
	end

	if ent.sligwolf_isConnector then
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
	local name = nearstAttachment.name

	local seat = LIB.TakeSeat(ply, ent, name)
	return seat
end

function LIB.TakeSeat(ply, parent, attachmentName)
	if not IsValid(ply) then return nil end
	if not IsValid(parent) then return nil end

	local seat = LIB.GetOrSpawnSeat(parent, attachmentName)
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

function LIB.GetOrSpawnSeat(parent, attachmentName)
	if not IsValid(parent) then return nil end

	local name = "DynamicSeat_" .. tostring(attachmentName)
	local seat = LIBEntities.GetChild(parent, name)

	if IsValid(seat) then
		return seat
	end

	local ownerPly = LIBEntities.GetOwner(parent)

	local seat = LIBEntities.MakeEnt("prop_vehicle_prisoner_pod", ownerPly, parent, name, addonname)
	if not IsValid(seat) then
		return nil
	end

	seat:SetModel(CONSTANTS.mdlDynamicSeat)

	if not LIBPosition.SetEntAngPosViaAttachment(parent, seat, attachmentName) then
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

	LIBEntities.SetupChildEntity(seat, parent, COLLISION_GROUP_NONE, attachmentName)

	return seat
end

function LIB.GetSeat(parent, attachmentName)
	if not IsValid(parent) then return nil end

	local name = "DynamicSeat_" .. tostring(attachmentName)
	local seat = LIB.GetChild(parent, name)

	if not IsValid(seat) then
		return nil
	end

	return seat
end

function LIB.RemoveSeat(seat)
	if not IsValid(seat) then return end

	local parent = LIBEntities.GetParent(seat)
	local root = LIBEntities.GetSuperParent(seat)

	LIBEntities.SetParent(seat, nil)

	LIBEntities.RemoveEntity(seat)

	LIBEntities.ClearChildrenCache(parent)
	LIBEntities.ClearChildrenCache(root)
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

		local function KeyPress(ply, key)
			if key ~= IN_USE then
				return
			end

			if not IsValid(ply) then
				return
			end

			if not ply:Alive() then
				return
			end

			if not ply:Alive() then
				return
			end

			if ply:InVehicle() then
				return
			end

			if ply:IsDrivingEntity() then
				return
			end

			LIB.TraceAndTakeSeat(ply)
		end

		LIBHook.Add("KeyPress", "Library_Seat_KeyPress", KeyPress, 10000)
	end
end

return true

