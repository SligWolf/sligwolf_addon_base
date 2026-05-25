local SligWolf_Addons = _G.SligWolf_Addons
if not SligWolf_Addons then
	return
end

local LIB = SligWolf_Addons:NewLib("SourceIO")

local LIBEntityhooks = nil
local LIBDuplicator = nil
local LIBUtil = nil

function LIB.GetKeyValue(ent, key)
	key = string.lower(tostring(key or ""))

	local keyValues = LIB.GetKeyValues(ent)
	return keyValues[key]
end

function LIB.GetKeyValues(ent)
	if CLIENT then
		return {}
	end

	local entTable = ent:SligWolf_GetTable()

	local keyValuesRef = entTable.keyValuesRef or {}
	entTable.keyValuesRef = keyValuesRef

	for key, value in pairs(ent:GetKeyValues() or {}) do
		key = string.lower(key)
		keyValuesRef[key] = tostring(value)
	end

	for key, value in pairs(entTable.keyValues or {}) do
		key = string.lower(key)
		keyValuesRef[key] = tostring(value)
	end

	return keyValuesRef
end

function LIB.SetKeyValue(ent, key, value)
	if CLIENT then
		return
	end

	key = string.lower(tostring(key or ""))
	if key == "" then
		return
	end

	if value == true then
		value = "1"
	elseif value == false then
		value = "0"
	else
		value = tostring(value or "")
	end

	ent:SetKeyValue(key, value)
	LIBEntityhooks.RegisterKeyValue(ent, key, value)
end

function LIB.SetKeyValues(ent, keyValues)
	if CLIENT then
		return
	end

	if not keyValues then
		return
	end

	for key, value in pairs(keyValues) do
		LIB.SetKeyValue(ent, key, value)
	end
end

local g_inputBlacklist = {
	["addoutput"] = true,
	["runpassedcode"] = true,
}

function LIB.IsAllowedMapInput(inputName)
	inputName = string.Trim(string.lower(inputName or ""))
	if inputName == "" then
		return false
	end

	if g_inputBlacklist[inputName] then
		-- Prevent potentially dangerous IO from being executed
		return false
	end

	return true
end

function LIB.IsAllowedMapOutput(outputName)
	outputName = string.Trim(string.lower(outputName or ""))
	if outputName == "" then
		return false
	end

	return true
end

function LIB.ParseMapOutputString(outputName, outputString)
	-- Newer Source Engine games use this symbol as a delimiter
	local rawData = string.Explode("\x1B", outputString)
	if #rawData < 2 then
		rawData = string.Explode(",", outputString)

		if #rawData < 2 then
			return nil
		end
	end

	outputName = string.lower(string.Trim(outputName or ""))
	if not LIB.IsAllowedMapOutput(outputName) then
		return nil
	end

	local inputName = string.lower(string.Trim(rawData[2] or ""))
	if not LIB.IsAllowedMapInput(inputName) then
		return nil
	end

	local result = {}
	result.targetName = rawData[1] or ""
	result.inputName = inputName
	result.param = rawData[3] or ""
	result.delay = tonumber(rawData[4] or 0) or 0
	result.times = tonumber(rawData[5] or -1) or -1
	result.outputName = outputName

	return result
end

function LIB.IsMapOutputString(ioString)
	if string.find(ioString, "\x1B", 0, true) then
		return true
	end

	if string.find(ioString, ",", 0, true) then
		return true
	end

	return false
end

function LIB.GetMapOutputs(ent, filterFunc)
	if CLIENT then
		return {}
	end

	local entTable = ent:SligWolf_GetTable()

	local ioList = entTable.mapOutputs or {}
	local ioListResult = {}

	for _, outputs in pairs(ioList) do
		for _, output in ipairs(outputs) do
			local outputName = string.lower(string.Trim(output.outputName or ""))
			if not LIB.IsAllowedMapOutput(outputName) then
				continue
			end

			local inputName = string.lower(string.Trim(output.inputName or ""))
			if not LIB.IsAllowedMapInput(inputName) then
				continue
			end

			output = table.Copy(output)
			output.inputName = inputName

			if isfunction(filterFunc) and filterFunc(output) == false then
				continue
			end

			local ioListResultOutputs = ioListResult[outputName] or {}
			ioListResult[outputName] = ioListResultOutputs

			table.insert(ioListResultOutputs, output)
		end
	end

	return ioListResult
end

