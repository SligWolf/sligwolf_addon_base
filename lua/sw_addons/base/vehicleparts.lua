AddCSLuaFile()

if !SW_Addons then
	return
end

if !SW_ADDON then
	SW_Addons.AutoLoadAddon(function() end)
	return
end

local g_FailbackComponentsParams = {
	model = "models/error.mdl",
	color = Color(255, 255, 255),
	skin = 0,
	bodygroups = {},
	shadow = false,
	nodraw = false,
	solid = SOLID_VPHYSICS,
	collision = COLLISION_GROUP_NONE,
	blocked = true,
	blockAllTools = false,
	keyValues = {},
	inputFires = {},
	constraints = {},
	motion = true,

	typesParams = {
		propParent = {
			collision = COLLISION_GROUP_IN_VEHICLE,
			parentAttachment = 0,
			boneMerge = false,
		},
		trigger = {
			parentAttachment = 0,			
		},
		door = {
			autoClose = true,
		},
		connector = {
			connectortype = "unknown",
			gender = "N",
			searchRadius = 10,
		},
		connectorButton = {
			collision = COLLISION_GROUP_WORLD,
			parentAttachment = 0,
			inVehicle = false,
		},
		button = {
			collision = COLLISION_GROUP_WORLD,
			parentAttachment = 0,
			inVehicle = false,
		},
		smoke = {
			spawnTime = 0.1,
			velocity = 7,
			startSize = 5,
			endSize = 1,
			startAlpha = 100,
			endAlpha = 10,
			lifeTime = 0,
			dieTime = 3,
			parentAttachment = 0,
		},
		light = {
			fov = 120,
			farZ = 2048,
			shadowRenderDist = 2048,
			parentAttachment = 0,
		},
		glow = {
			size = 30,
			enlarge = 10,
			count = 2,
			alphaReduce = 100,
			parentAttachment = 0,
		},
		animatedWheel = {
			size = 8,
			restrate = 16,
			parentAttachment = 0,
			boneMerge = false,
			collision = COLLISION_GROUP_WEAPON,
		},
		speedometer = {
			minSpeed = 0,
			maxSpeed = 1312,
			minPoseValue = 0,
			maxPoseValue = 1,
			poseName = "vehicle_guage",
		},
		display = {
			scale = 0.25,
			parentAttachment = 0,
			functionName = "",
		},
		bendi = {
			parentNameFront = "",
			parentNameRear = "",
		},
		pod = {
			collision = COLLISION_GROUP_WORLD,
			parentAttachment = 0,
			boneMerge = false,
			keyValues = {
				vehiclescript = "scripts/vehicles/prisoner_pod.txt",
				limitview = 0,
			},
		},
		hoverball = {
			speed = 5,
			airResistance = 5,
			strength = 5,
			numDown = KEY_SPACE,
			numUp = KEY_SPACE,
			numBackDown = KEY_LALT,
			numBackUp = KEY_LALT,
			solid = SOLID_NONE,
		},
	},
}

local g_FailbackConstraintsParams = {
	Weld = {
		bone1 = 0,
		bone2 = 0,
		forcelimit = 0,
		nocollide = true,
	},
	NoCollide = {
		bone1 = 0,
		bone2 = 0,
	},
	Axis = {
		bone1 = 0,
		bone2 = 0,
		lpos1 = Vector(),
		lpos2 = Vector(),
		forcelimit = 0,
		torquelimit = 0,
		friction = 0,
		nocollide = 1,
		localaxis = Vector(),
	},
	Ballsocket = {
		bone1 = 0,
		bone2 = 0,
		localpos = Vector(),
		forcelimit = 0,
		torquelimit = 0,
		nocollide = 1,
	},
	AdvBallsocket = {
		bone1 = 0,
		bone2 = 0,
		lpos1 = Vector(),
		lpos2 = Vector(),
		forcelimit = 0,
		torquelimit = 0,
		xmin = -45, 
		ymin = -45, 
		zmin = -45,
		xmax = 45, 
		ymax = 45, 
		zmax = 45,
		xfric = 0,
		yfric = 0,
		zfric = 0,
		onlyrotation = 0,
		nocollide  = 1,
	},
	Keepupright = {
		ang = Angle(),
		bone1 = 0,
		angularLimit = 0,
	},
}

