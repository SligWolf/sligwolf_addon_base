AddCSLuaFile()

if !SW_Addons then
	return
end

if !SW_ADDON then
	SW_Addons.AutoLoadAddon(function() end)
	return
end

function SW_ADDON:MakeEnt(classname, ply, parent, name)
    local ent = ents.Create(classname)
	
    if !IsValid(ent) then return end
	ent.__SW_Vars = ent.__SW_Vars or {}
	self:SetName(ent, name)
	self:SetParent(ent, parent)
	
	if ent.__IsSW_Entity then
		ent:SetAddonID(self.Addonname)
	end
	
	ent.__swAddonname = self.Addonname

    if !ent.CPPISetOwner then return ent end
    if !IsValid(ply) then return ent end

    ent:CPPISetOwner(ply)
    return ent
end

function SW_ADDON:SetupChildEntity(ent, parent, collision, attachmentid)
	if !IsValid(ent) then return end
	if !IsValid(parent) then return end
	
	collision = collision or COLLISION_GROUP_NONE
	attachmentid = tonumber(attachmentid or 0)
	
	ent:Spawn()
	ent:Activate()
	ent:SetParent(parent, attachmentid)
	ent:SetCollisionGroup(collision)
	ent:SetMoveType(MOVETYPE_NONE)
	ent.DoNotDuplicate = true
	parent:DeleteOnRemove(ent)

	local phys = ent:GetPhysicsObject()
	if !IsValid(phys) then return ent end
	phys:Sleep()
	
	return ent
end

function SW_ADDON:ConstraintIsAllowed(ent, ply, mode)
	if !IsValid(ent) then return false end
	if !IsValid(ply) then return false end
	
	mode = tostring(mode or "")
	mode = string.lower(mode)
	
	if mode == "" then
		mode = "weld"
	end
	
	local allowtool = true
	
	if ent.CPPICanTool then
		allowtool = ent:CPPICanTool(ply, mode) or false
	end
	
	if !allowtool then return false end
	return true
end

function SW_ADDON:AddToEntList(name, ent)
	name = tostring(name or "")

	self.ents = self.ents or {}
	self.ents[name] = self.ents[name] or {}
	
	if IsValid(ent) then
		self.ents[name][ent] = true
	else
		self.ents[name][ent] = nil
	end
end

function SW_ADDON:RemoveFromEntList(name, ent)
	name = tostring(name or "")

	self.ents = self.ents or {}
	self.ents[name] = self.ents[name] or {}
	self.ents[name][ent] = nil
end

function SW_ADDON:RemoveEntites(tb)
	tb = tb or {}
	if !istable(tb) then return end
	
	for k,v in pairs(tb) do
		if !IsValid(v) then continue end
		v:Remove()
	end
end

function SW_ADDON:GetAllFromEntList(name)
	name = tostring(name or "")

	self.ents = self.ents or {}
	return self.ents[name] or {}
end

function SW_ADDON:ForEachInEntList(name, func)
	if !isfunction(func) then return end
	name = tostring(name or "")
	
	local entlist = self:GetAllFromEntList(name)
	
	local index = 1
	for k, v in pairs(entlist) do
		if !IsValid(k) then
			entlist[k] = nil
			continue
		end
		
		local bbreak = func(self, index, k)
		if bbreak == false then
			break
		end
		
		index = index + 1
	end
end

function SW_ADDON:GetName(ent)
	if !IsValid(ent) then return end
	if !ent.__SW_Vars then return "" end
	
	return self:ValidateName(ent.__SW_Vars.Name)
end

function SW_ADDON:SetName(ent, name)
	if !IsValid(ent) then return end
	if !ent.__SW_Vars then return end
	local vars = ent.__SW_Vars
	
	name = self:ValidateName(name)
	if name == "" then
		name = tostring(util.CRC(tostring(ent)))
	end
	
	local oldname = self:GetName(ent)
	vars.Name = name
	
	local parent = self:GetParent(ent)
	if !IsValid(parent) then return end
	
	parent.__SW_Vars = parent.__SW_Vars or {}
	local vars_parent = parent.__SW_Vars

	vars_parent.ChildrenENTs = vars_parent.ChildrenENTs or {}
	vars_parent.ChildrenENTs[oldname] = nil
	vars_parent.ChildrenENTs[name] = ent
