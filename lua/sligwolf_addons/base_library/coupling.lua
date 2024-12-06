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
	if not IsValid(ent) then
		return nil
	end

	local entTable = ent:SligWolf_GetTable()

	local couplingCache = entTable.couplingCache or {}
	entTable.couplingCache = couplingCache

	local connections = couplingCache.connections or {}
	couplingCache.connections = connections

	local mainVehicles = couplingCache.mainVehicles or {}
	couplingCache.mainVehicles = mainVehicles

	local endVehicles = couplingCache.endVehicles or {}
	couplingCache.endVehicles = endVehicles

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

local function clearCacheEntities(entities)
	if not entities then return end

	for key, otherEnt in pairs(entities) do
		entities[key] = nil
	end
end

function LIB.ClearCache(ent)
	if not IsValid(ent) then return end

	local vehicles = LIB.GetTrailerVehicles(ent)

	if vehicles then
		for _, vehicle in ipairs(vehicles) do
			local cache = getCache(vehicle)
			if not cache then
				continue
			end

			local mainVehicles = cache.mainVehicles
			local endVehicles = cache.endVehicles
			local connections = cache.connections

			clearCacheEntities(mainVehicles)
			clearCacheEntities(endVehicles)
			clearCacheEntities(connections)
		end
	end

	local cache = getCache(ent)
	if not cache then
		return
	end

	local mainVehicles = cache.mainVehicles
	local endVehicles = cache.endVehicles
	local connections = cache.connections

	clearCacheEntities(mainVehicles)
	clearCacheEntities(endVehicles)
	clearCacheEntities(connections)
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

function LIB.GetCouplers(vehicle)
	vehicle = LIBEntities.GetSuperParent(vehicle)
	if not IsValid(vehicle) then return end

	local vehicleTable = vehicle:SligWolf_GetTable()

	local couplers = vehicleTable.couplers
	if not couplers then return end

	return couplers
end

function LIB.GetCoupler(vehicle, dir)
	local couplers = LIB.GetCouplers(vehicle)
	if not couplers then return end

	dir = tostring(dir or "")

	local coupler = couplers[dir]

	if not IsValid(coupler) then return end
	if not coupler.sligwolf_isConnector then return end

	return coupler
end

local function updateCouplerConnections(couplerConnections)
	if not couplerConnections then
		return
	end

	local vehicles = couplerConnections.vehicles or {}
	couplerConnections.vehicles = vehicles

	local i = 0

	for k, ent in pairs(vehicles) do
		if not IsValid(ent) then
			vehicles[k] = nil
			continue
		end

		i = i + 1
	end

	couplerConnections.count = i
end

function LIB.RegisterCoupler(vehicle, coupler)
	vehicle = LIBEntities.GetSuperParent(vehicle)

	if not IsValid(vehicle) then return end
	if not IsValid(coupler) then return end

	local connectorDirection = coupler.sligwolf_connectorDirection
	if not connectorDirection then return end

	local vehicleTable = vehicle:SligWolf_GetTable()

	local couplers = vehicleTable.couplers or {}
	vehicleTable.couplers = couplers

	couplers[connectorDirection] = coupler

	local couplerConnections = vehicleTable.couplerConnections or {}
	vehicleTable.couplerConnections = couplerConnections

	updateCouplerConnections(couplerConnections)

	LIB.ClearCache(vehicle)

	LIBEntities.CallOnRemove(vehicle, "Coupling_RegisterCoupler", function(thisVehicle)
		local thisCouplerConnections = LIB.GetConnectedVehicles(thisVehicle)

		if thisCouplerConnections then
			for k, ent in pairs(thisCouplerConnections.vehicles) do
				local entCouplerConnections = LIB.GetConnectedVehicles(ent)
				updateCouplerConnections(entCouplerConnections)
			end

			updateCouplerConnections(thisCouplerConnections)
		end

		LIB.ClearCache(thisVehicle)
	end)
end

function LIB.GetConnectedVehicles(vehicle)
	vehicle = LIBEntities.GetSuperParent(vehicle)
	if not IsValid(vehicle) then return end

	local vehicleTable = vehicle:SligWolf_GetTable()

	local couplerConnections = vehicleTable.couplerConnections
	if not couplerConnections then return end

	if not couplerConnections.vehicles then return end
	if not couplerConnections.count then return end

	return couplerConnections