local function SetPartKeyValues(ent, keyValues)	
	if !keyValues then return end
	
	for k, v in pairs(keyValues) do
		ent:SetKeyValue(tostring(k), v)
	end
end

local function SetPartInputFire(ent, inputFires)
	if !inputFires then return end
	
	for _, v in ipairs(inputFires) do
		ent:Fire(v)
	end
end

local function SetUnsetConstraintValuesToDefaults(constraint, constraintInfo)
	local failbackConstraintParamsForConstraint = g_FailbackConstraintsParams[constraint] or {}

	for k, v in pairs(failbackConstraintParamsForConstraint) do
		if constraintInfo[k] != nil then
			continue
		end
	
		constraintInfo[k] = v
	end
	
	return constraintInfo
end

local function SetUnsetConstraintsValuesToDefaults(constraints)
	constraints = constraints or {}
	
	for constraint, constraintInfo in pairs(constraints) do
		constraintInfo = SetUnsetConstraintValuesToDefaults(constraint, constraintInfo)
		constraints[constraint] = constraintInfo
	end
	
	return constraints
end

local function CreateWeld(ent, parent, constraintInfos)

	local WD = constraint.Weld(
		ent,
		parent,
		constraintInfos.bone1,
		constraintInfos.bone2,
		constraintInfos.forcelimit,
		constraintInfos.nocollide,
		true
	)
	
	if !IsValid(WD) then
		return
	end
	
	WD.DoNotDuplicate = true
	parent.__SW_ConstraintWeld = WD
	
	return WD
end

local function CreateNoCollide(ent, parent, constraintInfos)

	local NC = constraint.NoCollide(
		ent,
		parent,
		constraintInfos.bone1,
		constraintInfos.bone2
	)
	
	if !IsValid(NC) then
		return
	end
	
	NC.DoNotDuplicate = true
	parent.__SW_ConstraintNoCollide = NC
	
	return NC
end

local function CreateAxis(ent, parent, constraintInfos)

	local AX = constraint.Axis(
		ent,
		parent,
		constraintInfos.bone1,
		constraintInfos.bone2,
		constraintInfos.lpos1,
		constraintInfos.lpos2,
		constraintInfos.forcelimit,
		constraintInfos.torquelimit,
		constraintInfos.friction,
		constraintInfos.nocollide,
		constraintInfos.localaxis
	)

	if !IsValid(AX) then
		return
	end
	
	AX.DoNotDuplicate = true
	parent.__SW_ConstraintAxis = AX
	
	return AX
end

local function CreateBallSocket(ent, parent, constraintInfos)

	local BS = constraint.Ballsocket(
		parent,
		ent,
		constraintInfos.bone1,
		constraintInfos.bone2,
		constraintInfos.localpos,
		constraintInfos.forcelimit,
		constraintInfos.torquelimit,
		constraintInfos.nocollide
	)
	
	if !IsValid(BS) then
		return
	end
	
	BS.DoNotDuplicate = true
	parent.__SW_ConstraintBallSocket = BS
	
	return BS
end

local function CreateAdvBallsocket(ent, parent, constraintInfos)
	local ci = constraintInfos
	
	local ADVBS = constraint.AdvBallsocket(
		ent,
		parent,
		constraintInfos.bone1,
		constraintInfos.bone2,
		constraintInfos.lpos1,
		constraintInfos.lpos2,
		constraintInfos.forcelimit,
		constraintInfos.torquelimit,
		constraintInfos.xmin,
		constraintInfos.ymin,
		constraintInfos.zmin,
		constraintInfos.xmax,
		constraintInfos.ymax,
		constraintInfos.zmax,
		constraintInfos.xfric,
		constraintInfos.yfric,
		constraintInfos.zfric,
		constraintInfos.onlyrotation,
		constraintInfos.nocollide
	)
	
	if !IsValid(ADVBS) then
		return
	end
	
	ADVBS.DoNotDuplicate = true
	parent.__SW_ConstraintAdvBallsocket = ADVBS
	
	return ADVBS
end