end

function SW_ADDON:GetVal(ent, name, default)
    if !IsValid(ent) then return end
	
	local superparent = self:GetSuperParent(ent) or ent
    if !IsValid(superparent) then return end

	local path = self:GetEntityPath(ent)
	
	superparent.__SW_Vars = superparent.__SW_Vars or {}
	local vars = superparent.__SW_Vars
	
	name = self:ValidateName(name)
	name = self.NetworkaddonID .. "/" .. path .. "/!" .. name

	local data = vars.Data or {}
	local value = data[name]
	
	if value == nil then
		value = default 
	end
	
	return value
end

function SW_ADDON:SetVal(ent, name, value)
    if !IsValid(ent) then return end
	
	local superparent = self:GetSuperParent(ent) or ent
    if !IsValid(superparent) then return end

	local path = self:GetEntityPath(ent)
	
	superparent.__SW_Vars = superparent.__SW_Vars or {}
	local vars = superparent.__SW_Vars
	
	name = self:ValidateName(name)
	name = self.NetworkaddonID .. "/" .. path .. "/!" .. name
	
	vars.Data = vars.Data or {}
	vars.Data[name] = value
end

function SW_ADDON:SetupDupeModifier(ent, name, precopycallback, postcopycallback)
    if !IsValid(ent) then return end

	name = self:ValidateName(name)
    if name == "" then return end

	local superparent = self:GetSuperParent(ent) or ent
    if !IsValid(superparent) then return end

	superparent.__SW_Vars = superparent.__SW_Vars or {}
	local vars = superparent.__SW_Vars
	
    if vars.duperegistered then return end
	
    if !isfunction(precopycallback) then
		precopycallback = (function() end)
	end
	
	if !isfunction(postcopycallback) then
		postcopycallback = (function() end)
	end
	
	local oldprecopy = superparent.PreEntityCopy or (function() end)
	local dupename = "SW_Common_MakeEnt_Dupe_" .. self.NetworkaddonID  .. "_" .. name
	vars.dupename = dupename
	
	superparent.PreEntityCopy = function(...)
		if IsValid(superparent) then
			precopycallback(superparent)
		end
		
		vars.Data = vars.Data or {}
		duplicator.StoreEntityModifier(superparent, dupename, vars.Data)
		
		return oldprecopy(...)
	end
	vars.duperegistered = true

	self.duperegistered = self.duperegistered or {}
    if self.duperegistered[dupename] then return end
	
	duplicator.RegisterEntityModifier(dupename, function(ply, ent, data)
		if !IsValid(ent) then return end
		
		-- delay the dupe modifier 2 frames late, as the main spawn function is already delayed
		timer.Simple(0, function()
			if !IsValid(ent) then return end

			timer.Simple(0, function()
			if !IsValid(ent) then return end
				
				local superparent = self:GetSuperParent(ent) or ent
				if !IsValid(superparent) then return end

				superparent.__SW_Vars = superparent.__SW_Vars or {}
				local vars = superparent.__SW_Vars
				
				vars.Data = data or {}
				
				if IsValid(superparent) then
					postcopycallback(superparent)
				end
			end)
		end)
	end)
	
	self.duperegistered[dupename] = true
end

function SW_ADDON:GetParent(ent)
	if !IsValid(ent) then return end
	if !ent.__SW_Vars then return end
	local vars = ent.__SW_Vars

    if !IsValid(vars.ParentENT) then return end
	if vars.ParentENT == ent then return end

	return vars.ParentENT
end

