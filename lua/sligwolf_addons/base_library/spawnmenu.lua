local SligWolf_Addons = _G.SligWolf_Addons
if not SligWolf_Addons then
	return
end

local LIB = SligWolf_Addons:NewLib("Spawnmenu")

local LIBTimer = nil
local LIBHook = nil
local LIBUtil = nil

-- Tell the user something is wrong ("Broken") with the addons in case they see the usually hidden placeholder node.
local g_defaultNodeNameToBeRemoved = "SligWolf's Addons (Broken)"

local g_registeredSpawnMenuItems = {}
local g_registeredSpawnMenuItemsUnique = {}
local g_registeredSpawnMenuItemsOrdered = {}
local g_registeredSpawnMenuItemsCategories = {}
local g_registeredSpawnMenuItemsCategoriesByAddons = {}

local g_lastSpawnMenuState = LIB.g_lastSpawnMenuState or {}
LIB.g_lastSpawnMenuState = g_lastSpawnMenuState

local g_tabPanelIndex = g_lastSpawnMenuState.tabPanelIndex or {}
g_lastSpawnMenuState.tabPanelIndex = g_tabPanelIndex

local g_spawnmenuLoaded = SligWolf_Addons.WasReloaded

LIB.g_RegisterdVehicleSpawnnamesByModel = {}

local g_AddonContentContainers = {}

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

	local id = obj.id
	if not id then
		error("obj has no id")
		return
	end

	local content = obj.content
	if not istable(content) then
		error("obj has no or bad ContentData")
		return
	end

	local header = tostring(obj.header or "")
	local order = tonumber(obj.order or 0) or 0

	local data = {}

	data.addonName = addonName
	data.header = header
	data.itemClass = itemClass
	data.order = order
	data.content = content

	data.content.addonName = addonName

	local uniqueid = {
		"uniqueid",
		addonName,
		header,
		itemClass,
		id,
		content.skin or "",
		content.bodygroup or "",
	}

	uniqueid = table.concat(uniqueid, "_")
	uniqueid = util.MD5(uniqueid)

	data.uniqueid = uniqueid

	local items = g_registeredSpawnMenuItems[itemClass] or {}
	g_registeredSpawnMenuItems[itemClass] = items

	local uniqueItems = g_registeredSpawnMenuItemsUnique[itemClass] or {}
	g_registeredSpawnMenuItemsUnique[itemClass] = uniqueItems

	g_registeredSpawnMenuItemsOrdered[itemClass] = nil

	local replaceIndex = uniqueItems[uniqueid]
	if replaceIndex then
		-- If the item already exist, replace it with the updated data
		local oldData = items[replaceIndex]

		if oldData then
			table.CopyFromTo(data, oldData)
		else
			replaceIndex = nil
		end
	end

	if not replaceIndex then
		replaceIndex = table.insert(items, data)
		uniqueItems[uniqueid] = replaceIndex
	end

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

