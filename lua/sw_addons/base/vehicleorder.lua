AddCSLuaFile()

if !SW_Addons then
	return
end

if !SW_ADDON then
	SW_Addons.AutoLoadAddon(function() end)
	return
end

function SW_ADDON:VehicleOrderThink()
	if !self.HasVehicleOrders then return end

	if CLIENT then
		local ply = LocalPlayer()
		if !IsValid(ply) then return end
		local vehicle = ply:GetVehicle()
		if !IsValid(vehicle) then return end
		
		if gui.IsGameUIVisible() then return end
		if gui.IsConsoleVisible() then return end
		if IsValid(vgui.GetKeyboardFocus()) then return end
		if ply:IsTyping() then return end
		
		for k,v in pairs(self.KeySettings or {}) do
			if (!v.cv) then continue end
			
			local isdown = input.IsKeyDown(v.cv:GetInt())
			self:SendVehicleOrder(vehicle, k, isdown)
		end
		
		return
	end

	for vehicle, players in pairs(self.PressedKeyMap or {}) do
		if !IsValid(vehicle) then continue end
		
		for ply, keys in pairs(players or {}) do
			if !IsValid(ply) then continue end
			
			for name, callback_data in pairs(keys or {}) do
				if !callback_data.state then continue end
				
				local callback_hold = callback_data.callback_hold
				callback_hold(self, ply, vehicle, true)
			end
		end
	end
end

function SW_ADDON:VehicleOrderLeave(ply, vehicle)
	if !self.HasVehicleOrders then return end
	if CLIENT then return end
	
	local holdedkeys = self.PressedKeyMap or {}
	holdedkeys = holdedkeys[vehicle] or {}
	holdedkeys = holdedkeys[ply] or {}

	for name, callback_data in pairs(holdedkeys) do
		if !callback_data.state then continue end
	
		local callback_hold = callback_data.callback_hold
		local callback_up = callback_data.callback_up
		
		callback_hold(self, ply, vehicle, false)
		callback_up(self, ply, vehicle, false)
		
		callback_data.state = false
	end
end

