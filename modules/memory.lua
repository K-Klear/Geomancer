local UI = require "modules.ui"

local MEM = {}

MEM.level_data = {}
MEM.meta_data = {}
MEM.beat_data = {}
MEM.event_data = {}
MEM.geo_data = {}
MEM.sequence_data = {}
MEM.art_data = {}

MEM.sample_rate = 48000

local load = {}

local function read_file(path)
	local f = io.open(path, "rb")
	if f then
		local data = f:read("*a")
		io.close(f)
		return data
	end
end

function load.pw(data)
	MEM.level_data.string = data
	local tab = json.decode(MEM.level_data.string)
	MEM.level_data.enemy_set = tab.enemySet
	MEM.level_data.obstacle_set = tab.obstacleSet
	MEM.level_data.material_set = tab.materialPropertiesSet
	MEM.level_data.preview_time = tab.previewTime
	MEM.level_data.move_mode = tab.moveMode
	MEM.level_data.song_length = tonumber(tab.songLength)
	MEM.level_data.scene_name = tab.sceneDisplayName
	UI.tab.tab_level.state = true
	return true
end

function load.pw_meta(data)
	MEM.meta_data.string = data
	--MEM.meta_data.table = json.decode(MEM.meta_data.string)
	UI.tab.tab_meta.state = true
	return true
end

function load.pw_beat(data, filename)
	MEM.beat_data.string = data
	MEM.beat_data.filename = filename
	--MEM.beat_data.table = json.decode(MEM.beat_data.string)
	--if string.find(MEM.beat_data.string, "FlyingBomb") or string.find(MEM.beat_data.string, "Trap Enemy") then
	--	print("that file is fucked yo")
	--end
	UI.tab.tab_beat.state = true
	return true
end

function load.pw_event(data, filename)
	MEM.event_data.string = data
	MEM.event_data.filename = filename
	MEM.event_data.table = json.decode(MEM.event_data.string)
	--if not (#MEM.event_data.table.tempoSections == 1) then
	--	print("fucked again")
	--end
	UI.tab.tab_event.state = true
	return true
end

function load.pw_geo(data, filename)
	MEM.geo_data.string = data
	MEM.geo_data.filename = filename
	UI.tab.tab_geo.state = true
	return true
end

function load.pw_seq(data, filename)
	MEM.sequence_data.string = data
	MEM.sequence_data.filename = filename
	UI.tab.tab_sequence.state = true
	return true
end

function load.pw_art(data, filename)
	MEM.art_data.string = data
	if string.find(data, "\"dynamicProps\"") or string.find(data, "\"dynamicCullingRanges\"") then
		return
	end
	MEM.art_data.table = json.decode(MEM.art_data.string)
	MEM.art_data.filename = filename
	--if MEM.art_data.table.dynamicProps or MEM.art_data.table.dynamicCullingRanges then
	--	print("so totally fucked")
	--end
	UI.tab.tab_art.state = true
	return true
end

function MEM.load_file(path, filename, extension, data)
	if extension and load[extension] then
		data = data or read_file(path)
		if data then
			if load[extension](data, filename) then
				return extension
			end
		end
	end
end

return MEM