local function BuildTabPanelIndex(creationMenu)
	if not table.IsEmpty(g_tabPanelIndex) then
		return g_tabPanelIndex
	end

	local tabs = creationMenu:GetCreationTabs()

	for _, tab in pairs(tabs) do
		local name = tab.Name

		local panel = tab.Panel
		if not IsValid(panel) then
			continue
		end

		local tabPanel = tab.Tab
		if not IsValid(tabPanel) then
			continue
		end

		g_tabPanelIndex[panel] = {
			name = name,
			panel = panel,
			tabPanel = tabPanel,
		}
	end

	return g_tabPanelIndex
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

	local containerDivider = vgui.Create("DVerticalDivider", pnlContent)

	local container = vgui.Create("ContentContainer")
	container.IconList:SetReadOnly(true)
	container:SetVisible(true)

	containerDivider:SetTop(container)
	containerDivider:SetVisible(false)

	local height = 100000
	containerDivider:SetTopMin(height)
	containerDivider:SetTopMax(height)
	containerDivider:SetTopHeight(height)

	containerDivider:SetBottomMin(0)
	containerDivider:SetDividerHeight(0)

	containerDivider.sligwolf_container = container
	container.sligwolf_containerDivider = containerDivider

	local dragBar = containerDivider.m_DragBar
	dragBar.Paint = function() end

	return container, containerDivider
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
	node.sligwolf_id = nil

	node.DoPopulate = function(thisNode)
		if IsValid(thisNode.sligwolf_propPanelDivider) then
			return
		end

		local titleId = thisNode.sligwolf_titleId
		if not titleId then
			return
		end

		local propPanelDivider = g_AddonContentContainers[titleId]
		local propPanel = nil

		if IsValid(propPanelDivider) then
			thisNode.sligwolf_propPanelDivider = propPanelDivider
			return
		end

		propPanel, propPanelDivider = CreateContentContainer(pnlContent)

		thisNode.sligwolf_propPanelDivider = propPanelDivider
		g_AddonContentContainers[titleId] = propPanelDivider

		contentContainerBuilder(thisNode, propPanel)
	end

	node.DoClick = function(thisNode)
		if not IsValid(pnlContent) then
			return
		end

		g_lastSpawnMenuState.lastNodeId = nil

		thisNode:DoPopulate()

		local propPanelDivider = thisNode.sligwolf_propPanelDivider
		if not IsValid(propPanelDivider) then
			return
		end

		pnlContent:SwitchPanel(propPanelDivider)

		g_lastSpawnMenuState.lastNodeId = thisNode.sligwolf_id
	end

	LIBTimer.SimpleNextFrame(function()
		if not IsValid(pnlContent) then
			return
		end

		if not IsValid(parentNode) then
			return
		end

		if not IsValid(node) then
			return
		end

		local tabContainer = pnlContent:GetParent()
		if not IsValid(tabContainer) then
			return
		end

		local creationMenu = tabContainer:GetParent()
		if not IsValid(creationMenu) then
			return
		end

		local tabIndex = BuildTabPanelIndex(creationMenu)
		local tabItem = tabIndex[tabContainer]

		if not tabItem then
			return
		end

		local tabPanel = tabItem.tabPanel
		if not IsValid(tabPanel) then
			return
		end

		local pnlContentTitle = tabItem and tabItem.name or ""
		local parentTitle = parentNode:GetText()
		local nodeTitle = node:GetText()

		local id = string.format("id_%s_%s_%s", pnlContentTitle, parentTitle, nodeTitle)
		id = util.MD5(id)

		local titleId = string.format("id_%s_%s", pnlContentTitle, nodeTitle)
		titleId = util.MD5(titleId)

		node.sligwolf_id = id
		node.sligwolf_titleId = titleId

		if g_lastSpawnMenuState.lastNodeId and id == g_lastSpawnMenuState.lastNodeId then
			g_lastSpawnMenuState.lastNodeId = nil

			creationMenu:SetActiveTab(tabPanel)
			parentNode:SetExpanded(true)
			node:SetExpanded(true)

			node:InternalDoClick()
		end
	end)

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
				id = model,
				order = obj.order or g_PropOrder * 100,
				header = obj.header,
				content = {
					model = model,
					skin = tonumber(obj.skin or 0) or 0,
					bodygroup = tostring(obj.bodygroup or "00000000"),
				}
			}
		)

		LIB.RequestReloadSpawnmenu()
	end
end

local function g_SENTSetup(ply, sent)
	if not IsValid(sent) then return end
	if not sent.sligwolf_baseEntity then return end

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

	duplicator.StoreEntityModifier(sent, "SLIGWOLF_Library_Spawnmenu_SENTDupe", dupedata)
end

local function g_SENTDupe(ply, sent, data)
	if not IsValid(sent) then return end
	if not sent.sligwolf_baseEntity then return end

	if not data then return end
	if not data.spawnname then return end

	sent.spawnname = data.spawnname
	g_SENTSetup(ply, sent)
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