function SW_ADDON:RegisterVehicleOrder(name, callback_hold, callback_down, callback_up)
	self.HasVehicleOrders = true

	if CLIENT then return end

	local ID = self.NetworkaddonID or ""
	if ID == "" then
		error("Invalid NetworkaddonID!")
		return
	end
	
	name = name or ""
	if name == "" then return end

	local netname = "SligWolf_VehicleOrder_"..ID.."_"..name
	
	local valid = false
	if !isfunction(callback_hold) then
		callback_hold = (function() end)
	else
		valid = true
	end
		
	if !isfunction(callback_down) then
		callback_down = (function() end)
	else
		valid = true
	end
	
	if !isfunction(callback_up) then
		callback_up = (function() end)
	else
		valid = true
	end	
	
	if !valid then
		error("no callback functions given!")
		return
	end	
	
	util.AddNetworkString(netname)
	net.Receive(netname, function(len, ply)
		local ent = net.ReadEntity()
		local down = net.ReadBool() or false
		
		if !IsValid(ent) then return end
		if !IsValid(ply) then return end
		if !ply:InVehicle() then return end

		local veh = ply:GetVehicle()
		if(ent != veh) then return end
		
		local setting = self.KeySettings[name]
		if !setting then return end
		
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

function SW_ADDON:RegisterKeySettings(name, default, time, description, extra_text)
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
	setting.cvcmd = "cl_"..self.NetworkaddonID.."_key_"..name
	setting.default = default
	setting.time = time

	if (extra_text != "") then
		setting.extra_text = extra_text
	end

	if CLIENT then
		setting.cv = CreateClientConVar(setting.cvcmd, tostring(default), true, false)
	end

	self.KeySettings = self.KeySettings or {}
	self.KeySettings[name] = setting
end

if CLIENT then

	function SW_ADDON:SendVehicleOrder(vehicle, name, down)
		if !self.HasVehicleOrders then return end
		if !IsValid(vehicle) then return end

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

		local netname = "SligWolf_VehicleOrder_"..ID.."_"..name
		net.Start(netname) 
			net.WriteEntity(vehicle)
			net.WriteBool(down)
		net.SendToServer()
	end
	
	local function AddDescription(panel, text)
		local DLabel = vgui.Create("DLabel", panel)
		DLabel:SetText(text)
		DLabel:SetDark(true)
		DLabel:SetContentAlignment(8)
		panel:AddPanel(DLabel)

		return DLabel
	end

	local function AddGap(panel)
		local DPanel = vgui.Create("DPanel", panel)
		DPanel:SetTall(5)
		panel:AddPanel(DPanel)

		return DPanel
	end
	
	local function AddCtrlNumPad(panel, text, command)
		local CtrlNumPad = vgui.Create("SligWolf_Custom_CtrlNumPad", panel)
		CtrlNumPad:SetLabel(text)
		CtrlNumPad:SetConVar(command)
		panel:AddPanel(CtrlNumPad)
		
		return CtrlNumPad
	end

	function SW_ADDON:VehicleOrderMenu()
		if !self.HasVehicleOrders then return end
		
		local networkAddonID = self.NetworkaddonID

		spawnmenu.AddToolMenuOption(
			"Utilities", "SW Vehicle KEY's",
			networkAddonID.."_Key_Settings",
			self.NiceName, "", "",
			function(panel, ...)
				panel:Help("\nAll keys down below can be changed.\nUsing a mouse key will disable the control key.\n")
			
				local isFirst = true
			
				for k,v in SortedPairsByMemberValue(self.KeySettings or {}, "cvcmd") do
					if !v.cv then continue end
					
					if !isFirst then
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

local checkForEmptySpaceVectors = {
	V1 = { VecA = Vector(0,0,0), VecB = Vector(0,0,70) },
	V2 = { VecA = Vector(15,0,0), VecB = Vector(15,0,70) },
	V3 = { VecA = Vector(0,15,0), VecB = Vector(0,15,70) },
	V4 = { VecA = Vector(-15,0,0), VecB = Vector(-15,0,70) },
	V5 = { VecA = Vector(0,-15,0), VecB = Vector(0,-15,70) },
	V6 = { VecA = Vector(15,15,0), VecB = Vector(15,15,70) },
	V7 = { VecA = Vector(-15,15,0), VecB = Vector(-15,15,70) },
	V8 = { VecA = Vector(-15,-15,0), VecB = Vector(-15,-15,70) },
	V9 = { VecA = Vector(15,-15,0), VecB = Vector(15,-15,70) },
}
	
function SW_ADDON:Exit_Seat(ent, ply)

	if !IsValid(ent) then return false end
	if !IsValid(ply) then return false end
	
	local tb = ent.__swExitVectors or {}
	local exitPlyVector = tb[1]
	local exitEyeVector = tb[2]
	
	if !isvector(exitPlyVector) then return false end
	if !isvector(exitEyeVector) then return false end
	
	local Filter = function(addon, veh, f_ent)
		if !IsValid(f_ent) then return false end
		if !IsValid(ply) then return false end
		if f_ent == veh then return false end
		if f_ent == ply then return false end
		if f_ent:GetModel() == "models/sligwolf/unique_props/seat.mdl" then return false end

		return true
	end	

	local seatPos 	= ent:GetPos()
	local seatAng 	= ent:GetAngles()
	local forward 	= seatAng:Forward()
	local right 	= seatAng:Right()
	local up 		= seatAng:Up()
	
	local exitPos = seatPos + forward*exitPlyVector.x + right*exitPlyVector.y + up*exitPlyVector.z
	local eyePos  = seatPos - (seatPos + forward*exitEyeVector.x + right*exitEyeVector.y + up*exitEyeVector.z)
	
	for k,v in pairs(checkForEmptySpaceVectors) do
		local tr = self:Tracer(ent, exitPos + v.VecA, exitPos + v.VecB, Filter)
		if tr.Hit then return true end
	end
	
	ply:SetPos(exitPos)
	ply:SetEyeAngles(eyePos:Angle())
	
	return false
end

function SW_ADDON:PressButton(ply, playervehicle)
	if !IsValid(ply) then return end
	local tr = self:DoTrace(ply, 100)
	if !tr then return end
	
	local Button = tr.Entity
	if !IsValid(Button) then return end
	
	local superparent = self:GetSuperParent(Button)

	if !IsValid(superparent) then
		superparent = Button
		playervehicle = nil
	else
		if Button.__SW_Invehicle and !IsValid(playervehicle) then return end
	end

	if IsValid(playervehicle) and superparent != playervehicle then return end
	if !Button.__SW_Buttonfunc then return end

	if !superparent.__SW_AddonID or (superparent.__SW_AddonID == "") then
		error("superparent.__SW_AddonID missing!")
		return
	end
	
	if superparent.__SW_AddonID != self.NetworkaddonID then return end
	
	local allowuse = true
	
	if superparent.CPPICanUse then
		allowuse = superparent:CPPICanUse(ply) or false
	end
	
	if !allowuse then return end
	
	return Button.__SW_Buttonfunc(Button, superparent, ply)
end

function SW_ADDON:TrainDoorButtonToggle(button, mainvehicle, ply)
	if !IsValid(button) then return end
	if !IsValid(ply) then return end
	
	local Name = self:GetName(button)
	local Id = string.Right(Name, 1)
	
	local Door = self:GetChild(mainvehicle, "Door_D"..Id)
	if !IsValid(Door) then return end
	
	Door.__SW_Door_State = !Door.__SW_Door_State

	if Door.__SW_Door_State then
		Door:Set_AutoClose(false)
		Door:Open()
		return
	else
		Door:Set_AutoClose(true)
		Door:Close()
		return
	end
end