AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Debug = SligWolf_Addons.Debug or {}
table.Empty(SligWolf_Addons.Debug)

local LIB = SligWolf_Addons.Debug

local LIBConvar = nil
local LIBPrint = nil
local LIBUtil = nil
local LIBFile = nil

function LIB.Load()
	LIBConvar = SligWolf_Addons.Convar
	LIBPrint = SligWolf_Addons.Print
	LIBUtil = SligWolf_Addons.Util
	LIBFile = SligWolf_Addons.File
end

function LIB.IsDeveloper()
	if not LIBConvar then
		return false
	end

	return LIBConvar.IsDebug()
end

function LIB.Debug(...)
	if not LIBPrint then
		return
	end

	LIBPrint.Debug(...)
end

LIB.Print = LIB.Debug

local Color_trGreen = Color(50, 255, 50)
local Color_trBlue = Color(50, 50, 255)
local Color_trTextHit = Color(100, 255, 100)

local Color_trText = Color(137, 222, 255)
local Color_trCross = Color(167, 222, 255)

local LineOffset_trText = -3

if CLIENT then
	Color_trText = Color(255, 222, 102)
	Color_trCross = Color(255, 222, 132)
	LineOffset_trText = 0
end

local function debugText(pos, lineoffset, textTop, textBottom, lifetime, color)
	if text ~= "" then
		debugoverlay.EntityTextAtPosition(pos, lineoffset, textTop, lifetime, color)
		debugoverlay.EntityTextAtPosition(pos, lineoffset + 1, textBottom, lifetime, color)
	else
		debugoverlay.EntityTextAtPosition(pos, lineoffset, textBottom, lifetime, color)
	end
end

function LIB.ShowTrace(trace, traceResult, text, lifetime)
	if not LIB.IsDeveloper() then
		return
	end

	if not trace then
		return
	end

	if not traceResult then
		return
	end

	text = tostring(text or "")
	lifetime = lifetime or 1

	local trStart = traceResult.StartPos
	local trEnd = trace.endpos
	local trHitPos = traceResult.HitPos
	local trHit = traceResult.Hit
	local trHitNormal = traceResult.HitNormal
	local trHitNormalEnd = trHitPos + trHitNormal * 8

	debugText(trStart, LineOffset_trText, text, "Start", lifetime, Color_trText)

	debugoverlay.Cross(trStart, 1, lifetime, Color_trGreen, true)
	debugoverlay.Line(trStart, trHitPos, lifetime, Color_trGreen, true)
	debugoverlay.Line(trHitPos, trEnd, lifetime, Color_trBlue, true)
	debugoverlay.Cross(trEnd, 1, lifetime, Color_trBlue, true)

	if trHit then
		debugoverlay.Cross(trHitPos, 1, lifetime, Color_trCross, true)
		debugoverlay.Line(trHitPos, trHitNormalEnd, lifetime, Color_trCross, true)
		debugText(trHitPos, LineOffset_trText, text, "Hit", lifetime, Color_trTextHit)

	else
		debugText(trEnd, LineOffset_trText, text, "End", lifetime, Color_trText)
	end
end

function LIB.ShowHullTrace(traceHull, traceHullResult, text, lifetime)
	if not LIB.IsDeveloper() then
		return
	end

	if not traceHull then
		return
	end

	if not traceHullResult then
		return
	end

	text = tostring(text or "")
	lifetime = lifetime or 1

	local trStart = traceHullResult.StartPos
	local trEnd = traceHull.endpos
	local trHitPos = traceHullResult.HitPos
	local trHit = traceHullResult.Hit
	local trHitNormal = traceHullResult.HitNormal
	local trHitNormalEnd = trHitPos + trHitNormal * 8

	local trMins = traceHull.mins
	local trMaxs = traceHull.maxs

	local trMinsHit = trMins + Vector(1, 1, 0)
	local trMaxsHit = trMaxs - Vector(1, 1, 1)

	debugText(trStart, LineOffset_trText, text, "Start", lifetime, Color_trText)

	debugoverlay.Cross(trStart, 1, lifetime, Color_trGreen, true)
	debugoverlay.SweptBox(trStart, trHitPos, trMins, trMaxs, Angle(), lifetime, Color_trGreen)
	debugoverlay.Line(trHitPos, trEnd, lifetime, Color_trBlue, true)
	debugoverlay.Cross(trEnd, 1, lifetime, Color_trBlue, true)

	if trHit then
		debugoverlay.Cross(trHitPos, 1, lifetime, Color_trCross, true)
		debugoverlay.Line(trHitPos, trHitNormalEnd, lifetime, Color_trCross, true)
		debugoverlay.SweptBox(trHitPos, trHitPos, trMinsHit, trMaxsHit, Angle(), lifetime, Color_trCross)

		debugText(trHitPos, LineOffset_trText, text, "Hit", lifetime, Color_trTextHit)
	else
		debugText(trEnd, LineOffset_trText, text, "End", lifetime, Color_trText)
	end
