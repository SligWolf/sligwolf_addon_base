DEFINE_BASECLASS("sligwolf_proxy_vehicle")

ENT.Spawnable = false
ENT.AdminOnly = true

ENT.DisableDuplicator = true
ENT.DoNotDuplicate = true

ENT.sligwolf_trainProxyEntity = true

if not SligWolf_Addons then return end
if not SligWolf_Addons.IsLoaded then return end
if not SligWolf_Addons.IsLoaded() then return end

local LIBRail = SligWolf_Addons.Rail
local LIBSourceIO = SligWolf_Addons.SourceIO
local LIBPrint = SligWolf_Addons.Print

function ENT:GetGaugeName()
	local gaugeName = LIBSourceIO.GetKeyValue(self, "sligwolf_railgauge") or ""
	if gaugeName == "" then
		gaugeName = LIBRail.TRAIN_GAUGE_DEFAULT
	end

	return gaugeName
end

function ENT:GetFullSpawnnameFromGauge(spawnname)
	local gaugeName = self:GetGaugeName()

	if gaugeName ~= LIBRail.TRAIN_GAUGE_DEFAULT and not LIBRail.HasGaugeByName(gaugeName) then
		LIBPrint.Warn("The rail gauge '%s' is not registered. (Entity: %s)", gaugeName, self)
		return nil
	end

	local gaugeSpawnnameInfo = LIBRail.GetSpawnnameInfo(spawnname, gaugeName)
	if not gaugeSpawnnameInfo then
		LIBPrint.Warn("The spawnname '%s' does not support rail gauge '%s'. (Entity: %s)", spawnname, gaugeName, self)
		return nil
	end

	return gaugeSpawnnameInfo.spawnnameFull
end