local function CreateKeepupright(ent, parent, constraintInfos)
	
	local KU = constraint.Keepupright(
		ent,
		constraintInfos.ang,
		constraintInfos.bone1,
		constraintInfos.angularLimit
	)
	
	if !IsValid(KU) then
		return
	end
	
	KU.DoNotDuplicate = true
	parent.__SW_ConstraintKeepupright = KU
	
	return KU
end

local g_ConstraintCreateFunctions = {
	Weld = CreateWeld,
	NoCollide = CreateNoCollide,
	Axis = CreateAxis,
	Ballsocket = CreateBallSocket,
	AdvBallsocket = CreateAdvBallsocket,
	Keepupright = CreateKeepupright,
}

local function CreateConstraint(ent, parent, constraint, constraintInfos)
	local func = g_ConstraintCreateFunctions[constraint]
	
	if !func then
		error(string.format("%s is not a valid constraint type", constraint))
		return
	end
	
	local constraintEnt = func(ent, parent, constraintInfos)
	if !IsValid(constraintEnt) then return end

	return constraintEnt
end

local function CreateConstraints(ent, parent, componentConstraints)
	componentConstraints = componentConstraints or {}
	componentConstraints = SetUnsetConstraintsValuesToDefaults(componentConstraints)
	
	for constraint, constraintInfos in pairs(componentConstraints) do
		local cEnt = CreateConstraint(ent, parent, constraint, constraintInfos)
		
		if !IsValid(cEnt) then
			return false
		end
	end
	
	return true
end

local function ProceedVehicleSetUp(ent, tb)
	if !IsValid(ent) then return false end
	if !istable(tb) then return false end
	
	return true
end

local function SetUnsetComponentsValuesToDefaults(component)
	local componentType = tostring(component.type or "")
	if componentType == "" then
		error("component.type is not set!")
		return nil
	end
	component.type = componentType

	local mergedFailbackComponentsParams = table.Copy(g_FailbackComponentsParams)

	local typeParams = mergedFailbackComponentsParams.typesParams[componentType] or {}
	mergedFailbackComponentsParams.typesParams = nil
	
	mergedFailbackComponentsParams = table.Merge(mergedFailbackComponentsParams, typeParams)
	
	for k, v in pairs(mergedFailbackComponentsParams) do
		if !istable(v) then
			if component[k] != nil then
				continue
			end
		
			component[k] = v
			continue
		end
		
		component[k] = table.Merge(v, component[k] or {})
	end

	local color = component.color
	if !IsColor(color) then
		error("component.color is not a color!")
		return nil
	end
	
	if !color then
		color = mergedFailbackComponentsParams.color
	end
	
	local attachment = tostring(component.attachment or "")
	if attachment == "" then
		error("component.attachment is not set!")
		return nil
	end
	component.attachment = attachment
	
	local model = component.model
	if !util.IsValidModel(model) then 
		model = mergedFailbackComponentsParams.model
	end
	component.model = model
		
	local name = tostring(component.name or "")
	if name == "" then 
		name = string.format("unnamed_%s_%09u", component.type, math.floor(math.random(0, 999999999)))
	end
	component.name = name

	return component
end

function SW_ADDON:CheckToProceedToCreateEnt(ent, tb)
	if !ProceedVehicleSetUp(ent, tb) then return nil end
	
	local att = tostring(tb.attachment or "")
	if att == "" then return nil end
	
	local parentAttId = ent:LookupAttachment(att) or 0
	if parentAttId == 0 then return nil end
	
	return att
end

function SW_ADDON:SetPartValues(ent, parent, component, att)
	if !IsValid(ent) then return end
	
	local model = component.model
	local color = component.color
	local skin = component.skin
	local bodygroups = component.bodygroups
	local shadow = component.shadow
	local nodraw = component.nodraw
	local solid = component.solid
	local collision = component.collision
	local blocked = component.blocked
	local blockAllTools = component.blockAllTools
	local keyValues = component.keyValues
	local inputFires = component.inputFires
	local motion = component.motion
	local mass = component.mass
	
	ent:SetModel(model)
	
	if !self:SetEntAngPosViaAttachment(parent, ent, att, component.selfAttachment) then
		self:RemoveEntites({parent, ent})
		return
	end

	SetPartKeyValues(ent, keyValues)
	SetPartInputFire(ent, inputFires)
	
	ent:Spawn()
	ent:Activate()
	ent.DoNotDuplicate = true
	ent:SetModel(model)
	ent:SetColor(color)
	ent:SetSkin(skin)
	
	for bodygroupName, bodygroup in pairs(bodygroups) do
		ent:SetBodygroup(bodygroup.index, bodygroup.mesh)
	end

	ent:DrawShadow(shadow)
	ent:SetSolid(solid)
	ent:SetCollisionGroup(collision)
	ent:SetNoDraw(nodraw)
	ent.__SW_Blockedprop = blocked
	ent.__SW_BlockAllTools = blockAllTools
	
	local phys = ent:GetPhysicsObject()
	if !IsValid(phys) then 
		return ent
	end
	
	phys:Wake()
	phys:EnableMotion(motion)
	
	if mass then
		phys:SetMass(mass)
	end
