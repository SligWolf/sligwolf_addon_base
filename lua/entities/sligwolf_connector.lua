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
local LIBCoupling = SligWolf_Addons.Coupling

function ENT:Initialize()
	BaseClass.Initialize(self)

	self.allowedtypes = nil
	self.gender = LIBCoupling.GENDER_NEUTRAL
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
	if gender == LIBCoupling.GENDER_MALE then
		self.gender = LIBCoupling.GENDER_MALE
		return
	end

	if gender == LIBCoupling.GENDER_FEMALE then
		self.gender = LIBCoupling.GENDER_FEMALE
		return
	end

	self.gender = LIBCoupling.GENDER_NEUTRAL
end

function ENT:GetGender()
	return self.gender
end

function ENT:IsAllowedGender(gender)
	if not self.gender then return true end
	if self.gender == LIBCoupling.GENDER_NEUTRAL then return true end
	if gender == LIBCoupling.GENDER_NEUTRAL then return true end

	return self.gender ~= gender
end

function ENT:CanConnect(other)
	if not IsValid(other) then return false end
	if other == self then return false end
	if not other.sligwolf_isConnector then return false end

	if not self:IsAllowedType(other:GetType()) then return false end
	if not other:IsAllowedType(self:GetType()) then return false end

	if not self:IsAllowedGender(other:GetGender()) then return false end
	if not other:IsAllowedGender(self:GetGender()) then return false end

	if self:IsConnected() then return false end
	if other:IsConnected() then return false end

	return true
end

function ENT:GetConnectedEntity()
	if not IsValid(self._constraint) then return nil end
	if not IsValid(self._connected) then return nil end
	if self._connected == self then return nil end

	return self._connected
end

function ENT:GetConnectedConstraint()
	if not IsValid(self._constraint) then return nil end
	if not IsValid(self._connected) then return nil end
	if self._connected == self then return nil end

	return self._constraint
end

function ENT:IsConnected()
	if not IsValid(self._constraint) then return false end
	if not IsValid(self._connected) then return false end
	if self._connected == self then return false end

	return true
end

function ENT:IsConnectedWith(other)
	if not IsValid(other) then return false end
	if other == self then return false end

	if self._connected ~= other then return false end
	if other._connected ~= self then return false end

	if self:OnConnectionCheck(other) == false then return false end
	if other:OnConnectionCheck(self) == false then return false end

	return true
end

function ENT:Connect(other)
	if self:IsConnectedWith(other) then return true end
	if not self:CanConnect(other) then return false end

	self:SetPos(other:GetPos())
	local WD = LIBConstraints.Weld(self, other, {nocollide = true})

	if not IsValid(WD) then
		self:Disconnect(self, other)
		return false
	end

	self._constraint = WD
	other._constraint = WD

	self._connected = other
	other._connected = self

	self:OnConnect(other)
	other:OnConnect(self)

	return true
end

function ENT:Disconnect(other)
	if not self:IsConnectedWith(other) then return false end

	if IsValid(self._constraint) then
		self._constraint:Remove()
	end

	self:OnDisconnect(other)
	other:OnDisconnect(self)

	self._constraint = nil
	other._constraint = nil

	self._connected = nil
	other._connected = nil

	self:OnPostDisconnect(other)
	other:OnPostDisconnect(self)

	return true
end

function ENT:OnRemove()
	BaseClass.OnRemove(self)

	self:Disconnect(self._connected)
end

function ENT:ThinkInternal()
	BaseClass.ThinkInternal(self)

	if IsValid(self._connected) and not IsValid(self._constraint) then
		self:Disconnect(self._connected)
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
	if gender == LIBCoupling.GENDER_MALE then
		gender = "Male"
	end

	if gender == LIBCoupling.GENDER_FEMALE then
		gender = "Female"
	end

	if gender == LIBCoupling.GENDER_NEUTRAL then
		gender = "Neutral"
	end

	local debugtext = tostring(self) .. ", " .. kind .. ", " .. gender

	debugoverlay.EntityTextAtPosition(pos, 0, debugtext, Time, Col)
	debugoverlay.Cross(pos, Size, Time, Col, true)
end

function ENT:OnConnectionCheck(other)
	-- override me
end

function ENT:OnConnect(other)
	-- override me
end

function ENT:OnDisconnect(other)
	-- override me
end

function ENT:OnPostDisconnect(other)
	-- override me
end