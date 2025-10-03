local SND = {}

SND.music_is_playing = false
SND.music_loaded = false

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
	sound.play("/sound#music", {delay = 0, start_time = start_time or 0})
	return true
end


return SND