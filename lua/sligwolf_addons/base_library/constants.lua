AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Constants = SligWolf_Addons.Constants or {}
table.Empty(SligWolf_Addons.Constants)

local CONSTANTS = SligWolf_Addons.Constants

-- bools
CONSTANTS.DEBUG_ERROR = false

-- vectors
CONSTANTS.vecZero = Vector()
CONSTANTS.vecBogie = Vector(0, 0, 1)

-- angles
CONSTANTS.angZero = Angle()

-- colors
CONSTANTS.colorDefault = Color(255, 255, 255, 255)
CONSTANTS.colorError1 = Color(255, 0, 0, 255)
CONSTANTS.colorError2 = Color(255, 0, 255, 255)
CONSTANTS.colorFrontLight = Color(255, 255, 255, 200)
CONSTANTS.colorRearLight = Color(255, 0, 0, 200)
CONSTANTS.colorIndicatorLight = Color(255, 95, 0, 200)
CONSTANTS.colorIndicatorLightInside = Color(0, 155, 0, 200)
CONSTANTS.colorExhaustSmoke = Color(100, 100, 100, 255)

-- sounds
CONSTANTS.sndNull = Sound("SLIGWOLF.base.null")

CONSTANTS.sndVehicleDenyAction = Sound("Buttons.snd40")
CONSTANTS.sndVehicleDenyAction2 = Sound("Buttons.snd10")
CONSTANTS.sndBreakItem = Sound("Cardboard.Break")

CONSTANTS.sndVehicleFreeze = Sound("AmmoCrate.Close")
CONSTANTS.sndVehicleUnfreeze = Sound("AmmoCrate.Open")
CONSTANTS.sndIndicatorOn = Sound("SLIGWOLF.base.indicator.on")
CONSTANTS.sndIndicatorOff = Sound("SLIGWOLF.base.indicator.off")
CONSTANTS.sndSwitchClick = Sound("SLIGWOLF.base.generic.switchclick")
CONSTANTS.sndClick = Sound("SLIGWOLF.base.generic.click")
CONSTANTS.sndCarHorn = Sound("SLIGWOLF.base.generic.carhorn")
CONSTANTS.sndCarHorn2 = Sound("SLIGWOLF.base.generic.carhorn2")
CONSTANTS.sndBikeHorn = Sound("SLIGWOLF.base.generic.bikehorn")

CONSTANTS.sndDoor = Sound("SLIGWOLF.base.generic.door")
CONSTANTS.sndMetaldoorOpen = Sound("SLIGWOLF.base.generic.metaldoor.open")
CONSTANTS.sndMetaldoorClose = Sound("SLIGWOLF.base.generic.metaldoor.close")

CONSTANTS.sndTrainHorn = Sound("razortrain_horn")
CONSTANTS.sndWagonDrive = Sound("SLIGWOLF.base.wagon.drive")
CONSTANTS.sndCoupling = Sound("EpicMetal.ImpactHard")

CONSTANTS.sndPickupHealth = Sound("HealthVial.Touch")
CONSTANTS.sndPickupAmmo = Sound("BaseCombatCharacter.AmmoPickup")
CONSTANTS.sndReloadExplosives = Sound("Weapon_Mortar.Single")

CONSTANTS.sndCrowbarHitWorld = Sound("Weapon_Crowbar.Melee_HitWorld")
CONSTANTS.sndCrowbarHit = Sound("Weapon_Crowbar.Melee_Hit")
CONSTANTS.sndCrowbarMiss = Sound("Weapon_Crowbar.Single")
CONSTANTS.sndPistolEmpty = Sound("Weapon_Pistol.Empty")
CONSTANTS.sndSMGFire = Sound("Weapon_SMG1.Single")
CONSTANTS.sndSMGAltFire = Sound("Weapon_SMG1.Double")
CONSTANTS.sndSMGFiremode = Sound("Weapon_SMG1.Special1")
CONSTANTS.sndSMGIronsight = Sound("Weapon_SMG1.Special2")
CONSTANTS.sndShotgunFire = Sound("Weapon_Shotgun.Single")
CONSTANTS.sndShotgunAltFire = Sound("Weapon_Shotgun.Double")
CONSTANTS.sndShotgunEmpty = Sound("Weapon_Shotgun.Empty")
CONSTANTS.sndAR2Fire = Sound("Weapon_AR2.Single")
CONSTANTS.sndAR2AltFire = Sound("Weapon_IRifle.Single")
CONSTANTS.sndAR2Empty = Sound("Weapon_IRifle.Empty")
CONSTANTS.sndAR2ChargeUpComBall = Sound("Weapon_CombineGuard.Special1")
CONSTANTS.sndCrossbowFire = Sound("Weapon_Crossbow.Single")
CONSTANTS.sndCrossbowBoltFly = Sound("Weapon_Crossbow.BoltFly")
CONSTANTS.sndRPGFire = Sound("Weapon_RPG.Single")
CONSTANTS.sndRPGLaserOff = Sound("Weapon_RPG.LaserOff")
CONSTANTS.sndWeaponDenyAction = Sound("SLIGWOLF.base.weapon.denyaction")

CONSTANTS.sndCraneEngineStart = Sound("SLIGWOLF.base.crane.engineStart")
CONSTANTS.sndCraneExtendStart = Sound("SLIGWOLF.base.crane.moveArm")
CONSTANTS.sndCraneFirstgear = Sound("SLIGWOLF.base.crane.turn")
CONSTANTS.sndMagnetToggle = Sound("Crane_magnet_toggle")
CONSTANTS.sndMagnetRelease = Sound("Crane_magnet_release")

CONSTANTS.sndATVskidLow = Sound("ATV_skid_lowfriction")

-- models
CONSTANTS.mdlGmodError = Model("models/error.mdl")
CONSTANTS.mdlError = Model("models/sligwolf/base/error.mdl")
CONSTANTS.mdlCube1 = Model("models/sligwolf/base/unique/sw_cube_1x1x1.mdl")
CONSTANTS.mdlSphere4 = Model("models/sligwolf/base/unique/sw_sphere_4x4x4.mdl")
CONSTANTS.mdlCube4 = Model("models/sligwolf/base/unique/sw_cube_4x4x4.mdl")
CONSTANTS.mdlSeat = Model("models/sligwolf/base/unique/seat.mdl")
CONSTANTS.mdlDynamicSeat = Model("models/sligwolf/base/unique/seat.mdl")
CONSTANTS.mdlConnectorButton = Model("models/sligwolf/base/unique/sw_cube_16x40x18.mdl")
CONSTANTS.mdlSlider = Model("models/sligwolf/base/slider/sw_slider.mdl")
CONSTANTS.mdlControlpanel = Model("models/sligwolf/base/unique/button_controlfield.mdl")

-- numbers
CONSTANTS.skinError = 0
CONSTANTS.numAutoBrake = 150
CONSTANTS.numAcceleration = 75
CONSTANTS.numEmergencyBrake = 250
CONSTANTS.numConMass = 5000
CONSTANTS.numConRadius = 17
CONSTANTS.numBlinkInterval1 = 0.4
CONSTANTS.numBlinkInterval2 = 0.8

-- materials
CONSTANTS.errorPngMaterial = "materials/vgui/sligwolf/base/error.png"

-- special
CONSTANTS.toolRubatsEasyInspector = "rb655_easy_inspector"

return true