end

local g_lastHue = 0

function LIB.GetRandomDistinguishableColor()
	if not LIB.IsDeveloper() then
		return nil
	end

	local hue = 0
	local stepSize = 15

	while true do
		hue = math.Round(math.Rand(0, 360) / stepSize) * stepSize

		local delta = math.abs(hue - g_lastHue)
		delta = math.min(delta, 360 - delta)

		if delta < stepSize * 4 then
			continue
		end

		break
	end

	g_lastHue = hue

	local color = HSLToColor(hue, 1, 0.75)
	color = Color(color.r, color.g, color.b)

	return color
end

function LIB.HighlightEntities(entities, color)
	if not LIB.IsDeveloper() then
		return
	end

	if not color then
		color = LIB.GetRandomDistinguishableColor()
	end

	if not istable(entities) then
		entities = {entities}
	end

	local uniqueEntities = {}

	for entK, entV in pairs(entities) do
		if isentity(entV) and IsValid(entV) then
			uniqueEntities[entV] = entV
		end

		if entK ~= entV and isentity(entK) and IsValid(entK) then
			uniqueEntities[entK] = entK
		end
	end

	local count = 0
	local lastEnt = nil

	for _, ent in pairs(uniqueEntities) do
		ent:SetMaterial("models/debug/debugwhite")
		ent:SetColor(color)

		count = count + 1
		lastEnt = ent
	end

	if count <= 0 then
		LIB.Print("Debug.HighlightEntities: No Entities to highlight")
	elseif count == 1 then
		LIB.Print("Debug.HighlightEntities: Highlighting 1 Entity:\n  %s", lastEnt)
	else
		LIB.Print("Debug.HighlightEntities: Highlighting %i Entities", count)
	end
end