function SW_ADDON:SetParent(ent, parent)
	if !IsValid(ent) then return end
	if !ent.__SW_Vars then return end

	if parent == ent then
		parent = nil
	end
	
	local vars = ent.__SW_Vars

	vars.ParentENT = parent
	vars.SuperParentENT = self:GetSuperParent(ent)

	parent = self:GetParent(ent)
	if !IsValid(parent) then return end
	
	parent.__SW_Vars = parent.__SW_Vars or {}
	local vars_parent = parent.__SW_Vars

	local name = self:GetName(ent)
	vars_parent.ChildrenENTs = vars_parent.ChildrenENTs or {}
	vars_parent.ChildrenENTs[name] = ent
end

function SW_ADDON:GetSuperParent(ent)
	if !IsValid(ent) then return end
	if !ent.__SW_Vars then return end

	local vars = ent.__SW_Vars
	
	if IsValid(vars.SuperParentENT) and (vars.SuperParentENT != ent) then
		return vars.SuperParentENT
	end
	
	if !IsValid(vars.ParentENT) then
		return ent
	end
	
	vars.SuperParentENT = self:GetSuperParent(vars.ParentENT)
	if vars.SuperParentENT == ent then return end
    if !IsValid(vars.SuperParentENT) then return end
	
	return vars.SuperParentENT
end

function SW_ADDON:GetEntityPath(ent)
	if !IsValid(ent) then return end
	
	local name = self:GetName(ent)
	local parent = self:GetParent(ent)
	
	if !IsValid(parent) then
		return name
	end
	
	local parent_name = self:GetName(parent)
	name = parent_name .. "/" .. name
	
	return name
end

function SW_ADDON:GetChildren(ent)
	if !IsValid(ent) then return end
	if !ent.__SW_Vars then return end

	return ent.__SW_Vars.ChildrenENTs or {}
end

function SW_ADDON:GetChild(ent, name)
	local children = self:GetChildren(ent)
	if !children then return end
	
	local child = children[name]
	if !IsValid(child) then return end
	
	if self:GetParent(child) != ent then
		children[name] = nil
		return
	end
	
	return child
end

function SW_ADDON:GetChildFromPath(ent, path)
	path = tostring(path or "")
	local hirachy = string.Explode("/", path, false) or {}
	
	local curchild = ent
	for k, v in pairs(hirachy) do
		curchild = self:GetChild(curchild, v)
		if !IsValid(curchild) then return end
	end
	
	return curchild
end

function SW_ADDON:FindChildAtPath(ent, path)
	path = tostring(path or "")
	local hirachy = string.Explode("/", path, false) or {}
	local lastindex = #hirachy
	
	local curchild = ent
	for k, v in ipairs(hirachy) do
		if k >= lastindex then
			return self:FindChildren(curchild, v)
		end
		
		curchild = self:GetChild(curchild, v)
		if !IsValid(curchild) then return {} end
	end
	
	return {}
end

function SW_ADDON:ForEachFilteredChild(ent, name, func)
	if !IsValid(ent) then return end
	if !isfunction(func) then return end
	
	local found = self:FindChildAtPath(ent, name)
	local index = 0
	
	for k, v in pairs(found) do
		index = index + 1
		local bbreak = func(ent, index, k, v)
		if bbreak then break end
	end
end

function SW_ADDON:FindChildren(ent, name)
	local children = self:GetChildren(ent)
	if !children then return {} end
	
	name = tostring(name or "")
	
	local found = {}
	for k, v in pairs(children) do
		if !IsValid(v) then continue end
		if !string.find(k, name) then continue end
		found[k] = v
	end
	
	return found
end

function SW_ADDON:FindPropInSphere(ent, radius, attachment, filterA, filterB)
	if !IsValid(ent) then return nil end
	radius = tonumber(radius or 10)
	filterA = tostring(filterA or "none")
	filterB = tostring(filterB or "none")
	
	local new_ent = nil

	local pos = self:GetAttachmentPosAng(ent, attachment)
	local objs = ents.FindInSphere(pos, radius) or {}
	
	for k,v in pairs(objs) do
		if !IsValid(v) then continue end
		local mdl = v:GetModel()
		if mdl == filterA or mdl == filterB then
			new_ent = v
			return new_ent
		end
	end
	
	return nil
end