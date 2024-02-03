AddCSLuaFile()

if !SW_Addons then
	return
end

if !SW_ADDON then
	SW_Addons.AutoLoadAddon(function() end)
	return
end

local function AddNameToErrorText(addon, errText)
	errText = tostring(errText or "")

	if errText == "" then
		return ""
	end
	
	local name = tostring(addon.NiceName or addon.Addonname or "")
	if name == "" then
		name = "Unknown Addon"
	end
	
	errText = string.format('[%s] %s', name, errText)
	return errText
end

function SW_ADDON:Error(errText, errorLevel)
	errText = AddNameToErrorText(self, errText)
	if errText == "" then
		return
	end
	
	errorLevel = tonumber(errorLevel or 0) or 0
	if errorLevel <= 0 then
		errorLevel = 1
	end

	error(errText, errorLevel)
	return
end

function SW_ADDON:ErrorNoHalt(errText)
	errText = AddNameToErrorText(self, errText)
	if errText == "" then
		return
	end

	ErrorNoHalt(errText)
	return
end

function SW_ADDON:ErrorNoHaltWithStack(errText)
	errText = AddNameToErrorText(self, errText)
	if errText == "" then
		return
	end

	ErrorNoHaltWithStack(errText)
	return
end

function SW_ADDON:CallFunctionWithErrorNoHalt(func, ...)
	if !isfunction(func) then
		return false, nil
	end

	local status, errOrResult = pcall(func, ...)
	
	if status then
		return true, errOrResult
	end
	
	errOrResult = tostring(errOrResult or "")
	if errOrResult == "" then
		return false, nil
	end
	
	self:ErrorNoHaltWithStack(errOrResult)
	return false, nil
end

function SW_ADDON:CallAddonFunctionWithErrorNoHalt(addonFunc, ...)
	if isstring(addonFunc) then
		addonFunc = self[addonFunc]
	end

	if !isfunction(addonFunc) then
		return false, nil
	end

	return self:CallFunctionWithErrorNoHalt(addonFunc, self, ...)
end