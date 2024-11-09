AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Spawnmenu = SligWolf_Addons.Spawnmenu or {}
table.Empty(SligWolf_Addons.Spawnmenu)

local LIB = SligWolf_Addons.Spawnmenu

local LIBTimer = SligWolf_Addons.Timer
local LIBHook = SligWolf_Addons.Hook
local LIBUtil = SligWolf_Addons.Util

-- Tell the user something is wrong ("Broken") with the addons in case they see the usually hidden placeholder node.
local g_defaultNodeNameToBeRemoved = "SligWolf's Addons (Broken)"

local g_registeredSpawnMenuItems = {}
local g_registeredSpawnMenuItemsOrdered = {}
local g_registeredSpawnMenuItemsCategories = {}
local g_registeredSpawnMenuItemsCategoriesByAddons = {}

function LIB.AddSpawnMenuItemAddonCategory(addonName, itemClass, name, obj)
	addonName = tostring(addonName or "")
	if addonName == "" then
		error("no addonName")
		return
	end

	itemClass = tostring(itemClass or "")
	if itemClass == "" then
		error("no itemClass")
		return
	end

	name = tostring(name or "")
	if name == "" then
		error("no name")
		return
	end

	obj = obj or {}

	local order = tonumber(obj.order or 0) or 0

	local icon = tostring(obj.icon or "")
	if icon == "" then
		icon = "icon16/bricks.png"
	end

	local data = {
		name = name,
		itemClass = itemClass,
		order = order,
		icon = icon,
	}

	local oldData = LIB.GetSpawnMenuItemAddonCategory(itemClass, name)

	if oldData then
		for k, oldv in pairs(oldData) do
			local newv = data[k]

			if newv == oldv then
				continue
			end

			error(
				string.format(
					"conflict in spawnmenu item addon category '%s' for '%s', values at data['%s']: %s ~= %s",
					name,
					itemClass,
					k,
					oldv,
					newv
				)
			)

			return
		end
	end

	g_registeredSpawnMenuItemsOrdered[itemClass] = nil

	g_registeredSpawnMenuItemsCategories[itemClass] = g_registeredSpawnMenuItemsCategories[itemClass] or {}
	g_registeredSpawnMenuItemsCategories[itemClass][name] = data

	g_registeredSpawnMenuItemsCategoriesByAddons[addonName] = g_registeredSpawnMenuItemsCategoriesByAddons[addonName] or {}
	g_registeredSpawnMenuItemsCategoriesByAddons[addonName][itemClass] = g_registeredSpawnMenuItemsCategoriesByAddons[addonName][itemClass] or {}
	g_registeredSpawnMenuItemsCategoriesByAddons[addonName][itemClass][name] = data
end

function LIB.GetSpawnMenuItemAddonCategory(itemClass, addonCategory)
	itemClass = tostring(itemClass or "")
	if itemClass == "" then
		error("no itemClass")
		return nil
	end

	addonCategory = tostring(addonCategory or "")
	if addonCategory == "" then
		error("no addonCategory")
		return nil
	end

	if not g_registeredSpawnMenuItemsCategories[itemClass] then
		return nil
	end

	if not g_registeredSpawnMenuItemsCategories[itemClass][addonCategory] then
		return nil
	end

	return g_registeredSpawnMenuItemsCategories[itemClass][addonCategory]
end

function LIB.GetSpawnMenuItemAddonCategoriesForAddon(addonName, itemClass)
	addonName = tostring(addonName or "")
	if addonName == "" then
		error("no addonName")
		return nil
	end

	itemClass = tostring(itemClass or "")
	if itemClass == "" then
		error("no itemClass")
		return nil
	end

	if not g_registeredSpawnMenuItemsCategoriesByAddons[addonName] then
		return nil
	end

	if not g_registeredSpawnMenuItemsCategoriesByAddons[addonName][itemClass] then
		return nil
	end

	return g_registeredSpawnMenuItemsCategoriesByAddons[addonName][itemClass]
end

