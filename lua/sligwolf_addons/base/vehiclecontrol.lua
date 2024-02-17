AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SLIGWOLF_ADDON then
	SligWolf_Addons.AutoLoadAddon(function() end)
	return
end

local LIBVehicleControl = SligWolf_Addons.VehicleControl
local LIBEntities = SligWolf_Addons.Entities
local LIBTracer = SligWolf_Addons.Tracer

function SLIGWOLF_ADDON:VehicleOrderThink()
	if not self.HasVehicleOrders then return end

	if CLIENT then
		local ply = LocalPlayer()
		if not IsValid(ply) then return end

		local vehicle = LIBVehicleControl.GetControlledVehicle(ply)
		if not IsValid(vehicle) then return end

		if gui.IsGameUIVisible() then return end
		if gui.IsConsoleVisible() then return end
		if IsValid(vgui.GetKeyboardFocus()) then return end
		if ply:IsTyping() then return end

		for k, v in pairs(self.KeySettings or {}) do
			if not v.cv then continue end

			local isdown = input.IsKeyDown(v.cv:GetInt())
			self:SendVehicleOrder(vehicle, k, isdown)
		end

		return
	end

	for vehicle, players in pairs(self.PressedKeyMap or {}) do
		if not IsValid(vehicle) then continue end

		for ply, keys in pairs(players or {}) do
			if not IsValid(ply) then continue end

			for name, callback_data in pairs(keys or {}) do
				if not callback_data.state then continue end

				local callback_hold = callback_data.callback_hold
				callback_hold(self, ply, vehicle, true)
			end
		end
	end
end

function SLIGWOLF_ADDON:VehicleOrderLeave(ply, vehicle)
	if not self.HasVehicleOrders then return end
	if CLIENT then return end

	local holdedkeys = self.PressedKeyMap or {}
	holdedkeys = holdedkeys[vehicle] or {}
	holdedkeys = holdedkeys[ply] or {}

	for name, callback_data in pairs(holdedkeys) do
		if not callback_data.state then continue end

		local callback_hold = callback_data.callback_hold
		local callback_up = callback_data.callback_up

		callback_hold(self, ply, vehicle, false)
		callback_up(self, ply, vehicle, false)

		callback_data.state = false
	end
end

function SLIGWOLF_ADDON:RegisterVehicleOrder(name, callback_hold, callback_down, callback_up)
	self.HasVehicleOrders = true

	if CLIENT then return end

	local ID = self.NetworkaddonID or ""
	if ID == "" then
		error("Invalid NetworkaddonID!")
		return
	end

	name = name or ""
	if name == "" then return end

	local netname = "SligWolf_VehicleOrder_" .. ID .. "_" .. name

	local valid = false
	if not isfunction(callback_hold) then
		callback_hold = function() end
	else
		valid = true
	end

	if not isfunction(callback_down) then
		callback_down = function() end
	else
		valid = true
	end

	if not isfunction(callback_up) then
		callback_up = function() end
	else
		valid = true
	end

	if not valid then
		error("no callback functions given!")
		return
	end

	util.AddNetworkString(netname)
	net.Receive(netname, function(len, ply)
		local ent = net.ReadEntity()
		local down = net.ReadBool() or false

		if not IsValid(ent) then return end
		if not IsValid(ply) then return end

		local veh = LIBVehicleControl.GetControlledVehicle(ply)
		if not IsValid(veh) then return end

		local setting = self.KeySettings[name]
		if not setting then return end

		self.KeyBuffer = self.KeyBuffer or {}
		self.KeyBuffer[veh] = self.KeyBuffer[veh] or {}

		local changedbuffer = self.KeyBuffer[veh][name] or {}
		local times  = changedbuffer.times or {}

		local mintime = setting.time or 0
		if mintime > 0 then
			local lasttime = times[down] or 0
			local deltatime = CurTime() - lasttime

			if deltatime <= mintime then return end
		end

		if changedbuffer.state == down then return end

		times[down] = CurTime()
		changedbuffer.times = times
		changedbuffer.state = down

		self.KeyBuffer[veh][name] = changedbuffer

		self.PressedKeyMap = self.PressedKeyMap or {}
		self.PressedKeyMap[veh] = self.PressedKeyMap[veh] or {}
		self.PressedKeyMap[veh][ply] = self.PressedKeyMap[veh][ply] or {}
		self.PressedKeyMap[veh][ply][name] = {
			callback_hold = callback_hold,
			callback_up = callback_up,
			callback_down = callback_down,
			state = down,
		}

		if down then
			callback_down(self, ply, veh, down)
			return
		end

		callback_up(self, ply, veh, down)
	end)
end

