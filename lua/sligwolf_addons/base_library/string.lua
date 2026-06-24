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

function LIB.Load()
	LIBUtil = SligWolf_Addons.Util
end

return true

