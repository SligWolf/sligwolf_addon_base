AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SLIGWOLF_ADDON then
	SligWolf_Addons.AutoLoadAddon(function() end)
	return
end

local CONSTANTS = SligWolf_Addons.Constants

local LIBEntities = SligWolf_Addons.Entities
local LIBCoupling = SligWolf_Addons.Coupling

local function lightsUpdateGlowsSingle(trailer, lightState, indicatorState)
	local trailerTable = trailer:SligWolf_GetTable()

	local vehicleLights = trailerTable.vehicleLights
	if not vehicleLights then return end

	local lights = vehicleLights.lights
	local indicators = vehicleLights.indicators

	if lights then
		for i, filter in ipairs(lights) do
			LIBEntities.ForEachFilteredChild(trailer, filter, function(f_ent, index, k, v)
				if not lightState then
					v:TurnOn(false)
					return
				end

				local connector = v.sligwolf_linkedConnector

				if not IsValid(connector) then
					v:TurnOn(true)
					return
				end

				if not connector.sligwolf_isConnector then
					v:TurnOn(true)
					return
				end

				if not connector:IsConnected() then
					v:TurnOn(true)
					return
				end

				v:TurnOn(false)
			end)
		end
	end

	if not indicatorState and indicators then
		for side, indicatorsPerSide in pairs(indicators) do
			for i, filter in ipairs(indicatorsPerSide) do
				LIBEntities.ForEachFilteredChild(trailer, filter, function(f_ent, index, k, v)
					v:TurnOn(false)
				end)
			end
		end
	end
end

function SLIGWOLF_ADDON:LightsUpdateGlows(trailer)
	if not IsValid(trailer) then return end

	local trailerMain = LIBCoupling.GetTrailerMainVehicle(trailer)
	if IsValid(trailerMain) then
		LIBCoupling.ForEachTrailerVehicles(trailerMain, function(k, v)
			if trailerMain == v then
				return
			end

			local trailerData = LIBCoupling.GetTrailerData(v)
			if not trailerData.isTrailerMain then
				return
			end

			LIBCoupling.CloneTrailerData(trailerMain, v)
		end)
	end

	local trailerData = LIBCoupling.GetTrailerData(trailer)

	local lightState = tobool(trailerData.lightState or false)
	local indicatorState = tobool(trailerData.indicatorState or false)

	LIBCoupling.ForEachTrailerVehicles(trailer, function(k, v)
		lightsUpdateGlowsSingle(v, lightState, indicatorState)
	end)
end

local function lightsUpdateIndicatorsSingle(trailer, indicatorFlashState, indicatorR, indicatorL)
	local trailerTable = trailer:SligWolf_GetTable()

	local vehicleLights = trailerTable.vehicleLights
	if not vehicleLights then return end

	local indicators = vehicleLights.indicators
	if not indicators then return end

	local indicatorsR = indicators.R
	local indicatorsL = indicators.L

	if indicatorsR then
		for i, filter in ipairs(indicatorsR) do
			LIBEntities.ForEachFilteredChild(trailer, filter, function(f_ent, index, k, v)
				v:TurnOn(indicatorR and indicatorFlashState)
			end)
		end
	end

	if indicatorsL then
		for i, filter in ipairs(indicatorsL) do
			LIBEntities.ForEachFilteredChild(trailer, filter, function(f_ent, index, k, v)
				v:TurnOn(indicatorL and indicatorFlashState)
			end)
		end
	end
end

function SLIGWOLF_ADDON:LightsUpdateIndicators(trailerMain)
	if not IsValid(trailerMain) then return end

	local trailerMainData = LIBCoupling.GetTrailerData(trailerMain)

	local indicatorState = tobool(trailerMainData.indicatorState or false)
	if not indicatorState then
		trailerMainData.indicatorDelay = nil
		trailerMainData.indicatorFlashState = false
		return
	end

	local delay = trailerMainData.indicatorDelay
	local now = CurTime()

	if delay and delay > now then
		return
	end

	trailerMainData.indicatorDelay = now + CONSTANTS.numBlinkInterval1

	local indicatorFlashState = trailerMainData.indicatorFlashState
	trailerMainData.indicatorFlashState = not indicatorFlashState

	local indicatorR = trailerMainData.indicatorR
	local indicatorL = trailerMainData.indicatorL

	self:LightsEmitIndicatorSound(trailerMain, trailerMainData)

	LIBCoupling.ForEachTrailerVehicles(trailerMain, function(k, trailer)
		lightsUpdateIndicatorsSingle(trailer, indicatorFlashState, indicatorR, indicatorL)
	end)
end

function SLIGWOLF_ADDON:LightsEmitIndicatorSound(ent, vehData)
	if not vehData.indicatorFlashState then
		ent:EmitSound(CONSTANTS.sndIndicatorOn)
		return
	end

	ent:EmitSound(CONSTANTS.sndIndicatorOff)
end

return true

