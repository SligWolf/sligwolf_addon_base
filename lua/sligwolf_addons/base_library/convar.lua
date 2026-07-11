local SligWolf_Addons = _G.SligWolf_Addons
if not SligWolf_Addons then
	return
end

local LIB = SligWolf_Addons:NewLib("Convar")

local CONSTANTS = SligWolf_Addons.Constants

local LIBString = SligWolf_Addons.String
local LIBPlayer = SligWolf_Addons.Player
local LIBPrint = SligWolf_Addons.Print
local LIBDebug = SligWolf_Addons.Debug

LIB.ROLE_NONE = "none"
LIB.ROLE_PLAYER = "player"
LIB.ROLE_ADMIN = "admin"
LIB.ROLE_ADMIN_PLAYER = "admin_player"
LIB.ROLE_HOST = "host"
LIB.ROLE_HOST_PLAYER = "host_player"

LIB.HELP_COLORS = {
	Color(220, 220, 220), -- \x01 default color

	-- \x02 realm color
	CLIENT and Color(255, 222, 132) or Color(167, 222, 255),

	Color(255, 255, 255), -- \x03 title color
	Color(180, 240, 180), -- \x04 hightlight color
	Color(177, 177, 177), -- \x05 empty color
	Color(255, 90, 90),   -- \x06 warn color
}

LIB.g_callbacks = LIB.g_callbacks or {}
local g_callbacks = LIB.g_callbacks

LIB.g_varModifier = LIB.g_varModifier or {}
local g_varModifier = LIB.g_varModifier

LIB.g_commandRoles = LIB.g_commandRoles or {}
local g_commandRoles = LIB.g_commandRoles

LIB.g_helpList = LIB.g_helpList or {}
local g_helpList = LIB.g_helpList

g_helpList.shCvar = g_helpList.shCvar or {}
g_helpList.clCvar = g_helpList.clCvar or {}
g_helpList.cmd = g_helpList.cmd or {}

local g_nextThink = nil

