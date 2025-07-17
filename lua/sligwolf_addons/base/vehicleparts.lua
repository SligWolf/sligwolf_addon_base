AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SLIGWOLF_ADDON then
	SligWolf_Addons.AutoLoadAddon(function() end)
	return
end

local CONSTANTS = SligWolf_Addons.Constants

local LIBSpamprotection = SligWolf_Addons.Spamprotection
local LIBConstraints = SligWolf_Addons.Constraints
local LIBEntities = SligWolf_Addons.Entities
local LIBPosition = SligWolf_Addons.Position
local LIBCoupling = SligWolf_Addons.Coupling
local LIBVehicle = SligWolf_Addons.Vehicle
local LIBPhysics = SligWolf_Addons.Physics
local LIBModel = SligWolf_Addons.Model

local g_FallbackComponentsParams = {
	model = "",
	class = "",
	color = CONSTANTS.colorDefault,
	skin = 0,
	bodygroups = {},
	shadow = false,
	nodraw = false,
	freeze = false,
	customPhysics = false,
	solid = SOLID_VPHYSICS,
	collision = COLLISION_GROUP_NONE,
	blocked = true,
	blockAllTools = false,
	keyValues = {},
	inputFires = {},
	constraints = {},
	colorFromParent = false,
	isBody = false,
	removeAllOnDelete = true,

	typesParams = {
		propParent = {
			collision = COLLISION_GROUP_IN_VEHICLE,
			boneMerge = false,
			freeze = true,
		},
		trigger = {
			customPhysics = true,
			minSize = Vector(-4, -4, -4),
			maxSize = Vector(4, 4, 4),
			model = CONSTANTS.mdlCube4,
			freeze = true,
		},
		help = {
			helpName = "",
			freeze = true,
		},
		door = {
			autoClose = true,
			openTime = 3,
			disableUse = false,
			spawnOpen = false,
			freeze = false,
		},
		connector = {
			collision = COLLISION_GROUP_IN_VEHICLE,
			connectortype = "unknown",
			gender = LIBCoupling.GENDER_NEUTRAL,
			searchRadius = CONSTANTS.numConRadius,
			model = CONSTANTS.mdlSphere4,
			freeze = false,
		},
		connectorButton = {
			collision = COLLISION_GROUP_WORLD,
			inVehicle = false,
			freeze = true,
		},
		button = {
			collision = COLLISION_GROUP_WORLD,
			inVehicle = false,
			freeze = true,
		},
		camera = {
			forceThirdperson = false,
			allowThirdperson = false,
			allowRotation = false,
			defaultDistance = nil,
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
		},
		light = {
			fov = 120,
			farZ = 2048,
			shadowRenderDist = 2048,
		},
		glow = {
			size = 30,
			enlarge = 10,
			count = 2,
			alphaReduce = 100,
		},
		animatedWheel = {
			size = 8,
			restrate = 16,
			boneMerge = false,
			collision = COLLISION_GROUP_WEAPON,
			freeze = true,
		},
		speedometer = {
			minSpeed = 0,
			maxSpeed = 1312,
			minPoseValue = 0,
			maxPoseValue = 1,
			poseName = "vehicle_guage",
			freeze = true,
		},
		display = {
			scale = 0.25,
			functionName = "",
			maxDrawDistance = 2048,
			freeze = true,
		},
		bendi = {
			parentNameFront = "",
			parentNameRear = "",
			freeze = false,
		},
		pod = {
			collision = COLLISION_GROUP_WORLD,
			boneMerge = false,
			keyValues = {
				vehiclescript = "scripts/vehicles/prisoner_pod.txt",
				limitview = 0,
			},
			freeze = true,
		},
		seatGroup = {
			collision = COLLISION_GROUP_WORLD,
			seatModel = CONSTANTS.mdlDynamicSeat,
			seatKeyValues = {
				vehiclescript = "scripts/vehicles/prisoner_pod.txt",
				limitview = 0,
			},
			freeze = true,
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
			freeze = false,
		},
		jeep = {
			enableWheels = true,
			freeze = false,
		},
		airboat = {
			enableWheels = true,
			freeze = false,
		},
	},
}

local g_FallbackConstraintsParams = {
	Weld = {
		bone1 = 0,
		bone2 = 0,
		forcelimit = 0,
		nocollide = true,
		forceRecreation = false,
	},
	NoCollide = {
		bone1 = 0,
		bone2 = 0,
		forceRecreation = false,
	},
	Axis = {
		bone1 = 0,
		bone2 = 0,
		lpos1 = CONSTANTS.vecZero,
		lpos2 = CONSTANTS.vecZero,
		forcelimit = 0,
		torquelimit = 0,
		friction = 0,
		nocollide = true,
		localaxis = CONSTANTS.vecZero,
		forceRecreation = false,
	},
	Ballsocket = {
		bone1 = 0,
		bone2 = 0,
		localpos = CONSTANTS.vecZero,
		forcelimit = 0,
		torquelimit = 0,
		nocollide = true,
		forceRecreation = false,
	},
	AdvBallsocket = {
		bone1 = 0,
		bone2 = 0,
		lpos1 = CONSTANTS.vecZero,
		lpos2 = CONSTANTS.vecZero,
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
		nocollide  = true,
		forceRecreation = false,
	},
	Keepupright = {
		ang = Angle(),
		angularLimit = 0,
		forceRecreation = false,
	},
}