local function AddSpawnMenuItem(addonName, itemClass, obj)
	addonName = tostring(addonName or "")
	if addonName == "" then
		error("no addonName")
		return
	end

	itemClass = tostring(itemClass or "")
	if itemClass == "" then
		error("no itemClass")
		return
	end

	if not istable(obj) then
		error("no or bad obj")
		return
	end

	if not istable(obj.content) then
		error("obj has no or bad ContentData")
		return
	end

	local order = tonumber(obj.order or 0) or 0

	local data = {}

	data.addonName = addonName
	data.header = tostring(obj.header or "")
	data.itemClass = itemClass
	data.order = order
	data.content = obj.content

	g_registeredSpawnMenuItemsOrdered[itemClass] = nil

	g_registeredSpawnMenuItems[itemClass] = g_registeredSpawnMenuItems[itemClass] or {}
	table.insert(g_registeredSpawnMenuItems[itemClass], data)

	return data
end

function LIB.GetSpawnMenuItems(itemClass)
	return g_registeredSpawnMenuItems[itemClass]
end

local function sortByOrder(tab)
	tab = table.ClearKeys(tab)

	table.SortByMember(tab, "order", true)

	return tab
end

function LIB.GetSpawnMenuItemsOrdered(itemClass)
	if g_registeredSpawnMenuItemsOrdered[itemClass] then
		return g_registeredSpawnMenuItemsOrdered[itemClass]
	end

	local items = LIB.GetSpawnMenuItems(itemClass)
	if not items then
		return nil
	end

	local itemsOrderedInAddonCategories = {}

	for i, item in ipairs(items) do
		local addonName = item.addonName
		local header = item.header

		local addonCategories = LIB.GetSpawnMenuItemAddonCategoriesForAddon(addonName, itemClass) or {}

		for addonCategory, addonCategoryData in pairs(addonCategories) do
			local addonsByAddonCategory = itemsOrderedInAddonCategories[addonCategory]

			if not addonsByAddonCategory then
				addonsByAddonCategory = {
					addonCategory = {
						name = addonCategoryData.name,
						icon = addonCategoryData.icon,
					},
					order = addonCategoryData.order,
					addons = {},
				}

				itemsOrderedInAddonCategories[addonCategory] = addonsByAddonCategory
			end

			local addons = addonsByAddonCategory.addons

			local headersByAddon = addons[addonName]

			if not headersByAddon then
				local addonTitle = SligWolf_Addons.GetAddonTitle(addonName)

				if not addonTitle then
					addonTitle = addonName
				end

				headersByAddon = {
					addon = {
						name = addonName,
						title = addonTitle,
					},
					order = string.lower(addonTitle),
					headersCount = 0,
					headers = {},
				}

				addons[addonName] = headersByAddon
			end

			local headers = headersByAddon.headers
			local headersCount = headersByAddon.headersCount

			local itemsByHeader = headers[header]

			if not itemsByHeader then
				local headerName = header
				local headerOrder = headersCount

				if headerName == "" then
					headerOrder = -10000000
				end

				itemsByHeader = {
					header = {
						name = headerName,
					},
					order = headerOrder,
					items = {},
				}

				headers[header] = itemsByHeader
				headersByAddon.headersCount = headersCount + 1
			end

			table.insert(itemsByHeader.items, item)
		end
	end

	for addonCategory, addonsByAddonCategory in pairs(itemsOrderedInAddonCategories) do
		for addonName, headersByAddon in pairs(addonsByAddonCategory.addons) do
			for header, itemsByHeader in pairs(headersByAddon.headers) do
				itemsByHeader.items = sortByOrder(itemsByHeader.items)
			end

			headersByAddon.headers = sortByOrder(headersByAddon.headers)
		end

		addonsByAddonCategory.addons = sortByOrder(addonsByAddonCategory.addons)
	end

	itemsOrderedInAddonCategories = sortByOrder(itemsOrderedInAddonCategories)

	g_registeredSpawnMenuItemsOrdered[itemClass] = itemsOrderedInAddonCategories
	return g_registeredSpawnMenuItemsOrdered[itemClass]
end

