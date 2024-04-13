local UI = require "modules.ui"
local S = require "modules.status"

local MEM = {}

MEM.level_data = {}
MEM.meta_data = {}
MEM.beat_data = {}
MEM.event_data = {}
MEM.geo_data = {}
MEM.sequence_data = {}
MEM.art_data = {}
MEM.sample_rate = 48000

local current_version = 0.4

local load = {}

local function sanitise_json(str)
	local json_error
	repeat
		json_error = string.find(str, "},]") or string.find(str, "],}")
		if json_error then
			str = string.sub(str, 1, json_error)..string.sub(str, json_error + 2)
		end
	until not json_error
	return str
end

local function check_version(str, filename)
	local pos = string.find(str, "\"version\":")
	if not pos then
		S.update("Unknown format of "..filename..".")
		return
	else
		local ver = string.sub(str, pos + 11, pos + 13)
		if tonumber(ver) < current_version then
			S.update("Version of "..filename.." is lower than "..current_version..". Resave it with the current Pistol Mix version.")
			return
		elseif tonumber(ver) > current_version then
			S.update("Version of "..filename.." is higher than "..current_version..". This may cause unknown issues. Be careful.")
			return true
		else
			return true
		end
	end
end

local function read_file(path)
	local f = io.open(path, "rb")
	if f then
		local data = f:read("*a")
		io.close(f)
		return data
	end
end

function load.pw(data)
	if not check_version(data, "level.pw") then
		return
	end
	data = sanitise_json(data)
	MEM.level_data.string = data
	local tab = json.decode(MEM.level_data.string)
	MEM.level_data.enemy_set = tab.enemySet
	MEM.level_data.obstacle_set = tab.obstacleSet
	MEM.level_data.material_set = tab.materialPropertiesSet
	MEM.level_data.preview_time = tab.previewTime
	MEM.level_data.move_mode = tab.moveMode
	MEM.level_data.song_length = tonumber(tab.songLength)
	MEM.level_data.scene_name = tab.sceneDisplayName
	MEM.level_data.art_file = tab.sharedLevelArt
	UI.tab.tab_level.state = true
	return true
end