local g_EntityOrder = 0

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

	local hidden = obj.hidden or false
	if not hidden then
		AddSpawnMenuItem(
			addonname,
			"entity",
			{
				id = spawnname,
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

		LIB.RequestReloadSpawnmenu()
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

	duplicator.RegisterEntityModifier("SLIGWOLF_Library_Spawnmenu_SENTDupe", g_SENTDupe)
end

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

	local hidden = obj.hidden or false
	if not hidden then
		AddSpawnMenuItem(
			addonname,
			"weapon",
			{
				id = spawnname,
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

		LIB.RequestReloadSpawnmenu()
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

	g_NpcOrder = (g_NpcOrder % 1000000) + 1

	obj = obj or {}

	local hidden = obj.hidden or false
	if not hidden then
		AddSpawnMenuItem(
			addonname,
			"npc",
			{
				id = spawnname,
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

		LIB.RequestReloadSpawnmenu()
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

	if not LIB.g_RegisterdVehicleSpawnnamesByModel[model] then
		LIB.g_RegisterdVehicleSpawnnamesByModel[model] = spawnname
	end

	local hidden = obj.hidden or false
	if not hidden then
		AddSpawnMenuItem(
			addonname,
			"vehicle",
			{
				id = spawnname,
				order = obj.order or g_VehicleOrder * 100,
				header = obj.header,
				content = {
					title = obj.title or spawnname,
					spawnName = spawnname,
					adminOnly = obj.adminOnly or false,
					icon = obj.icon,
					trainOptions = obj.trainOptions,
				}
			}
		)

		LIB.RequestReloadSpawnmenu()
	end

	local spawnFreezed = obj.spawnFreezed or false

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
	vehicleListItem.SLIGWOLF_Spawnname = spawnname
	vehicleListItem.SLIGWOLF_SpawnFreezed = spawnFreezed

	vehicleListItem.Members = members

	vehicleListItem.KeyValues = keyValues
	vehicleListItem.KeyValues.vehiclescript = vehiclescript
	vehicleListItem.KeyValues.limitview = tobool(keyValues.limitview) and 1 or 0

	vehicleListItem.SLIGWOLF_Custom = table.Copy(obj.customProperties or {})

	list.Set("Vehicles", spawnname, vehicleListItem)
end

function LIB.ReloadSpawnmenu()
	if not CLIENT then
		return
	end

	RunConsoleCommand("spawnmenu_reload")
end

function LIB.RequestReloadSpawnmenu()
	if not CLIENT then
		return
	end

	if not g_spawnmenuLoaded then
		-- Avoid reloading the spawn menu if it has not been loaded yet
		return
	end

	local timerName = "Library_Spawnmenu_RequestReloadSpawnmenu_Debounce"
	LIBTimer.Once(timerName, 0.1, function()
		if not g_spawnmenuLoaded then
			return
		end

		LIB.ReloadSpawnmenu()
	end)
end

if CLIENT then
	spawnmenu.AddContentType("sligwolf_train", function(container, obj)
		if not obj.material then return end
		if not obj.nicename then return end
		if not obj.spawnname then return end

		local icon = vgui.Create("ContentIcon", container)

		icon:SetContentType("vehicle")
		icon:SetSpawnName(obj.spawnname)
		icon:SetName(obj.nicename)
		icon:SetMaterial(obj.material)
		icon:SetAdminOnly(obj.admin)
		icon:SetColor(Color(0, 0, 0, 255))

		local toolTip = language.GetPhrase(obj.nicename)

		local trainOptions = trainOptions or {}

		-- Generate a nice tooltip with extra info
		local VehInfo = list.GetEntry("Vehicles", obj.spawnname)
		if VehInfo then
			local extraInfo = ""
			if VehInfo.Information and VehInfo.Information ~= "" then extraInfo = extraInfo .. "\n" .. VehInfo.Information end
			if VehInfo.Author and VehInfo.Author ~= "" then extraInfo = extraInfo .. "\n" .. language.GetPhrase("entityinfo.author") .. " " .. VehInfo.Author end
			if #extraInfo > 0 then toolTip = toolTip .. "\n" .. extraInfo end
		end

		icon:SetTooltip(toolTip)
		icon.DoClick = function()
			-- @TODO: Add auto gauge detection from trainOptions

			print("this is a train", obj.spawnname)

			RunConsoleCommand("gm_spawnvehicle", obj.spawnname)
			surface.PlaySound("ui/buttonclickrelease.wav")
		end

		icon.OpenMenuExtra = function(self, menu)
			-- @TODO: Add gauge options from trainOptions

			menu:AddOption("#spawnmenu.menu.spawn_with_toolgun", function()
				RunConsoleCommand("gmod_tool", "creator")
				RunConsoleCommand("creator_type", "1")
				RunConsoleCommand("creator_name", obj.spawnname)
			end):SetIcon("icon16/brick_add.png")
		end

		icon.OpenMenu = icon.OpenGenericSpawnmenuRightClickMenu

		if IsValid(container) then
			container:Add(icon)
		end

		return icon
	end)
end

local function AddExtraContent(propPanel, addonname)
	if propPanel.sligwolf_extraHasContent then
		return
	end

	propPanel.sligwolf_extraHasContent = true

	LIBTimer.SimpleNextFrame(function()
		if not IsValid(propPanel) then
			return
		end

		local containerDivider = propPanel.sligwolf_containerDivider
		if not IsValid(containerDivider) then
			return
		end

		local colorSkinPicker = vgui.Create("SligWolf_ColorSkinPicker")

		for a = 1, 10 do
			colorSkinPicker:AddOption("teat" .. a, {
				icon = "entities/sligwolf_help.png",
			})
		end

		containerDivider:SetBottom(colorSkinPicker)

		containerDivider:SetDividerHeight(16)
		containerDivider:SetBottomMin(0)

		containerDivider:DoConstraints()

		propPanel.sligwold_oldPerformLayout = propPanel.sligwold_oldPerformLayout or propPanel.PerformLayout
		propPanel.PerformLayout = function(this, w, h, ...)
			this.sligwold_oldPerformLayout(this, w, h, ...)

			if not IsValid(containerDivider) then
				return
			end

			local height = containerDivider:GetTall()

			if height <= 200 then
				return
			end

			local topMin = math.Clamp(height - 200, 0, height)
			local topMax = height
			local topHeight = math.Clamp(height - 100, topMin, height)

			containerDivider:SetTopMin(topMin)
			containerDivider:SetTopMax(topMax)
			containerDivider:SetTopHeight(topHeight)

			this.PerformLayout = this.sligwold_oldPerformLayout or this.PerformLayout
		end

		local dragBar = containerDivider.m_DragBar
		local dragBarSkin = dragBar:GetSkin()

		dragBar.Paint = function(_, w, h)
			local lineH = math.floor(h / 6)
			local lineW = math.min(math.floor(w * 0.95), w - lineH * 4)

			local lineX = math.floor((w - lineW) / 2)
			local lineY1 = lineH * 3
			local lineY2 = h - lineH * 3

			local fgColor = dragBarSkin.Colours.Label.Default

			surface.SetDrawColor(0, 0, 0, 120)
			surface.DrawRect(lineX + 1, lineY1 + 1, lineW, lineH)
			surface.SetDrawColor(fgColor)
			surface.DrawRect(lineX, lineY1, lineW, lineH)

			surface.SetDrawColor(0, 0, 0, 120)
			surface.DrawRect(lineX + 1, lineY2 + 1, lineW, lineH)
			surface.SetDrawColor(fgColor)
			surface.DrawRect(lineX, lineY2, lineW, lineH)
		end

		propPanel:InvalidateLayout()
	end)
end

-- local function test()
-- 	local testName = "aaaaaaaaaaaaaaaaaaa"

-- 	LIBTimer.NextFrame(testName, function()
-- 		local frame = _G.sw_frame

-- 		if IsValid(frame) then
-- 			frame:Remove()
-- 		end

-- 		frame = vgui.Create("DFrame")
-- 		_G.sw_frame = frame

-- 		local colorSkinPicker = vgui.Create("SligWolf_ColorSkinPicker", frame)

-- 		colorSkinPicker:Dock(FILL)

-- 		local num = vgui.Create("DNumSlider", frame)
-- 		num:SetTall(30)
-- 		num:SetDecimals(0)
-- 		num:SetMinMax(1, 100)

-- 		num:Dock(BOTTOM)

-- 		frame:SetSize(300, 300)
-- 		frame:SetSizable(true)
-- 		frame:MakePopup()

-- 		function num:OnValueChanged()
-- 			LIBTimer.Once(testName, 0.1, function()
-- 				if not IsValid(num) then
-- 					return
-- 				end

-- 				if not IsValid(colorSkinPicker) then
-- 					return
-- 				end

-- 				local value = math.Round(num:GetValue())

-- 				colorSkinPicker:Clear()

-- 				for a = 1, value do
-- 					colorSkinPicker:AddOption("teat" .. a, {
-- 						icon = "entities/sligwolf_help.png",
-- 					})
-- 				end
-- 			end)
-- 		end

-- 		num:OnValueChanged()
-- 	end)
-- end

function LIB.Load()
	LIBTimer = SligWolf_Addons.Timer
	LIBHook = SligWolf_Addons.Hook
	LIBUtil = SligWolf_Addons.Util

	-- if CLIENT then
	-- 	xpcall(test, ErrorNoHaltWithStack)
	-- end

	local function PopulatePropListContent(pnlContent, tree)
		g_spawnmenuLoaded = true
		table.Empty(g_tabPanelIndex)

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

	local function PopulateEntityListContent(pnlContent, tree)
		g_spawnmenuLoaded = true
		table.Empty(g_tabPanelIndex)

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

				AddExtraContent(propPanel, item.addonName)
			end
		)

		RemoveDefaultNode(tree)
	end

	local function PopulateWeaponListContent(pnlContent, tree)
		g_spawnmenuLoaded = true
		table.Empty(g_tabPanelIndex)

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

				AddExtraContent(propPanel, item.addonName)
			end
		)

		RemoveDefaultNode(tree)
	end

	local function PopulateNPCListContent(pnlContent, tree)
		g_spawnmenuLoaded = true
		table.Empty(g_tabPanelIndex)

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

				AddExtraContent(propPanel, item.addonName)
			end
		)

		RemoveDefaultNode(tree)
	end

	local function PopulateVehicleListContent(pnlContent, tree)
		g_spawnmenuLoaded = true
		table.Empty(g_tabPanelIndex)

		PopulateSpawnmenuListContent(
			pnlContent,
			tree,
			"vehicle",
			"icon16/car.png",
			function(node, propPanel, item)
				local trainOptions = item.trainOptions

				if trainOptions then
					spawnmenu.CreateContentIcon("sligwolf_train", propPanel, {
						nicename = item.title,
						spawnname = item.spawnName,
						material = item.icon or "entities/" .. item.spawnName .. ".png",
						admin = item.adminOnly,
						trainOptions = trainOptions,
					})
				else
					spawnmenu.CreateContentIcon("vehicle", propPanel, {
						nicename = item.title,
						spawnname = item.spawnName,
						material = item.icon or "entities/" .. item.spawnName .. ".png",
						admin = item.adminOnly,
					})
				end

				AddExtraContent(propPanel, item.addonName)
			end
		)

		RemoveDefaultNode(tree)
	end

	LIBHook.Add("PopulateContent", "Library_Spawnmenu_PopulateProplistContent", PopulatePropListContent, 20000)
	LIBHook.Add("PopulateEntities", "Library_Spawnmenu_PopulateEntitylistContent", PopulateEntityListContent, 20000)
	LIBHook.Add("PopulateWeapons", "Library_Spawnmenu_PopulateWeaponlistContent", PopulateWeaponListContent, 20000)
	LIBHook.Add("PopulateNPCs", "Library_Spawnmenu_PopulateNPClistContent", PopulateNPCListContent, 20000)
	LIBHook.Add("PopulateVehicles", "Library_Spawnmenu_PopulateVehiclelistContent", PopulateVehicleListContent, 20000)
end

return true

