local UI = require "modules.ui"
local G = require "modules.global"
local SET = require "modules.settings"

local MEM = {}

MEM.level_data = {}
MEM.meta_data = {}
MEM.beat_data = {}
MEM.event_data = {}
MEM.geo_data = {}
MEM.sequence_data = {}
MEM.art_data = {}

local load = {}

local function read_file(path)
	local f = io.open(path, "rb")
	if f then
		local data = f:read("*a")
		io.close(f)
		return data
	end
end

local QUOTE = "\""
local QUOTE_2 = QUOTE..":"..QUOTE
local QUOTE_3 = QUOTE..":{"
local QUOTE_4 = QUOTE..":["
local QUOTE_5 = QUOTE..","
local QUOTE_6 = QUOTE..":"
local TABLE = "table"
local STRING = "string"

function MEM.export_json(json_tab)
	io.write("{")
	local string_tab = {}
	local function export_table(tab)
		if tab._key_sort then
			local key_count = #tab._key_sort
			for key, val in ipairs(tab._key_sort) do
				local val_type = type(tab[val])
				if val_type == TABLE then
					if tab[val]._key_sort then
						io.write(QUOTE..val..QUOTE_3)
						export_table(tab[val])
						io.write("}")
					elseif tab[val]._pure_array then
						io.write(QUOTE..val..QUOTE_6..tab[val]._pure_array)
					else
						io.write(QUOTE..val..QUOTE_4)
						export_table(tab[val])
						io.write("]")
					end
					if key_count > 1 then
						io.write(",")
					end
				elseif val_type == STRING then
					if key_count > 1 then
						io.write(QUOTE..val..QUOTE_2..tab[val]..QUOTE_5)
					else
						io.write(QUOTE..val..QUOTE_2..tab[val]..QUOTE)
					end
				elseif val_type then
					if key_count > 1 then
						io.write(QUOTE..val..QUOTE_6..tab[val]..",")
					else
						io.write(QUOTE..val..QUOTE_6..tab[val])
					end
				end
				key_count = key_count - 1
			end
		else
			local key_count = #tab
			for key, val in ipairs(tab) do
				local val_type = type(val)
				if val_type == TABLE then
					if val._key_sort then
						io.write("{")
						export_table(val)
						io.write("}")
					elseif val._pure_array then
						io.write(tab[val]._pure_array)
					else
						io.write("[")
						export_table(val)
						io.write("]")
					end
					if key_count > 1 then
						io.write(",")
					end
				elseif val_type == STRING then
					if key_count > 1 then
						io.write(QUOTE..val..QUOTE_5)
					else
						io.write(QUOTE..val..QUOTE)
					end
				else
					if key_count > 1 then
						io.write(",")
					else
						io.write(val)
					end
				end
				key_count = key_count - 1
			end
		end
	end
	export_table(json_tab)
	io.write("}")
	return true
end

