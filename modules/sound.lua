local SND = {}
local SET = require "modules.settings"

SND.music_is_playing = false
SND.music_loaded = false
SND.playback_speed = 1

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