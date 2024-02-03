AddCSLuaFile()

if !SW_Addons then
	return
end

if !SW_ADDON then
	SW_Addons.AutoLoadAddon(function() end)
	return
end

local SW_Addons = SW_Addons

function SW_ADDON:AddVehicleTable(vehicle, vehicleListName)
	if !IsValid(vehicle) then return end
	if !vehicle:IsVehicle() then return end

	local VehicleList = list.Get("Vehicles") or {}
	local vehicleTable = VehicleList[vehicleListName]

	if !vehicleTable then return end
	
	vehicle.VehicleName = vehicleListName
	vehicle.VehicleTable = vehicleTable
end

function SW_ADDON:HandleVehicleSpawn(vehicle)
	if !IsValid(vehicle) then return end
	if !vehicle:IsVehicle() then return end
	
	local model = vehicle:GetModel()
	local registerdVehicleModels = self.RegisterdVehicleModels or {}
	local modelParams = registerdVehicleModels[model]
	
	if !modelParams then
		return
	end

	if !istable(modelParams) then
		modelParams = {}
	end
	
	vehicle.__swIsVehicle = true
	vehicle.__swAddonname = self.Addonname
	vehicle.__swModelParams = modelParams
	
	local ply = vehicle.__swSpawnerPlayer
	vehicle.__swSpawnerPlayer = nil
	
	if modelParams.VehicleListName then
		self:AddVehicleTable(vehicle, modelParams.VehicleListName)
	end
	
	local ok = self:CallAddonFunctionWithErrorNoHalt("SpawnVehicle", ply, vehicle, modelParams)
	
	if !ok then	
		vehicle.__swIsVehicle = nil
		vehicle.__swAddonname = nil
		vehicle.__swModelParams = nil
	end
end

local function PlayerEnteredVehicle(ply, vehicle)
	if !SW_Addons then return end

    if !IsValid(vehicle) then return end
    if !IsValid(ply) then return end
	
    if !vehicle.__swIsVehicle then return end
    if !vehicle.__swAddonname then return end
	
	SW_Addons.CallFunctionOnAddon(vehicle.__swAddonname, "ViewEnt", ply)
	SW_Addons.CallFunctionOnAddon(vehicle.__swAddonname, "EnterVehicle", ply, vehicle)
end
hook.Remove("PlayerEnteredVehicle", "SW_Common_Vehicle_PlayerEnteredVehicle")
hook.Add("PlayerEnteredVehicle", "SW_Common_Vehicle_PlayerEnteredVehicle", PlayerEnteredVehicle)

local function PlayerLeaveVehicle(ply, vehicle)
	if !SW_Addons then return end

    if !IsValid(vehicle) then return end
    if !IsValid(ply) then return end
	
    if !vehicle.__swIsVehicle then return end
    if !vehicle.__swAddonname then return end
	
	SW_Addons.CallFunctionOnAddon(vehicle.__swAddonname, "LeaveVehicle", ply, vehicle)
	SW_Addons.CallFunctionOnAddon(vehicle.__swAddonname, "Exit_Seat", vehicle, ply)
	SW_Addons.CallFunctionOnAddon(vehicle.__swAddonname, "ViewEnt", ply)
end
hook.Remove("PlayerLeaveVehicle", "SW_Common_Vehicle_PlayerLeaveVehicle")
hook.Add("PlayerLeaveVehicle", "SW_Common_Vehicle_PlayerLeaveVehicle", PlayerLeaveVehicle)

local function OnEntityCreated(ent)
	if !IsValid(ent) then return end
	
	timer.Simple(0, function()
		if !SW_Addons then return end
		SW_Addons.CallFunctionOnAllAddons("HandleVehicleSpawn", ent)
	end)
end
hook.Remove("OnEntityCreated", "SW_Common_Vehicle_OnEntityCreated")
hook.Add("OnEntityCreated", "SW_Common_Vehicle_OnEntityCreated", OnEntityCreated)

local function PlayerSpawnedVehicle(ply, vehicle)
	if !IsValid(ply) then return end
	if !IsValid(vehicle) then return end

	vehicle.__swSpawnerPlayer = ply
end
hook.Remove("PlayerSpawnedVehicle", "SW_Common_Vehicle_PlayerSpawnedVehicle")
hook.Add("PlayerSpawnedVehicle", "SW_Common_Vehicle_PlayerSpawnedVehicle", PlayerSpawnedVehicle)