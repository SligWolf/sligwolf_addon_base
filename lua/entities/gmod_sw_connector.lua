AddCSLuaFile()
DEFINE_BASECLASS("base_entity")

ENT.Spawnable			= false
ENT.RenderGroup 		= RENDERGROUP_BOTH
ENT.DoNotDuplicate 		= true
ENT.__IsSW_Connector 	= true

local GENDER_MALE = "M"
local GENDER_FEMALE = "F"
local GENDER_NEUTRAL = "N"

function ENT:Initialize()
	self:SetModel("models/sligwolf/unique_props/sw_sphere_4x4x4.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	self:SetNotSolid(true)
	self:SetNoDraw(true)
	
	self.allowedtypes = nil
	self.gender = GENDER_NEUTRAL
	self.kind = ""
end

function ENT:DrawTranslucent()

end

function ENT:AllowAllTypes(kind)
	self.allowedtypes = nil
end

function ENT:AllowType(kind)
	kind = tostring(kind or "")
	if kind == "" then return end

	self.allowedtypes = self.allowedtypes or {}
	self.allowedtypes[kind] = true
end

function ENT:DisallowType(kind)
	kind = tostring(kind or "")
	if kind == "" then return end

	self.allowedtypes = self.allowedtypes or {}
	self.allowedtypes[kind] = nil
end

function ENT:IsAllowedType(kind)
	if !self.allowedtypes then return true end
	
	return self.allowedtypes[kind]
end

function ENT:SetType(kind)
	kind = tostring(kind or "")
	if kind == "" then return end

	self.kind = kind
	
	self.allowedtypes = nil
	self:AllowType(self.kind)
end

function ENT:GetType()
	return self.kind
end

function ENT:SetGender(gender)
	if gender == GENDER_MALE then
		self.gender = GENDER_MALE
		return
	end
	
	if gender == GENDER_FEMALE then
		self.gender = GENDER_FEMALE
		return
	end

	self.gender = GENDER_NEUTRAL
end

function ENT:GetGender()
	return self.gender
end

function ENT:IsAllowedGender(gender)
	if !self.gender then return true end
	if self.gender == GENDER_NEUTRAL then return true end
	if gender == GENDER_NEUTRAL then return true end
	
	return self.gender != gender
end

function ENT:CanConnect(Con)
	if !IsValid(Con) then return false end
	if Con == self then return false end
	if !Con.__IsSW_Connector then return false end
	
	if !self:IsAllowedType(Con:GetType()) then return false end
	if !Con:IsAllowedType(self:GetType()) then return false end
	
	if !self:IsAllowedGender(Con:GetGender()) then return false end
	if !Con:IsAllowedGender(self:GetGender()) then return false end
	
	if self:IsConnected() then return false end
	if Con:IsConnected() then return false end

	return true
end

function ENT:GetConnectedEntity()
	if !IsValid(self.constraint) then return nil end
	if !IsValid(self.connected) then return nil end
	if self.connected == self then return nil end

	return self.connected
end

function ENT:GetConnectedConstraint()
	if !IsValid(self.constraint) then return nil end
	if !IsValid(self.connected) then return nil end
	if self.connected == self then return nil end

	return self.constraint
end

function ENT:IsConnected()
	if !IsValid(self.constraint) then return false end
	if !IsValid(self.connected) then return false end
	if self.connected == self then return false end

	return true
end

function ENT:IsConnectedWith(Con)
	if !IsValid(Con) then return false end
	if Con == self then return false end
	
	if IsValid(self.constraint) and IsValid(Con.constraint) then
		if self.constraint != Con.constraint then return false end
	end
	
	if self.connected != Con then return false end
	if Con.connected != self then return false end
	
	if self:OnConnectionCheck(Con) == false then return false end
	if Con:OnConnectionCheck(self) == false then return false end

	return true
end

function ENT:Connect(Con)
	if self:IsConnectedWith(Con) then return true end
	if !self:CanConnect(Con) then return false end

	self:SetPos(Con:GetPos())
	local WD = constraint.Weld(self, Con, 0, 0, 0, 0, false)
	
	if !IsValid(WD) then
		self:Disconnect(self, Con)
		return false
	end
	
	WD.DoNotDuplicate = true
	self.constraint = WD
	Con.constraint = WD
	
	self.connected = Con
	Con.connected = self

	self:OnConnect(Con)
	Con:OnConnect(self)
	return true
end

function ENT:Disconnect(Con)
	if !self:IsConnectedWith(Con) then return false end

	if IsValid(self.constraint) then
		self.constraint:Remove()
	end
	
	self.constraint = nil
	Con.constraint = nil

	self.connected = nil
	Con.connected = nil

	self:OnDisconnect(Con)
	Con:OnDisconnect(self)
	return true
end

function ENT:OnRemove()
	self:Disconnect(self.connected)
end

function ENT:Think()	
	if IsValid(self.connected) and !IsValid(self.constraint) then
		self:Disconnect(self.connected)
	end
	
	self:Debug()
end

function ENT:Debug(Size, Col, Time)
	if CLIENT then return end

	local pos = self:GetPos()
	Col = Col or color_white
	Size = Size or 4
	Time = Time or 0.33
	
	local kind = self.kind or ""
	if kind == "" then
		kind = "<none>"
	end
	
	local gender = self.gender or "Neutral"
	if gender == GENDER_MALE then
		gender = "Male"
	end
	
	if gender == GENDER_FEMALE then
		gender = "Female"
	end
	
	if gender == GENDER_NEUTRAL then
		gender = "Neutral"
	end
	
	local debugtext = tostring(self) .. ", " .. kind .. ", " .. gender
	debugoverlay.EntityTextAtPosition(pos, 0, debugtext, Time, Col)
	debugoverlay.Cross(pos, Size, Time, Col, true)
end

function ENT:OnConnectionCheck(Con)
	
end

function ENT:OnConnect(Con)

end

function ENT:OnDisconnect(Con)

end