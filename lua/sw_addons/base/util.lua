AddCSLuaFile()

if !SW_Addons then
	return
end

if !SW_ADDON then
	SW_Addons.AutoLoadAddon(function() end)
	return
end

function SW_ADDON:ValidateName(name)
	name = tostring(name or "")
	name = string.gsub(name, "^!", "", 1)
	name = string.gsub(name, "[\\/]", "")
	return name
end

function SW_ADDON:IsValidModel(ent)
	if !IsValid(ent) then return false end
	
	local model = tostring(ent:GetModel() or "")
	if model == "" then return false end
	
	model = Model(model)
	if !util.IsValidModel(model) then return false end
	
	return true
end

local matcache = {}
function SW_ADDON:SW_HUD_Texture(PNGname, RGB, TexX, TexY, W, H)
	local texturedata = matcache[PNGname]

	if texturedata then
		texturedata.color = RGB
		texturedata.x = TexX
		texturedata.y = TexY
		texturedata.w = W
		texturedata.h = H
   
		return texturedata
	end

	matcache[PNGname] = { Textur = Material(PNGname), color=RGB, x=TexX, y=TexY, w=W, h=H }
	return matcache[PNGname]
end

function SW_ADDON:DrawMaterial(texturedata)
	surface.SetMaterial(texturedata.Textur)
	surface.DrawTexturedRect(texturedata.x, texturedata.y, texturedata.w, texturedata.h)
end

function SW_ADDON:ChangeMat(ent, num, mat)
	if !IsValid(ent) then return end
	num = tonumber(num or 0)
	mat = tostring(mat or "")
	
	ent:SetSubMaterial(num, mat)
end

function SW_ADDON:AddFont(name, data)
	if !CLIENT then return nil end
	
	name = tostring(name or "")
	if name == "" then return nil end

	name = self.NetworkaddonID .. "_" .. name
	
	self.cachedfonts = self.cachedfonts or {}
	if self.cachedfonts[name] then return name end
	
	self.cachedfonts[name] = true

	surface.CreateFont(name, data)
	return name
end

function SW_ADDON:GetFont(name)
	if !CLIENT then return nil end
	
	name = tostring(name or "")
	if name == "" then return nil end
	
	name = self.NetworkaddonID .. "_" .. name
	if !self.cachedfonts[name] then return nil end
	
	return name
end