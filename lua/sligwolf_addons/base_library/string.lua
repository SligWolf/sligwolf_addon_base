local SligWolf_Addons = _G.SligWolf_Addons
if not SligWolf_Addons then
	return
end

local LIB = SligWolf_Addons:NewLib("String")

local LIBUtil = SligWolf_Addons.Util

function LIB.UniqueString(prefix)
	prefix = tostring(prefix or "")

	if prefix == "" then
		prefix = "UniqueString"
	end

	local timeHash = tonumber(util.CRC(tostring(SysTime())))
	local uniqueString = string.format("%s-%d-%08X", prefix, LIBUtil.Uid(), timeHash)

	return uniqueString
end

function LIB.WildcardMatch(strInput, wildcard)
	if wildcard == "*" then
		return true
	end

	if wildcard == "" then
		return false
	end

	if strInput == wildcard then
		return true
	end

	local escapedWildcard = string.PatternSafe(wildcard)
	local pattern = "^" .. string.gsub(escapedWildcard, "%%%*", ".*") .. "$"

	if not string.match(strInput, pattern) then
		return false
	end

	return true
end

function LIB.ValidateName(name)
	name = tostring(name or "")
	name = string.gsub(name, "^!", "", 1)
	name = string.gsub(name, "[\\/]", "")
	return name
end

function LIB.NormalizeNewlines(text, nl)
	nl = tostring(nl or "")
	text = tostring(text or "")

	local replacemap = {
		["\r\n"] = true,
		["\r"] = true,
		["\n"] = true,
	}

	if not replacemap[nl] then
		nl = "\n"
	end

	replacemap[nl] = nil

	for k, v in pairs(replacemap) do
		replacemap[k] = nl
	end

	text = string.gsub(text, "([\r]?[\n]?)", replacemap)

	return text
end

local g_createColoredStringMeta = LIB.g_createColoredStringMeta or {}
LIB.g_createColoredStringMeta = g_createColoredStringMeta

do

	function g_createColoredStringMeta:SetColors(colors)
		colors = colors or {}

		local colorTable = {}

		for i, color in ipairs(colors) do
			colorTable[i] = color:Copy()
		end

		if not colorTable[1] then
			colorTable[1] = Color(255, 255, 255)
		end

		self.defaultColor = colorTable[1]
		self.colors = colorTable

		self.tokens = nil
	end

	function g_createColoredStringMeta:SetText(rawtext)
		rawtext = tostring(rawtext)
		self.rawtext = rawtext

		self.tokens = nil
		self.plaintext = nil
	end

	function g_createColoredStringMeta:SetTextFormat(format, ...)
		local rawtext = string.format(format, ...)
		self:SetText(rawtext)
	end

	function g_createColoredStringMeta:GetTokens()
		local tokens = self.tokens

		if tokens then
			return tokens
		end

		tokens = {}

		local text = self.rawtext or ""

		local defaultColor = self.defaultColor
		local currentColor = defaultColor
		local colors = self.colors

		local start = 1
		local len = #text

		for i = 1, len do
			local byte = string.byte(text, i, i)

			if byte == 0x0A then
				-- Newline

				if i > start then
					table.insert(tokens, {
						color = currentColor,
						text = string.sub(text, start, i - 1)
					})
				end

				-- Newline gets its own token with default color
				table.insert(tokens, {
					color = defaultColor,
					text = "\n"
				})

				currentColor = defaultColor
				start = i + 1
			else
				local color = colors[byte]
				if color then
					if i > start then
						table.insert(tokens, {
							color = currentColor,
							text = string.sub(text, start, i - 1)
						})
					end

					currentColor = color
					start = i + 1
				end
			end
		end

		if start <= len then
			table.insert(tokens, {
				color = currentColor,
				text = string.sub(text, start)
			})
		end

		self.tokens = tokens
		return tokens
	end

	function g_createColoredStringMeta:GetPlaintext()
		local plaintext = self.plaintext

		if plaintext then
			return plaintext
		end

		local tokens = self:GetTokens()
		local parts = {}

		for _, token in ipairs(tokens) do
			table.insert(parts, token.text)
		end

		plaintext = table.concat(parts)

		self.plaintext = plaintext
		return plaintext
	end

	g_createColoredStringMeta.__index = g_createColoredStringMeta
	g_createColoredStringMeta.__tostring = g_createColoredStringMeta.GetPlaintext
end

function LIB.CreateColoredString(rawtext, colors)
	local obj = {}

	setmetatable(obj, g_createColoredStringMeta)

	obj:SetColors(colors)
	obj:SetText(rawtext)

	return obj
end

function LIB.Load()
	LIBUtil = SligWolf_Addons.Util
end

return true