end

function LIB.ConnectVehicles(vehicleA, vehicleB, dirA)
	vehicleA = LIBEntities.GetSuperParent(vehicleA)
	vehicleB = LIBEntities.GetSuperParent(vehicleB)

	if not IsValid(vehicleA) then return end
	if not IsValid(vehicleB) then return end
	if vehicleA == vehicleB then return end

	dirA = tostring(dirA or "")

	local couplerConnections = LIB.GetConnectedVehicles(vehicleA)
	if not couplerConnections then
		return
	end

	local vehicles = couplerConnections.vehicles
	vehicles[dirA] = vehicleB

	updateCouplerConnections(couplerConnections)

	LIB.ClearCache(vehicleA)
	LIB.ClearCache(vehicleB)
end

function LIB.DisconnectVehicles(vehicleA, dirA)
	vehicleA = LIBEntities.GetSuperParent(vehicleA)
	if not IsValid(vehicleA) then return end

	dirA = tostring(dirA or "")

	local couplerConnections = LIB.GetConnectedVehicles(vehicleA)
	if not couplerConnections then
		return
	end

	local vehicles = couplerConnections.vehicles
	local vehicleB = vehicles[dirA]
	vehicles[dirA] = nil

	updateCouplerConnections(couplerConnections)

	LIB.ClearCache(vehicleA)

	if vehicleA == vehicleB then return end
	LIB.ClearCache(vehicleB)
end

function LIB.IsConnected(vehicleA, vehicleB, dirA)
	vehicleA = LIBEntities.GetSuperParent(vehicleA)
	vehicleB = LIBEntities.GetSuperParent(vehicleB)

	if not IsValid(vehicleA) then return false end
	if not IsValid(vehicleB) then return false end
	if vehicleA == vehicleB then return false end

	dirA = tostring(dirA or "")

	local couplerConnections = LIB.GetConnectedVehicles(vehicleA)
	if not couplerConnections then
		return false
	end

	local vehicleToCheck = couplerConnections.vehicles[dirA]

	if not IsValid(vehicleToCheck) then
		return false
	end

	if vehicleToCheck ~= vehicleB then
		return false
	end

	return true
end

local function copyCache(vehicle, otherVehicles, name)
	local cache = getCache(vehicle)
	if not cache then
		return
	end

	local cacheItems = cache[name]
	if not cacheItems then
		return
	end

	for i, otherVehicle in ipairs(otherVehicles) do
		if vehicle == otherVehicle then
			continue
		end

		local otherCache = getCache(otherVehicle)
		if not otherCache then
			continue
		end

		local otherCacheItems = otherCache[name]
		if not otherCacheItems then
			return
		end

		table.Empty(otherCacheItems)
		table.CopyFromTo(cacheItems, otherCacheItems)
	end
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
			if not IsValid(currentEntity) then
				continue
			end

			if not connectionsIndexed[currentEntity] then
				connectionsIndexed[currentEntity] = true
				table.insert(connections, currentEntity)
			end

			local couplerConnections = LIB.GetConnectedVehicles(currentEntity)
			if not couplerConnections then
				continue
			end

			for k, v in pairs(couplerConnections.vehicles) do
				if not IsValid(v) then
					continue
				end

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

	copyCache(vehicle, connections, "connections")

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

			local couplerConnections = LIB.GetConnectedVehicles(v)
			if couplerConnections and couplerConnections.count > 1 then
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

	copyCache(vehicle, vehicles, "mainVehicles")

	return mainVehicles
end