function LIB.SetMapOutput(ent, output)
	if CLIENT then
		return false
	end

	local outputName = string.lower(string.Trim(output.outputName or ""))
	if not LIB.IsAllowedMapOutput(outputName) then
		return false
	end

	local inputName = string.lower(string.Trim(output.inputName or ""))
	if not LIB.IsAllowedMapInput(inputName) then
		return false
	end

	local outputCopy = {}

	outputCopy.targetName = tostring(output.targetName or "")
	outputCopy.inputName = inputName
	outputCopy.param = tostring(output.param or "")
	outputCopy.delay = tonumber(output.delay or 0) or 0
	outputCopy.times = tonumber(output.times or -1) or -1
	outputCopy.outputName = outputName

	local outputParams = {
		outputCopy.targetName,
		outputCopy.inputName,
		outputCopy.param,
		outputCopy.delay,
		outputCopy.times
	}

	outputParams = table.concat(outputParams, "\x1B")

	ent:SetKeyValue(outputName, outputParams)
	LIBEntityhooks.RegisterOutput(ent, outputName, outputCopy)

	return true
end

function LIB.SetMapOutputs(ent, ioList)
	if CLIENT then
		return
	end

	if not ioList then
		return
	end

	for _, outputs in pairs(ioList) do
		for _, output in ipairs(outputs) do
			LIB.SetMapOutput(ent, output)
		end
	end
end

function LIB.GetHammerId(ent)
	if not IsValid(ent) then
		return nil
	end

	local hammerid = tonumber(LIB.GetKeyValue(ent, "hammerid") or 0) or 0
	if hammerid ~= 0 then
		return hammerid
	end

	return nil
end

function LIB.GetMapCreationID(ent)
	if not IsValid(ent) then
		return nil
	end

	if not ent:CreatedByMap() then
		return nil
	end

	return ent:MapCreationID()
end

local g_hashTmp = {}

function LIB.GetMapCreationHash(ent)
	if CLIENT then
		return nil
	end

	local id = LIB.GetMapCreationID(ent)
	if not id then
		return nil
	end

	table.Empty(g_hashTmp)

	table.insert(g_hashTmp, game.GetMap())
	table.insert(g_hashTmp, ent:GetClass())
	table.insert(g_hashTmp, ent:GetName())

	table.insert(g_hashTmp, id)

	local hash = table.concat(g_hashTmp, "_")
	hash = util.SHA1(hash)

	return hash
end

function LIB.IsCreatedByMap(ent, alsoCheckHammerId)
	if not IsValid(ent) then
		return false
	end

	if ent:CreatedByMap() then
		return true
	end

	if not alsoCheckHammerId then
		return false
	end

	local hammerid = LIB.GetHammerId(ent)
	if hammerid then
		return true
	end

	return false
end

function LIB.IsSpawnedByEngine(ent)
	if not IsValid(ent) then return false end

	local entTable = ent:SligWolf_GetTable()
	if entTable.isSpawnedByEngine ~= nil then
		return entTable.isSpawnedByEngine
	end

	entTable.isSpawnedByEngine = true

	if LIB.IsCreatedByMap(ent, true) then
		return true
	end

	if ent:IsVehicle() then
		local vehicleSpawnname = tostring(ent.VehicleName or "")
		if vehicleSpawnname == "" then
			return true
		end
	end

	entTable.isSpawnedByEngine = false
	return false
end

function LIB.GetProxySpawnID(ent)
	if not IsValid(ent) then
		return nil
	end

	local entTable = ent:SligWolf_GetTable()
	local proxySpawnId = entTable.proxySpawnId

	if not proxySpawnId then
		return nil
	end

	return proxySpawnId
end

function LIB.SetProxySpawnID(ent, proxySpawnId)
	if not IsValid(ent) then
		return
	end

	if not proxySpawnId then
		return
	end

	local entTable = ent:SligWolf_GetTable()
	entTable.proxySpawnId = proxySpawnId

	LIBDuplicator.StoreEntityProxyModifier(ent, proxySpawnId)
end

function LIB.GetProxyEntitiesRegister()
	if not LIB.g_proxyEntities then
		LIB.g_proxyEntities = LIBUtil.CreateEntityLookup("ProxyEntitiesRegister", function(thisent)
			return LIB.GetProxySpawnID(thisent)
		end)
	end

	return LIB.g_proxyEntities
end

function LIB.Load()
	LIBEntityhooks = SligWolf_Addons.Entityhooks
	LIBDuplicator = SligWolf_Addons.Duplicator
	LIBUtil = SligWolf_Addons.Util
end

return true

