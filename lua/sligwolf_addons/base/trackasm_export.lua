AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SLIGWOLF_ADDON then
	return
end

local LIBTrackasm = SligWolf_Addons.Trackasm

local taSettings = SLIGWOLF_ADDON.TrackAssamblerSettings
if not taSettings then
	error("SLIGWOLF_ADDON.TrackAssamblerSettings missing")
	return
end

local asmlib = LIBTrackasm.GetLib()
if not asmlib then
	error("TrackAssemblyTool was not loaded!")
	return
end

local myAddon = taSettings.Addon
local myError = taSettings.Error
local myPrefix = myAddon:gsub("[^%w]", "_")

local myScript = tostring(debug.getinfo(1).source or "N/A")
myScript = "@" .. myScript:gsub("^%W+", ""):gsub("\\", "/")

local function myThrowError(vMesg)
	local sMesg = (myScript .. " > (" .. myAddon .. "): " .. tostring(vMesg))

	asmlib.LogInstance(sMesg)

	myError(sMesg)
end

local function mySyncTable(sName, tData, bRepl)
	if not asmlib.IsEmpty(tData) then
		asmlib.LogInstance("SynchronizeDSV START <" .. myPrefix .. ">")

		if not asmlib.SynchronizeDSV(sName, tData, bRepl, myPrefix) then
			myThrowError("Failed to synchronize: " .. sName)
		else
			asmlib.LogInstance("TranslateDSV START <" .. myPrefix .. ">")

			if not asmlib.TranslateDSV(sName, myPrefix) then
				myThrowError("Failed to translate DSV: " .. sName)
			end

			asmlib.LogInstance("TranslateDSV OK <" .. myPrefix .. ">")
		end
	else
		asmlib.LogInstance("SynchronizeDSV EMPTY <" .. myPrefix .. ">")
	end
end

local function myRegisterDSV(bSkip)
	asmlib.LogInstance("RegisterDSV START <" .. myPrefix .. ">")

	if bSkip then
		asmlib.LogInstance("RegisterDSV SKIP <" .. myPrefix .. ">")
	else
		if not asmlib.RegisterDSV(myScript, myPrefix) then
			myThrowError("Failed to register DSV")
		end

		asmlib.LogInstance("RegisterDSV OK <" .. myPrefix .. ">")
	end
end

local function myExportCategory(tCatg)
	asmlib.LogInstance("ExportCategory START <" .. myPrefix .. ">")

	if CLIENT then
		if not asmlib.IsEmpty(tCatg) then
			if not asmlib.ExportCategory(3, tCatg, myPrefix) then
				myThrowError("Failed to synchronize category")
			end

			asmlib.LogInstance("ExportCategory OK <" .. myPrefix .. ">")
		else
			asmlib.LogInstance("ExportCategory SKIP <" .. myPrefix .. ">")
		end
	else
		asmlib.LogInstance("ExportCategory SERVER <" .. myPrefix .. ">")
	end
end

local gsToolPF = asmlib.GetOpVar("TOOLNAME_PU")
local gsFormPF = asmlib.GetOpVar("FORM_PREFIXDSV")

local myDsv = asmlib.GetOpVar("DIRPATH_BAS") .. asmlib.GetOpVar("DIRPATH_DSV") .. gsFormPF:format(myPrefix, gsToolPF .. "PIECES")
local myFlag = file.Exists(myDsv, "DATA")

asmlib.LogInstance(">>> " .. myScript .. " (" .. tostring(myFlag) .. "): {" .. myAddon .. ", " .. myPrefix .. "}")

local myAddonWsId = taSettings.WorkshopID
if myAddonWsId then
	asmlib.WorkshopID(myAddon, myAddonWsId)
end

myRegisterDSV(myFlag)

local myCategory = SLIGWOLF_ADDON:TrackAssamblerExportCategories()
if myCategory then
	myExportCategory(myCategory)
end

local myPieces = SLIGWOLF_ADDON:TrackAssamblerExportPieces()
if myPieces then
	mySyncTable("PIECES", myPieces, true)
end

asmlib.LogInstance("<<< " .. myScript)

return true

