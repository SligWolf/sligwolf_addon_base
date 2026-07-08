local SligWolf_Addons = _G.SligWolf_Addons
if not SligWolf_Addons then
	return
end

local LIB = SligWolf_Addons:NewLib("Util")

local CONSTANTS = SligWolf_Addons.Constants

local LIBEntities = SligWolf_Addons.Entities
local LIBTimer = SligWolf_Addons.Timer

local g_uid = 0
function LIB.Uid()
	g_uid = (g_uid + 1) % (2 ^ 30)
	return g_uid
end

local g_order = 0
function LIB.Order()
	g_order = (g_order + 1) % 10000000

	local order = -100000000 + g_order
	return order
end

function LIB.EmptyTableSafe(tab)
	if not tab then
		return
	end

	table.Empty(tab)
end

local g_IsValidTextureCache = {}
local g_IsValidTextureFileCache = {}

function LIB.IsValidTextureFile(path)
	path = tostring(path or "")

	if g_IsValidTextureFileCache[path] then
		return true
	end

	g_IsValidTextureFileCache[path] = nil

	if path == "" then
		return false
	end

	if not file.Exists(path, "GAME") then
		return false
	end

	g_IsValidTextureFileCache[path] = true
	return true
end

function LIB.LoadPngMaterial(path, params, fallbackPath)
	path = tostring(path or "")
	params = tostring(params or "")
	fallbackPath = tostring(fallbackPath or "")

	local err = CONSTANTS.matPngError

	if path == "" then
		path = err
	end

	if fallbackPath == "" then
		fallbackPath = err
	end

	if path == err then
		path = fallbackPath
	end

	if path == fallbackPath then
		fallbackPath = err
	end

	local cacheId = string.format("%s_%s_%s", path, fallbackPath, params)

	if g_IsValidTextureCache[cacheId] ~= nil then
		local mat = g_IsValidTextureCache[cacheId]
		if not mat then
			return nil
		end

		return mat
	end

	g_IsValidTextureCache[cacheId] = false

	if not LIB.IsValidTextureFile(path) then
		local mat = LIB.LoadPngMaterial(fallbackPath, err, params)

		if not mat or mat:IsError() then
			return nil
		end

		g_IsValidTextureCache[cacheId] = mat
		return mat
	end

	local mat = Material(path, params)
	if not mat or mat:IsError() then
		mat = LIB.LoadPngMaterial(fallbackPath, err, params)

		if not mat or mat:IsError() then
			return nil
		end
	end

	g_IsValidTextureCache[cacheId] = mat
	return mat
end

local g_MatCache = {}

function LIB.GetMaterialData(PNGname, RGB, TexX, TexY, W, H)
	local texturedata = g_MatCache[PNGname]

	if texturedata then
		texturedata.color = RGB
		texturedata.x = TexX
		texturedata.y = TexY
		texturedata.w = W
		texturedata.h = H

		return texturedata
	end

	g_MatCache[PNGname] = {Textur = Material(PNGname), color = RGB, x = TexX, y = TexY, w = W, h = H}
	return g_MatCache[PNGname]
end

function LIB.DrawMaterial(texturedata)
	surface.SetMaterial(texturedata.Textur)
	surface.DrawTexturedRect(texturedata.x, texturedata.y, texturedata.w, texturedata.h)
end

function LIB.ChangeSubMaterial(ent, num, mat)
	if not IsValid(ent) then return end
	num = tonumber(num or 0)
	mat = tostring(mat or "")

	ent:SetSubMaterial(num, mat)
end

function LIB.SetDFrameButtonProperties(ent, posx, posy, sizex, sizey, text, cmd, target)
	if not IsValid(ent) then return end

	posx = tonumber(posx or 0)
	posy = tonumber(posy or 0)
	sizex = tonumber(sizex or 0)
	sizey = tonumber(sizey or 0)
	text = tostring(text or "")
	cmd = tostring(cmd or "")

	ent:SetPos(posx, posy)
	ent:SetSize(sizex, sizey)
	ent:SetText(text)

	if ent:GetClassName() ~= "Label" then return end
	if not isfunction(ent.SetConsoleCommand) then return end
	ent:SetConsoleCommand("say", cmd)