local g_fgdFile = [[
//=============================================================================
//===================== Game data for SW Base Vehicles ========================
//============================= Made by SligWolf ==============================

// Please also include garrysmod.fgd or halflife2.fgd in Hammer for optimal results.
// It is not recommended to edit this file as it is automaticly generated.

// Generated file:
//   Base Version:  {{SW_VERSION}}
//   Generated At:  {{SW_GENERATED_AT}}
//   Addons Count:  {{SW_ADDON_COUNT}}
//   Vehicle Count: {{SW_VEHICLE_COUNT}}

@PointClass base(BaseDriveableVehicle, Parentname) studioprop() = prop_vehicle_prisoner_pod :
	"Combine prisoner pod that the player can ride in."
[
	model(studio) : "World model" : "models/vehicles/prisoner_pod.mdl"
	vehiclescript(string) : "Vehicle Script File" : "scripts/vehicles/prisoner_pod.txt"
	
	input Open(void) : "Plays the pod's open animation and unlocks the pod for entry or exit."
	input Close(void) : "Plays the pod's close animation and locks the pod for entry or exit."
	input EnterVehicle(void) : "Forces the activator (or player) into the pod."
	input EnterVehicleImmediate(void) : "Forces the activator (or player) into the pod without enter/exit animations."
	input ExitVehicle(void) : "Boots the prisoner out of the pod."
	
	output OnOpen(void) : "Fired when the pod is open enough to enter."
	output OnClose(void) : "Fired when the pod too closed to enter."
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
	sligwolf_spawnname(choices) : "[SW-ADDONS] Vehicle spawnname" : "" : "\nSligWolf's Addon vehicle spawnname: \n" +
		"If not set, the game will spawn the standard variant of the vehicle found by its model. " +
		"Enter the desired spawnname of the SW-ADDON vehicle that you would like to spawn. " +
		"Be sure the model, vehicle class and vehicle script matches the choosen spawnname! " +
		"In case of any mismatches issues, the game will tell what's wrong via an error." =
	[
{{SW_SPAWNNAME_PROP_VEHICLE_PRISONER_POD_OPTIONS}}
	]
]

@PointClass base(BaseDriveableVehicle) studioprop() = prop_vehicle_airboat :
	"Driveable studiomodel airboat."
[
	model(studio) : "World model" : "models/airboat.mdl"
	vehiclescript(string) : "Vehicle Script File" : "scripts/vehicles/airboat.txt"
	EnableGun(choices) : "Has Gun" : 0 : "Whether the airboat's gun is enabled or disabled." =
	[
		0 : "No"
		1 : "Yes"
	]
	input EnableGun(bool) : "Enables or disables the airboat gun and associated crosshair."
	input InputStartRotorWashForces(void) : "The airboat will start to be blown around by the helicopter rotor wash."
	input InputStopRotorWashForces(void) : "The airboat will no longer be blown around by the helicopter rotor wash."

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
	sligwolf_spawnname(choices) : "[SW-ADDONS] Vehicle spawnname" : "" : "\nSligWolf's Addon vehicle spawnname: \n" +
		"If not set, the game will spawn the standard variant of the vehicle found by its model. " +
		"Enter the desired spawnname of the SW-ADDON vehicle that you would like to spawn. " +
		"Be sure the model, vehicle class and vehicle script matches the choosen spawnname! " +
		"In case of any mismatches issues, the game will tell what's wrong via an error." =
	[
{{SW_SPAWNNAME_PROP_VEHICLE_AIRBOAT_OPTIONS}}
	]
]

@PointClass base(BaseDriveableVehicle) studioprop() = prop_vehicle_jeep :
	"Driveable studiomodel jeep."
[
	input StartRemoveTauCannon(void) : "Start the tau removal sequence."
	input FinishRemoveTauCannon(void) : "Finish the tau removal sequence."
	
	// FIXME: These will move into episodic
	input LockEntrance( void ) : "Stops NPC's from entering the vehicle until unlocked."
	input UnlockEntrance( void ) : "Allows NPC's to enter the vehicle."
	input LockExit( void ) : "Stops NPC's from exiting the vehicle until unlocked."
	input UnlockExit( void ) : "Allows NPC's to exit the vehicle."
	input EnableRadar( void ) : "Turn on the Jalopy radar"
	input DisableRadar( void ) : "Turn off the Jalopy radar"
	input EnableRadarDetectEnemies( void ) : "Enable Jalopy radar to detect Striders and Hunters"
	input AddBusterToCargo( void ) : "Put a striderbuster in the cargo trigger"
	input SetCargoHopperVisibility ( bool ) : "Set the strider buster hopper thingy to be visible, or invisible."

	input DisablePhysGun(void) : "Disable Gravity Gun interactions with the jeep."
	input EnablePhysGun(void) : "Enable Gravity Gun interactions with the jeep (default)."

	input CreateLinkController(void) : "Automatically builds and attaches a link controller to the car, which cuts the node connections under the car while the car is standing still."
	input DestroyLinkController(void) : "Destroys the link controller created by CreateLinkController."

	
	CargoVisible(choices): "Hopper Visible" : 0 : "Is the striderbuster cargo hopper visible?" =
	[
		0 : "No"
		1 : "Yes"
	]

	spawnflags(Flags) = 
	[
		1 : "HUD Locator Precache" : 0
	]

	
	// FIXME: These are going to change!
	output OnCompanionEnteredVehicle(void) : "Companion has entered the vehicle."
	output OnCompanionExitedVehicle(void) : "Companion has exited the vehicle."
	output OnHostileEnteredVehicle(void) : "Hostile has entered the vehicle."
	output OnHostileExitedVehicle(void) : "Hostile has exited the vehicle."
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
	sligwolf_spawnname(choices) : "[SW-ADDONS] Vehicle spawnname" : "" : "\nSligWolf's Addon vehicle spawnname: \n" +
		"If not set, the game will spawn the standard variant of the vehicle found by its model. " +
		"Enter the desired spawnname of the SW-ADDON vehicle that you would like to spawn. " +
		"Be sure the model, vehicle class and vehicle script matches the choosen spawnname! " +
		"In case of any mismatches issues, the game will tell what's wrong via an error." =
	[
{{SW_SPAWNNAME_PROP_VEHICLE_JEEP_OPTIONS}}
	]
]
]]

