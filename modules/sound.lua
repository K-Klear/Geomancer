local SND = {}
local SET = require "modules.settings"

SND.music_is_playing = false
SND.music_loaded = false
SND.playback_speed = 1

SND.metronome_sound_list = {
	{sound = "/sound#beep", offset = 0.016, name = "Beep"},
	{sound = "/sound#click", offset = 0.03, name = "Click"}
}

SND.metronome_stupid_sound_list = {
	{sound = "/sound#fart", offset = 0.0, name = "Fart", random_pitch = true},
	{sound = "/sound#meow", offset = 0.08, name = "Meow", random_pitch = true},
	{sound = "/sound#anime", offset = 0.028, name = "Aah", random_pitch = true},
	{sound = "/sound#wilhelm", offset = 0.045, name = "Wilhelm", random_pitch = true},
	{sound = "/sound#icq", offset = 0.013, name = "ICQ"},
	{sound = "/sound#quake", offset = 0.035, name = "Quake"},
	{sound = "/sound#duke1", offset = 0.01, name = "Duke", duke = true, special = true},
	{sound = "/sound#rick", offset = 0.00, name = "Rick", rick = true, special = true},
}

local rick_count = 0

function SND.metronome_tick()
	local props
	if SND.metronome_sound_list[SET.metronome_sound].random_pitch then
		props = {speed = math.random() * 0.25 + 0.875}
	elseif SND.metronome_sound_list[SET.metronome_sound].special then
		if SND.metronome_sound_list[SET.metronome_sound].duke then
			if math.random() > 0.8 then
				sound.play("/sound#duke2")
			else
				sound.play("/sound#duke1")
			end
		elseif SND.metronome_sound_list[SET.metronome_sound].rick then
			rick_count = rick_count + 1
			if rick_count > 16 then rick_count = 1 end
			sound.play("/sound#rick"..rick_count)
		end
		return
	end
	sound.play(SND.metronome_sound_list[SET.metronome_sound].sound, props)
end

function SND.stop_music()
	if SND.music_is_playing then
		SND.music_is_playing = false
		sound.stop("/sound#music")
	end
end

function SND.play_music(start_time)
	if not SND.music_loaded then
		msg.post("/navbar#navbar", hash("update_status"), {text = "No music file loaded", clear = true})
		return
	end
	SND.stop_music()
	SND.music_is_playing = true
	local delay = 0
	if start_time < 0 then
		delay = -start_time
		start_time = 0
	end
	sound.play("/sound#music", {delay = delay, start_time = start_time or 0, speed = SND.playback_speed})
	return true
end

local music_resource_index = 0
function SND.load_music(data)
	if SND.music_loaded then
		resource.release("/music"..music_resource_index..".ogg")
	end
	music_resource_index = music_resource_index + 1
	msg.post("/sound", hash("music_loaded"))
	return resource.create_sound_data("/music"..music_resource_index..".ogg", {data = data})
end

function SND.unload_music()
	SND.stop_music()
	if SND.music_loaded then
		resource.release("/music"..music_resource_index..".ogg")
	end
	music_resource_index = music_resource_index + 1
	SND.music_loaded = false
end


return SND