local function CreateCategoryNode(tree, parentNode, name, icon, cookieName)
	if not ispanel(tree) then
		error("invalid tree panel")
		return
	end

	if not ispanel(parentNode) then
		error("invalid parentNode panel")
		return
	end

	name = tostring(name or "")
	if name == "" then
		error("no name")
		return
	end

	icon = tostring(icon or "")
	if icon == "" then
		error("no icon")
		return
	end

	cookieName = string.lower(tostring(cookieName or ""))
	if cookieName == "" then
		error("no cookieName")
		return
	end

	local node = parentNode:AddNode(name, icon)
	node.DoRightClick = function() end
	node.OnModified = function() end

	local oldSetExpanded = node.SetExpanded
	node.SetExpanded = function(thisNode, bExpand, bSurpressAnimation)
		oldSetExpanded(thisNode, bExpand, bSurpressAnimation)

		cookie.Set(cookieName, thisNode:GetExpanded() and 1 or 0)
	end

	node:SetExpanded(tobool(cookie.GetNumber(cookieName, 0)))

	node.DoClick = function(thisNode)
		tree:SetSelectedItem(nil)
		thisNode:SetExpanded(not thisNode:GetExpanded())
	end

	return node
end

local function CreateMainNode(tree, parentNode, itemClass)
	if not SligWolf_Addons then return end
	if not SligWolf_Addons.IsLoaded then return end
	if not SligWolf_Addons.IsLoaded() then return end

	local cookieName = string.format(
		"sligwolf_addons.spawnmenu.%s.main_node.expanded",
		itemClass
	)

	local name = "SligWolf's Addons"
	local icon = "icon16/sligwolf_base.png"

	local node = CreateCategoryNode(tree, parentNode, name, icon, cookieName)
	return node
end

local function CreateAddonCategoryNode(tree, parentNode, itemClass, addonCategoryData)
	if not istable(addonCategoryData) then
		error("invalid addonCategoryData")
		return
	end

	local name = addonCategoryData.name
	if not name then
		error("no name in addonCategoryData")
		return
	end

	local icon = addonCategoryData.icon
	if not icon then
		error("no icon in addonCategoryData")
		return
	end

	local cookieName = string.format(
		"sligwolf_addons.spawnmenu.%s.addon_category_node.%s.expanded",
		itemClass,
		name
	)

	local node = CreateCategoryNode(tree, parentNode, name, icon, cookieName)
	return node
end

local function CreateContentContainer(pnlContent)
	local container = vgui.Create("ContentContainer", pnlContent)
	container:SetVisible(false)
	container.IconList:SetReadOnly(true)

	return container
end

local function CreateContentContainerNode(pnlContent, parentNode, title, icon, contentContainerBuilder)
	if not ispanel(pnlContent) then
		error("invalid pnlContent panel")
		return
	end

	if not ispanel(parentNode) then
		error("invalid parentNode panel")
		return
	end

	title = tostring(title or "")
	if title == "" then
		error("no title")
		return
	end

	icon = tostring(icon or "")
	if icon == "" then
		error("no icon")
		return
	end

	if not isfunction(contentContainerBuilder) then
		error("invalid contentContainerBuilder")
		return
	end

	local node = parentNode:AddNode(title, icon)

	node.DoPopulate = function(thisNode)
		if thisNode.PropPanel then
			return
		end

		local propPanel = CreateContentContainer(pnlContent)
		thisNode.PropPanel = propPanel

		contentContainerBuilder(thisNode, propPanel)
	end

	node.DoClick = function(thisNode)
		thisNode:DoPopulate()
		pnlContent:SwitchPanel(thisNode.PropPanel)
	end

	return node
end

local function CreateAddonNode(pnlContent, parentNode, icon, addonDataWrap, buildFunction)
	if not istable(addonDataWrap) then
		error("invalid addonDataWrap")
		return
	end

	if not isfunction(buildFunction) then
		error("invalid buildFunction")
		return
	end

	local addon = addonDataWrap.addon
	local headers = addonDataWrap.headers

	if not istable(addon) then
		error("invalid addon in addonDataWrap")
		return
	end

	if not istable(headers) then
		error("invalid headers in addonDataWrap")
		return
	end

	local addonTitle = addon.title
	if not addonTitle then
		error("no title in addon")
		return
	end

	local headerBuilder = spawnmenu.GetContentType("header")

	local contentContainerBuilder = function(thisNode, propPanel)
		for _, itemsByHeader in ipairs(headers) do
			local header = itemsByHeader.header
			local headerName = tostring(header.name or "")

			if headerName ~= "" then
				headerBuilder(propPanel, {text = headerName})
			end

			for _, itemData in ipairs(itemsByHeader.items) do
				local item = itemData.content or {}

				buildFunction(thisNode, propPanel, item)
			end
		end
	end

	local node = CreateContentContainerNode(pnlContent, parentNode, addonTitle, icon, contentContainerBuilder)
	return node
