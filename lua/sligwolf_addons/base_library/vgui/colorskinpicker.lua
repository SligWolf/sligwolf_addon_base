
if not SligWolf_Addons then
	return
end

if SligWolf_Addons:ReloadAddonSystem() then
	return
end

local LIBUtil = SligWolf_Addons.Util

local PANEL = {}
AccessorFunc(PANEL, "m_ConVar", "ConVar")

function PANEL:Init()
	self:SetPaintBackground(false)
	self:SetHeight(100)

	self.itemsOrdered = {}
	self.itemsByName = {}
	self.isDirty = false
end

function PANEL:SetLabel(txt)
end

function PANEL:SetConVar(cvar)
end

local g_buttonSizes = {
	128,
	64,
	32
}

function PANEL:PerformLayout(w, h)
	if self.isDirty then
		self:RebuildButtonList()
	end

	local itemsOrdered = self.itemsOrdered
	local buttonCount = #itemsOrdered

	local margin = 8

	h = math.max(h - margin * 2, 0)
	w = math.max(w - margin * 2, 0)

	local rows = 0
	local cols = 0

	local sizeCount = #g_buttonSizes

	local buttonSize = 0
	local buttonMargin = 0

	for sizeIndex, minSize in ipairs(g_buttonSizes) do
		local maxSize = g_buttonSizes[sizeIndex - 1] or minSize
		local isLastSize = sizeIndex >= sizeCount

		buttonMargin = math.min(minSize / 4, 16)

		local maxRows = math.max(math.floor((h + buttonMargin) / (minSize + buttonMargin)), 1)
		local maxCols = math.max(math.floor((w + buttonMargin) / (minSize + buttonMargin)), 1)

		local maxButtonCount = maxRows * maxCols

		if buttonCount > maxButtonCount and not isLastSize then
			-- Buttons sized "minSize" or larger would not fit.
			continue
		end

		rows = math.max(math.ceil(buttonCount / maxCols), 1)
		cols = math.max(math.ceil(buttonCount / rows), 1)

		local sizeY = math.floor(((h + buttonMargin) / rows) - buttonMargin)
		local sizeX = math.floor(((w + buttonMargin) / cols) - buttonMargin)

		local size = math.min(sizeX, sizeY, maxSize)

		if size < minSize and not isLastSize then
			-- Buttons are too small.
			continue
		end

		buttonSize = math.max(size, minSize)
		break
	end

	local buttonsH = rows * buttonSize + (rows - 1) * buttonMargin
	local buttonsY = math.max(math.floor((h - buttonsH) / 2), 0) + margin

	local colsLast = buttonCount % cols
	if colsLast == 0 then
		colsLast = cols
	end

	for row = 0, rows - 1 do
		local colsInRow = cols
		if row == rows - 1 then
			colsInRow = colsLast
		end

		local buttonsW = colsInRow * buttonSize + (colsInRow - 1) * buttonMargin
		local buttonsX = math.max(math.floor((w - buttonsW) / 2), 0) + margin

		for col = 0, colsInRow - 1 do
			local index = cols * row + col + 1

			local item = itemsOrdered[index]
			if not item then
				continue
			end

			local itemButton = item.button
			if not IsValid(itemButton) then
				continue
			end

			itemButton:SetHeight(buttonSize)
			itemButton:SetWidth(buttonSize)

			local buttonX = buttonsX + col * (buttonSize + buttonMargin)
			local buttonY = buttonsY + row * (buttonSize + buttonMargin)

			itemButton:SetPos(buttonX, buttonY)
		end
	end
end

function PANEL:RebuildButtonList()
	local itemsByName = self.itemsByName
	local itemsOrdered = self.itemsOrdered

	table.Empty(itemsOrdered)

	for i, item in SortedPairsByMemberValue(itemsByName, "order") do
		local name = item.name
		if not name then
			continue
		end

		local itemByName = itemsByName[name]
		if itemByName ~= item then
			continue
		end

		local itemButton = item.button
		if not IsValid(itemButton) then
			continue
		end

		if itemButton:IsMarkedForDeletion() then
			continue
		end

		local index = #itemsOrdered + 1

		itemButton:SetZPos(index)
		itemButton:SetVisible(true)

		itemsOrdered[index] = item
	end

	self.isDirty = false
	self:InvalidateLayout()
end

function PANEL:AddOption(name, params)
	local itemsByName = self.itemsByName

	local item = itemsByName[name] or {}
	itemsByName[name] = item

	table.Empty(item)

	local icon = params.icon or ""
	local title = params.title or ""
	local order = params.order or LIBUtil.Order()

	item.name = name
	item.icon = icon
	item.title = title
	item.order = order

	local itemButton = item.button

	if not IsValid(itemButton) or itemButton:IsMarkedForDeletion() then
		itemButton = vgui.Create("SligWolf_ColorSkinPickerButton")
		item.button = itemButton
	end

	if icon ~= "" then
		itemButton:SetMaterial(icon)
	end

	if title == "" then
		title = name
	end

	itemButton:SetTitle(title)
	itemButton:SetColorSkinName(name)
	itemButton:SetVisible(false)

	self.isDirty = true

	self:Add(itemButton)

	self:InvalidateLayout()
end

function PANEL:RemoveOption(name)
	local itemsByName = self.itemsByName

	local item = itemsByName[name]
	itemsByName[name] = nil

	if not item then
		return
	end

	self.isDirty = true

	local itemButton = item.button
	table.Empty(item)

	if IsValid(itemButton) then
		itemButton:Remove()
	end

	self:InvalidateLayout()
end

function PANEL:Clear(...)
	local itemsByName = self.itemsByName
	local itemsOrdered = self.itemsOrdered

	self.isDirty = true

	for name, item in pairs(itemsByName) do
		local itemButton = item.button
		table.Empty(item)

		if IsValid(itemButton) then
			itemButton:Remove()
		end
	end

	table.Empty(itemsByName)
	table.Empty(itemsOrdered)

	self.BaseClass.Clear(self, ...)
	self:InvalidateLayout()
end

vgui.Register("SligWolf_ColorSkinPicker", PANEL, "DPanel")

return true

