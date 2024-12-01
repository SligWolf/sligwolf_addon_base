AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

DEFINE_BASECLASS("sligwolf_phys")

ENT.Spawnable			= false
ENT.RenderGroup 		= RENDERGROUP_OPAQUE
ENT.DoNotDuplicate 		= true

ENT.sligwolf_isConnector = true

if not SligWolf_Addons then return end
if not SligWolf_Addons.IsLoaded then return end
if not SligWolf_Addons.IsLoaded() then return end

local LIBConstraints = SligWolf_Addons.Constraints

local GENDER_MALE = "M"
local GENDER_FEMALE = "F"
local GENDER_NEUTRAL = "N"

function ENT:Initialize()
	BaseClass.Initialize(self)

	self.allowedtypes = nil
	self.gender = GENDER_NEUTRAL
	self.kind = ""
end

function ENT:InitializePhysics()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	self:SetNotSolid(true)
end

function ENT:Draw()
	-- invisible
end

function ENT:DrawTranslucent()
	-- invisible
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
	if not self.allowedtypes then return true end

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
	if not self.gender then return true end
	if self.gender == GENDER_NEUTRAL then return true end
	if gender == GENDER_NEUTRAL then return true end

	return self.gender ~= gender
end

function ENT:CanConnect(Con)
	if not IsValid(Con) then return false end
	if Con == self then return false end
	if not Con.sligwolf_isConnector then return false end

	if not self:IsAllowedType(Con:GetType()) then return false end
	if not Con:IsAllowedType(self:GetType()) then return false end

	if not self:IsAllowedGender(Con:GetGender()) then return false end
	if not Con:IsAllowedGender(self:GetGender()) then return false end

	if self:IsConnected() then return false end
	if Con:IsConnected() then return false end

	return true
end

function ENT:GetConnectedEntity()
	if not IsValid(self.constraint) then return nil end
	if not IsValid(self.connected) then return nil end
	if self.connected == self then return nil end

	return self.connected
end

function ENT:GetConnectedConstraint()
	if not IsValid(self.constraint) then return nil end
	if not IsValid(self.connected) then return nil end
	if self.connected == self then return nil end

	return self.constraint
end

function ENT:IsConnected()
	if not IsValid(self.constraint) then return false end
	if not IsValid(self.connected) then return false end
	if self.connected == self then return false end

	return true
end

function ENT:IsConnectedWith(Con)
	if not IsValid(Con) then return false end
	if Con == self then return false end

	if IsValid(self.constraint) and IsValid(Con.constraint) then
		if self.constraint ~= Con.constraint then return false end
	end

	if self.connected ~= Con then return false end
	if Con.connected ~= self then return false end

	if self:OnConnectionCheck(Con) == false then return false end
	if Con:OnConnectionCheck(self) == false then return false end

	return true
end

function ENT:Connect(Con)
	if self:IsConnectedWith(Con) then return true end
	if not self:CanConnect(Con) then return false end

	self:SetPos(Con:GetPos())
	local WD = LIBConstraints.Weld(self, Con, {nocollide = true})

	if not IsValid(WD) then
		self:Disconnect(self, Con)
		return false
	end

	self.constraint = WD
	Con.constraint = WD

	self.connected = Con
	Con.connected = self

	self:OnConnect(Con)
	Con:OnConnect(self)

	return true
end

function ENT:Disconnect(Con)
	if not self:IsConnectedWith(Con) then return false end

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
	BaseClass.OnRemove(self)

	self:Disconnect(self.connected)
end

function ENT:ThinkInternal()
	BaseClass.ThinkInternal(self)

	if IsValid(self.connected) and not IsValid(self.constraint) then
		self:Disconnect(self.connected)
	end

	self:Debug()
end

function ENT:Debug(Size, Col, Time)
	if CLIENT then return end

	if not self:IsDeveloper() then
		return
	end

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

