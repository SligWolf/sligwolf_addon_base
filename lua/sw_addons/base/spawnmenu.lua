AddCSLuaFile()

if !SW_Addons then
	return
end

if !SW_ADDON then
	SW_Addons.AutoLoadAddon(function() end)
	return
end

function SW_ADDON:Add_Items(name, listname, model, class, skin)
	class = tostring(class or "prop_physics")
	skin = tonumber(skin or 0)
	
	local NormalOffset = nil
	local DropToFloor = nil
	
	if (class != "prop_ragdoll") then
		NormalOffset = 64
		DropToFloor = true
	end

	list.Set("SpawnableEntities", name, { 
		PrintName = listname, 
		ClassName = class, 
		Category = "SligWolf's Props",
		
		NormalOffset = NormalOffset,
		DropToFloor = DropToFloor,

		KeyValues = {
			model = model,
			skin = skin,
			addonname = self.Addonname,
		}
	})
end

function SW_ADDON:AddPlayerModel(name, player_model, vhands_model, skin, bodygroup)
	player_model = tostring(player_model or "")
	vhands_model = tostring(vhands_model or "")
	name = tostring(name or player_model)
	skin = tonumber(skin or 0)
	bodygroup = tostring(bodygroup or "00000000")

	if player_model == "" then return end
	
	player_manager.AddValidModel(name, player_model)

	if vhands_model == "" then return end
	player_manager.AddValidHands(name, vhands_model, skin, bodygroup)
end

local function NPC_Setup(ply, npc)
	if !IsValid(npc) then return end
	if npc.__IsSW_Duped then return end
	
	local kv = npc:GetKeyValues()
	local name = kv["classname"] or ""
	
	local tab = list.Get("NPC")
	local data = tab[name]
	if !data then return end
	if !data.IsSW then return end
	
	local data_custom = data.SW_Custom or {}
	
	if data_custom.Accuracy then
		npc:SetCurrentWeaponProficiency(data_custom.Accuracy)
	end
	
	if data_custom.Health then
		npc:SetHealth(data_custom.Health)
	end
	
	if data_custom.Blood then
		npc:SetBloodColor(data_custom.Blood)
	end
	
	if data_custom.Color then
		npc:SetColor(data_custom.Color)
	end
	
	if data_custom.Owner then
		npc.Owner = ply
	end
	
	local func = data_custom.OnSpawn
	if isfunction(func) then
		func(npc, data)
	end
	
	npc.__IsSW_Addon = true
	npc.__IsSW_Class = name
	
	local class = tostring(data.Class or "Corrupt Class!")
	npc:SetKeyValue("classname", class)
	
	local dupedata = {}
	dupedata.customclass = name
	
	duplicator.StoreEntityModifier(npc, "SW_Common_NPC_Dupe", dupedata) 
end

local function NPC_Dupe(ply, npc, data)
	if !IsValid(npc) then return end
	if !data then return end
	if !data.customclass then return end

	npc:SetKeyValue("classname", data.customclass)
	NPC_Setup(ply, npc)
	npc.__IsSW_Duped = true
end

function SW_ADDON:Add_NPC(name, npc)
	name = tostring(name or "")
	if name == "" then return end
	npc = npc or {}

	npc.Name = npc.Name or "SligWolf - Generic"
	npc.Class = npc.Class or "npc_citizen"
	npc.Category = npc.Category or "SligWolf's NPC's"
	npc.Skin = npc.Skin or 0
	npc.KeyValues = npc.KeyValues or {}
	npc.IsSW = true
	
	-- Workaround to get back to custom NPC classname from the spawned NPC
	npc.KeyValues.classname = name

	npc.SW_Custom = npc.SW_Custom or {}
	list.Set("NPC", name, npc)

	hook.Remove("PlayerSpawnedNPC", "SW_Common_NPC_Setup")
	hook.Add("PlayerSpawnedNPC", "SW_Common_NPC_Setup", NPC_Setup)
	duplicator.RegisterEntityModifier("SW_Common_NPC_Dupe", NPC_Dupe)
	
	if CLIENT then
		language.Add(name, npc.Name)
	end
end