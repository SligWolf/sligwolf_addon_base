AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Coupling = SligWolf_Addons.Coupling or {}
table.Empty(SligWolf_Addons.Coupling)

local LIB = SligWolf_Addons.Coupling

local CONSTANTS = SligWolf_Addons.Constants

local LIBVehicleControl = nil
local LIBEntities = nil

function LIB.Load()
	LIBVehicleControl = SligWolf_Addons.VehicleControl
	LIBEntities = SligWolf_Addons.Entities
end

function LIB.GetTrailerData(vehicle)
	if not IsValid(vehicle) then
		return {}
	end

	local vehicle_table = vehicle:SligWolf_GetTable()
	return vehicle_table.trailerData
end

function LIB.InitTrailerData(vehicle)
	local vehicle_table = vehicle:SligWolf_GetTable()
	local trailer_data = vehicle_table.trailerData

	if trailer_data then
		return trailer_data
	end

	vehicle_table.trailerData = {}
	LIB.ResetTrailerData(vehicle)

	return trailer_data
end

function LIB.ResetTrailerData(vehicle)
	local trailer_data = LIB.GetTrailerData(vehicle)

	trailer_data.lightstate = false
	trailer_data.indicatorHazzard = false
	trailer_data.indicatorL = false
	trailer_data.indicatorR = false
	trailer_data.indicatorOnOff = false
	trailer_data.indicatorDelay = 0
end

function LIB.MarkAsTrailerMain(vehicle)
	if not IsValid(vehicle) then return end

	vehicle.sligwolf_isTrailerMain = true
	vehicle.sligwolf_isTrailer = false

	LIB.InitTrailerData(vehicle)
end

function LIB.MarkAsTrailer(vehicle)
	if not IsValid(vehicle) then return end

	vehicle.sligwolf_isTrailerMain = false
	vehicle.sligwolf_isTrailer = true

	LIB.InitTrailerData(vehicle)
end

function LIB.CloneDataFromMainTrailer(mainTrailer)
	if not IsValid(mainTrailer) then return end

	local mainTrailerData = LIB.GetTrailerData(mainTrailer)

	LIB.ForEachTrailerVehicles(mainTrailer, function(k, subTrailer)
		if mainTrailer == subTrailer then return end
		local subTrailerData = LIB.GetTrailerData(subTrailer)

		for key, value in pairs(mainTrailerData) do
			subTrailerData[key] = value
		end
	end)
end

function LIB.ResetDataOfSubTrailer(mainTrailer)
	if not IsValid(mainTrailer) then return end

	LIB.ForEachTrailerVehicles(mainTrailer, function(k, subTrailer)
		LIB.ResetTrailerData(subTrailer)
	end)
end

function LIB.GetConnectedVehicles(vehicle)
	vehicle = LIBEntities.GetSuperParent(vehicle)
	if not IsValid(vehicle) then return end

	vehicle.SLIGWOLF_Connected = vehicle.SLIGWOLF_Connected or {}
	return vehicle.SLIGWOLF_Connected
end

function LIB.GetTrailerVehicles(vehicle)
	if not IsValid(vehicle) then return end

	local connected = {}

	local function recusive_func(f_ent)
		if not IsValid(f_ent) then return end

		if connected[f_ent] then return end
		connected[f_ent] = f_ent

		local vehicles = LIB.GetConnectedVehicles(f_ent)
		if not vehicles then return end

		for k, v in pairs(vehicles) do
			recusive_func(v)
		end
	end

	recusive_func(vehicle)

	connected = table.ClearKeys(connected)
	return connected
end

function LIB.ForEachTrailerVehicles(vehicle, func)
	if not IsValid(vehicle) then return end
	if not isfunction(func) then return end

	local vehicles = LIB.GetTrailerVehicles(vehicle)
	if not vehicles then return end

	for k, v in ipairs(vehicles) do
		if not IsValid(vehicle) then continue end
		if func(k, v) == false then break end
	end
