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
local LIBEntities = SligWolf_Addons.Entities

local function isButtom(ent)
	local name = LIBEntities.GetName(ent)
	local md5 = util.MD5(name)

	md5 = string.sub(md5, 0, 4)
	md5 = tonumber(md5, 16)

	local top = (md5 % 2) == 0
	return top
end

function ENT:Initialize()
	BaseClass.Initialize(self)

	self._allowedTypes = nil
	self._gender = LIBCoupling.GENDER_NEUTRAL
	self._kind = ""
	self._isButtom = false
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
	self._allowedTypes = nil
end

function ENT:AllowType(kind)
	kind = tostring(kind or "")
	if kind == "" then return end

	self._allowedTypes = self._allowedTypes or {}
	self._allowedTypes[kind] = true
end

function ENT:DisallowType(kind)
	kind = tostring(kind or "")
	if kind == "" then return end

	self._allowedTypes = self._allowedTypes or {}
	self._allowedTypes[kind] = nil
end

function ENT:IsAllowedType(kind)
	if not self._allowedTypes then return true end

	return self._allowedTypes[kind]
end

function ENT:SetType(kind)
	kind = tostring(kind or "")
	if kind == "" then return end

	self._kind = kind

	self._allowedTypes = nil
	self:AllowType(self._kind)
end

function ENT:GetType()
	return self._kind
end

function ENT:IsButtom()
	return self._isButtom
end

function ENT:SetGender(gender)
	if gender == LIBCoupling.GENDER_MALE then
		self._gender = LIBCoupling.GENDER_MALE
		return
	end

	if gender == LIBCoupling.GENDER_FEMALE then
		self._gender = LIBCoupling.GENDER_FEMALE
		return
	end

	self._gender = LIBCoupling.GENDER_NEUTRAL
end

function ENT:GetGender()
	return self._gender
end

function ENT:IsAllowedGender(gender)
	if not self._gender then return true end
	if self._gender == LIBCoupling.GENDER_NEUTRAL then return true end
	if gender == LIBCoupling.GENDER_NEUTRAL then return true end

	return self._gender ~= gender
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

	self._isButtom = isButtom(self)
	other._isButtom = isButtom(other)

	if self._isButtom == other._isButtom then
		-- ensure we never have the same buttom state
		self._isButtom = not other._isButtom
	end

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

	self._isButtom = false
	other._isButtom = false

	self:OnPostDisconnect(other)
	other:OnPostDisconnect(self)

	return true
end

function ENT:OnRemove()
	BaseClass.OnRemove(self)

	self:Disconnect(self._connected)

	self._isButtom = false
end

function ENT:ThinkInternal()
	BaseClass.ThinkInternal(self)

	local connected = self._connected
	local connectedConstraint = self._constraint

	if IsValid(connected) and not IsValid(connectedConstraint) then
		self:Disconnect(connected)
	end

	self:Debug()
end

local g_colDisconnected = Color(255, 255, 255)
local g_colConnected = Color(175, 255, 175)

function ENT:Debug()
	if CLIENT then return end

	if not self:IsDeveloper() then
		return
	end

	local color = g_colDisconnected

	if self:IsConnected() then
		color = g_colConnected
	end

	local pos = self:GetPos()
	local size = 4
	local time = 0.33
	local line = self:IsButtom() and 1 or 0

	local kind = self._kind or ""
	if kind == "" then
		kind = "<none>"
	end

	local gender = self._gender

	if gender == LIBCoupling.GENDER_MALE then
		gender = "Male"
	end

	if gender == LIBCoupling.GENDER_FEMALE then
		gender = "Female"
	end

	if gender == LIBCoupling.GENDER_NEUTRAL then
		gender = "Neutral"
	end

	local debugtext = string.format(
		"%-33s | %s, %s, %s",
		tostring(self),
		LIBEntities.GetName(self),
		kind,
		gender
	)

	debugoverlay.EntityTextAtPosition(pos, line, debugtext, time, color)
	debugoverlay.Cross(pos, size, time, color, true)
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