local function getVehicleTablesByClass()
	local result = {}

	local vehicleTables = LIBUtil.GetList("Vehicles")

	local count = 0

	for spawnname, vehicleTable in pairs(vehicleTables) do
		if not istable(vehicleTable) then
			continue
		end

		if not vehicleTable.Is_SLIGWOLF then
			continue
		end

		if vehicleTable.SLIGWOLF_Hidden then
			continue
		end

		local class = tostring(vehicleTable.Class or "")
		if class == "" then
			continue
		end

		result[class] = result[class] or {}
		local items = result[class]

		table.insert(items, {
			spawnname = spawnname,
			title = vehicleTable.Name,
			addontitle = SligWolf_Addons.GetAddonTitle(vehicleTable.SLIGWOLF_Addonname) or vehicleTable.SLIGWOLF_Addonname,
		})

		count = count + 1
	end

	return result, count
end

local function spawnnameOptionsListSorter(a, b)
	if a.addontitle ~= b.addontitle then
		return a.addontitle < b.addontitle
	end

	if a.title ~= b.title then
		return a.title < b.title
	end

	return a.spawnname < b.spawnname
end

local function getSpawnnameOptionsList(options)
	options = options or {}

	local lines = {}
	table.insert(lines, [[\t\t"" : "Nothing (No SW-ADDON Vehicle)"]])

	table.sort(options, spawnnameOptionsListSorter)

	for _, item in ipairs(options) do
		local title = item.title
		local addontitle = item.addontitle
		local spawnname = item.spawnname

		local line = string.format(
			[[\t\t"%s" : "%s | %s (%s)"]],
			spawnname,
			addontitle,
			title,
			spawnname
		)

		table.insert(lines, line)
	end

	lines = table.concat(lines, "\n")
	return lines
end

function LIB.GenerateFGD()
	local fgd = g_fgdFile

	local vehicleTables, vehicleTablesCount = getVehicleTablesByClass()

	fgd = string.Replace(fgd, "{{SW_VERSION}}", SligWolf_Addons.BaseVersion)
	fgd = string.Replace(fgd, "{{SW_GENERATED_AT}}", os.date("%Y-%m-%d %H:%M:%S"))
	fgd = string.Replace(fgd, "{{SW_ADDON_COUNT}}", SligWolf_Addons.GetLoadedAddonsCount())
	fgd = string.Replace(fgd, "{{SW_VEHICLE_COUNT}}", vehicleTablesCount)

	fgd = string.Replace(
		fgd,
		"{{SW_SPAWNNAME_PROP_VEHICLE_PRISONER_POD_OPTIONS}}",
		getSpawnnameOptionsList(vehicleTables["prop_vehicle_prisoner_pod"])
	)

	fgd = string.Replace(
		fgd,
		"{{SW_SPAWNNAME_PROP_VEHICLE_AIRBOAT_OPTIONS}}",
		getSpawnnameOptionsList(vehicleTables["prop_vehicle_airboat"])
	)

	fgd = string.Replace(
		fgd,
		"{{SW_SPAWNNAME_PROP_VEHICLE_JEEP_OPTIONS}}",
		getSpawnnameOptionsList(vehicleTables["prop_vehicle_jeep"])
	)

	fgd = LIBUtil.NormalizeNewlines(fgd, "\n\r")
	fgd = string.Replace(fgd, "\\t", "\t")

	local fileName = "debug/sligwolf_base.fgd.txt"

	local success = LIBFile.Write(fileName, fgd)
	local path = LIBFile.GetAbsolutePath(fileName)

	if success then
		LIBPrint.Print("Debug.GenerateFGD: Written to 'data/%s'. Ready for copy and paste.", path)
	else
		LIBPrint.Print("Debug.GenerateFGD: Could not Write to 'data/%s'", path)
	end
end

if SERVER then
	concommand.Add("sv_sligwolf_debug_generate_fgd", function(ply)
		if not LIBUtil.IsAdminForCMD(ply) then
			return
		end

		LIB.GenerateFGD()
	end)
end

return true