end

function LIB.GetTrailerMainVehicles(vehicle)
	if not IsValid(vehicle) then return end

	local vehicles = LIB.GetTrailerVehicles(vehicle)
	if not vehicles then return end

	local mainvehicles = {}

	for k, v in pairs(vehicles) do
		if not IsValid(v) then continue end
		if not v.sligwolf_isTrailerMain then continue end

		table.insert(mainvehicles, v)
	end

	return mainvehicles
end

function LIB.TrailerHasMainVehicles(vehicle)
	local mainvehicles = LIB.GetTrailerMainVehicles(vehicle)

	if not mainvehicles then return false end
	if not IsValid(mainvehicles[1]) then return false end

	return true
end

function LIB.FindCorrectConnector(parent, dir)
	if not IsValid(parent) then return end

	local connector = LIBEntities.GetChild(parent, "Connector_" .. dir)

	if not IsValid(connector) then
		local children = LIBEntities.GetChildren(parent)

		for _, child in pairs(children) do
			if not IsValid(child) then continue end

			connector = LIBEntities.GetChild(child, "Connector_" .. dir)

			if IsValid(connector) then
				return connector
			end

			connector = LIB.FindCorrectConnector(child, dir)

			if IsValid(connector) then
				return connector
			end
		end
	end

	return connector
end

function LIB.CouplingMechanism(couplerButton, mainvehicle, ply)
	if not IsValid(couplerButton) then return end
	if not IsValid(ply) then return end

	local dir = couplerButton.sligwolf_connectorDirection
	if not dir then return end

	local ConA = LIB.FindCorrectConnector(mainvehicle, dir)
	local ConB = nil

	if not IsValid(ConA) then return end
	if not ConA.sligwolf_isConnector then return end
	if not ConA.sligwolf_connectorDirection then return end
	if ConA.sligwolf_connectorDirection ~= dir then return end

	local Radius = ConA.searchRadius
	if not Radius then return end

	local RadiusSqr = Radius * Radius

	local PosA = ConA:GetPos()
	local Cons = ents.FindInSphere(PosA, Radius) or {}

	for k, v in pairs(Cons) do
		if not IsValid(v) then continue end
		if v == ConA then continue end
		if not v.sligwolf_isConnector then continue end
		if not v.sligwolf_connectorDirection then continue end

		local sp = LIBEntities.GetSuperParent(v)
		if sp == mainvehicle then continue end

		ConB = v
		break
	end

	if not IsValid(ConB) then return end
	local PosB = ConB:GetPos()

	local Allow = LIBEntities.ConstraintIsAllowed(ConB, ply)
	if not Allow then return end

	if ConA:IsConnectedWith(ConB) then
		local isControllingVehicle = LIBVehicleControl.IsControllingVehicle(ply)
		if isControllingVehicle then return end

		if not ConA:Disconnect(ConB) then return end
		ConA:EmitSound(CONSTANTS.sndCoupling)

		return
	end

	if PosA:DistToSqr(PosB) >= RadiusSqr then return end

	if not ConA:Connect(ConB) then return end
	ConA:EmitSound(CONSTANTS.sndCoupling)
end

function LIB.AutoConnectVehicles(ConA)
	if not IsValid(ConA) then return end

	local Radius = ConA.searchRadius
	if not Radius then return end

	local RadiusSqr = Radius * Radius

	local PosA = ConA:GetPos()
	local Cons = ents.FindInSphere(PosA, Radius) or {}

	for k, ConB in pairs(Cons) do
		if not ConB.sligwolf_isConnector then continue end
		if ConB == ConA then continue end

		local PosB = ConB:GetPos()
		if PosA:DistToSqr(PosB) >= RadiusSqr then continue end

		ConA:Connect(ConB)
		ConA:EmitSound(CONSTANTS.sndCoupling)
	end
end

return true