function MEM.parse_json(json_str)
	local tab = {}
	local char
	local char_pos = 0
	local json_lenght = #json_str - 1
	local key
	local tab_list = {tab}
	local value_start
	local pure_array
	local to_boolean = {["true"] = true, ["false"] = false}

	local function get_value()
		if not value_start then return end
		local value = string.sub(json_str, value_start, char_pos - 1)
		value_start = nil
		value = to_boolean[value] or tonumber(value) or value
		if key then
			table.insert(tab_list[#tab_list]._key_sort, key)
			tab_list[#tab_list][key] = value
			key = nil
		else
			table.insert(tab_list[#tab_list], value)
		end
		-- FIGURE OUT THE VALUE TYPE HERE
	end

	local handle_char = {}
	handle_char["{"] = function()
		pure_array = false
		local new_tab = {_key_sort = {}}
		if key then
			table.insert(tab_list[#tab_list]._key_sort, key)
			tab_list[#tab_list][key] = new_tab
			key = nil
		else
			table.insert(tab_list[#tab_list], new_tab)
		end
		table.insert(tab_list, new_tab)
	end
	handle_char["["] = function()
		pure_array = char_pos
		local new_tab = {}
		if key then
			table.insert(tab_list[#tab_list]._key_sort, key)
			tab_list[#tab_list][key] = new_tab
			key = nil
		else
			table.insert(tab_list[#tab_list], new_tab)
		end
		table.insert(tab_list, new_tab)
	end
	handle_char["}"] = function()
		get_value()
		tab_list[#tab_list] = nil
	end
	handle_char["]"] = function()
		if pure_array and (char_pos - pure_array > 1) then
			tab_list[#tab_list]._pure_array = string.sub(json_str, pure_array, char_pos)
		end
		pure_array = false
		get_value()
		tab_list[#tab_list] = nil
	end
	handle_char[QUOTE] = function()
		local end_quote = string.find(json_str, QUOTE, char_pos + 1)
		if not end_quote then
			print("ERROR! Missing end quote")
		else
			local key_or_value = string.sub(json_str, char_pos + 1, end_quote - 1)
			if key then
				tab_list[#tab_list][key] = key_or_value
				table.insert(tab_list[#tab_list]._key_sort, key)
				key = nil
				char_pos = end_quote
			else
				if tab_list[#tab_list]._key_sort then
					key = key_or_value
					char_pos = string.find(json_str, ":", end_quote) or end_quote
				else
					table.insert(tab_list[#tab_list], key_or_value)
					char_pos = end_quote
				end
			end
		end
	end
	handle_char[":"] = function() return end
	handle_char[" "] = function() return end
	handle_char[","] = get_value
		
	repeat
		char_pos = char_pos + 1
		char = string.sub(json_str, char_pos, char_pos)
		if handle_char[char] then
			handle_char[char]()
		elseif not value_start then
			value_start = char_pos
		end
	until char_pos > json_lenght
	return tab[1]
end

function MEM.check(tab, file_type, filename)
	filename = filename or "file"
	if not (tab and G.check_version(tab, filename)) then return end
	local expected_values = {}
	expected_values.pw = {"enemySet", "obstacleSet", "materialPropertiesSet", "previewTime", "moveMode", "songLength", "sceneDisplayName", "sharedLevelArt", "mapper", "description"}
	expected_values.pw_beat = {"beatData"}
	expected_values.pw_event = {"eventsData", "tempoSections"}
	expected_values.pw_art = {"colors", "propsDictionary"}
	expected_values.pw_geo = {"chunkData", "chunkSlices"}
	for key, val in pairs(expected_values[file_type]) do
		if not tab[val] then
			G.update_navbar(filename.." is missing the "..val.." entry.")
			return
		end
	end
	return true
end

function load.pw(data)
	local tab = MEM.parse_json(data)
	if MEM.check(tab, "pw", "level.pw") then
		UI.tab.tab_level.state = true
		MEM.level_data = tab
		return true
	else
		MEM.level_data = {}
		UI.tab.tab_level.state = false
	end
end

function load.pw_meta(data)
	if true then return end
	local tab = MEM.parse_json(data)
	if not tab then return end
	MEM.meta_data.string = data
	
	local s_index = string.find(MEM.meta_data.string, "\"Volume\":[", 1, true)
	if not s_index then
		msg.post("/navbar#navbar", hash("update_status"), {text = "Error loading volume information. Try resaving the file with the current version of Pistol Mix."})
		MEM.meta_data = {}
		return false
	end
	local e_index = string.find(MEM.meta_data.string, "]", s_index + 8, true)
	local _ = string.sub(MEM.meta_data.string, s_index + 9, e_index)
	tab = G.safe_decode(string.sub(MEM.meta_data.string, s_index + 9, e_index), "do_not_ship.pw_meta")
	if not tab then return end
	MEM.meta_data.volume_table = tab
	local expected_group_index = 1
	local fix_applied = false
	for key, val in ipairs(tab) do
		if val.groupIndex and (tonumber(val.groupIndex) > expected_group_index) then
			local index = G.find_substring(MEM.meta_data.string, "groupIndex", key, s_index) + 12
			MEM.meta_data.string = string.sub(MEM.meta_data.string, 1, index)..expected_group_index..string.sub(MEM.meta_data.string, index + 1 + #val.groupIndex)
			val.groupIndex = expected_group_index
			fix_applied = true
		end
		expected_group_index = expected_group_index + 1
	end
	if fix_applied then
		G.update_navbar("Volume index information corruption detected and fixed.")
	end
	if #MEM.meta_data.volume_table < 1 then
		MEM.meta_data.free_group_index = 1
	elseif not MEM.meta_data.volume_table[#MEM.meta_data.volume_table].groupIndex then
		msg.post("/navbar#navbar", hash("update_status"), {text = "Error loading volume information. Try resaving the file with the current version of Pistol Mix."})
		MEM.meta_data = {}
		return false
	else
		MEM.meta_data.free_group_index = MEM.meta_data.volume_table[#MEM.meta_data.volume_table].groupIndex + 1
	end
	MEM.meta_data.string_start = string.sub(MEM.meta_data.string, 1, e_index - 1)
	MEM.meta_data.string_end = string.sub(MEM.meta_data.string, e_index)
	UI.tab.tab_meta.state = true
	MEM.slices_reloaded = true
	return true
end

function load.pw_beat(data, filename)
	local tab = MEM.parse_json(data)
	if MEM.check(tab, "pw_beat", filename) then
		UI.tab.tab_beat.state = true
		local obstacle_list = {}
		local enemy_list = {}
		local enemy_types = {}
		local types = {Normal = "normal", Tough = "tough", ChuckNorris = "chuck", Shield = "shield", ["Mounted Enemy"] = "horse", ["Normal Turret"] = "turret",
		["Minigun Turret"] = "minigun", FlyingBomb = "skull", ["Trap Enemy"] = "trap"}
		
		for key, val in ipairs(tab.beatData) do
			for k, v in ipairs(val.obstacles) do
				table.insert(obstacle_list, {beat_data_key = key, obstacles_key = k})
			end
			for k, v in ipairs(val.targets) do
				table.insert(enemy_list, {beat_data_key = key, enemies_key = k})
				enemy_types[types[v.enemyType]] = true
			end
		end
		MEM.beat_data = {table = tab, obstacle_list = obstacle_list, enemy_list = enemy_list, enemy_types = enemy_types, filename = filename}
		return true
	else
		MEM.beat_data = {}
		UI.tab.tab_beat.state = false
	end
	UI.tab.tab_beat.state = true
	MEM.beat_reloaded = true
	return true
end

function load.pw_event(data, filename)
	local tab = MEM.parse_json(data)
	if MEM.check(tab, "pw_event", filename) then
		UI.tab.tab_event.state = true
		MEM.event_data = {table = tab, filename = filename, filter = {}}
		for key, val in ipairs(tab.eventsData) do
			if val.track == "NoBeat" then
				MEM.event_data.nobeat_track_index = key
			elseif val.track == "Event" then
				MEM.event_data.event_track_index = key
			end
		end
		MEM.event_reloaded = true
		return true
	else
		MEM.event_data = {}
		UI.tab.tab_event.state = false
	end
end

function load.pw_geo(data, filename)
	local tab = MEM.parse_json(data)
	if MEM.check(tab, "pw_geo", filename) then
		MEM.geo_data = {table = tab, filename = filename}
		UI.tab.tab_geo.state = true
		return true
	else
		MEM.geo_data = {}
		UI.tab.tab_geo.state = false
	end
end

function load.pw_seq(data, filename)
	--MEM.sequence_data.string = data
	--MEM.sequence_data.filename = filename
	--UI.tab.tab_sequence.state = true
	--return true
end

local function parse_tween_action(script)
	local action = {}
	local str_start, str_end, x, y, z
	action.type = string.sub(script, 1, 1)
	if action.type == "W" then
		str_end = string.find(script, ";")
		action.time = string.sub(script, 2, str_end - 1)
		return action, string.sub(script, str_end + 1)
	elseif action.type == "T" or action.type == "R" or action.type == "S" then
		str_start = string.find(script, ";")
		action.part = string.sub(script, 2, str_start - 1)
		str_end = string.find(script, ",", str_start + 1)
		x = string.sub(script, str_start + 1, str_end - 1)
		str_start = str_end
		str_end = string.find(script, ",", str_start + 1)
		y = string.sub(script, str_start + 1, str_end - 1)
		str_start = str_end
		str_end = string.find(script, ";", str_start + 1)
		z = string.sub(script, str_start + 1, str_end - 1)
		str_start = str_end
		action.start_state = {x = x, y = y, z = z}
		str_end = string.find(script, ",", str_start + 1)
		x = string.sub(script, str_start + 1, str_end - 1)
		str_start = str_end
		str_end = string.find(script, ",", str_start + 1)
		y = string.sub(script, str_start + 1, str_end - 1)
		str_start = str_end
		str_end = string.find(script, ";", str_start + 1)
		z = string.sub(script, str_start + 1, str_end - 1)
		str_start = str_end
		action.end_state = {x = x, y = y, z = z}
		str_end = string.find(script, ";", str_start + 1)
		action.time = string.sub(script, str_start + 1, str_end - 1)
		return action, string.sub(script, str_end + 1)
	else
		return
	end
end

function MEM.parse_tween(tween_script)
	local tween_table = {}
	local safety = #tween_script / 3
	local tween_working, tween_action
	repeat
		tween_working, tween_action, tween_script = pcall(parse_tween_action, tween_script)
		safety = safety - 1
		if safety < 0 or not (tween_working and tween_script) then
			G.update_navbar("Malformed tween script has not been loaded.")
			return
		else
			table.insert(tween_table, tween_action)
		end
	until #tween_script < 1
	if tween_working then
		return tween_table
	end
end



--{name or "[no name]", level = level, tween = tab.tween, mesh_count = mesh_count, part_index = _part_index, tab = tab.tab}


local tween_count, part_list, transform_list
local function explore_model_tree(source_tab, part_name, level, parent_tab)
	if source_tab.name == "Colliders" then
	--	tree_section\.name = source_tab.name
		return
	end -- Catch colliders here so they appear on the model preview somehow
	part_name = source_tab.name or part_name
	table.insert(transform_list, {})
	local current_transform = transform_list[#transform_list]
	if source_tab.components then
		for k, v in ipairs(source_tab.components) do
			if v.type == "Transform" then
				current_transform.position, current_transform.rotation, current_transform.scale = G.parse_transform(v.values)
				current_transform.name = part_name
				current_transform.tab = source_tab
				current_transform.level = level
				current_transform.parent_tab = parent_tab
			elseif v.type == "ScriptedTween" then
				local tween_script = MEM.parse_tween(v.Script)
				if tween_script then
					current_transform.tween = tween_script
					tween_count = tween_count + 1
				end
			elseif v.type == "LevelEventReceiver" then
				if current_transform.tween then
					current_transform.tween.signal = v.EventId
				end
			elseif v.type == "MeshFilter" then
				local mesh_tab = {}
				for key, val in ipairs(v.subMeshes) do
					mesh_tab[key] = {IndexStart = val.IndexStart + 1, IndexEnd = val.IndexCount + val.IndexStart, verts = v.verts, tris = v.tris, normals = v.normals}
				end
				current_transform.meshes = {}
				for key, val in ipairs(mesh_tab) do
					current_transform.meshes[key] = val
				end
				current_transform.mesh_count = #mesh_tab
			elseif v.type == "MeshRenderer" then
				for key, val in ipairs(v.materials) do
					table.insert(part_list, {name = part_name, tab = v.materials, index = key})
				end
			end
		end
	end
	if source_tab.children and source_tab.children[1] then
		for k, v in ipairs(source_tab.children) do
			explore_model_tree(v, part_name, level + 1, current_transform)
		end
	end
end

function MEM.add_metadata(model_tab)
	part_list, transform_list = {}, {}
	tween_count = 0
	explore_model_tree(model_tab.object, "[no name]", 1)
	model_tab.tween = tween_count
	if #part_list < 1 then
		model_tab.model_data = {parts = part_list, transform_list = {}, do_not_render = true}
	else
		model_tab.model_data = {parts = part_list, transform_list = transform_list}
	end
end

function load.pw_art(data, filename)
	local tab = MEM.parse_json(data)
	if MEM.check(tab, "pw_art", filename) then
		MEM.art_data = {table = tab, filename = filename}
		local dynamic_models = {}
		local model_count = {}
		if tab.dynamicProps then
			for key, val in ipairs(tab.dynamicProps) do
				dynamic_models[val.name] = true
				model_count[val.name] = (model_count[val.name] or 0) + 1
			end
		end
		if tab.dynamicCullingRanges then
			for key, val in ipairs(tab.dynamicCullingRanges) do
				for k, v in ipairs(val.members) do
					dynamic_models[v.name] = true
					model_count[v.name] = (model_count[v.name] or 0) + 1
				end
			end
		end
		if tab.staticProps then
			for key, val in ipairs(tab.staticProps) do
				model_count[val.name] = (model_count[val.name] or 0) + 1
			end
		end
		if tab.staticCullingRanges then
			for key, val in ipairs(tab.staticCullingRanges) do
				for k, v in ipairs(val.members) do
					model_count[v.name] = (model_count[v.name] or 0) + 1
				end
			end
		end

		if tab.propsDictionary[1] and tab.propsDictionary[1].object.name == "Placeholder" then
			MEM.art_data.placeholder = table.remove(tab.propsDictionary, 1)
		end

		for key, val in ipairs(tab.propsDictionary) do
			if not (val.object.name == val.key) then
				val.object.name = val.key
				G.update_navbar("Found key/name mismatch is prop "..val.key..". It has been fixed.")
			end
			MEM.add_metadata(val)
			if dynamic_models[val.key] or (val.tween > 0) then
				val.dynamic = true
			end
			val.model_data.model_count = model_count[val.key] or 0
		end

		MEM.art_data.colours = {}
		local colour_check = {}
		for key, val in ipairs(tab.colors) do
			local all_colours = val.mainColor..val.fogColor..val.glowColor..val.enemyColor
			local add_this_colour = true
			for k, v in ipairs(colour_check) do
				if v == all_colours then
					add_this_colour = false
					break
				end
			end
			if add_this_colour then
				local t = {main = val.mainColor, fog = val.fogColor, glow = val.glowColor, enemy = val.enemyColor}
				table.insert(MEM.art_data.colours, t)
				table.insert(colour_check, all_colours)
			end
		end
		local t = {main = SET.custom_colour_main, fog = SET.custom_colour_fog, glow = SET.custom_colour_glow, enemy = SET.custom_colour_enemy}
		table.insert(MEM.art_data.colours, t)
		UI.tab.tab_art.state = true
		MEM.art_reloaded = true
		return true
	else
		MEM.art_data = {}
		UI.tab.tab_art.state = false
	end
end

function load.geomancer(data, filename)
	local tab = G.safe_decode(data, filename)
	if tab then
		if tab.props then
			for key, val in pairs(tab.props) do
				for k, v in pairs(val.tweens) do
					v.table.signal = v.signal
				end
			end
		end
		MEM.geomancer_meta = tab
		return true
	else
		MEM.geomancer_meta = nil
	end
end

function MEM.load_geomancer_data(data, filename)
	load.geomancer(data, filename)
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