end

function SW_ADDON:SetUpVehicleParts(parent, components, dtr, ply)
	if !ProceedVehicleSetUp(parent, components) then return end
	dtr = dtr or {}

	for i, component in ipairs(components) do
		self:SetUpVehiclePart(parent, component, dtr, ply)
	end
end

function SW_ADDON:SetUpVehiclePart(parent, component, dtr, ply)
	if !ProceedVehicleSetUp(parent, component) then return end
	dtr = dtr or {}
	
	component = SetUnsetComponentsValuesToDefaults(component)
	
	local funcs = {		
		prop = self.SetUpVehicleProp,
		propParent = self.SetUpVehiclePropParented,
		animatable = self.SetUpVehicleAnimatable,
		speedometer = self.SetUpVehicleSpeedometer,
		trigger = self.SetUpVehicleTrigger,
		door = self.SetUpVehicleDoor,
		connector = self.SetUpVehicleConnector,
		connectorButton = self.SetUpVehicleConnectorButton,
		button = self.SetUpVehicleButton,
		animatedWheel = self.SetUpVehicleAnimatedWheel,
		light = self.SetUpVehicleLight,
		glow = self.SetUpVehicleGlow,
		smoke = self.SetUpVehicleSmoke,
		pod = self.SetUpVehiclePod,
		display = self.SetUpVehicleDisplay,
		bendi = self.SetUpVehicleBendi,
		jeep = self.SetUpVehicleJeep,
		airboat = self.SetUpVehicleAirboat,
		hoverball = self.SetUpVehicleHoverball,
	}
	
	local componentType = component.type
	local func = funcs[componentType]
	
	if !func then
		error(string.format("%s is not a valid part type", componentType))
		return
	end
	
	local ent = func(self, parent, component, ply)
	if !IsValid(ent) then return end
	
	ent.__SW_DenyToolReload = dtr

	local hasSpawnedConstraints = CreateConstraints(ent, parent, component.constraints)
	if !hasSpawnedConstraints then
		ent:Remove()
		parent:Remove()
		return
	end

	self:SetUpVehicleParts(ent, component.children, dtr, ply)

	return ent
end

function SW_ADDON:SetUpVehicleProp(parent, component, ply)
	
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if !attachment then return end
	
	local name = component.name
	
	local ent = self:MakeEnt("prop_physics", ply, parent, "Prop_"..name)
	if !IsValid(ent) then return end
	
	self:SetPartValues(ent, parent, component, attachment)
	parent:DeleteOnRemove(ent)
	
	return ent
end

function SW_ADDON:SetUpVehiclePropParented(parent, component, ply)
	
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if !attachment then return end
	
	local name = component.name
	local boneMerge = component.boneMerge
	
	local ent = self:MakeEnt("prop_physics", ply, parent, "ParentedProp_"..name)
	if !IsValid(ent) then return end
	
	self:SetPartValues(ent, parent, component, attachment)
	self:SetupChildEntity(ent, parent, component.collision, component.parentAttachment)
	
	if boneMerge then
		ent:AddEffects(EF_BONEMERGE)
	end
	
	return ent
end

function SW_ADDON:SetUpVehicleAnimatable(parent, component, ply)
	
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if !attachment then return end
	
	local name = component.name
	local boneMerge = component.boneMerge
	
	local ent = self:MakeEnt("gmod_sw_animatable", ply, parent, "Animatable_"..name)
	if !IsValid(ent) then return end
	
	self:SetPartValues(ent, parent, component, attachment)
	self:SetupChildEntity(ent, parent, component.collision, component.parentAttachment)
	
	if boneMerge then
		ent:AddEffects(EF_BONEMERGE)
	end
	
	return ent