function load.pw_meta(data)
	data = sanitise_json(data)
	MEM.meta_data.string = data
	
	local s_index = string.find(MEM.meta_data.string, "\"Volume\":[", 1, true)
	if not s_index then
		S.update("Error loading volume information. Try resaving the file with the current version of Pistol Mix.")
		MEM.meta_data = {}
		return false
	end
	local e_index = string.find(MEM.meta_data.string, "]", s_index + 8, true)
	local _ = string.sub(MEM.meta_data.string, s_index + 9, e_index)
	MEM.meta_data.volume_table = json.decode(string.sub(MEM.meta_data.string, s_index + 9, e_index))
	if #MEM.meta_data.volume_table < 1 then
		MEM.meta_data.free_group_index = 1
	elseif not MEM.meta_data.volume_table[#MEM.meta_data.volume_table].groupIndex then
		S.update("Error loading volume information. Try resaving the file with the current version of Pistol Mix.")
		MEM.meta_data = {}
		return false
	else
		MEM.meta_data.free_group_index = MEM.meta_data.volume_table[#MEM.meta_data.volume_table].groupIndex + 1
	end
	MEM.meta_data.string_start = string.sub(MEM.meta_data.string, 1, e_index - 1)
	MEM.meta_data.string_end = string.sub(MEM.meta_data.string, e_index)
	UI.tab.tab_meta.state = true
	return true
end

function load.pw_beat(data, filename)
	if not check_version(data, filename) then
		return
	end
	data = sanitise_json(data)
	local tab = json.decode(data)
	MEM.beat_data.obstacle_list = {}
	for key, val in ipairs(tab.beatData) do
		if not (val.obstacles == {}) then
			for k, v in ipairs(val.obstacles) do
				table.insert(MEM.beat_data.obstacle_list, {time = val.time, placement = v.placement, type = v.type, beat_data_key = key, obstacles_key = k})
			end
		end
	end

	MEM.beat_data.changed_obstacles = {}

	MEM.beat_data.table = tab.beatData
	MEM.beat_data.string = data
	MEM.beat_data.filename = filename
	MEM.beat_data.enemy_types = {}
	MEM.beat_data.enemy_types.normal = not not string.find(data, "Normal")
	MEM.beat_data.enemy_types.tough = not not string.find(data, "Tough")
	MEM.beat_data.enemy_types.chuck = not not string.find(data, "ChuckNorris")
	MEM.beat_data.enemy_types.shield = not not string.find(data, "Shield")
	MEM.beat_data.enemy_types.horse = not not string.find(data, "Mounted Enemy")
	MEM.beat_data.enemy_types.turret = not not string.find(data, "Normal Turret")
	MEM.beat_data.enemy_types.minigun = not not string.find(data, "Minigun Turret")
	MEM.beat_data.enemy_types.skull = not not string.find(data, "FlyingBomb")
	MEM.beat_data.enemy_types.trap = not not string.find(data, "Trap Enemy")
	
	UI.tab.tab_beat.state = true
	return true
end

function load.pw_event(data, filename)
	if not check_version(data, filename) then
		return
	end
	data = sanitise_json(data)
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
	if not check_version(data, filename) then
		return
	end
	local chunk = string.find(data, "chunkData")
	local slices = string.find(data, "chunkSlices")
	MEM.geo_data.start = string.sub(data, 1, chunk - 2)
	MEM.geo_data.chunk = string.sub(data, chunk - 1, slices - 2)
	MEM.geo_data.slices = string.sub(data, slices - 1)
	MEM.geo_data.filename = filename
	UI.tab.tab_geo.state = true
	return true
end

function load.pw_seq(data, filename)
	--MEM.sequence_data.string = data
	--MEM.sequence_data.filename = filename
	--UI.tab.tab_sequence.state = true
	--return true
end

function load.pw_art(data, filename)
	if not check_version(data, filename) then
		return
	end
	data = sanitise_json(data)
	MEM.art_data.string = data
	local model_table = json.decode(MEM.art_data.string)

	local function find_section(tab, model_index, name)
		if type(tab) == "table" then
			current_name = tab.name or current_name
			if tab.materials then
				for key, val in ipairs(tab.materials) do
					table.insert(MEM.art_data.model_list[model_index].parts, val)
					table.insert(MEM.art_data.part_names[name], current_name)
				end
			else
				for key, val in pairs(tab) do
					find_section(val, model_index, name)
				end
			end
		end
	end
	MEM.art_data.table_static_props = model_table.staticProps
	MEM.art_data.table_dynamic_props = model_table.dynamicProps or {}
	MEM.art_data.table_culling_ranges = model_table.staticCullingRanges
	MEM.art_data.table_dynamic_culling_ranges = model_table.dynamicCullingRanges or {}

	MEM.art_data.dynamic_models = {}
	for key, val in ipairs(MEM.art_data.table_dynamic_props) do
		MEM.art_data.dynamic_models[val.name] = true
	end
	for key, val in ipairs(MEM.art_data.table_dynamic_culling_ranges) do
		for k, v in ipairs(val.members) do
			MEM.art_data.dynamic_models[v.name] = true
		end
	end
	
	MEM.art_data.model_list = {}
	MEM.art_data.model_names = {}
	MEM.art_data.part_names = {[false] = {}}
	local current_name = ""
	for k, v in ipairs(model_table.propsDictionary) do
		if k > 1 and v.key then
			table.insert(MEM.art_data.model_names, v.key)
			table.insert(MEM.art_data.model_list, {name = v.key, parts = {}, dynamic = MEM.art_data.dynamic_models[v.key]})
			MEM.art_data.part_names[v.key] = {}
			find_section(v, #MEM.art_data.model_list, v.key)
		end
	end

	local staticProps_start = string.find(MEM.art_data.string, "staticProps")
	local ranges_start = string.find(MEM.art_data.string, "staticCullingRanges")
	local dictionary_start = string.find(MEM.art_data.string, "propsDictionary")

	MEM.art_data.string_colours = string.sub(MEM.art_data.string, 1, staticProps_start - 2)
	MEM.art_data.string_static_props = string.sub(MEM.art_data.string, staticProps_start - 1, ranges_start - 2)
	MEM.art_data.string_culling_ranges = string.sub(MEM.art_data.string, ranges_start - 1, dictionary_start - 2)
	local string_props_dictionary = string.sub(MEM.art_data.string, dictionary_start - 1)

	--string_beginning = string.sub(MEM.art_data.string, 1, dictionary_start + 1016)

	local start_index = 1018
	local search_string = "{\"key"

	local key_indices = {}
	repeat
		local next_key_index = string.find(string_props_dictionary, search_string, start_index)
		if next_key_index then
			table.insert(key_indices, next_key_index)
			start_index = next_key_index + 5
		end
	until not next_key_index
	for i = 1, #key_indices - 1 do
		MEM.art_data.model_list[i].string = string.sub(string_props_dictionary, key_indices[i], key_indices[i + 1] - 2)
	end
	if #key_indices > 0 then
		MEM.art_data.string_dictionary = string.sub(string_props_dictionary, 1, key_indices[1] - 1)
		MEM.art_data.model_list[#key_indices].string = string.sub(string_props_dictionary, key_indices[#key_indices], -3)
	else
		MEM.art_data.string_dictionary = string.sub(string_props_dictionary, 1, -2)
	end
	UI.tab.tab_art.state = true
	MEM.art_data.filename = filename
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