end

function LIB.GameIsPaused()
	local frametime = FrameTime()

	if frametime > 0 then
		return false
	end

	return true
end

local function entitySpawnSorterAsc(a, b)
	local ctA = a:GetCreationTime()
	local ctB = b:GetCreationTime()

	if ctA == ctB then
		return a:GetCreationID() < b:GetCreationID()
	end

	return ctA < ctB
end

local function entitySpawnSorterDesc(a, b)
	local ctA = a:GetCreationTime()
	local ctB = b:GetCreationTime()

	if ctA == ctB then
		return a:GetCreationID() > b:GetCreationID()
	end

	return ctA > ctB
end

function LIB.SortEntitiesBySpawn(entities, asc)
	local func = asc and entitySpawnSorterAsc or entitySpawnSorterDesc
	table.sort(entities, func)
end

function LIB.CountEntities(entities)
	local i = 0

	for _, ent in pairs(entities) do
		if not IsValid(ent) then
			continue
		end

		i = i + 1
	end

	return i
end

function LIB.GetList(name)
	local listItem = list.GetForEdit(name)
	return listItem
end

function LIB.CheckSumOfFile(filePath, gamePath)
	local data = file.Read(filePath, gamePath)
	if not data then
		return nil
	end

	if data == "" then
		return nil
	end

	local hash = util.SHA256(data)
	return hash
end

function LIB.DeduplicateTable(array)
	local seen = {}
	local result = {}

	for _, v in ipairs(array) do
		if seen[v] then
			continue
		end

		table.insert(result, v)
		seen[v] = true
	end

	return result
end

function LIB.FlashWindow()
	-- This helps detecting load time behavour if the game is unfocused.
	-- This is only active if the code has been reloaded.
	-- If it blinks, the game is ready for testing.

	if not CLIENT then
		return
	end

	if LIB.IsEarly() then
		-- We don't want to blink during load time.
		return
	end

	local timerName = "Library_Util_FlashWindow"
	LIBTimer.Remove(timerName)

	if system.HasFocus() then
		return
	end

	-- Debounce the flash effect by a frame and 2 x 0.1 sec
	LIBTimer.NextFrame(timerName, function()
		if system.HasFocus() then
			return
		end

		LIBTimer.Once(timerName, 0.1, function()
			if system.HasFocus() then
				return
			end

			LIBTimer.Once(timerName, 0.1, function()
				if system.HasFocus() then
					return
				end

				system.FlashWindow()
			end)
		end)
	end)
end

function LIB.IsEarly()
	-- Detects if we are early in the game, e.g:
	--  It is sill starting up the map.
	--  It just started up the map.

	if not LIBTimer then
		return true
	end

	if UnPredictedCurTime() < 10 then
		return true
	end

	return false
end

local g_createCacheArrayMeta = LIB.g_createCacheArrayMeta or {}
LIB.g_createCacheArrayMeta = g_createCacheArrayMeta

do
	function g_createCacheArrayMeta:Set(cacheid, data, expires)
		if cacheid == nil then
			return
		end

		if data == nil then
			self:Remove(cacheid)
			return
		end

		if self.limit > 0 and self.count > self.limit then
			self:Empty()
		end

		local cache = self.cache
		local cacheItem = cache[cacheid]

		if not cacheItem then
			cacheItem = {}
			cache[cacheid] = cacheItem

			self.count = self.count + 1
		end

		cacheItem.data = data
		cacheItem.expires = expires
	end

	function g_createCacheArrayMeta:Get(cacheid, now)
		if cacheid == nil then
			return nil
		end

		local cache = self.cache
		local cacheItem = cache[cacheid]

		if not cacheItem then
			return nil
		end

		local data = cacheItem.data
		if data == nil then
			self:Remove(cacheid)
			return nil
		end

		now = now or 0
		local expires = cacheItem.expires or 0

		if now > 0 and expires > 0 and expires < now then
			self:Remove(cacheid)
			return nil
		end

		return data
	end

	function g_createCacheArrayMeta:Remove(cacheid)
		if cacheid == nil then
			return
		end

		local cache = self.cache
		if cache[cacheid] == nil then
			return
		end

		cache[cacheid] = nil
		self.count = math.max(self.count - 1, 0)
	end

	function g_createCacheArrayMeta:Has(cacheid, now)
		return self:Get(cacheid, now) ~= nil
	end

	function g_createCacheArrayMeta:Empty()
		LIB.EmptyTableSafe(self.cache)
		self.count = 0
	end

	function g_createCacheArrayMeta:Count()
		return self.count
	end

	g_createCacheArrayMeta.__index = g_createCacheArrayMeta