function LIB.GetTrailerEndVehicles(vehicle)
	if not IsValid(vehicle) then return end

	local cache = getCache(vehicle)

	local endVehicles = cache.endVehicles
	if not table.IsEmpty(endVehicles) then
		return endVehicles
	end

	local vehicles = LIB.GetTrailerVehicles(vehicle)
	if not vehicles then return end

	for k, v in pairs(vehicles) do
		if not IsValid(v) then
			continue
		end

		local couplerConnections = LIB.GetConnectedVehicles(v)
		if couplerConnections and couplerConnections.count > 1 then
			continue
		end

		table.insert(endVehicles, v)
	end

	copyCache(vehicle, vehicles, "endVehicles")

	return endVehicles
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

	if #mainVehicles <= 1 then
		local mainVehicle = mainVehicles[1]

		if IsValid(mainVehicle) then
			return mainVehicle
		end

		if allowFallback then
			return vehicle
		end

		return nil
	end

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

function LIB.GetCouplerByButton(couplerOrButton)
	if not IsValid(couplerOrButton) then return end

	if couplerOrButton.sligwolf_isConnector then
		return couplerOrButton
	end

	local coupler = LIB.GetCoupler(couplerOrButton, couplerOrButton.sligwolf_connectorDirection)
	return coupler
end

function LIB.FindOtherCoupler(coupler)
	if not IsValid(coupler) then return end
	if not coupler.sligwolf_isConnector then return end

	local radius = coupler.searchRadius
	if not radius then
		return
	end

	local radiusSqr = radius * radius
	local posA = coupler:GetPos()

	local otherCouplers = ents.FindInSphere(posA, radius)
	if not otherCouplers then return end

	local superparent = LIBEntities.GetSuperParent(coupler)

	for i, otherCoupler in ipairs(otherCouplers) do
		if not IsValid(otherCoupler) then continue end

		if otherCoupler == coupler then continue end
		if not otherCoupler.sligwolf_isConnector then continue end

		local posB = otherCoupler:GetPos()
		if posA:DistToSqr(posB) >= radiusSqr then continue end

		local otherSuperparent = LIBEntities.GetSuperParent(otherCoupler)
		if otherSuperparent == superparent then continue end

		return otherCoupler
	end

	return nil
end

function LIB.Connect(coupler, ply)
	coupler = LIB.GetCouplerByButton(coupler)
	if not IsValid(coupler) then
		return false
	end

	if coupler:IsConnected() then
		return false
	end

	local otherCoupler = LIB.FindOtherCoupler(coupler)
	if not IsValid(otherCoupler) then
		return false
	end

	if IsValid(ply) then
		if not LIBEntities.ConstraintIsAllowed(coupler, ply) then
			return false
		end

		if not LIBEntities.ConstraintIsAllowed(otherCoupler, ply) then
			return false
		end
	end

	if coupler:Connect(otherCoupler) then
		coupler:EmitSound(CONSTANTS.sndCoupling)
		return true
	end

	return false
end

function LIB.Disconnect(coupler, ply)
	coupler = LIB.GetCouplerByButton(coupler)
	if not IsValid(coupler) then
		return false
	end

	if not coupler:IsConnected() then
		return false
	end

	local otherCoupler = coupler:GetConnectedEntity()
	if not IsValid(otherCoupler) then
		return false
	end

	if IsValid(ply) then
		if not LIBEntities.ConstraintIsAllowed(coupler, ply) then
			return false
		end

		if not LIBEntities.ConstraintIsAllowed(otherCoupler, ply) then
			return false
		end
	end

	if coupler:Disconnect(otherCoupler) then
		coupler:EmitSound(CONSTANTS.sndCoupling)
		return true
	end

	return false
end

function LIB.ToogleConnection(coupler, ply)
	coupler = LIB.GetCouplerByButton(coupler)
	if not IsValid(coupler) then
		return false
	end

	if coupler:IsConnected() then
		return LIB.Disconnect(coupler, ply)
	end

	return LIB.Connect(coupler, ply)
end

function LIB.AutoConnect(vehicle, ply)
	if not IsValid(vehicle) then
		return false
	end

	local endVehicles = LIB.GetTrailerEndVehicles(vehicle)

	local hasConnected = false

	for i, endVehicle in ipairs(endVehicles) do
		local couplers = LIB.GetCouplers(endVehicle)
		if not couplers then
			continue
		end

		for _, coupler in pairs(couplers) do
			if not LIB.Connect(coupler, ply) then
				continue
			end

			hasConnected = true
		end
	end

	return hasConnected
end

return true

