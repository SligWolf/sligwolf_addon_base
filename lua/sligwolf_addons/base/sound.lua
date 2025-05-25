AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SLIGWOLF_ADDON then
	SligWolf_Addons.AutoLoadAddon(function() end)
	return
end

SLIGWOLF_ADDON:AddSoundScript({
	name = "null",
	channel = CHAN_AUTO,
	volume = 0,
	level = 75,
	sound = "common/null.wav"
})

SLIGWOLF_ADDON:AddSoundScript({
	name = "indicator.on",
	channel = CHAN_AUTO,
	volume = 0.15,
	level = 75,
	pitch = 100,
	sound = "sligwolf/base/indicator_on.wav"
})

SLIGWOLF_ADDON:AddSoundScript({
	name = "indicator.off",
	channel = CHAN_AUTO,
	volume = 0.15,
	level = 75,
	pitch = 75,
	sound = "sligwolf/base/indicator_on.wav"
})

SLIGWOLF_ADDON:AddSoundScript({
	name = "generic.click",
	channel = CHAN_STATIC,
	volume = 1.5,
	level = 70,
	sound = "sligwolf/base/talk.wav"
})

SLIGWOLF_ADDON:AddSoundScript({
	name = "generic.switchclick",
	channel = CHAN_STATIC,
	volume = 1.0,
	level = 70,
	sound = "sligwolf/base/light.wav"
})

SLIGWOLF_ADDON:AddSoundScript({
	name = "generic.carhorn",
	channel = CHAN_STATIC,
	level = 90,
	sound = "sligwolf/base/carhorn.wav"
})

SLIGWOLF_ADDON:AddSoundScript({
	name = "generic.carhorn2",
	channel = CHAN_STATIC,
	level = 90,
	sound = "sligwolf/base/carhorn2.wav"
})

SLIGWOLF_ADDON:AddSoundScript({
	name = "generic.bikehorn",
	channel = CHAN_STATIC,
	level = 90,
	sound = "sligwolf/base/bikehorn.wav"
})

SLIGWOLF_ADDON:AddSoundScript({
	name = "generic.door",
	channel = CHAN_AUTO,
	level = 75,
	pitch = 100,
	sound = "sligwolf/base/door01.wav"
})

SLIGWOLF_ADDON:AddSoundScript({
	name = "generic.metaldoor.open",
	channel = CHAN_AUTO,
	level = 75,
	pitch = 100,
	sound = "doors/door_metal_medium_open1.wav"
})

SLIGWOLF_ADDON:AddSoundScript({
	name = "generic.metaldoor.close",
	channel = CHAN_AUTO,
	level = 75,
	pitch = 100,
	sound = "doors/door_metal_medium_close1.wav"
})

SLIGWOLF_ADDON:AddSoundScript({
	name = "wagon.drive",
	channel = CHAN_STATIC,
	volume = 1.0,
	level = 90,
	sound = "sligwolf/base/wagon_wheel_loop.wav"
})

SLIGWOLF_ADDON:AddSoundScript({
	name = "weapon.denyaction",
	channel = CHAN_WEAPON,
	level = 75,
	pitch = 120,
	sound = "buttons/combine_button2.wav"
})

SLIGWOLF_ADDON:AddSoundScript({
	name = "crane.engineStart",
	channel = CHAN_STATIC,
	volume = 1.0,
	level = 90,
	sound = "vehicles/crane/crane_startengine1.wav"
})

SLIGWOLF_ADDON:AddSoundScript({
	name = "crane.turn",
	channel = CHAN_STATIC,
	volume = 1.0,
	level = 90,
	sound = "vehicles/crane/crane_turn_loop2.wav"
})

SLIGWOLF_ADDON:AddSoundScript({
	name = "crane.moveArm",
	channel = CHAN_STATIC,
	volume = 1.0,
	level = 90,
	pitch = {90, 120},
	sound = "vehicles/crane/crane_extend_loop1.wav"
})

return true

