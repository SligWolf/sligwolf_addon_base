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
local LIBUtil = nil

LIB.GENDER_MALE = "M"
LIB.GENDER_FEMALE = "F"
LIB.GENDER_NEUTRAL = "N"

function LIB.Load()
	LIBVehicleControl = SligWolf_Addons.VehicleControl
	LIBEntities = SligWolf_Addons.Entities
	LIBUtil = SligWolf_Addons.Util
end

local function getCache(ent)
	local entTable = ent:SligWolf_GetTable()

	local couplingCache = entTable.couplingCache or {}
	entTable.couplingCache = couplingCache

	local connections = couplingCache.connections or {}
	couplingCache.connections = connections

	local mainVehicles = couplingCache.mainVehicles or {}
	couplingCache.mainVehicles = mainVehicles

	return couplingCache
end

local function resetTrailerData(trailerData)
	trailerData.lightState = false
	trailerData.indicatorState = false
	trailerData.indicatorHazzard = false
	trailerData.indicatorL = false
	trailerData.indicatorR = false
	trailerData.indicatorFlashState = false
	trailerData.indicatorDelay = nil

	trailerData.isTrailerMain = false
	trailerData.isTrailer = false
end

LIB.GetCouplingCache = getCache

function LIB.GetTrailerData(vehicle)
	if not IsValid(vehicle) then
		local trailerData = {}

		resetTrailerData(trailerData)

		return trailerData
	end

	local vehicleTable = vehicle:SligWolf_GetTable()
	local trailerData = vehicleTable.trailerData

	if not trailerData then
		trailerData = {}
		vehicleTable.trailerData = trailerData

		resetTrailerData(trailerData)
	end

	return trailerData
end

function LIB.GetTrailerDataForDupe(vehicle)
	local trailerData = LIB.GetTrailerData(vehicle)

	return {
		lightState = trailerData.lightState or false,
		indicatorState = trailerData.indicatorState or false,
		indicatorHazzard = trailerData.indicatorHazzard or false,
		indicatorL = trailerData.indicatorL or false,
		indicatorR = trailerData.indicatorR or false,
	}
end

function LIB.SetTrailerDataFromDupe(vehicle, newTrailerData)
	local trailerData = LIB.GetTrailerData(vehicle)
	newTrailerData = newTrailerData or {}

	trailerData.lightState = newTrailerData.lightState or false
	trailerData.indicatorState = newTrailerData.indicatorState or false
	trailerData.indicatorHazzard = newTrailerData.indicatorHazzard or false
	trailerData.indicatorL = newTrailerData.indicatorL or false
	trailerData.indicatorR = newTrailerData.indicatorR or false
end

function LIB.CloneTrailerData(vehicleA, vehicleB)
	if not IsValid(vehicleA) then return end
	if not IsValid(vehicleB) then return end

	local mainTrailerDataA = LIB.GetTrailerData(vehicleA)
	local mainTrailerDataB = LIB.GetTrailerData(vehicleB)

	mainTrailerDataB.lightState = mainTrailerDataA.lightState or false
	mainTrailerDataB.indicatorState = mainTrailerDataA.indicatorState or false
	mainTrailerDataB.indicatorHazzard = mainTrailerDataA.indicatorHazzard or false
	mainTrailerDataB.indicatorL = mainTrailerDataA.indicatorL or false
	mainTrailerDataB.indicatorR = mainTrailerDataA.indicatorR or false
	mainTrailerDataB.indicatorFlashState = mainTrailerDataA.indicatorFlashState or false
	mainTrailerDataB.indicatorDelay = mainTrailerDataA.indicatorDelay
end

function LIB.ClearCache(ent, notRecursive)
	if not IsValid(ent) then return end

	local cache = getCache(ent)
	if not cache then return end

	local mainVehicles = cache.mainVehicles
	local connections = cache.connections

	if mainVehicles then
		for key, otherEnt in pairs(mainVehicles) do
			mainVehicles[key] = nil

			if notRecursive then
				continue
			end

			if otherEnt == ent then
				continue
			end

			LIB.ClearCache(otherEnt, true)
		end
	end

	if connections then
		for key, otherEnt in pairs(connections) do
			connections[key] = nil

			if notRecursive then
				continue
			end

			if otherEnt == ent then
				continue
			end

			LIB.ClearCache(otherEnt, true)
		end
	end
end

function LIB.ResetTrailerData(vehicle)
	local vehicleTable = vehicle:SligWolf_GetTable()
	local trailerData = vehicleTable.trailerData

	if not trailerData then
		return
	end

	resetTrailerData(trailerData)
end

function LIB.MarkAsTrailerMain(vehicle)
	if not IsValid(vehicle) then return end

	local trailerData = LIB.GetTrailerData(vehicle)
	trailerData.isTrailerMain = true
	trailerData.isTrailer = false
end

function LIB.MarkAsTrailer(vehicle)
	if not IsValid(vehicle) then return end

	local trailerData = LIB.GetTrailerData(vehicle)
	trailerData.isTrailerMain = false
	trailerData.isTrailer = true
end

function LIB.GetConnectedVehicles(vehicle)
	vehicle = LIBEntities.GetSuperParent(vehicle)
	if not IsValid(vehicle) then return end

	local vehicleTable = vehicle:SligWolf_GetTable()
	return vehicleTable.couplerConnections
end