local function buildHelp(cmdName, parameters, role)
	local innerHelp = tostring(parameters.help or "")
	local min = tostring(parameters.min or "")
	local max = tostring(parameters.max or "")
	local default = parameters.default
	local helpOptions = parameters.helpOptions or {}
	local helpSyntax = tostring(parameters.helpSyntax or "")
	local optiosHelp = {}

	local isBoolean = isbool(default)

	if #helpOptions <= 0 and isBoolean then
		helpOptions = {
			{0, "Off"},
			{1, "On"},
		}
	end

	for _, helpOption in ipairs(helpOptions) do
		local value = tostring(helpOption[1] or "")
		local name = tostring(helpOption[2] or "")

		if value == "" then
			continue
		end

		if name == "" then
			continue
		end

		local optiosHelpItem = string.format("\x04%s\x01 = %s", value, name)
		optiosHelp[#optiosHelp + 1] = optiosHelpItem
	end

	local roleTitle = ""

	if role then
		roleTitle = tostring(role.title or "")
	end

	local helpBuffer = {}

	if innerHelp == "" then
		innerHelp = "No Description."
	end

	if roleTitle ~= "" then
		helpBuffer[#helpBuffer + 1] = string.format("\x06[%s]\x01 ", roleTitle)
	end

	helpBuffer[#helpBuffer + 1] = string.format("\x03%s\x01", innerHelp)

	if #optiosHelp <= 0 then
		helpBuffer[#helpBuffer + 1] = "\n"

		if min ~= "" then
			min = string.format("Min: \x04%s\x01", min)
			helpBuffer[#helpBuffer + 1] = min
		end

		if max ~= "" then
			max = string.format("Max: \x04%s\x01", max)
			helpBuffer[#helpBuffer + 1] = max
		end
	else
		helpBuffer[#helpBuffer + 1] = "\n"

		optiosHelp = string.format("Options: %s", table.concat(optiosHelp, ", "))
		helpBuffer[#helpBuffer + 1] = optiosHelp
	end

	if helpSyntax ~= "" then
		helpBuffer[#helpBuffer + 1] = "\n"
		helpSyntax = string.format("Syntax: \x02%s\x01 \x04%s\x01", cmdName, helpSyntax)
		helpBuffer[#helpBuffer + 1] = helpSyntax
	end

	if default ~= nil then
		helpBuffer[#helpBuffer + 1] = "\n"

		if isBoolean then
			default = string.format("Default: \x04%i\x01", default and 1 or 0)
		else
			if default == "" then
				default = string.format("Default: \x05<empty>\x01", default)
			else
				default = string.format("Default: \x04%s\x01", default)
			end
		end

		helpBuffer[#helpBuffer + 1] = default
	end

	local help = table.concat(helpBuffer, " ")

	help = string.Trim(help)

	help = string.gsub(help, "[ \t]+", " ")
	help = string.gsub(help, "[ \t]+[\r\n]+", "\n")
	help = string.gsub(help, "[\r\n]+[ \t]+", "\n")

	local helpObj = LIBString.CreateColoredString(help, LIB.HELP_COLORS)

	return helpObj
end

local g_defaultColor = LIB.HELP_COLORS[1]
local g_nameColor = LIB.HELP_COLORS[2]
local g_headerColor = LIB.HELP_COLORS[3]
local g_emptyColor = LIB.HELP_COLORS[5]

local function printList(items)
	if #items <= 0 then
		MsgC(g_emptyColor, "  - Empty result -")
		MsgC(g_defaultColor, "\n\n")
	else
		for _, item in ipairs(items) do
			MsgC(g_nameColor, "  " .. item.name)
			MsgC(g_defaultColor, " :\n")

			MsgC(g_defaultColor, "    ")

			local tokens = item.help:GetTokens()
			local last = #tokens

			for i, token in ipairs(tokens) do
				local text = token.text

				if text == "\n" and i < last then
					text = "\n      "
				end

		 		MsgC(token.color, text)
			end

			MsgC(g_defaultColor, "\n\n")
		end
	end
end

local function printHelp(filter)
	filter = tostring(filter or "")
	filter = string.Trim(filter)
	filter = string.lower(filter)

	if not filter or filter == "" then
		filter = "*"
	end

	local shCvar = {}
	local clCvar = {}
	local cmd = {}

	for _, item in SortedPairsByMemberValue(g_helpList.shCvar, "name", false) do
		if not LIBString.WildcardMatch(item.name, filter) then
			continue
		end

		table.insert(shCvar, item)
	end

	if CLIENT then
		for _, item in SortedPairsByMemberValue(g_helpList.clCvar, "name", false) do
			if not LIBString.WildcardMatch(item.name, filter) then
				continue
			end

			table.insert(clCvar, item)
		end
	end

	for _, item in SortedPairsByMemberValue(g_helpList.cmd, "name", false) do
		if not LIBString.WildcardMatch(item.name, filter) then
			continue
		end

		table.insert(cmd, item)
	end

	MsgC(g_defaultColor, "\n")
	MsgC(g_headerColor, "ConVars:")
	MsgC(g_defaultColor, "\n\n")

	printList(shCvar)

	if CLIENT then
		MsgC(g_defaultColor, "\n")
		MsgC(g_headerColor, "Client ConVars")
		MsgC(g_defaultColor, "\n\n")

		printList(clCvar)
	end

	MsgC(g_defaultColor, "\n")
	MsgC(g_headerColor, "ConCommands:")
	MsgC(g_defaultColor, "\n\n")

	printList(cmd)

	MsgC(g_defaultColor, "\n")
end

local function formatPlaintextHelp(helpPlaintext)
	helpPlaintext = string.gsub(helpPlaintext, "\n+", "\n     ")
	return helpPlaintext
end

function LIB.AddConvar(convarName, parameters)
	convarName = tostring(convarName or "")
	if convarName == "" then
		LIBPrint.Error("No convarName given.")
		return nil
	end

	parameters = parameters or {}

	local default = parameters.default
	local min = parameters.min
	local max = parameters.max
	local modifier = parameters.modifier

	if isbool(default) then
		default = default and "1" or "0"
		min = 0
		max = 1
		modifier = modifier or tobool
	elseif isnumber(default) then
		if not modifier then
			local toLimitedNumber = nil

			if min and max then
				toLimitedNumber = function(num)
					num = tonumber(num or 0) or 0
					num = math.Clamp(num, min, max)

					return num
				end
			elseif min and not max then
				toLimitedNumber = function(num)
					num = tonumber(num or 0) or 0
					num = math.max(num, min)

					return num
				end
			elseif not min and max then
				toLimitedNumber = function(num)
					num = tonumber(num or 0) or 0
					num = math.min(num, max)

					return num
				end
			else
				toLimitedNumber = function(num)
					return tonumber(num or 0) or 0
				end
			end

			modifier = toLimitedNumber
		end
	end

	default = tostring(default)

	local helpItem = LIB.AddConvarHelp(convarName, parameters)

	local convar = CreateConVar(
		convarName,
		default,
		parameters.flags or 0,
		helpItem.plaintext,
		min,
		max
	)

	if modifier then
		LIB.AddVarModifier(convarName, modifier)
	end

	return convar
end

function LIB.AddClientConvar(convarName, parameters)
	if SERVER then
		return nil
	end

	convarName = tostring(convarName or "")
	if convarName == "" then
		LIBPrint.Error("No convarName given.")
		return nil
	end

	parameters = parameters or {}

	local default = parameters.default
	local min = parameters.min
	local max = parameters.max
	local modifier = parameters.modifier

	if isbool(default) then
		default = default and "1" or "0"
		min = 0
		max = 1
		modifier = modifier or tobool
	elseif isnumber(default) then
		if not modifier then
			local toLimitedNumber = nil

			if min and max then
				toLimitedNumber = function(num)
					num = tonumber(num or 0) or 0
					num = math.Clamp(num, min, max)

					return num
				end
			elseif min and not max then
				toLimitedNumber = function(num)
					num = tonumber(num or 0) or 0
					num = math.max(num, min)

					return num
				end
			elseif not min and max then
				toLimitedNumber = function(num)
					num = tonumber(num or 0) or 0
					num = math.min(num, max)

					return num
				end
			else
				toLimitedNumber = function(num)
					return tonumber(num or 0) or 0
				end
			end

			modifier = toLimitedNumber
		end
	end

	default = tostring(default)

	local helpItem = LIB.AddClientConvarHelp(convarName, parameters)

	local convar = CreateClientConVar(
		convarName,
		default,
		tobool(parameters.shouldsave),
		tobool(parameters.userinfo),
		helpItem.plaintext,
		min,
		max
	)

	if modifier then
		LIB.AddVarModifier(convarName, modifier)
	end

	return convar
end

function LIB.AddCommand(cmdName, parameters)
	cmdName = tostring(cmdName or "")
	if cmdName == "" then
		LIBPrint.Error("No cmdName given.")
		return
	end

	parameters = parameters or {}

	local roleName = tostring(parameters.role or "")
	local role = LIB.GetCommandRole(roleName)

	if not role then
		if roleName == "" then
			LIBPrint.Error("No parameters.role given.")
		else
			LIBPrint.Error("Invalid parameters.role '%s' given.", roleName)
		end

		return
	end

	local roleCallback = role.callback
	local callback = parameters.callback
	local autoCompleteCallback = parameters.autoComplete

	local callCallback = function(ply, cmd, args)
		local allowed = true

		if roleCallback then
			allowed = roleCallback(ply, cmd, args)
		end

		if not allowed then
			return
		end

		if callback then
			ProtectedCall(callback, ply, cmd, args)
		end
	end

	local helpItem = LIB.AddCommandHelp(cmdName, parameters)

	concommand.Add(
		cmdName,
		callCallback,
		autoCompleteCallback,
		helpItem.plaintext,
		parameters.flags or 0
	)
end

function LIB.AddConvarHelp(convarName, parameters)
	convarName = tostring(convarName or "")
	if convarName == "" then
		LIBPrint.Error("No convarName given.")
		return nil
	end

	local helpObj = buildHelp(convarName, parameters)

	local helpPlaintext = helpObj:GetPlaintext()
	helpPlaintext = formatPlaintextHelp(helpPlaintext)

	local item = {
		name = convarName,
		help = helpObj,
		plaintext = helpPlaintext,
	}

	if not parameters.unlisted then
		g_helpList.shCvar[convarName] = item
	end

	return item
end

function LIB.AddClientConvarHelp(convarName, parameters)
	if SERVER then
		return nil
	end

	convarName = tostring(convarName or "")
	if convarName == "" then
		LIBPrint.Error("No convarName given.")
		return nil
	end

	local helpObj = buildHelp(convarName, parameters)

	local helpPlaintext = helpObj:GetPlaintext()
	helpPlaintext = formatPlaintextHelp(helpPlaintext)

	local item = {
		name = convarName,
		help = helpObj,
		plaintext = helpPlaintext,
	}

	if not parameters.unlisted then
		g_helpList.clCvar[convarName] = item
	end

	return item
end

function LIB.AddCommandHelp(cmdName, parameters)
	cmdName = tostring(cmdName or "")
	if cmdName == "" then
		LIBPrint.Error("No cmdName given.")
		return nil
	end

	parameters = parameters or {}

	local roleName = tostring(parameters.role or "")
	local role = LIB.GetCommandRole(roleName)

	if not role then
		if roleName == "" then
			LIBPrint.Error("No parameters.role given.")
		else
			LIBPrint.Error("Invalid parameters.role '%s' given.", roleName)
		end

		return nil
	end

	local helpObj = buildHelp(cmdName, parameters, role)

	local helpPlaintext = helpObj:GetPlaintext()
	helpPlaintext = formatPlaintextHelp(helpPlaintext)

	local item = {
		name = cmdName,
		help = helpObj,
		plaintext = helpPlaintext,
	}

	if not parameters.unlisted then
		g_helpList.cmd[cmdName] = item
	end

	return item
end

function LIB.AddCommandRole(roleName, parameters)
	roleName = tostring(roleName or "")

	if roleName == "" then
		return nil
	end

	parameters = parameters or {}

	local title = tostring(parameters.title or "")
	local help = tostring(parameters.help or "")

	g_commandRoles[roleName] = {
		name = roleName,
		title = title,
		help = help,
		callback = parameters.callback,
	}
end

function LIB.GetCommandRole(roleName)
	roleName = tostring(roleName or "")
	if roleName == "" then
		return nil
	end

	local role = g_commandRoles[roleName]
	if not role then
		return nil
	end

	return role
end

function LIB.AddVarModifier(convarName, modifier)
	convarName = tostring(convarName or "")
	g_varModifier[convarName] = modifier
end

function LIB.AddChangeCallback(convarName, callback, identifier)
	convarName = tostring(convarName or "")
	identifier = tostring(identifier or "")

	if not isfunction(callback) then
		return
	end

	local convarCallbacks = g_callbacks[convarName] or {}
	g_callbacks[convarName] = convarCallbacks

	local convarCallback = convarCallbacks[identifier] or {}
	convarCallbacks[identifier] = convarCallback

	convarCallback.callback = callback
	convarCallback.convar = LIB.GetConvar(convarName)
	convarCallback.oldValue = nil
end

function LIB.GetConvar(convarName)
	convarName = tostring(convarName or "")
	if convarName == "" then
		return nil
	end

	local convar = GetConVar(convarName)
	if not convar then
		return nil
	end

	return convar
end

function LIB.GetValue(convarName)
	local convar = LIB.GetConvar(convarName)
	if not convar then
		return nil
	end

	local value = convar:GetString() or ""

	local modifier = g_varModifier[convarName]
	if modifier then
		value = modifier(value)
	end

	return value
end

function LIB.Refresh()
	g_nextThink = nil
end

LIB.AddCommandRole(LIB.ROLE_NONE, {
	title = "",
	callback = function(ply, cmd, args)
		return true
	end,
})

LIB.AddCommandRole(LIB.ROLE_PLAYER, {
	title = "",
	callback = function(ply, cmd, args)
		if not IsValid(ply) then
			LIBPrint.PrintForPlayer(ply, "This needs a valid player.")
			return false
		end

		return true
	end,
})

LIB.AddCommandRole(LIB.ROLE_ADMIN, {
	title = "Admin only",
	callback = function(ply, cmd, args)
		if not LIBPlayer.IsAdminForCMD(ply) then
			LIBPrint.PrintForPlayer(ply, "Not Allowed! This is admin only.")
			return false
		end

		return true
	end,
})

LIB.AddCommandRole(LIB.ROLE_ADMIN_PLAYER, {
	title = "Admin player only",
	callback = function(ply, cmd, args)
		if not LIBPlayer.IsAdmin(ply) then
			LIBPrint.PrintForPlayer(ply, "Not Allowed! This is admin player only.")
			return false
		end

		return true
	end,
})

LIB.AddCommandRole(LIB.ROLE_HOST, {
	title = "Host only",
	callback = function(ply, cmd, args)
		if not LIBPlayer.IsHostPlayerForCMD(ply) then
			LIBPrint.PrintForPlayer(ply, "Not Allowed! This is host only.")
			return false
		end

		return true
	end,
})

LIB.AddCommandRole(LIB.ROLE_HOST_PLAYER, {
	title = "Host player only",
	callback = function(ply, cmd, args)
		if not LIBPlayer.IsHostPlayer(ply) then
			LIBPrint.PrintForPlayer(ply, "Not Allowed! This is host player only.")
			return false
		end

		return true
	end,
})

local g_sliderRenderMode = 0
local cl_calcSliderRenderMode = nil

if CLIENT then
	LIB.ENUM_SLIDER_RENDER_MODE_DISABLED = 0
	LIB.ENUM_SLIDER_RENDER_MODE_PHYSGUN = 1
	LIB.ENUM_SLIDER_RENDER_MODE_ALWAYS = 2

	LIB.AddClientConvar("cl_sligwolf_base_slider_render_mode", {
		default = LIB.ENUM_SLIDER_RENDER_MODE_PHYSGUN,
		shouldsave = true,
		userinfo = false,
		min = 0,
		max = 2,

		help = "Sets the rendering mode of sliders.",
		helpOptions = {
			{0, "Disabled"},
			{1, "Render when grapped with Physgun"},
			{2, "Always render"},
		},
	})

	function LIB.GetSliderRenderMode()
		return g_sliderRenderMode
	end

	local function getToolMode()
		local ply = LocalPlayer()

		local toolgun = ply:GetActiveWeapon()
		if not IsValid(toolgun) then
			return
		end

		if toolgun:GetClass() ~= "gmod_tool" then
			return
		end

		return toolgun:GetMode()
	end

	cl_calcSliderRenderMode = function()
		if LIBDebug.IsDeveloper() then
			return LIB.ENUM_SLIDER_RENDER_MODE_ALWAYS
		end

		local showSlidersMode = LIB.GetValue("cl_sligwolf_base_slider_render_mode")

		if showSlidersMode == LIB.ENUM_SLIDER_RENDER_MODE_DISABLED then
			return showSlidersMode
		end

		if getToolMode() == CONSTANTS.toolRubatsEasyInspector then
			return LIB.ENUM_SLIDER_RENDER_MODE_ALWAYS
		end

		return showSlidersMode
	end
end

local function pollChangeCallbacks(force)
	for convarName, convarCallbacks in pairs(g_callbacks) do
		for identifier, convarCallback in pairs(convarCallbacks) do
			local convar = convarCallback.convar

			if not convar then
				convar = GetConVar(convarName)
				convarCallback.convar = convar

				if not convar then
					continue
				end
			end

			local oldValue = convarCallback.oldValue
			local newValue = convar:GetString() or ""

			local modifier = g_varModifier[convarName]
			if modifier then
				newValue = modifier(newValue)
			end

			if oldValue ~= nil and newValue == oldValue and not force then
				continue
			end

			ProtectedCall(convarCallback.callback, newValue, convarName)
			convarCallback.oldValue = newValue
		end
	end
end

local function doDelayedThink()
	pollChangeCallbacks()

	if SERVER then
		return
	end

	g_sliderRenderMode = cl_calcSliderRenderMode()
end

function LIB.Load()
	LIBString = SligWolf_Addons.String
	LIBPlayer = SligWolf_Addons.Player
	LIBPrint = SligWolf_Addons.Print
	LIBDebug = SligWolf_Addons.Debug

	local LIBHook = SligWolf_Addons.Hook

	if CLIENT then
		LIB.AddCommand("cl_sligwolf_base_help", {
			flags = bit.bor(FCVAR_DONTRECORD, FCVAR_CLIENTDLL),
			role = LIB.ROLE_NONE,

			callback = function(ply, cmd, args)
				printHelp(args[1])
			end,

			help = "Lists all ConCommands and ConVars related to SW Addons.",
			helpSyntax = "[<commandname wildcard|*>]",
		})
	else
		LIB.AddCommand("sv_sligwolf_base_help", {
			flags = bit.bor(FCVAR_DONTRECORD, FCVAR_GAMEDLL),
			role = LIB.ROLE_HOST,

			callback = function(ply, cmd, args)
				printHelp(args[1])
			end,

			help = "Lists all ConCommands and ConVars related to SW Addons.",
			helpSyntax = "[<commandname wildcard|*>]",
		})

		LIB.AddConvarHelp("sv_sligwolf_base_workshop_download", {
			default = true,
			flags = bit.bor(FCVAR_ARCHIVE, FCVAR_GAMEDLL),
			help = "Enables workshop downloads (resource.AddWorkshop()) of SW Addons for joining clients. Requires server restart.",
		})
	end

	LIBHook.Add("Think", "ConvarsUpdate", function()
		local now = RealTime()

		if not g_nextThink or g_nextThink < now then
			doDelayedThink()
			g_nextThink = now + 1 + math.random()
		end
	end)
end

function LIB.FirstFrame()
	g_nextThink = nil
	pollChangeCallbacks(true)
end

return true

