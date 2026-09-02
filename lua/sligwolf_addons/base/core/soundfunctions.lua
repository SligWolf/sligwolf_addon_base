AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SLIGWOLF_ADDON then
	SligWolf_Addons:ReloadAddonSystem()
	return
end

function SLIGWOLF_ADDON:AddSoundScript(scriptData)
	scriptData = scriptData or {}
	local name = tostring(scriptData.name or "")

	if name == "" then
		error("scriptData.name is empty!")
		return nil
	end

	scriptData.name = self:GetSoundScriptName(name)

	sound.Add(scriptData)
end

function SLIGWOLF_ADDON:GetSoundScriptName(name)
	name = tostring(name or "")

	if name == "" then
		error("name is empty!")
		return nil
	end

	name = string.format("SLIGWOLF.%s.%s", self.Addonname, name)
	return name
end

function SLIGWOLF_ADDON:SoundCreate(ent, name, recipientFilter)
	name = self:GetSoundScriptName(name)

	if not recipientFilter then
		recipientFilter = RecipientFilter()
		recipientFilter:AddAllPlayers()
	end

	local soundObj = CreateSound(ent, name, recipientFilter)
	return soundObj
end

function SLIGWOLF_ADDON:SoundEdit(soundObj, state, pitch, pitchtime, volume, volumetime)
	if not soundObj then
		return
	end

	state = tonumber(state or 0)
	pitch = tonumber(pitch or 100)
	pitchtime = tonumber(pitchtime or 0)
	volume = tonumber(volume or 1)
	volumetime = tonumber(volumetime or 0)

	if state == 0 then
		soundObj:Stop()
	end
	if state == 1 then
		soundObj:Play()
	end
	if state == 2 then
		soundObj:ChangePitch(pitch, pitchtime)
	end
	if state == 3 then
		soundObj:ChangeVolume(volume, volumetime)
	end
	if state == 4 then
		soundObj:Play()
		soundObj:ChangePitch(pitch, pitchtime)
		soundObj:ChangeVolume(volume, volumetime)
	end
	if state == 5 then
		soundObj:Stop()
		soundObj:ChangePitch(pitch, pitchtime)
		soundObj:ChangeVolume(volume, volumetime)
	end
end

return true