end

local function PopulateSpawnmenuListContent(pnlContent, tree, itemClass, icon, buildFunction)
	local itemsOrderedInAddonCategories = LIB.GetSpawnMenuItemsOrdered(itemClass)

	if not itemsOrderedInAddonCategories or table.IsEmpty(itemsOrderedInAddonCategories) then
		return
	end

	local mainNode = CreateMainNode(tree, tree, cookieName)

	if not IsValid(mainNode) then
		return
	end

	for _, addonsByAddonCategory in ipairs(itemsOrderedInAddonCategories) do
		local addonCategoryData = addonsByAddonCategory.addonCategory
		local addonCategoryAddons = addonsByAddonCategory.addons

		if table.IsEmpty(addonCategoryAddons) then
			continue
		end

		local addonCategoryNode = CreateAddonCategoryNode(tree, mainNode, itemClass, addonCategoryData)

		for _, headersByAddon in ipairs(addonCategoryAddons) do
			CreateAddonNode(pnlContent, addonCategoryNode, icon, headersByAddon, buildFunction)
		end
	end
end

local function RemoveDefaultNode(treePanel)
	if not IsValid(treePanel) then
		return
	end

	LIBTimer.SimpleNextFrame(function()
		if not IsValid(treePanel) then
			return
		end

		if not treePanel.Root then
			return
		end

		local rootNode = treePanel:Root()
		if not IsValid(rootNode) then
			return
		end

		local nodes = rootNode:GetChildNodes()

		for _, node in ipairs(nodes) do
			if not IsValid(node) then
				continue
			end

			if node:GetText() ~= g_defaultNodeNameToBeRemoved then
				continue
			end

			node:Remove()
			break
		end
	end)
end

function LIB.AddPlayerModel(name, playerModel, vHandsModel, skin, bodygroup)
	name = tostring(name or "")
	if name == "" then
		error("no name")
		return
	end

	playerModel = tostring(playerModel or "")
	if playerModel == "" then
		error("no valid playerModel")
		return
	end

	vHandsModel = tostring(vHandsModel or "")
	if vHandsModel == "" then
		error("no valid vHandsModel")
		return
	end

	skin = tonumber(skin or 0)
	bodygroup = tostring(bodygroup or "00000000")

	player_manager.AddValidModel(name, playerModel)
	player_manager.AddValidHands(name, vHandsModel, skin, bodygroup)
end

local g_PropOrder = 0

function LIB.AddProp(addonname, model, obj)
	addonname = tostring(addonname or "")
	if addonname == "" then
		error("no addonname")
		return
	end

	model = tostring(model or "")
	if model == "" then
		error("no valid model")
		return
	end

	obj = obj or {}

	g_PropOrder = (g_PropOrder % 1000000) + 1

	if not obj.hidden then
		AddSpawnMenuItem(
			addonname,
			"prop",
			{
				order = obj.order or g_PropOrder * 100,
				header = obj.header,
				content = {
					model = model,
					skin = tonumber(obj.skin or 0) or 0,
					bodygroup = tostring(obj.bodygroup or "00000000"),
				}
			}
		)
	end
end

local function PopulateProplistContent(pnlContent, tree)
	PopulateSpawnmenuListContent(
		pnlContent,
		tree,
		"prop",
		"icon16/page.png",
		function(node, propPanel, item)
			spawnmenu.CreateContentIcon("model", propPanel, {
				model = item.model,
				skin = item.skin,
				body = item.bodygroup,
			})
		end
	)
end

LIBHook.Add("PopulateContent", "Library_Spawnmenu_PopulateProplistContent", PopulateProplistContent, 20000)

local g_EntityOrder = 0

local function g_SENTSetup(ply, sent)
	if not IsValid(sent) then return end
	if not sent.sligwolf_baseEntity then return end

	local entTable = sent:SligWolf_GetTable()
	if entTable.isDuped then return end

	local spawnname = sent:GetSpawnName()
	if not spawnname then return end

	local tab = LIBUtil.GetList("SpawnableEntities")
	local data = tab[spawnname]

	if not data then return end
	if not data.Is_SLIGWOLF then return end

	local addonname = data.SLIGWOLF_Addonname or ""
	sent:SetAddonID(addonname)

	local data_custom = data.SLIGWOLF_Custom or {}
	sent:SetSpawnProperties(data_custom)

	local dupedata = {}
	dupedata.spawnname = spawnname

	duplicator.StoreEntityModifier(sent, "SLIGWOLF_Common_SENTDupe", dupedata)