function LIB.ConnectVehicles(vehicleA, vehicleB, dirA)
	vehicleA = LIBEntities.GetSuperParent(vehicleA)
	vehicleB = LIBEntities.GetSuperParent(vehicleB)

	if not IsValid(vehicleA) then return end
	if not IsValid(vehicleB) then return end

	dirA = tostring(dirA or "")

	local vehicleATable = vehicleA:SligWolf_GetTable()

	local couplerConnectionsA = vehicleATable.couplerConnections or {}
	vehicleATable.couplerConnections = couplerConnectionsA

	couplerConnectionsA[dirA] = vehicleB

	LIB.ClearCache(vehicleA)
	LIB.ClearCache(vehicleB)
end

function LIB.DisconnectVehicles(vehicleA, dirA)
	vehicleA = LIBEntities.GetSuperParent(vehicleA)
	if not IsValid(vehicleA) then return end

	dirA = tostring(dirA or "")

	local vehicleATable = vehicleA:SligWolf_GetTable()

	local couplerConnectionsA = vehicleATable.couplerConnections or {}
	vehicleATable.couplerConnections = couplerConnectionsA

	local vehicleB = couplerConnectionsA[dirA]
	couplerConnectionsA[dirA] = nil

	LIB.ClearCache(vehicleA)
	LIB.ClearCache(vehicleB)
end

function LIB.IsConnected(vehicleA, vehicleB, dirA)
	vehicleA = LIBEntities.GetSuperParent(vehicleA)
	vehicleB = LIBEntities.GetSuperParent(vehicleB)

	if not IsValid(vehicleA) then return false end
	if not IsValid(vehicleB) then return false end

	dirA = tostring(dirA or "")

	local vehicleATable = vehicleA:SligWolf_GetTable()

	local couplerConnectionsA = vehicleATable.couplerConnections or {}
	vehicleATable.couplerConnections = couplerConnectionsA

	local vehicleToCheck = couplerConnectionsA[dirA]

	if not IsValid(vehicleToCheck) then
		return false
	end

	if vehicleToCheck ~= vehicleB then
		return false
	end

	return true
end

function LIB.GetTrailerVehicles(vehicle)
	if not IsValid(vehicle) then return end

	local cache = getCache(vehicle)

	local connections = cache.connections
	if not table.IsEmpty(connections) then
		return connections
	end

	local connectionsIndexed = {}

	local currentEntities = {vehicle}

	local maxiter = 0xFFFF

	while true do
		if maxiter <= 0 then
			error("maxiter exhausted")
			break
		end

		maxiter = maxiter - 1

		local nextEntities = {}

		for i, currentEntity in ipairs(currentEntities) do
			if not connectionsIndexed[currentEntity] then
				connectionsIndexed[currentEntity] = true
				table.insert(connections, currentEntity)
			end

			local vehicles = LIB.GetConnectedVehicles(currentEntity)
			if not vehicles then
				continue
			end

			for k, v in pairs(vehicles) do
				if connectionsIndexed[v] then
					continue
				end

				connectionsIndexed[v] = true

				table.insert(connections, v)
				table.insert(nextEntities, v)
			end
		end

		if table.IsEmpty(nextEntities) then
			break
		end

		currentEntities = nextEntities
	end

	-- Sort by oldest entity first
	LIBUtil.SortEntitiesBySpawn(connections, true)

	return connections
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

local function getTrailerMainVehicleInternal(vehicles, checkPattern)
	local checkPlayer = checkPattern[1]
	local checkAdmin = checkPattern[2]
	local checkConnections = checkPattern[3]

	for k, v in pairs(vehicles) do
		if checkPlayer then
			local ply = LIBEntities.GetDriver(v)
			if not IsValid(ply) then
				continue
			end

			if checkAdmin and not LIBUtil.IsAdmin(ply) then
				continue
			end
		end

		if checkConnections then
			-- check if v is in the middle
			local connections = LIB.GetConnectedVehicles(v)

			if connections and table.Count(connections) > 1 then
				continue
			end
		end

		return v
	end

	return nil
end

function LIB.GetTrailerMainVehicles(vehicle)
	if not IsValid(vehicle) then return end

	local cache = getCache(vehicle)

	local mainVehicles = cache.mainVehicles
	if not table.IsEmpty(mainVehicles) then
		return mainVehicles
	end

	local vehicles = LIB.GetTrailerVehicles(vehicle)
	if not vehicles then return end

	for k, v in pairs(vehicles) do
		if not IsValid(v) then
			continue
		end

		local trailerData = LIB.GetTrailerData(v)
		if not trailerData.isTrailerMain then
			continue
		end

		table.insert(mainVehicles, v)
	end

	return mainVehicles
end

local g_checkPatterns = {
	-- checkPlayer, checkAdmin, checkConnections
	{true, true, true},
	{true, true, false},

	{true, false, true},
	{true, false, false},

	{false, false, true},
	{false, false, false},
}

function LIB.GetTrailerMainVehicle(vehicle, allowFallback)
	if not IsValid(vehicle) then return end

	local mainVehicles = LIB.GetTrailerMainVehicles(vehicle)
	if not mainVehicles then return end

	for key, checkPattern in ipairs(g_checkPatterns) do
		local mainVehicle = getTrailerMainVehicleInternal(mainVehicles, checkPattern)
		if not mainVehicle then
			continue
		end

		return mainVehicle
	end

	if allowFallback then
		return vehicle
	end

	return nil
end

function LIB.TrailerHasMainVehicle(vehicle, allowFallback)
	local mainVehicle = LIB.GetTrailerMainVehicle(vehicle, allowFallback)
	if not IsValid(mainVehicle) then return false end

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

