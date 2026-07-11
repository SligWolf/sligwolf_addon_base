AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SLIGWOLF_ADDON then
	SligWolf_Addons:ReloadAddonSystem()
	return
end

local LIBVehicleControl = SligWolf_Addons.VehicleControl
local LIBEntities = SligWolf_Addons.Entities
local LIBConvar = SligWolf_Addons.Convar
local LIBTrace = SligWolf_Addons.Trace
local LIBNet = SligWolf_Addons.Net

function SLIGWOLF_ADDON:VehicleOrderThink()
	if not self.HasVehicleOrders then return end

	if CLIENT then
		local ply = LocalPlayer()
		if not IsValid(ply) then return end

		if gui.IsGameUIVisible() then return end
		if gui.IsConsoleVisible() then return end
		if IsValid(vgui.GetKeyboardFocus()) then return end
		if ply:IsTyping() then return end

		local vehicle = LIBVehicleControl.GetControlledVehicle(ply)
		if not IsValid(vehicle) then return end

		local spawntable = LIBEntities.GetSpawntable(vehicle, true)
		if not spawntable or spawntable.SLIGWOLF_Addonname ~= self.Addonname then
			return
		end

		for k, v in pairs(self.KeySettings or {}) do
			if not v.cv then continue end

			local isdown = input.IsKeyDown(v.cv:GetInt())
			self:SendVehicleOrder(vehicle, k, isdown)
		end

		return
	end

	for vehicle, players in pairs(self.PressedKeyMap or {}) do
		if not LIBEntities.IsSpawnSystemFinished(vehicle) then continue end

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
	if not LIBEntities.IsSpawnSystemFinished(vehicle) then return end

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

	name = name or ""

	name = string.Trim(name)
	name = string.lower(name)

	if name == "" then return end

	local netname = self.Addonname .. "_vo_" .. name

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

	LIBNet.AddNetworkString(netname)
	LIBNet.Receive(netname, function(len, ply)
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

function SLIGWOLF_ADDON:RegisterKeySettings(name, default, time, description)
	self.HasVehicleOrders = true

	name = name or ""
	description = description or ""
	default = default or 0
	time = time or 0.1

	name = string.Trim(name)
	name = string.lower(name)

	if name == "" then return end
	if description == "" then return end
	if default == 0 then return end

	local cmd = "cl_sligwolf_" .. self.Addonname .. "_key_" .. name

	local setting = {}
	setting.description = description
	setting.cvcmd = cmd
	setting.default = default
	setting.time = time

	if CLIENT then
		local help = string.format(
			"Set control key for \x04'%s'\x03 in addon \x04'%s'\x03.",
			description,
			self.Addonname
		)

		setting.cv = LIBConvar.AddClientConvar(setting.cvcmd, {
			default = default,
			shouldsave = true,
			userinfo = false,
			help = help,
			unlisted = true,
		})
	end

	self.KeySettings = self.KeySettings or {}
	self.KeySettings[name] = setting
end

if CLIENT then
	function SLIGWOLF_ADDON:SendVehicleOrder(vehicle, name, down)
		if not self.HasVehicleOrders then return end
		if not IsValid(vehicle) then return end

		name = name or ""
		down = down or false

		name = string.Trim(name)
		name = string.lower(name)

		if name == "" then return end

		self.KeyBuffer = self.KeyBuffer or {}
		self.KeyBuffer[vehicle] = self.KeyBuffer[vehicle] or {}

		local changedbuffer = self.KeyBuffer[vehicle][name] or {}

		if changedbuffer.state == down then return end
		changedbuffer.state = down

		self.KeyBuffer[vehicle][name] = changedbuffer

		local netname = self.Addonname .. "_vo_" .. name
		LIBNet.Start(netname)
			net.WriteEntity(vehicle)
			net.WriteBool(down)
		LIBNet.SendToServer()
	end

	local function AddGap(panel)
		local this = vgui.Create("DPanel", panel)
		this:SetTall(5)
		panel:AddPanel(this)

		return this
	end

	local function AddCtrlNumPad(panel, text, command)
		local this = vgui.Create("SligWolf_CtrlNumPad", panel)
		this:SetLabel(text)
		this:SetConVar(command)
		panel:AddPanel(this)

		return this
	end

	function SLIGWOLF_ADDON:VehicleOrderMenu()
		if not self.HasVehicleOrders then return end

		spawnmenu.AddToolMenuOption(
			"Utilities", "SligWolf Keys",
			"SligWolf_VehicleOrder_" .. self.Addonname .. "_Key_Settings",
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

	local tr = LIBTrace.PlayerAimTrace(ply, 100)
	if not tr then return end

	local button = tr.Entity
	if not IsValid(button) then return end

	local superparent = LIBEntities.GetSuperParent(button)
	if not LIBEntities.IsSpawnSystemFinished(superparent) then return end

	if not IsValid(superparent) then
		superparent = button
		playervehicle = nil
	else
		if button.sligwolf_inVehicle and not IsValid(playervehicle) then return end
	end

	if IsValid(playervehicle) and superparent ~= playervehicle then return end
	if superparent.sligwolf_addonname ~= self.Addonname then return end

	if not button.sligwolf_buttonEntity then
		return
	end

	local allowuse = true

	if superparent.CPPICanUse then
		allowuse = superparent:CPPICanUse(ply) or false
	end

	if not allowuse then
		return
	end

	return button:OnPress(ply)
end

return true