end

function SW_ADDON:SetUpVehicleSpeedometer(parent, component, ply)
	
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if !attachment then return end

	local name = component.name
	local minSpeed = component.minSpeed
	local maxSpeed = component.maxSpeed
	local minPoseValue = component.minPoseValue
	local maxPoseValue = component.maxPoseValue
	local poseName = component.poseName
	
	local ent = self:MakeEnt("gmod_sw_speedometer", ply, parent, "Speedometer_"..name)
	if !IsValid(ent) then return end

	self:SetPartValues(ent, parent, component, attachment)
	ent:SetMinSpeed(minSpeed)
	ent:SetMaxSpeed(maxSpeed)
	ent:SetMinPoseValue(minPoseValue)
	ent:SetMaxPoseValue(maxPoseValue)
	ent:SetPoseName(poseName)
	ent:SetMessureEntity(parent)
	
	ent:AttachToEnt(parent, component.parentAttachment)
	
	if boneMerge then
		ent:AddEffects(EF_BONEMERGE)
	end
	
	return ent
end

function SW_ADDON:SetUpVehicleTrigger(parent, component, ply)
	
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if !attachment then return end
	
	local name = component.name
	
	local ent = self:MakeEnt("gmod_sw_trigger_search", ply, parent, "Trigger_"..name)
	if !IsValid(ent) then return end
	
	self:SetPartValues(ent, parent, component, attachment)
	self:SetupChildEntity(ent, parent, component.collision, component.parentAttachment)
		
	return ent
end

function SW_ADDON:SetUpVehicleDoor(parent, component, ply)
	
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if !attachment then return end
	
	local name = component.name
	local soundOpen = component.soundOpen
	local soundClose = component.soundClose
	local autoClose = component.autoClose
	
	local ent = self:MakeEnt("gmod_sw_door", ply, parent, "Door_"..name)
	if !IsValid(ent) then
		parent:Remove()
		return
	end
	
	self:SetPartValues(ent, parent, component, attachment)
	parent:DeleteOnRemove(ent)
	ent:SetAddon(self)
	
	if isstring(soundOpen) then
		ent:Set_OpenSound(soundOpen)
	end
	
	if isstring(soundClose) then
		ent:Set_CloseSound(soundClose)
	end

	ent:Set_AutoClose(autoClose)
	ent:TurnOn(true)
	
	return ent
end