local function GetColor(superparent, colorOrColorName)
	if not IsValid(superparent) then
		error("Superparent is missing!")
		return nil
	end

	if not isstring(colorOrColorName) then
		if not IsColor(colorOrColorName) then
			ErrorNoHaltWithStack(
				string.format(
					"Invalid or missing color at entity '%s', replaced with a fallback color!",
					LIBVehicle.ToString(superparent)
				)
			)

			return CONSTANTS.colorError1
		end

		return colorOrColorName
	end

	local superparentTable = superparent:SligWolf_GetTable()

	local customProperties = superparentTable.customSpawnProperties or {}
	local colors = customProperties.colors or {}

	local color = colors[colorOrColorName]
	if not color or not IsColor(color)  then
		ErrorNoHaltWithStack(
			string.format(
				"Color named '%s' is invalid or missing at entity '%s', replaced with a fallback color!",
				colorOrColorName,
				LIBVehicle.ToString(superparent)
			)
		)

		return CONSTANTS.colorError2
	end

	return color
end

local function GetSkin(superparent, skinOrSkinName)
	if not IsValid(superparent) then
		error("Superparent is missing!")
		return nil
	end

	if not isstring(skinOrSkinName) then
		if not isnumber(skinOrSkinName) then
			ErrorNoHaltWithStack(
				string.format(
					"Invalid or missing skin at entity '%s', replaced with a fallback skin!",
					LIBVehicle.ToString(superparent)
				)
			)

			return CONSTANTS.skinError
		end

		return skinOrSkinName
	end

	local superparentTable = superparent:SligWolf_GetTable()

	local customProperties = superparentTable.customSpawnProperties or {}
	local skins = customProperties.skins or {}

	local skinValue = skins[skinOrSkinName]
	if not skinValue or not isnumber(skinValue)  then
		ErrorNoHaltWithStack(
			string.format(
				"Skin named '%s' is invalid or missing at entity '%s', replaced with a fallback skin!",
				skinOrSkinName,
				LIBVehicle.ToString(superparent)
			)
		)

		return CONSTANTS.skinError
	end

	return skinValue
end

local function SetPartKeyValues(ent, keyValues)
	if not keyValues then return end

	for k, v in pairs(keyValues) do
		ent:SetKeyValue(tostring(k), v)
	end
end

local function SetPartInputFire(ent, inputFires)
	if not inputFires then return end

	for _, v in ipairs(inputFires) do
		ent:Fire(v)
	end
end

local function SetUnsetConstraintValuesToDefaults(constraint, constraintInfo)
	local fallbackConstraintParamsForConstraint = g_FallbackConstraintsParams[constraint] or {}

	for k, v in pairs(fallbackConstraintParamsForConstraint) do
		if constraintInfo[k] ~= nil then
			continue
		end

		constraintInfo[k] = v
	end

	return constraintInfo
end

local function SetUnsetConstraintsValuesToDefaults(constraints)
	constraints = constraints or {}

	for constraintName, constraintInfo in pairs(constraints) do
		constraintInfo = SetUnsetConstraintValuesToDefaults(constraintName, constraintInfo)
		constraints[constraintName] = constraintInfo
	end

	return constraints
end

local function CreateWeld(ent, parent, constraintInfos)
	constraintInfos.deleteEntOnBreak = true

	local constraintEnt = LIBConstraints.Weld(ent, parent, constraintInfos)
	return constraintEnt
end

local function CreateNoCollide(ent, parent, constraintInfos)
	local constraintEnt = LIBConstraints.NoCollide(ent, parent, constraintInfos)
	return constraintEnt
end

local function CreateAxis(ent, parent, constraintInfos)
	constraintInfos.dontAddTable = false

	local constraintEnt = LIBConstraints.Axis(ent, parent, constraintInfos)
	return constraintEnt
end

local function CreateBallsocket(ent, parent, constraintInfos)
	local constraintEnt = LIBConstraints.Ballsocket(ent, parent, constraintInfos)
	return constraintEnt
end

local function CreateAdvBallsocket(ent, parent, constraintInfos)
	local constraintEnt = LIBConstraints.AdvBallsocket(ent, parent, constraintInfos)
	return constraintEnt
end

local function CreateKeepupright(ent, parent, constraintInfos)
	local constraintEnt = LIBConstraints.Keepupright(ent, constraintInfos)
	return constraintEnt
end

local g_ConstraintCreateFunctions = {
	Weld = CreateWeld,
	NoCollide = CreateNoCollide,
	Axis = CreateAxis,
	Ballsocket = CreateBallsocket,
	AdvBallsocket = CreateAdvBallsocket,
	Keepupright = CreateKeepupright,
}

function SLIGWOLF_ADDON:CreateConstraint(ent, parent, constraintName, constraintInfos)
	if LIBEntities.IsMarkedForDeletion(ent) then
		return nil
	end

	if LIBEntities.IsMarkedForDeletion(parent) then
		return nil
	end

	local func = g_ConstraintCreateFunctions[constraintName]

	if not func then
		self:Error("%s is not a valid constraint type", constraintName)
		return nil
	end

	local constraintEnt = func(ent, parent, constraintInfos)

	if not IsValid(constraintEnt) then
		self:RemoveFaultyEntities(
			{ent, parent},
			"Couldn't create %s constraint between %s <===> %s. Removing entities.",
			constraintName,
			ent,
			parent
		)

		return nil
	end

	local parentTable = parent:SligWolf_GetTable()

	local vehiclePartsConstraint = parentTable.vehiclePartsConstraint or {}
	parentTable.vehiclePartsConstraint = vehiclePartsConstraint

	vehiclePartsConstraint[constraintName] = constraintInfos

	return constraintEnt