end

local function g_SENTDupe(ply, sent, data)
	if not IsValid(sent) then return end
	if not sent.sligwolf_baseEntity then return end

	if not data then return end
	if not data.spawnname then return end

	sent.spawnname = data.spawnname

	g_SENTSetup(ply, sent)

	local entTable = sent:SligWolf_GetTable()
	entTable.isDuped = true
end

local g_entityAliases = {}

function LIB.AddEntityAlias(alias, class)
	alias = tostring(alias or "")
	if alias == "" then
		error("no alias")
		return
	end

	class = tostring(class or "")
	if class == "" then
		error("no class")
		return
	end

	if alias == class then
		return
	end

	if g_entityAliases[alias] == class then
		return
	end

	g_entityAliases[alias] = class
	scripted_ents.Alias(alias, class)
	duplicator.Allow(alias)
end

function LIB.GetEntityClassFromAlias(alias)
	alias = tostring(alias or "")
	if alias == "" then
		return
	end

	local class = g_entityAliases[alias]
	if class == "" then
		return
	end

	if class == alias then
		return
	end

	return class
end

function LIB.GetEntityAliasList()
	local result = {}

	for alias, class in pairs(g_entityAliases) do
		if alias == class then
			continue
		end

		result[alias] = class
	end

	return result
end

function LIB.AddEntity(addonname, spawnname, obj)
	addonname = tostring(addonname or "")
	if addonname == "" then
		error("no addonname")
		return
	end

	spawnname = tostring(spawnname or "")
	if spawnname == "" then
		error("no spawnname")
		return
	end

	obj = obj or {}

	g_EntityOrder = (g_EntityOrder % 1000000) + 1

	if not obj.hidden then
		AddSpawnMenuItem(
			addonname,
			"entity",
			{
				order = obj.order or g_EntityOrder * 100,
				header = obj.header,
				content = {
					title = obj.title or spawnname,
					spawnName = spawnname,
					adminOnly = obj.adminOnly or false,
					icon = obj.icon,
				}
			}
		)
	end

	local SpawnableEntities = LIBUtil.GetList("SpawnableEntities")
	if not SpawnableEntities then return end

	local entityItem = table.Copy(SpawnableEntities[spawnName] or {})

	entityItem.PrintName = entityItem.PrintName or tostring(obj.title or spawnname)
	entityItem.ClassName = entityItem.ClassName or obj.class or spawnname
	entityItem.Model = entityItem.Model or tostring(obj.model or "")
	entityItem.Category = g_defaultNodeNameToBeRemoved

	entityItem.Is_SLIGWOLF = true
	entityItem.SLIGWOLF_Addonname = addonname
	entityItem.SLIGWOLF_Hidden = hidden

	local keyValues = table.Copy(obj.keyValues or {})

	entityItem.KeyValues = keyValues
	entityItem.KeyValues.sligwolf_spawnname = spawnname

	entityItem.SLIGWOLF_Custom = table.Copy(obj.customProperties or {})

	list.Set("SpawnableEntities", spawnname, entityItem)

	LIB.AddEntityAlias(spawnname, entityItem.ClassName)

	LIBHook.Add("PlayerSpawnedSENT", "Library_Spawnmenu_SENTSetup", g_SENTSetup, 2000)

	duplicator.RegisterEntityModifier("SLIGWOLF_Common_SENTDupe", g_SENTDupe)
end

local function PopulateEntitylistContent(pnlContent, tree)
	PopulateSpawnmenuListContent(
		pnlContent,
		tree,
		"entity",
		"icon16/bricks.png",
		function(node, propPanel, item)
			spawnmenu.CreateContentIcon("entity", propPanel, {
				nicename = item.title,
				spawnname = item.spawnName,
				material = item.icon or "entities/" .. item.spawnName .. ".png",
				admin = item.adminOnly
			})
		end
	)

	RemoveDefaultNode(tree)
end

LIBHook.Add("PopulateEntities", "Library_Spawnmenu_PopulateEntitylistContent", PopulateEntitylistContent, 20000)