function SW_ADDON:SetUpVehicleConnector(parent, component, ply)
	
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if !attachment then return end

	local name = component.name
	local connectortype = component.connectortype
	local gender = component.gender
	local searchRadius = component.searchRadius
	
	local ent = self:MakeEnt("gmod_sw_connector", ply, parent, "Connector_"..name)
	if !IsValid(ent) then return end
	
	self:SetPartValues(ent, parent, component, attachment)
	ent.__SW_Dir = name
	parent:DeleteOnRemove(ent)
	
	ent.OnDisconnect = function(ConA, ConB)
		local vehicleA = self:GetSuperParent(ConA)
		local vehicleB = self:GetSuperParent(ConB)
		if !IsValid(vehicleA) then return end
		if !IsValid(vehicleB) then return end
	
		local DirA = ConA.__SW_Dir
		local DirB = ConB.__SW_Dir
		
		if isfunction(self.OnDisconnectTrailer) then
			self:OnDisconnectTrailer(vehicleA, vehicleB, DirA)
			self:OnDisconnectTrailer(vehicleB, vehicleA, DirB)
		end
		
		vehicleA.__SW_Connected = vehicleA.__SW_Connected or {}
		vehicleB.__SW_Connected = vehicleB.__SW_Connected or {}
		
		vehicleA.__SW_Connected[DirA] = nil
		vehicleB.__SW_Connected[DirB] = nil
	end
	
	ent.OnConnect = function(ConA, ConB)
		local vehicleA = self:GetSuperParent(ConA)
		local vehicleB = self:GetSuperParent(ConB)
		if !IsValid(vehicleA) then return end
		if !IsValid(vehicleB) then return end
	
		local DirA = ConA.__SW_Dir
		local DirB = ConB.__SW_Dir
		
		vehicleA.__SW_Connected = vehicleA.__SW_Connected or {}
		vehicleB.__SW_Connected = vehicleB.__SW_Connected or {}
		
		vehicleA.__SW_Connected[DirA] = vehicleB
		vehicleB.__SW_Connected[DirB] = vehicleA

		if isfunction(self.OnConnectTrailer) then
			self:OnConnectTrailer(vehicleA, vehicleB, DirA)
			self:OnConnectTrailer(vehicleB, vehicleA, DirB)
		end
	end

	ent.OnConnectionCheck = function(ConA, ConB)
		local vehicleA = self:GetSuperParent(ConA)
		local vehicleB = self:GetSuperParent(ConB)
		if !IsValid(vehicleA) then return end
		if !IsValid(vehicleB) then return end
	
		local DirA = ConA.__SW_Dir
		local DirB = ConB.__SW_Dir
		
		vehicleA.__SW_Connected = vehicleA.__SW_Connected or {}
		vehicleB.__SW_Connected = vehicleB.__SW_Connected or {}
		
		if !IsValid(vehicleA.__SW_Connected[DirA]) then return false end
		if !IsValid(vehicleB.__SW_Connected[DirB]) then return false end

		if vehicleA.__SW_Connected[DirA] != vehicleB then return false end
		if vehicleB.__SW_Connected[DirB] != vehicleA then return false end

		return true
	end
	
	ent:SetType(connectortype)
	ent:SetGender(gender)
	ent.searchRadius = searchRadius
	
	self:CreateUTimerOnEnt(ent, "Auto_Connect_Trailers", 0.1, function(f_ent)
		self:AutoConnectVehicles(f_ent)
	end)
	
	return ent
end

function SW_ADDON:SetUpVehicleConnectorButton(parent, component, ply)
	
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if !attachment then return end

	local name = component.name
	local inVehicle = component.inVehicle
	
	local ent = self:MakeEnt("prop_physics", ply, parent, "ConnectorButton_"..name)
	if !IsValid(ent) then return end
	
	self:SetPartValues(ent, parent, component, attachment)
	self:SetupChildEntity(ent, parent, component.collision, component.parentAttachment)
	
	ent.__SW_Dir = name
	ent.__SW_Cantpickup = true
	ent.__SW_Invehicle = inVehicle
	ent.__SW_Buttonfunc = (function(...)
		return self:CouplingMechanism(...)
	end)
	
	return ent
end

function SW_ADDON:SetUpVehicleButton(parent, component, ply)
	
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if !attachment then return end
	
	local name = component.name
	local inVehicle = component.inVehicle
	local func = component.func
	
	if !isfunction(func) then 
		error("component.func is not a function!")
		return 
	end
	
	local ent = self:MakeEnt("prop_physics", ply, parent, "Button_"..name)
	if !IsValid(ent) then return end
	
	self:SetPartValues(ent, parent, component, attachment)
	self:SetupChildEntity(ent, parent, component.collision, component.parentAttachment)
	
	ent.__SW_Cantpickup = true
	ent.__SW_Invehicle = inVehicle
	ent.__SW_Buttonfunc = (function(...)
		return func(...)
	end)
	
	return ent
end

function SW_ADDON:SetUpVehicleSmoke(parent, component, ply)
	if !ProceedVehicleSetUp(parent, component) then return end
	
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if !attachment then return end

	local name = component.name
	local keyValues = component.keyValues
	local inputFires = component.inputFires
	local color = component.color
	local spawnTime = component.spawnTime
	local velocity = component.velocity
	local startSize = component.startSize
	local endSize = component.endSize
	local lifeTime = component.lifeTime
	local dieTime = component.dieTime
	local startAlpha = component.startAlpha
	local endAlpha = component.endAlpha
	
	local ent = self:MakeEnt("gmod_sw_particle", ply, parent, "Smoke_"..name)
	if !IsValid(ent) then return end
	
	SetPartKeyValues(ent, keyValues)
	SetPartInputFire(ent, inputFires)
	
	ent:Spawn()
	ent:Activate()
	
	if !self:SetEntAngPosViaAttachment(parent, ent, attachment, component.selfAttachment) then
		self:RemoveEntites({parent, ent})
		return
	end
	
	ent:AttachToEnt(parent, component.parentAttachment)
	ent:Set_SpawnTime(spawnTime)
	ent:Set_Velocity(velocity)
	ent:SetColor(color)
	ent:Set_StartSize(startSize)
	ent:Set_EndSize(endSize)
	ent:Set_LifeTime(lifeTime)
	ent:Set_DieTime(dieTime)
	ent:Set_StartAlpha(startAlpha)
	ent:Set_EndAlpha(endAlpha)
	ent.__SW_Blockedprop = true
	
	return ent