end

function SLIGWOLF_ADDON:CreateConstraints(ent, parent, componentConstraints)
	if LIBEntities.IsMarkedForDeletion(ent) then
		return false
	end

	if LIBEntities.IsMarkedForDeletion(parent) then
		return false
	end

	componentConstraints = componentConstraints or {}
	componentConstraints = SetUnsetConstraintsValuesToDefaults(componentConstraints)

	for constraintName, constraintInfos in pairs(componentConstraints) do
		local cEnt = self:CreateConstraint(ent, parent, constraintName, constraintInfos)

		if not IsValid(cEnt) then
			return false
		end
	end

	return true
end

function SLIGWOLF_ADDON:RecreateConstraints(ent, parent)
	if LIBEntities.IsMarkedForDeletion(ent) then
		return false
	end

	if LIBEntities.IsMarkedForDeletion(parent) then
		return false
	end

	local parentTable = parent:SligWolf_GetTable()
	local vehiclePartsConstraint = parentTable.vehiclePartsConstraint or {}

	return self:CreateConstraints(ent, parent, vehiclePartsConstraint)
end

local function ProceedVehicleSetUp(ent, tb)
	if LIBEntities.IsMarkedForDeletion(ent) then
		return false
	end

	if not istable(tb) then
		return false
	end

	return true
end

local function SetUnsetComponentsValuesToDefaults(component)
	local componentType = tostring(component.type or "")
	if componentType == "" then
		error("component.type is not set!")
		return nil
	end
	component.type = componentType

	local mergedFallbackComponentsParams = table.Copy(g_FallbackComponentsParams)

	local typeParams = mergedFallbackComponentsParams.typesParams[componentType] or {}
	mergedFallbackComponentsParams.typesParams = nil

	mergedFallbackComponentsParams = table.Merge(mergedFallbackComponentsParams, typeParams)

	for k, v in pairs(mergedFallbackComponentsParams) do
		if not istable(v) or IsColor(v) then
			if component[k] ~= nil then
				continue
			end

			component[k] = v
			continue
		end

		component[k] = table.Merge(v, component[k] or {})
	end

	local color = component.color
	if not color then
		color = mergedFallbackComponentsParams.color
	end

	local attachment = tostring(component.attachment or "")
	if attachment == "" then
		error("component.attachment is not set!")
		return nil
	end
	component.attachment = attachment

	component.model = LIBModel.LoadModel(component.model, mergedFallbackComponentsParams.model)

	local name = tostring(component.name or "")
	if name == "" then
		name = string.format("unnamed_%s_%09u", component.type, math.floor(math.random(0, 999999999)))
	end
	component.name = name

	local class = tostring(component.class or "")
	if class == "" then
		class = nil
	end
	component.class = class

	if component.customPhysics then
		component.solid = nil
		component.collision = nil
	end

	return component
end

function SLIGWOLF_ADDON:CheckToProceedToCreateEnt(ent, tb)
	if not ProceedVehicleSetUp(ent, tb) then return nil end

	local att = tostring(tb.attachment or "")
	if att == "" then return nil end

	local parentAttId = ent:LookupAttachment(att) or 0
	if parentAttId == 0 then return nil end

	return parentAttId
end

local function disableEntPhysicsTemporarily(ent, freeze, solid)
	if not IsValid(ent) then return end

	local entTable = ent:SligWolf_GetTable()
	if entTable.spawnState then
		return
	end

	local spawnState = {}
	entTable.spawnState = spawnState

	spawnState.solid = solid or false
	spawnState.freeze = freeze or false

	LIBEntities.EnableMotion(ent, false)
	ent:SetNotSolid(true)
end

function SLIGWOLF_ADDON:SetPartValues(ent, parent, component, attachment, superparent, callback)
	if not IsValid(ent) then return end

	local model = component.model
	local color = GetColor(superparent, component.color)
	local skin = GetSkin(superparent, component.skin)
	local bodygroups = component.bodygroups
	local shadow = component.shadow
	local nodraw = component.nodraw
	local solid = component.solid
	local collision = component.collision
	local blocked = component.blocked
	local blockAllTools = component.blockAllTools
	local keyValues = component.keyValues
	local inputFires = component.inputFires
	local mass = component.mass
	local colorFromParent = component.colorFromParent
	local isBody = component.isBody
	local selfAttachment = component.selfAttachment
	local freeze = component.freeze

	LIBModel.SetModel(ent, model)

	SetPartKeyValues(ent, keyValues)
	SetPartInputFire(ent, inputFires)

	if ent.sligwolf_baseEntity then
		-- spawn first when if it is a custom entity, so we can use model dependent positioning

	 	ent:Spawn()
	 	ent:Activate()
	end

	if not LIBPosition.MountToAttachment(parent, ent, attachment, selfAttachment, callback) then
		self:RemoveFaultyEntities(
			{parent, ent},
			"Couldn't attach entities %s <===> %s. Attachments %s <===> %s. Removing entities.",
			ent,
			parent,
			tostring(selfAttachment or "<origin>"),
			tostring(attachment or "<origin>")
		)

		return
	end

	if not ent.sligwolf_baseEntity then
		-- engine entities must not be spawned before model dependent positioning.

		ent:Spawn()
		ent:Activate()
	end

	ent:SetColor(color)
	ent:SetSkin(skin)

	ent.DoNotDuplicate = true

	for bodygroupName, bodygroup in pairs(bodygroups) do
		ent:SetBodygroup(bodygroup.index, bodygroup.mesh)
	end

	ent:DrawShadow(shadow)

	if solid then
		ent:SetSolid(solid)
	end

	if collision then
		ent:SetCollisionGroup(collision)
	end

	ent:SetNoDraw(nodraw)

	if colorFromParent and ent.sligwolf_baseEntity then
		ent:SetColorBaseEntity(parent)
	end

	if blocked then
		ent.sligwolf_blockedprop = true
		ent:SetNWBool("sligwolf_blockedprop", true)
	end

	if blockAllTools then
		ent.sligwolf_blockAllTools = true
		ent:SetNWBool("sligwolf_blockAllTools", true)
	end

	if isBody then
		ent.sligwolf_isBody = true
		ent:SetNWBool("sligwolf_isBody", true)
	end

	disableEntPhysicsTemporarily(superparent, false, true)
	disableEntPhysicsTemporarily(
		ent,
		freeze,
		ent:IsSolid() and LIBPhysics.IsTraceableCollision(solid, collision)
	)

	local phys = ent:GetPhysicsObject()
	if IsValid(phys) and mass then
		phys:SetMass(mass)
	end

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleParts(parent, components, dtr, ply, superparent)
	if not ProceedVehicleSetUp(parent, components) then return end
	if table.IsEmpty(components) then return end

	dtr = dtr or {}
	superparent = superparent or parent

	for i, component in ipairs(components) do
		self:SetUpVehiclePart(parent, component, dtr, ply, superparent)
	end
