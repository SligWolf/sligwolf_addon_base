AddCSLuaFile()

if !SW_ADDON then
	SW_Addons.AutoLoadAddon(function() end)
	return
end

function SW_ADDON:Indicator_Sound(ent, bool_R, bool_L, pitchon, pitchoff, vol, sound)
	if !IsValid(ent) then return end
	
	local Check = bool_R or bool_L or nil
	if !Check then return end
	
	vol = tonumber(vol or 50)
	pitchon = tonumber(pitchon or 100)
	pitchoff = tonumber(pitchoff or 75)
	sound = tostring(sound or "vehicles/sligwolf/generic/indicator_on.wav")
	
	if !ent.__SW_Indicator_OnOff then
		ent:EmitSound(sound, vol, pitchon)
		ent.__SW_Indicator_OnOff = true
		return
	else
		ent:EmitSound(sound, vol, pitchoff)
		ent.__SW_Indicator_OnOff = false
		return
	end
end

function SW_ADDON:SoundEdit(sound, state, pitch, pitchtime, volume, volumetime)

	sound = sound or nil
	if !sound then return end
	
	state = tonumber(state or 0)
	pitch = tonumber(pitch or 100)
	pitchtime = tonumber(pitchtime or 0)
	volume = tonumber(volume or 1)
	volumetime = tonumber(volumetime or 0)
	
	if state == 0 then
		sound:Stop()
	end
	if state == 1 then
		sound:Play()
	end
	if state == 2 then
		sound:ChangePitch(pitch, pitchtime)
	end
	if state == 3 then
		sound:ChangeVolume(volume, volumetime)
	end
	if state == 4 then
		sound:Play()
		sound:ChangePitch(pitch, pitchtime)
		sound:ChangeVolume(volume, volumetime)
	end
	if state == 5 then
		sound:Stop()
		sound:ChangePitch(pitch, pitchtime)
		sound:ChangeVolume(volume, volumetime)
	end
end

sound.Add(
{
    name = "SW_Generic_Click",
    channel = CHAN_STATIC,
    volume = 1.0,
    level = 70,
    sound = "vehicles/sligwolf/generic/light.wav"
})

sound.Add(
{
    name = "SW_Generic_CarHorn",
    channel = CHAN_STATIC,
    level = 110,
    sound = "vehicles/sligwolf/generic/carhorn.wav"
})

sound.Add(
{
    name = "SW_Generic_CarHorn2",
    channel = CHAN_STATIC,
    level = 110,
    sound = "vehicles/sligwolf/generic/carhorn2.wav"
})

sound.Add(
{
    name = "SW_Generic_BikeHorn",
    channel = CHAN_STATIC,
    level = 110,
    sound = "vehicles/sligwolf/generic/bikehorn.wav"
})

sound.Add(
{
	name = "SW_Wagon_Drive",
    channel = CHAN_STATIC,
    volume = 1.0,
    level = 90,
    sound = "vehicles/sligwolf/generic/wagon_wheel_loop.wav"
})

sound.Add(
{
	name = "SW_Weapon_DenyAction",
    channel = CHAN_WEAPON,
    level = 100,
    pitch = 120,
    sound = "buttons/combine_button2.wav"
})