end

function LIB.CreateCacheArray(limit)
	local cache = {}

	cache.cache = {}
	cache.limit = math.max(limit or 0, 0)
	cache.count = 0

	setmetatable(cache, g_createCacheArrayMeta)

	return cache
end

local g_createEntityLookupMeta = LIB.g_createEntityLookupMeta or {}
LIB.g_createEntityLookupMeta = g_createEntityLookupMeta

do
	local function _GetID(this, entOrId)
		if not entOrId then
			return nil
		end

		local id = nil

		if isnumber(entOrId) or isstring(entOrId) then
			id = entOrId
		else
			if not IsValid(entOrId) then
				return nil
			end

			id = this.idGetterFunc(entOrId)
		end

		if not id then
			return nil
		end

		return id
	end

	function g_createEntityLookupMeta:Add(ent)
		if not IsValid(ent) then
			return
		end

		local id = _GetID(self, ent)
		if not id then
			return
		end

		local lookup = self.lookup
		local lookupReverse = self.lookupReverse

		if lookup[id] then
			return
		end

		lookup[id] = ent
		lookupReverse[ent] = id

		self.count = self.count + 1

		LIBEntities.CallOnRemove(ent, "EntityLookup_" .. self.name, function(thisent, withEffect)
			if withEffect then
				return
			end

			self:Remove(thisent)
		end)
	end

	function g_createEntityLookupMeta:Remove(entOrId)
		local id = _GetID(self, entOrId)
		if not id then
			return
		end

		local lookup = self.lookup
		local lookupReverse = self.lookupReverse

		local ent = lookup[id]
		lookup[id] = nil

		if ent then
			lookupReverse[ent] = nil
			self.count = math.max(self.count - 1, 0)
		end

		if IsValid(ent) then
			LIBEntities.RemovCallOnRemove(ent, "EntityLookup_" .. self.name)
		end
	end

	function g_createEntityLookupMeta:Get(entOrId)
		local id = _GetID(self, entOrId)
		if not id then
			return nil
		end

		local ent = self.lookup[id]
		if not IsValid(ent) then
			self:Remove(id)
			return nil
		end

		return ent
	end

	function g_createEntityLookupMeta:Has(entOrId)
		return self:Get(entOrId) ~= nil
	end

	function g_createEntityLookupMeta:Empty(self)
		local lookup = self.lookup
		local lookupReverse = self.lookupReverse

		for id, _ in pairs(lookup) do
			self:Remove(id)
		end

		for _, id in pairs(lookupReverse) do
			self:Remove(id)
		end

		LIB.EmptyTableSafe(lookup)
		LIB.EmptyTableSafe(lookupReverse)

		self.count = 0
	end

	function g_createEntityLookupMeta:Count(self)
		return self.count
	end

	g_createEntityLookupMeta.__index = g_createEntityLookupMeta
end

function LIB.CreateEntityLookup(name, idGetterFunc)
	if not name then
		error("name is missing")
		return nil
	end

	if not idGetterFunc then
		error("idGetterFunc is missing")
		return nil
	end

	local lookup = {}

	lookup.lookup = {}
	lookup.lookupReverse = {}
	lookup.count = 0
	lookup.name = name
	lookup.idGetterFunc = idGetterFunc

	setmetatable(lookup, g_createEntityLookupMeta)

	return lookup
end

function LIB.Load()
	LIBEntities = SligWolf_Addons.Entities
	LIBTimer = SligWolf_Addons.Timer
end

return true