local g_WeaponOrder = 0

function LIB.AddWeapon(addonname, spawnname, obj)
	addonname = tostring(addonname or "")
	if addonname == "" then
		error("no addonname")
		return
	end

	spawnname = tostring(spawnname or "")
	if spawnname == "" then
		error("no spawnname")
		return
	end

	obj = obj or {}

	g_WeaponOrder = (g_WeaponOrder % 1000000) + 1

	if not obj.hidden then
		AddSpawnMenuItem(
			addonname,
			"weapon",
			{
				order = obj.order or g_WeaponOrder * 100,
				header = obj.header,
				content = {
					title = obj.title or spawnname,
					spawnName = spawnname,
					adminOnly = obj.adminOnly or false,
					icon = obj.icon,
				}
			}
		)
	end

	local SpawnableWeapons = LIBUtil.GetList("Weapon")
	if not SpawnableWeapons then return end

	local weaponItem = table.Copy(SpawnableWeapons[spawnName] or {})

	weaponItem.PrintName = weaponItem.PrintName or tostring(obj.title or spawnname)
	weaponItem.ClassName = weaponItem.ClassName or obj.class or spawnname
	weaponItem.Category = g_defaultNodeNameToBeRemoved

	weaponItem.Is_SLIGWOLF = true
	weaponItem.SLIGWOLF_Addonname = addonname
	weaponItem.SLIGWOLF_Hidden = hidden

	local keyValues = table.Copy(obj.keyValues or {})

	weaponItem.KeyValues = keyValues
	weaponItem.KeyValues.sligwolf_spawnname = spawnname

	weaponItem.SLIGWOLF_Custom = table.Copy(obj.customProperties or {})

	list.Set("Weapon", spawnname, weaponItem)
end

local function PopulateWeaponlistContent(pnlContent, tree)
	PopulateSpawnmenuListContent(
		pnlContent,
		tree,
		"weapon",
		"icon16/gun.png",
		function(node, propPanel, item)
			spawnmenu.CreateContentIcon("weapon", propPanel, {
				nicename = item.title,
				spawnname = item.spawnName,
				material = item.icon or "entities/" .. item.spawnName .. ".png",
				admin = item.adminOnly
			})
		end
	)

	RemoveDefaultNode(tree)
end

LIBHook.Add("PopulateWeapons", "Library_Spawnmenu_PopulateWeaponlistContent", PopulateWeaponlistContent, 20000)

local function g_NPCSetup(ply, npc)
	if not IsValid(npc) then return end

	local spawnname = npc.NPCName
	if not spawnname then return end

	local tab = LIBUtil.GetList("NPC")
	local data = tab[spawnname]

	if not data then return end
	if not data.Is_SLIGWOLF then return end

	local data_custom = data.SLIGWOLF_Custom or {}

	if data_custom.Accuracy then
		npc:SetCurrentWeaponProficiency(data_custom.Accuracy)
	end

	if data_custom.Blood then
		npc:SetBloodColor(data_custom.Blood)
	end

	if data_custom.Color then
		npc:SetColor(data_custom.Color)
	end

	local func = data_custom.OnSpawn
	if isfunction(func) then
		func(npc, data)
	end

	npc.Is_SLIGWOLF_Addon = true
end

local g_NpcOrder = 0

function LIB.AddNPC(addonname, spawnname, obj)
	addonname = tostring(addonname or "")
	if addonname == "" then
		error("no addonname")
		return
	end

	spawnname = tostring(spawnname or "")
	if spawnname == "" then
		error("no spawnname")
		return
	end

	obj = obj or {}

	g_NpcOrder = (g_NpcOrder % 1000000) + 1

	if not obj.hidden then
		AddSpawnMenuItem(
			addonname,
			"npc",
			{
				order = obj.order or g_NpcOrder * 100,
				header = obj.header,
				content = {
					title = obj.title or spawnname,
					spawnName = spawnname,
					adminOnly = obj.adminOnly or false,
					icon = obj.icon,
					weapons = obj.weapons,
				}
			}
		)
	end

	local npcListItem = {}

	npcListItem.Name = tostring(obj.title or spawnname)
	npcListItem.Class = obj.class or "npc_citizen"
	npcListItem.Model = obj.model
	npcListItem.Skin = obj.skin
	npcListItem.Category = g_defaultNodeNameToBeRemoved
	npcListItem.Weapons = obj.weapons
	npcListItem.Health = obj.health
	npcListItem.OnDuplicated = obj.onDuplicated

	npcListItem.Is_SLIGWOLF = true
	npcListItem.SLIGWOLF_Addonname = addonname
	npcListItem.SLIGWOLF_Hidden = hidden

	npcListItem.SpawnFlags = obj.spawnFlags
	npcListItem.KeyValues = table.Copy(obj.keyValues or {})
	npcListItem.SLIGWOLF_Custom = table.Copy(obj.customProperties or {})

	list.Set("NPC", spawnname, npcListItem)

	LIBHook.Add("PlayerSpawnedNPC", "Library_Spawnmenu_NPCSetup", g_NPCSetup, 20000)