function SLIGWOLF_ADDON:RegisterKeySettings(name, default, time, description, extra_text)
	self.HasVehicleOrders = true

	name = name or ""
	description = description or ""
	help = help or ""
	default = default or 0
	time = time or 0.1

	if (name == "") then return end
	if (description == "") then return end
	if (default == 0) then return end

	local setting = {}
	setting.description = description
	setting.cvcmd = "cl_" .. self.NetworkaddonID .. "_key_" .. name
	setting.default = default
	setting.time = time

	if extra_text ~= "" then
		setting.extra_text = extra_text
	end

	if CLIENT then
		setting.cv = CreateClientConVar(setting.cvcmd, tostring(default), true, false)
	end

	self.KeySettings = self.KeySettings or {}
	self.KeySettings[name] = setting
end

if CLIENT then
	function SLIGWOLF_ADDON:SendVehicleOrder(vehicle, name, down)
		if not self.HasVehicleOrders then return end
		if not IsValid(vehicle) then return end

		local ID = self.NetworkaddonID or ""
		if ID == "" then
			error("Invalid NetworkaddonID!")
			return
		end

		name = name or ""
		down = down or false

		if name == "" then return end

		self.KeyBuffer = self.KeyBuffer or {}
		self.KeyBuffer[vehicle] = self.KeyBuffer[vehicle] or {}

		local changedbuffer = self.KeyBuffer[vehicle][name] or {}

		if changedbuffer.state == down then return end
		changedbuffer.state = down

		self.KeyBuffer[vehicle][name] = changedbuffer

		local netname = "SligWolf_VehicleOrder_" .. ID .. "_" .. name
		net.Start(netname)
			net.WriteEntity(vehicle)
			net.WriteBool(down)
		net.SendToServer()
	end

	-- local function AddDescription(panel, text)
	-- 	local DLabel = vgui.Create("DLabel", panel)
	-- 	DLabel:SetText(text)
	-- 	DLabel:SetDark(true)
	-- 	DLabel:SetContentAlignment(8)
	-- 	panel:AddPanel(DLabel)

	-- 	return DLabel
	-- end

	local function AddGap(panel)
		local DPanel = vgui.Create("DPanel", panel)
		DPanel:SetTall(5)
		panel:AddPanel(DPanel)

		return DPanel
	end

	local function AddCtrlNumPad(panel, text, command)
		local CtrlNumPad = vgui.Create("SligWolf_CtrlNumPad", panel)
		CtrlNumPad:SetLabel(text)
		CtrlNumPad:SetConVar(command)
		panel:AddPanel(CtrlNumPad)

		return CtrlNumPad
	end

	function SLIGWOLF_ADDON:VehicleOrderMenu()
		if not self.HasVehicleOrders then return end

		local networkAddonID = self.NetworkaddonID

		spawnmenu.AddToolMenuOption(
			"Utilities", "SligWolf Keys",
			networkAddonID .. "_Key_Settings",
			self.NiceName, "", "",
			function(panel, ...)
				panel:Help("\nAll keys down below can be changed.\nUsing a mouse key will disable the control key.\n")

				local isFirst = true

				for k, v in SortedPairsByMemberValue(self.KeySettings or {}, "cvcmd") do
					if not v.cv then continue end

					if not isFirst then
						AddGap(panel)
					end

					AddCtrlNumPad(panel, v.description, v.cvcmd)

					if (v.extra_text) then
						panel:ControlHelp(v.extra_text)
					end

					isFirst = false
				end

				panel:Help("Made by:")
				panel:ControlHelp("- SligWolf")
				panel:ControlHelp("- Grocel")
				panel:Help("")
			end
		)
	end
end

function SLIGWOLF_ADDON:PressButton(ply, playervehicle)
	if not IsValid(ply) then return end

	local tr = LIBTracer.DoTrace(ply, 100)
	if not tr then return end

	local button = tr.Entity
	if not IsValid(button) then return end

	local superparent = LIBEntities.GetSuperParent(button)

	if not IsValid(superparent) then
		superparent = button
		playervehicle = nil
	else
		if button.sligwolf_inVehicle and not IsValid(playervehicle) then return end
	end

	if IsValid(playervehicle) and superparent ~= playervehicle then return end
	if not button.SLIGWOLF_Buttonfunc then return end

	if not superparent.SLIGWOLF_AddonID or (superparent.SLIGWOLF_AddonID == "") then
		error("superparent.SLIGWOLF_AddonID missing!")
		return
	end

	if superparent.SLIGWOLF_AddonID ~= self.NetworkaddonID then return end

	local allowuse = true

	if superparent.CPPICanUse then
		allowuse = superparent:CPPICanUse(ply) or false
	end

	if not allowuse then return end

	return button.SLIGWOLF_Buttonfunc(button, superparent, ply)
end

return true