end

function SW_ADDON:SetUpVehicleLight(parent, component, ply)
	if !ProceedVehicleSetUp(parent, component) then return end
	
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if !attachment then return end

	local name = component.name
	local keyValues = component.keyValues
	local inputFires = component.inputFires
	local fov = component.fov
	local farZ = component.farZ
	local color = component.color
	local shadowRenderDist = component.shadowRenderDist
	
	local ent = self:MakeEnt("gmod_sw_light_cone", ply, parent, "Light_"..name)
	if !IsValid(ent) then return end
	
	SetPartKeyValues(ent, keyValues)
	SetPartInputFire(ent, inputFires)
	
	ent:Spawn()
	ent:Activate()
	
	if !self:SetEntAngPosViaAttachment(parent, ent, attachment, component.selfAttachment) then
		self:RemoveEntites({parent, ent})
		return
	end
	
	ent:AttachToEnt(parent, component.parentAttachment)
	ent:Set_FOV(fov)
	ent:Set_FarZ(farZ)
	ent:SetColor(color)
	ent:Set_ShadowRenderDist(shadowRenderDist)
	ent.__SW_Blockedprop = true
	
	return ent
end

function SW_ADDON:SetUpVehicleGlow(parent, component, ply)
	if !ProceedVehicleSetUp(parent, component) then return end
	
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if !attachment then return end

	local name = component.name
	local keyValues = component.keyValues
	local inputFires = component.inputFires
	local color = component.color
	local size = component.size
	local enlarge = component.enlarge
	local count = component.count
	local alphaReduce = component.alphaReduce
	
	local ent = self:MakeEnt("gmod_sw_glow", ply, parent, "Glow_"..name)
	if !IsValid(ent) then return end
	
	SetPartKeyValues(ent, keyValues)
	SetPartInputFire(ent, inputFires)
	
	ent:Spawn()
	ent:Activate()
	
	if !self:SetEntAngPosViaAttachment(parent, ent, attachment, component.selfAttachment) then
		self:RemoveEntites({parent, ent})
		return
	end

	ent:SetColor(color)
	ent:AttachToEnt(parent, component.parentAttachment)
	ent:Set_Size(size)
	ent:Set_Enlarge(enlarge)
	ent:Set_Count(count)
	ent:Set_Alpha_Reduce(alphaReduce)
	ent.__SW_Blockedprop = true
	
	return ent
end

function SW_ADDON:SetUpVehiclePod(parent, component, ply)
	
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if !attachment then return end

	local name = component.name
	local boneMerge = component.boneMerge
	
	local ent = self:MakeEnt("prop_vehicle_prisoner_pod", ply, parent, "Seat_"..name)
	if !IsValid(ent) then return end
	
	self:SetPartValues(ent, parent, component, attachment)
	self:SetupChildEntity(ent, parent, component.collision, component.parentAttachment)
	ent.__swIsVehicle = true
	ent.__swExitVectors = component.exitVectors
	
	if boneMerge then
		ent:AddEffects(EF_BONEMERGE)
	end
	
	return ent
end

function SW_ADDON:SetUpVehicleAnimatedWheel(parent, component, ply)
	
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if !attachment then return end

	local name = component.name
	local size = component.size
	local restrate = component.restrate
	local boneMerge = component.boneMerge
	
	local ent = self:MakeEnt("gmod_sw_wheel", ply, parent, "Wheel_"..name)
	if !IsValid(ent) then return end

	self:SetPartValues(ent, parent, component, attachment)
	ent:SetSize(size)
	ent:SetRestRate(restrate)
	ent:SetMessureEntity(parent)
	ent:AttachToEnt(parent, component.parentAttachment)
	
	if boneMerge then
		ent:AddEffects(EF_BONEMERGE)
	end
	
	return ent