end

local function PopulateNPClistContent(pnlContent, tree)
	PopulateSpawnmenuListContent(
		pnlContent,
		tree,
		"npc",
		"icon16/monkey.png",
		function(node, propPanel, item)
			spawnmenu.CreateContentIcon("npc", propPanel, {
				nicename = item.title,
				spawnname = item.spawnName,
				material = item.icon or "entities/" .. item.spawnName .. ".png",
				admin = item.adminOnly,
				weapon = item.weapons,
			})
		end
	)

	RemoveDefaultNode(tree)
end

LIBHook.Add("PopulateNPCs", "Library_Spawnmenu_PopulateNPClistContent", PopulateNPClistContent, 20000)

local g_VehicleOrder = 0

function LIB.AddVehicle(addonname, spawnname, vehiclescript, obj)
	addonname = tostring(addonname or "")
	if addonname == "" then
		error("no addonname")
		return
	end

	spawnname = tostring(spawnname or "")
	if spawnname == "" then
		error("no spawnname")
		return
	end

	vehiclescript = tostring(vehiclescript or "")
	if vehiclescript == "" then
		error("no vehiclescript")
		return
	end

	obj = obj or {}

	local model = tostring(obj.model or "")
	if model == "" then
		error("no model")
		return
	end

	g_VehicleOrder = (g_VehicleOrder % 1000000) + 1

	if not obj.hidden then
		AddSpawnMenuItem(
			addonname,
			"vehicle",
			{
				order = obj.order or g_VehicleOrder * 100,
				header = obj.header,
				content = {
					title = obj.title or spawnname,
					spawnName = spawnname,
					adminOnly = obj.adminOnly or false,
					icon = obj.icon,
				}
			}
		)
	end

	local vehicleListItem = {}

	local members = table.Copy(obj.members or {})
	local keyValues = table.Copy(obj.keyValues or {})

	vehicleListItem.Name = tostring(obj.title or spawnname)
	vehicleListItem.Class = obj.class or "prop_vehicle_prisoner_pod"
	vehicleListItem.Category = g_defaultNodeNameToBeRemoved
	vehicleListItem.Model = model

	vehicleListItem.Is_SLIGWOLF = true
	vehicleListItem.SLIGWOLF_Addonname = addonname
	vehicleListItem.SLIGWOLF_Hidden = hidden

	vehicleListItem.Members = members

	vehicleListItem.KeyValues = keyValues
	vehicleListItem.KeyValues.vehiclescript = vehiclescript
	vehicleListItem.KeyValues.limitview = tobool(keyValues.limitview) and 1 or 0

	vehicleListItem.SLIGWOLF_Custom = table.Copy(obj.customProperties or {})

	list.Set("Vehicles", spawnname, vehicleListItem)
end

local function PopulateVehiclelistContent(pnlContent, tree)
	PopulateSpawnmenuListContent(
		pnlContent,
		tree,
		"vehicle",
		"icon16/car.png",
		function(node, propPanel, item)
			spawnmenu.CreateContentIcon("vehicle", propPanel, {
				nicename = item.title,
				spawnname = item.spawnName,
				material = item.icon or "entities/" .. item.spawnName .. ".png",
				admin = item.adminOnly,
			})
		end
	)

	RemoveDefaultNode(tree)
end

LIBHook.Add("PopulateVehicles", "Library_Spawnmenu_PopulateVehiclelistContent", PopulateVehiclelistContent, 20000)

return true

