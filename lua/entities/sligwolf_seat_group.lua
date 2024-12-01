AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

DEFINE_BASECLASS("sligwolf_phys")

ENT.Spawnable 				= false
ENT.AdminOnly 				= false
ENT.DoNotDuplicate 			= true

ENT.sligwolf_noPickup = true
ENT.sligwolf_blockedprop = true

ENT.sligwolf_seatGroupEntity = true

if not SligWolf_Addons then return end
if not SligWolf_Addons.IsLoaded then return end
if not SligWolf_Addons.IsLoaded() then return end

local CONSTANTS = SligWolf_Addons.Constants

local LIBModel = SligWolf_Addons.Model
local LIBSeat = SligWolf_Addons.Seat

ENT.SeatModel = CONSTANTS.mdlDynamicSeat
ENT.SeatKeyValues = {
	vehiclescript = "scripts/vehicles/prisoner_pod.txt",
	limitview = 0,
}

function ENT:Initialize()
	BaseClass.Initialize(self)

	if SERVER then
		self:SetUseType(SIMPLE_USE)
	end
end

function ENT:InitializePhysics()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
end

function ENT:Use(activator, caller, useType, value)
	if CLIENT then return end

	if not IsValid(activator) then return end
	if not activator:IsPlayer() then return end

	if LIBSeat.SeatGroupUsageBounced(activator) then
		return
	end

	LIBSeat.TraceAndTakeSeat(activator)
	LIBSeat.DebounceSeatGroupUsage(activator)
end

function ENT:SetSeatModel(model)
	if CLIENT then return end
	self.SeatModel = LIBModel.LoadModel(model, CONSTANTS.mdlDynamicSeat)
end

function ENT:GetSeatModel()
	if CLIENT then return end
	return self.SeatModel
end

function ENT:SetSeatKeyValues(seatKeyValues)
	if CLIENT then return end

	local seatKeyValuesCopy = {}

	for k, v in pairs(seatKeyValues) do
		k = tostring(k)
		seatKeyValuesCopy[k] = v
	end

	self.SeatKeyValues = seatKeyValuesCopy
end

function ENT:GetSeatKeyValues()
	if CLIENT then return end
	return self.SeatKeyValues
end

function ENT:TakeSeat(ply, attachmentName)
	if CLIENT then return end

	return LIBSeat.TakeSeat(ply, self, attachmentName)
end

function ENT:GetOrSpawnSeat(attachmentName)
	if CLIENT then return end

	return LIBSeat.GetOrSpawnSeat(self, attachmentName)
end

function ENT:GetSeat(attachmentName)
	if CLIENT then return end

	return LIBSeat.GetSeat(self, attachmentName)
end

function ENT:IsSeatOccupied(attachmentName)
	if CLIENT then return end

	return LIBSeat.IsSeatOccupied(self, attachmentName)
end

function ENT:RemoveSeat(seat)
	if CLIENT then return end

	LIBSeat.RemoveSeat(seat)
end

function ENT:RemoveSeatByAttachment(attachmentName)
	if CLIENT then return end

	LIBSeat.RemoveSeatByAttachment(attachmentName)
end