end

function SW_ADDON:SetUpVehicleDisplay(parent, component, ply)
	
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if !attachment then return end

	local name = component.name
	local scale = component.scale
	local functionName = component.functionName
	
	local ent = self:MakeEnt("gmod_sw_display", ply, parent, "Display_"..name)
	if !IsValid(ent) then return end

	self:SetPartValues(ent, parent, component, attachment)
	ent:SetDisplayOriginName("displaypos01")
	ent:SetAddon(self)
	ent:AttachToEnt(parent, component.parentAttachment)
	ent:TurnOn(true)
	ent:Set_Scale(scale)
	ent:SetColor(color_white)
	ent:SetDisplayFunctionName(functionName)
	
	return ent
end

function SW_ADDON:SetUpVehicleBendi(parent, component, ply)

	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if !attachment then return end

	local name = component.name
	local parentNameFront = component.parentNameFront
	local parentNameRear = component.parentNameRear
	local parentFront = parent
	local parentRear = parent
	
	if parentNameFront != "" then 
		parentFront = self:GetChildFromPath(parent, parentNameFront)
	end
	
	if parentNameRear != "" then 
		parentRear = self:GetChildFromPath(parent, parentNameRear)
	end
	
	local ent = self:MakeEnt("prop_ragdoll", ply, parent, "Bendi_"..name)
	if !IsValid(ent) then return end

	self:SetPartValues(ent, parent, component, attachment)
	
	local WD1 = constraint.Weld(ent, parentFront, 1, 0, 0, true)	
	if !IsValid(WD1) then
		parent:Remove()
		return
	end
	
	WD1.DoNotDuplicate = true
	parent.__SW_ConstraintWeld1 = WD1
	
	local WD2 = constraint.Weld(ent, parentRear, 0, 0, 0, true)	
	if !IsValid(WD2) then
		parent:Remove()
		return
	end
	
	WD2.DoNotDuplicate = true
	parent.__SW_ConstraintWeld2 = WD2
	
	return ent
end

function SW_ADDON:SetUpVehicle(ent, parent, component, attachment)

	self:SetPartValues(ent, parent, component, attachment)
	ent.__swIsVehicle = true
	ent.__swExitVectors = component.exitVectors
end

function SW_ADDON:SetUpVehicleJeep(parent, component, ply)

	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if !attachment then return end
	
	local name = component.name

	local ent = self:MakeEnt("prop_vehicle_jeep", ply, parent, "Jeep_"..name)
	if !IsValid(ent) then return end

	self:SetUpVehicle(ent, parent, component, attachment)
	
	return ent
end

function SW_ADDON:SetUpVehicleAirboat(parent, component, ply)

	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if !attachment then return end
	
	local name = component.name

	local ent = self:MakeEnt("prop_vehicle_airboat", ply, parent, "Airboat_"..name)
	if !IsValid(ent) then return end
	
	self:SetUpVehicle(ent, parent, component, attachment)
	
	return ent
end

function SW_ADDON:SetUpVehicleHoverball(parent, component, ply)

	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if !attachment then return end
	
	local name = component.name
	local speed = component.speed
	local airResistance = component.airResistance
	local strength = component.strength
	local numDown = component.numDown
	local numUp = component.numUp
	local numBackDown = component.numBackDown
	local numBackUp = component.numBackUp
	
	local ent = self:MakeEnt("gmod_hoverball", ply, parent, "Hoverball_"..name)
	if !IsValid(ent) then return end
		
	self:SetPartValues(ent, parent, component, attachment)
	
	ent:SetSpeed(speed)
	ent:SetAirResistance(airResistance)
	ent:SetStrength(strength)
	ent.NumDown = numpad.OnDown(ply, numDown, "Hoverball_Up", ent, true)
	ent.NumUp = numpad.OnUp(ply, numUp, "Hoverball_Up", ent, false)
	ent.NumBackDown = numpad.OnDown(ply, numBackDown, "Hoverball_Down", ent, true)
	ent.NumBackUp = numpad.OnUp(ply, numBackUp, "Hoverball_Down", ent, false)
	
	return ent
end