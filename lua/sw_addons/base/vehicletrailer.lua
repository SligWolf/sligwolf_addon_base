AddCSLuaFile()

if !SW_Addons then
	return
end

if !SW_ADDON then
	SW_Addons.AutoLoadAddon(function() end)
	return
end

local ConnectSound = Sound("EpicMetal.ImpactHard")

function SW_ADDON:GetConnectedVehicles(vehicle)
	vehicle = self:GetSuperParent(vehicle)
	if !IsValid(vehicle) then return end

	vehicle.__SW_Connected = vehicle.__SW_Connected or {}
	return vehicle.__SW_Connected
end

function SW_ADDON:GetTrailerVehicles(vehicle)
	if !IsValid(vehicle) then return end

	local unique = {}
	local connected = {}

	local function recusive_func(f_ent)
		local vehicles = self:GetConnectedVehicles(f_ent)
		if !vehicles then return end

		for k, v in pairs(vehicles) do
			if !IsValid(v) then continue end
			if unique[v] then continue end
			
			unique[v] = true
			connected[#connected + 1] = v
			recusive_func(v)
		end
		
		if unique[f_ent] then return end
		
		unique[f_ent] = true
		connected[#connected + 1] = f_ent
	end
	
	recusive_func(vehicle)
	
	return connected
end

function SW_ADDON:ForEachTrailerVehicles(vehicle, func)
	if !IsValid(vehicle) then return end
	if !isfunction(func) then return end
	
	local vehicles = self:GetTrailerVehicles(vehicle)
	if !vehicles then return end

	for k, v in ipairs(vehicles) do
		if !IsValid(vehicle) then continue end
		if func(k, v) == false then break end
	end
end

function SW_ADDON:GetTrailerMainVehicles(vehicle)
	if !IsValid(vehicle) then return end
	
	local vehicles = self:GetTrailerVehicles(vehicle)
	if !vehicles then return end

	local mainvehicles = {}
	for k, v in pairs(vehicles) do
		if !IsValid(v) then continue end
		if !v.__IsSW_TrailerMain then continue end
		mainvehicles[#mainvehicles + 1] = v
	end
	
	return mainvehicles
end

function SW_ADDON:TrailerHasMainVehicles(vehicle)
	local mainvehicles = self:GetTrailerMainVehicles(vehicle)
	
	if !mainvehicles then return false end
	if !IsValid(mainvehicles[1]) then return false end
	
	return true
end

function SW_ADDON:FindCorrectConnector(parent, dir)
	if !IsValid(parent) then return end
	
	local connector = self:GetChild(parent, "Connector_"..dir)
	
	if !IsValid(connector) then
		local children = self:GetChildren(parent)
		
		for _, child in pairs(children) do
			if !IsValid(child) then continue end
			local name = self:GetName(child)

			connector = self:GetChild(child, "Connector_"..dir)
			
			if IsValid(connector) then 
				return connector 
			end
			
			connector = self:FindCorrectConnector(child, dir)
			
			if IsValid(connector) then 
				return connector 
			end
		end
	end
	
	return connector
end

function SW_ADDON:CouplingMechanism(couplerButton, mainvehicle, ply)
	if !IsValid(couplerButton) then return end
	if !IsValid(ply) then return end
	
	local dir = couplerButton.__SW_Dir
	if !dir then return end
	
	local ConA = self:FindCorrectConnector(mainvehicle, dir)
	local ConB = nil
	
	if !IsValid(ConA) then return end
	if !ConA.__IsSW_Connector then return end
	if !ConA.__SW_Dir then return end
	if ConA.__SW_Dir != dir then return end

	local Radius = ConA.searchRadius
	local PosA = ConA:GetPos()
	local Cons = ents.FindInSphere(PosA, Radius) or {}
	
	for k, v in pairs(Cons) do
		if !IsValid(v) then continue end
		if v == ConA then continue end
		if !v.__IsSW_Connector then continue end
		if !v.__SW_Dir then continue end
		
		local sp = self:GetSuperParent(v)
		if sp == mainvehicle then continue end
		
		ConB = v
		break
	end

	if !IsValid(ConB) then return end
	local PosB = ConB:GetPos()
	
	local Allow = self:ConstraintIsAllowed(ConB, ply)
	if !Allow then return end
		
	if ConA:IsConnectedWith(ConB) then
		if ply:InVehicle() then return end
		if !ConA:Disconnect(ConB) then return end
		ConA:EmitSound(ConnectSound)
		
		return
	end
	
	if PosA:Distance(PosB) >= Radius then return end
	
	if !ConA:Connect(ConB) then return end
	ConA:EmitSound(ConnectSound)
end

local cuoplerDistance = 10

function SW_ADDON:AutoConnectVehicles(connector)
	if !IsValid(connector) then return end
	local pos = connector:GetPos()
	
	local Cons = ents.FindInSphere(pos, cuoplerDistance) or {}
	
	for k,v in pairs(Cons) do
		if !v.__IsSW_Connector then continue end
		if v == connector then continue end
		if pos:Distance(v:GetPos()) >= cuoplerDistance then continue end
		
		connector:Connect(v)
		connector:EmitSound(ConnectSound)
	end
end