end

function SLIGWOLF_ADDON:SetUpVehiclePart(parent, component, dtr, ply, superparent, callback)
	if not ProceedVehicleSetUp(parent, component) then return end
	dtr = dtr or {}

	component = SetUnsetComponentsValuesToDefaults(component)

	local funcs = {
		prop = self.SetUpVehicleProp,
		slider = self.SetUpVehicleSlider,
		bogie = self.SetUpVehicleBogie,
		camera = self.SetUpVehicleCamera,
		propParent = self.SetUpVehiclePropParented,
		seatGroup = self.SetUpVehicleSeatGroup,
		animatable = self.SetUpVehicleAnimatable,
		speedometer = self.SetUpVehicleSpeedometer,
		trigger = self.SetUpVehicleTrigger,
		help = self.SetUpVehicleHelp,
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

	if not isfunction(func) then
		self:Error("%s is not a valid part type", componentType)
		return
	end

	local ent = func(self, parent, component, ply, superparent, function(ent)
		if not IsValid(ent) then return end

		self:SetUpVehicleParts(ent, component.children, dtr, ply, superparent)

		if isfunction(callback) then
			self:HandleSpawnFinishedEvent(ent)
			callback(ent)
		end
	end)

	if not IsValid(ent) then
		return
	end

	local removeAllOnDelete = component.removeAllOnDelete

	if removeAllOnDelete then
		LIBEntities.RemoveSystemEntitiesOnDelete(ent)
	end

	ent.sligwolf_denyToolReload = dtr

	local hasSpawnedConstraints = self:CreateConstraints(ent, parent, component.constraints)
	if not hasSpawnedConstraints then
		return
	end

	LIBSpamprotection.DelayNextSpawn(ply)
	self:HandleSpawnFinishedEvent(ent)

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleProp(parent, component, ply, superparent, callback)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local class = component.class

	local ent = self:MakeEntEnsured(class or "sligwolf_phys", ply, parent, "Prop_" .. name)
	if not IsValid(ent) then return end

	self:SetPartValues(ent, parent, component, attachment, superparent, callback)
	LIBEntities.RemoveEntitiesOnDelete(parent, ent)

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleSlider(parent, component, ply, superparent, callback)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local class = component.class

	local ent = self:MakeEntEnsured(class or "sligwolf_slider", ply, parent, "Slider_" .. name)
	if not IsValid(ent) then return end

	self:SetPartValues(ent, parent, component, attachment, superparent, callback)
	LIBEntities.RemoveEntitiesOnDelete(parent, ent)

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleBogie(parent, component, ply, superparent, callback)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local class = component.class

	local ent = self:MakeEntEnsured(class or "sligwolf_bogie", ply, parent, "Bogie_" .. name)
	if not IsValid(ent) then return end

	self:SetPartValues(ent, parent, component, attachment, superparent, callback)
	LIBEntities.RemoveEntitiesOnDelete(parent, ent)

	return ent
end

function SLIGWOLF_ADDON:SetUpVehiclePropParented(parent, component, ply, superparent, callback)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local class = component.class
	local boneMerge = component.boneMerge

	local ent = self:MakeEntEnsured(class or "sligwolf_phys", ply, parent, "ParentedProp_" .. name)
	if not IsValid(ent) then return end

	self:SetPartValues(ent, parent, component, attachment, superparent, callback)
	LIBEntities.SetupDecoratorEntity(ent, parent, component.collision, attachment)

	if boneMerge then
		ent:AddEffects(EF_BONEMERGE)
		ent:AddEffects(EF_BONEMERGE_FASTCULL)
	end

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleSeatGroup(parent, component, ply, superparent, callback)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local class = component.class
	local seatModel = component.seatModel
	local seatKeyValues = component.seatKeyValues

	local ent = self:MakeEntEnsured(class or "sligwolf_seat_group", ply, parent, "SeatGroup_" .. name)
	if not IsValid(ent) then return end

	self:SetPartValues(ent, parent, component, attachment, superparent, callback)
	LIBEntities.SetupDecoratorEntity(ent, parent, component.collision, attachment)

	ent:SetSeatModel(seatModel)
	ent:SetSeatKeyValues(seatKeyValues)

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleAnimatable(parent, component, ply, superparent, callback)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local class = component.class
	local boneMerge = component.boneMerge

	local ent = self:MakeEntEnsured(class or "sligwolf_animatable", ply, parent, "Animatable_" .. name)
	if not IsValid(ent) then return end

	self:SetPartValues(ent, parent, component, attachment, superparent, callback)
	LIBEntities.SetupDecoratorEntity(ent, parent, component.collision, attachment)

	if boneMerge then
		ent:AddEffects(EF_BONEMERGE)
		ent:AddEffects(EF_BONEMERGE_FASTCULL)
	end

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleSpeedometer(parent, component, ply, superparent, callback)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local class = component.class
	local minSpeed = component.minSpeed
	local maxSpeed = component.maxSpeed
	local minPoseValue = component.minPoseValue
	local maxPoseValue = component.maxPoseValue
	local poseName = component.poseName

	local ent = self:MakeEntEnsured(class or "sligwolf_speedometer", ply, parent, "Speedometer_" .. name)
	if not IsValid(ent) then return end

	self:SetPartValues(ent, parent, component, attachment, superparent, callback)
	ent:SetSpeedoMinSpeed(minSpeed)
	ent:SetSpeedoMaxSpeed(maxSpeed)
	ent:SetSpeedoMinPoseValue(minPoseValue)
	ent:SetSpeedoMaxPoseValue(maxPoseValue)
	ent:SetSpeedoPoseName(poseName)
	ent:SetSpeedoMessureEntity(parent)

	ent:AttachToEnt(parent, attachment)

	if boneMerge then
		ent:AddEffects(EF_BONEMERGE)
		ent:AddEffects(EF_BONEMERGE_FASTCULL)
	end

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleTrigger(parent, component, ply, superparent, callback)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local class = component.class
	local minSize = component.minSize
	local maxSize = component.maxSize
	local filterFunc = component.filterFunc

	if filterFunc and not isfunction(filterFunc) then
		error("component.filterFunc is not a function!")
		return
	end

	local ent = self:MakeEntEnsured(class or "sligwolf_trigger", ply, parent, "Trigger_" .. name)
	if not IsValid(ent) then return end

	ent:SetTriggerAABB(minSize, maxSize)

	if filterFunc then
		ent.PassesTriggerFilters = filterFunc
	end

	self:SetPartValues(ent, parent, component, attachment, superparent, callback)
	LIBEntities.SetupDecoratorEntity(ent, parent, component.collision, attachment)

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleHelp(parent, component, ply, superparent, callback)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local class = component.class
	local model = component.model
	local helpName = component.helpName

	local ent = self:MakeEntEnsured(class or "sligwolf_help", ply, parent, "Help_" .. name)
	if not IsValid(ent) then
		return
	end

	self:SetPartValues(ent, parent, component, attachment, superparent, callback)
	LIBEntities.RemoveEntitiesOnDelete(parent, ent)

	LIBModel.SetModel(ent, model)

	ent:SetHelpName(helpName)
	ent:TurnOn(true)

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleDoor(parent, component, ply, superparent, callback)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local class = component.class
	local disableUse = component.disableUse
	local model = component.model
	local openPhysModel = component.openPhysModel
	local soundOpen = component.soundOpen
	local soundClose = component.soundClose
	local autoClose = component.autoClose
	local openTime = component.openTime
	local spawnOpen = component.spawnOpen
	local funcOnOpen = component.onOpen
	local funcOnClose = component.onClose

	if funcOnOpen and not isfunction(funcOnOpen) then
		error("component.funcOnOpen is not a function!")
		return
	end

	if funcOnClose and not isfunction(funcOnClose) then
		error("component.funcOnClose is not a function!")
		return
	end

	local ent = self:MakeEntEnsured(class or "sligwolf_door", ply, parent, "Door_" .. name)
	if not IsValid(ent) then
		return
	end

	self:SetPartValues(ent, parent, component, attachment, superparent, callback)
	LIBEntities.RemoveEntitiesOnDelete(parent, ent)

	if isstring(soundOpen) then
		ent:SetDoorOpenSound(soundOpen)
	end

	if isstring(soundClose) then
		ent:SetDoorCloseSound(soundClose)
	end

	LIBModel.SetModel(ent, model)

	ent:SetDoorOpenPhysModel(openPhysModel)
	ent:SetDoorOpenTime(openTime)
	ent:SetDoorAutoClose(autoClose)
	ent:SetDoorSpawnOpen(spawnOpen)
	ent:SetDoorDisableUse(disableUse)
	ent:TurnOn(true)

	if funcOnOpen then
		ent.OnOpen = funcOnOpen
	end

	if funcOnClose then
		ent.OnClose = funcOnClose
	end

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleConnector(parent, component, ply, superparent, callback)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local class = component.class
	local connectortype = component.connectortype
	local gender = component.gender
	local searchRadius = component.searchRadius

	local ent = self:MakeEntEnsured(class or "sligwolf_connector", ply, parent, "Connector_" .. name)
	if not IsValid(ent) then return end

	self:SetPartValues(ent, parent, component, attachment, superparent, callback)

	ent.sligwolf_connectorDirection = name
	LIBCoupling.RegisterCoupler(superparent, ent)

	LIBEntities.RemoveEntitiesOnDelete(parent, ent)

	ent.OnDisconnect = function(ConA, ConB)
		local vehicleA = LIBEntities.GetSuperParent(ConA)
		local vehicleB = LIBEntities.GetSuperParent(ConB)
		if not IsValid(vehicleA) then return end
		if not IsValid(vehicleB) then return end

		local dirA = ConA.sligwolf_connectorDirection

		if isfunction(self.OnDisconnectTrailer) then
			self:OnDisconnectTrailer(vehicleA, vehicleB, dirA)
		end

		LIBCoupling.DisconnectVehicles(vehicleA, dirA)
	end

	ent.OnPostDisconnect = function(ConA, ConB)
		local vehicleA = LIBEntities.GetSuperParent(ConA)
		local vehicleB = LIBEntities.GetSuperParent(ConB)
		if not IsValid(vehicleA) then return end
		if not IsValid(vehicleB) then return end

		local dirA = ConA.sligwolf_connectorDirection

		if isfunction(self.OnPostDisconnectTrailer) then
			self:OnPostDisconnectTrailer(vehicleA, vehicleB, dirA)
		end
	end

	ent.OnConnect = function(ConA, ConB)
		local vehicleA = LIBEntities.GetSuperParent(ConA)
		local vehicleB = LIBEntities.GetSuperParent(ConB)
		if not IsValid(vehicleA) then return end
		if not IsValid(vehicleB) then return end

		local dirA = ConA.sligwolf_connectorDirection

		LIBCoupling.ConnectVehicles(vehicleA, vehicleB, dirA)

		if isfunction(self.OnConnectTrailer) then
			self:OnConnectTrailer(vehicleA, vehicleB, dirA)
		end
	end

	ent.OnConnectionCheck = function(ConA, ConB)
		local vehicleA = LIBEntities.GetSuperParent(ConA)
		local vehicleB = LIBEntities.GetSuperParent(ConB)
		if not IsValid(vehicleA) then return end
		if not IsValid(vehicleB) then return end

		local dirA = ConA.sligwolf_connectorDirection

		if not LIBCoupling.IsConnected(vehicleA, vehicleB, dirA) then
			return false
		end

		return true
	end

	ent:SetType(connectortype)
	ent:SetGender(gender)
	ent.searchRadius = searchRadius

	self:EntityTimerOnce(ent, "AutoConnectTrailers", 0.1, function()
		LIBCoupling.Connect(ent, ply)
	end)

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleConnectorButton(parent, component, ply, superparent, callback)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local class = component.class
	local inVehicle = component.inVehicle

	local ent = self:MakeEntEnsured(class or "sligwolf_button", ply, parent, "ConnectorButton_" .. name)
	if not IsValid(ent) then return end

	self:SetPartValues(ent, parent, component, attachment, superparent, callback)
	LIBEntities.SetupDecoratorEntity(ent, parent, component.collision, attachment)

	ent.sligwolf_connectorDirection = name

	ent.sligwolf_noPickup = true
	ent:SetNWBool("sligwolf_noPickup", true)

	ent.sligwolf_inVehicle = inVehicle
	ent.SLIGWOLF_Buttonfunc = function()
		return LIBCoupling.ToogleConnection(ent, ply)
	end

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleButton(parent, component, ply, superparent, callback)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local class = component.class
	local inVehicle = component.inVehicle
	local func = component.func

	if not isfunction(func) then
		error("component.func is not a function!")
		return
	end

	local ent = self:MakeEntEnsured(class or "sligwolf_button", ply, parent, "Button_" .. name)
	if not IsValid(ent) then return end

	self:SetPartValues(ent, parent, component, attachment, superparent, callback)
	LIBEntities.SetupDecoratorEntity(ent, parent, component.collision, attachment)

	ent.sligwolf_noPickup = true
	ent:SetNWBool("sligwolf_noPickup", true)

	ent.sligwolf_inVehicle = inVehicle
	ent.SLIGWOLF_Buttonfunc = function(...)
		return func(...)
	end

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleCamera(parent, component, ply, superparent, callback)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local class = component.class
	local forceThirdperson = component.forceThirdperson
	local allowThirdperson = component.allowThirdperson
	local allowRotation = component.allowRotation
	local defaultDistance = component.defaultDistance
	local selfAttachment = component.selfAttachment

	local ent = self:MakeEntEnsured(class or "sligwolf_camera", ply, parent, "Camera_" .. name)
	if not IsValid(ent) then return end

	ent:Spawn()
	ent:Activate()

	if not LIBPosition.MountToAttachment(parent, ent, attachment, selfAttachment, callback) then
		self:RemoveFaultyEntities(
			{parent, ent},
			"Couldn't attach entities %s <===> %s. Attachments %s <===> %s. Removing entities.",
			ent,
			parent,
			tostring(selfAttachment or "<origin>"),
			tostring(attachment or "<origin>")
		)

		return
	end

	ent:AttachToEnt(parent, attachment)
	ent:SetCameraForceThirdperson(forceThirdperson)
	ent:SetCameraAllowThirdperson(allowThirdperson)
	ent:SetCameraAllowRotation(allowRotation)
	ent:SetCameraDefaultDistance(defaultDistance)

	ent.sligwolf_blockedprop = true
	ent:SetNWBool("sligwolf_blockedprop", true)

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleSmoke(parent, component, ply, superparent, callback)
	if not ProceedVehicleSetUp(parent, component) then return end

	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local class = component.class
	local keyValues = component.keyValues
	local inputFires = component.inputFires
	local color = GetColor(superparent, component.color)
	local spawnTime = component.spawnTime
	local velocity = component.velocity
	local startSize = component.startSize
	local endSize = component.endSize
	local lifeTime = component.lifeTime
	local dieTime = component.dieTime
	local startAlpha = component.startAlpha
	local endAlpha = component.endAlpha
	local selfAttachment = component.selfAttachment

	local ent = self:MakeEntEnsured(class or "sligwolf_particle", ply, parent, "Smoke_" .. name)
	if not IsValid(ent) then return end

	SetPartKeyValues(ent, keyValues)
	SetPartInputFire(ent, inputFires)

	ent:Spawn()
	ent:Activate()

	if not LIBPosition.MountToAttachment(parent, ent, attachment, selfAttachment, callback) then
		self:RemoveFaultyEntities(
			{parent, ent},
			"Couldn't attach entities %s <===> %s. Attachments %s <===> %s. Removing entities.",
			ent,
			parent,
			tostring(selfAttachment or "<origin>"),
			tostring(attachment or "<origin>")
		)

		return
	end

	ent:AttachToEnt(parent, attachment)
	ent:SetParticleSpawnTime(spawnTime)
	ent:SetParticleVelocity(velocity)
	ent:SetColor(color)
	ent:SetParticleStartSize(startSize)
	ent:SetParticleEndSize(endSize)
	ent:SetParticleLifeTime(lifeTime)
	ent:SetParticleDieTime(dieTime)
	ent:SetParticleStartAlpha(startAlpha)
	ent:SetParticleEndAlpha(endAlpha)

	ent.sligwolf_blockedprop = true
	ent:SetNWBool("sligwolf_blockedprop", true)

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleLight(parent, component, ply, superparent, callback)
	if not ProceedVehicleSetUp(parent, component) then return end

	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local class = component.class
	local keyValues = component.keyValues
	local inputFires = component.inputFires
	local fov = component.fov
	local farZ = component.farZ
	local color = GetColor(superparent, component.color)
	local shadowRenderDist = component.shadowRenderDist
	local selfAttachment = component.selfAttachment

	local ent = self:MakeEntEnsured(class or "sligwolf_light_cone", ply, parent, "Light_" .. name)
	if not IsValid(ent) then return end

	SetPartKeyValues(ent, keyValues)
	SetPartInputFire(ent, inputFires)

	ent:Spawn()
	ent:Activate()

	if not LIBPosition.MountToAttachment(parent, ent, attachment, selfAttachment, callback) then
		self:RemoveFaultyEntities(
			{parent, ent},
			"Couldn't attach entities %s <===> %s. Attachments %s <===> %s. Removing entities.",
			ent,
			parent,
			tostring(selfAttachment or "<origin>"),
			tostring(attachment or "<origin>")
		)

		return
	end

	ent:AttachToEnt(parent, attachment)
	ent:SetLightConeFOV(fov)
	ent:SetLightConeFarZ(farZ)
	ent:SetColor(color)
	ent:SetLightConeShadowRenderDist(shadowRenderDist)

	ent.sligwolf_blockedprop = true
	ent:SetNWBool("sligwolf_blockedprop", true)

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleGlow(parent, component, ply, superparent, callback)
	if not ProceedVehicleSetUp(parent, component) then return end

	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local class = component.class
	local keyValues = component.keyValues
	local inputFires = component.inputFires
	local color = GetColor(superparent, component.color)
	local size = component.size
	local enlarge = component.enlarge
	local count = component.count
	local alphaReduce = component.alphaReduce
	local selfAttachment = component.selfAttachment

	local ent = self:MakeEntEnsured(class or "sligwolf_glow", ply, parent, "Glow_" .. name)
	if not IsValid(ent) then return end

	SetPartKeyValues(ent, keyValues)
	SetPartInputFire(ent, inputFires)

	ent:Spawn()
	ent:Activate()

	if not LIBPosition.MountToAttachment(parent, ent, attachment, selfAttachment, callback) then
		self:RemoveFaultyEntities(
			{parent, ent},
			"Couldn't attach entities %s <===> %s. Attachments %s <===> %s. Removing entities.",
			ent,
			parent,
			tostring(selfAttachment or "<origin>"),
			tostring(attachment or "<origin>")
		)

		return
	end

	ent:SetColor(color)
	ent:AttachToEnt(parent, attachment)
	ent:SetGlowSize(size)
	ent:SetGlowEnlarge(enlarge)
	ent:SetGlowCount(count)
	ent:SetGlowAlphaReduce(alphaReduce)
	ent:TurnOn(false)

	ent.sligwolf_blockedprop = true
	ent:SetNWBool("sligwolf_blockedprop", true)

	return ent
end

function SLIGWOLF_ADDON:SetUpVehiclePod(parent, component, ply, superparent, callback)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local boneMerge = component.boneMerge

	local ent = self:MakeEntEnsured("prop_vehicle_prisoner_pod", ply, parent, "Seat_" .. name)
	if not IsValid(ent) then return end

	self:SetPartValues(ent, parent, component, attachment, superparent, callback)
	LIBEntities.SetupDecoratorEntity(ent, parent, component.collision, attachment)

	ent.sligwolf_vehicle = true
	ent.sligwolf_vehiclePod = true

	LIBPhysics.InitializeAsPhysEntity(ent)

	ent.sligwolf_ExitVectors = component.exitVectors

	if boneMerge then
		ent:AddEffects(EF_BONEMERGE)
		ent:AddEffects(EF_BONEMERGE_FASTCULL)
	end

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleAnimatedWheel(parent, component, ply, superparent, callback)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local class = component.class
	local size = component.size
	local restrate = component.restrate
	local boneMerge = component.boneMerge

	local ent = self:MakeEntEnsured(class or "sligwolf_wheel", ply, parent, "Wheel_" .. name)
	if not IsValid(ent) then return end

	self:SetPartValues(ent, parent, component, attachment, superparent, callback)
	ent:SetWheelSize(size)
	ent:SetWheelRestRate(restrate)
	ent:SetWheelMessureEntity(parent)
	ent:AttachToEnt(parent, attachment)

	if boneMerge then
		ent:AddEffects(EF_BONEMERGE)
		ent:AddEffects(EF_BONEMERGE_FASTCULL)
	end

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleDisplay(parent, component, ply, superparent, callback)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local class = component.class
	local scale = component.scale
	local maxDrawDistance = component.maxDrawDistance
	local functionName = component.functionName

	local ent = self:MakeEntEnsured(class or "sligwolf_display", ply, parent, "Display_" .. name)
	if not IsValid(ent) then return end

	self:SetPartValues(ent, parent, component, attachment, superparent, callback)
	ent:SetDisplayOriginName("displaypos")
	ent:AttachToEnt(parent, attachment)
	ent:TurnOn(true)
	ent:SetDisplayScale(scale)
	ent:SetDisplayMaxDrawDistance(maxDrawDistance)
	ent:SetDisplayFunctionName(functionName)

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleBendi(parent, component, ply, superparent, callback)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local parentNameFront = component.parentNameFront
	local parentNameRear = component.parentNameRear
	local parentFront = parent
	local parentRear = parent

	if parentNameFront ~= "" then
		parentFront = LIBEntities.GetChildFromPath(parent, parentNameFront)
	end

	if parentNameRear ~= "" then
		parentRear = LIBEntities.GetChildFromPath(parent, parentNameRear)
	end

	local ent = self:MakeEntEnsured("prop_ragdoll", ply, parent, "Bendi_" .. name)
	if not IsValid(ent) then return end

	self:SetPartValues(ent, parent, component, attachment, superparent, callback)

	LIBEntities.RemoveEntitiesOnDelete(parentFront, {parentRear, ent})
	LIBEntities.RemoveEntitiesOnDelete(parentRear, {parentFront, ent})

	local WD1 = self:CreateConstraint(ent, parentFront, "Weld", {
		bone1 = 1,
		bone2 = 0,
		forcelimit = 0,
		nocollide = true,
	})

	if not IsValid(WD1) then
		LIBEntities.RemoveEntities({ent, parentFront, parentRear})
		return
	end

	parent.sligwolf_constraintWeld1 = WD1

	local WD2 = self:CreateConstraint(ent, parentRear, "Weld", {
		bone1 = 0,
		bone2 = 0,
		forcelimit = 0,
		nocollide = true,
	})

	if not IsValid(WD2) then
		LIBEntities.RemoveEntities({ent, parentFront, parentRear})
		return
	end

	parent.sligwolf_constraintWeld2 = WD2

	LIBPhysics.InitializeAsPhysEntity(ent)

	LIBEntities.EnableMotion(ent, true)

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicle(ent, parent, component, attachment, superparent, callback)
	self:SetPartValues(ent, parent, component, attachment, superparent, callback)

	local enableWheels = component.enableWheels

	ent.sligwolf_vehicle = true

	LIBPhysics.InitializeAsPhysEntity(ent)

	ent.sligwolf_ExitVectors = component.exitVectors

	LIBVehicle.EnableWheels(ent, enableWheels)
end

function SLIGWOLF_ADDON:SetUpVehicleJeep(parent, component, ply, superparent, callback)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name

	local ent = self:MakeEntEnsured("prop_vehicle_jeep", ply, parent, "Jeep_" .. name)
	if not IsValid(ent) then return end

	self:SetUpVehicle(ent, parent, component, attachment, superparent, callback)

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleAirboat(parent, component, ply, superparent, callback)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name

	local ent = self:MakeEntEnsured("prop_vehicle_airboat", ply, parent, "Airboat_" .. name)
	if not IsValid(ent) then return end

	self:SetUpVehicle(ent, parent, component, attachment, superparent, callback)

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleHoverball(parent, component, ply, superparent, callback)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local speed = component.speed
	local airResistance = component.airResistance
	local strength = component.strength
	local numDown = component.numDown
	local numUp = component.numUp
	local numBackDown = component.numBackDown
	local numBackUp = component.numBackUp

	local ent = self:MakeEntEnsured("gmod_hoverball", ply, parent, "Hoverball_" .. name)
	if not IsValid(ent) then return end

	self:SetPartValues(ent, parent, component, attachment, superparent, callback)

	LIBPhysics.InitializeAsPhysEntity(ent)

	ent:SetSpeed(speed)
	ent:SetAirResistance(airResistance)
	ent:SetStrength(strength)
	ent.NumDown = numpad.OnDown(ply, numDown, "Hoverball_Up", ent, true)
	ent.NumUp = numpad.OnUp(ply, numUp, "Hoverball_Up", ent, false)
	ent.NumBackDown = numpad.OnDown(ply, numBackDown, "Hoverball_Down", ent, true)
	ent.NumBackUp = numpad.OnUp(ply, numBackUp, "Hoverball_Down", ent, false)

	return ent
end

return true

