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

function load.pw(data)
	local tab
	tab, data = G.safe_decode(data, "level.pw")
	if not (tab and G.check_version(data, "level.pw")) then return end
	MEM.level_data.string = G.sanitise_json(data)
	MEM.level_data.enemy_set = tab.enemySet
	MEM.level_data.obstacle_set = tab.obstacleSet
	MEM.level_data.material_set = tab.materialPropertiesSet
	MEM.level_data.preview_time = tab.previewTime
	MEM.level_data.move_mode = tab.moveMode
	MEM.level_data.song_length = tonumber(tab.songLength)
	MEM.level_data.scene_name = tab.sceneDisplayName
	MEM.level_data.art_file = tab.sharedLevelArt
	local my_name = {Klear = true, Klear_ = true, kingklear = true}
	MEM.level_data.my_map = my_name[tab.mapper]
	MEM.level_data.description = tab.description
	UI.tab.tab_level.state = true
	return true
end

function load.pw_meta(data)
	local tab
	tab, data = G.safe_decode(data, "do_not_ship.pw_meta")
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
	local tab
	tab, data = G.safe_decode(data, filename)
	if not (tab and G.check_version(data, filename)) then return end
	MEM.beat_data.obstacle_list = {}
	MEM.beat_data.enemy_list = {}
	for key, val in ipairs(tab.beatData) do
		for k, v in ipairs(val.obstacles) do
			table.insert(MEM.beat_data.obstacle_list, {time = val.time, placement = v.placement, type = v.type, beat_data_key = key, obstacles_key = k})
		end
		for k, v in ipairs(val.targets) do
			local comma = string.find(v.placement, ",")
			local placement_x = string.sub(v.placement, 1, comma - 1)
			local placement_y = string.sub(v.placement, comma + 1)
			table.insert(MEM.beat_data.enemy_list, {
				time = val.time, type = v.enemyType, distance = v.distance, placement = v.placement, placement_x = placement_x, placement_y = placement_y, 
				offset = v.enemyOffset, sequence = v.enemySequence, bonus = v.bonusEnemy, shielded = v.shielded, no_ground = v.noGround, no_carve = v.noCarve,
				beat_data_key = key, enemies_key = k
			})
		end
	end

	MEM.beat_data.changed_obstacles = {}
	MEM.beat_data.changed_enemies = {}

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
	MEM.beat_reloaded = true
	return true
end

function load.pw_event(data, filename)
	local tab
	tab, data = G.safe_decode(data, filename)
	if not (tab and G.check_version(data, filename)) then	return end
	MEM.event_data.table = tab
	MEM.event_data.string = data
	MEM.event_data.filename = filename
	MEM.event_data.filter = {}
	UI.tab.tab_event.state = true
	MEM.event_reloaded = true
	return true
end

function MEM.load_geo(data, filename)
	data = G.sanitise_json(data)
	if not G.check_version(data, filename) then
		return
	end
	local chunk = string.find(data, "chunkData")
	local slices = string.find(data, "chunkSlices")
	if not (chunk and slices) then
		return
	end
	local start = string.sub(data, 1, chunk - 2)
	local chunk = string.sub(data, chunk - 1, slices - 2)
	local slices = string.sub(data, slices - 1)
	return start, chunk, slices
end

function load.pw_geo(data, filename)
	local start, chunk, slices = MEM.load_geo(data, filename)
	if not (start and chunk and slices) then
		msg.post("/navbar#navbar", hash("update_status"), {text = "Error loading geo data from "..filename})
		return
	end
	MEM.geo_data.start = start
	MEM.geo_data.chunk = chunk
	MEM.geo_data.slices = slices
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

function MEM.get_root_transform(model_tab)
	if type(model_tab) == "string" then
		model_tab = G.safe_decode(model_tab, "tween information")
	end
	if not model_tab then
		return
	end
	local found_name
	for key, val in ipairs(model_tab.object.children) do
		if #val.components > 2 then
			return false
		elseif #val.children > 0 then
			if not found_name then
				found_name = val.name
			else
				return false
			end
		end
	end
	return found_name
end

function MEM.parse_tween(script)
	local action = {}
	local str_start, str_end, x, y, z
	action.type = string.sub(script, 1, 1)
	if action.type == "W" then
		str_end = string.find(script, ";")
		action.time = string.sub(script, 2, str_end - 1)
		return action, str_end + 1
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
		return action, str_end + 1
	else
		return
	end
end

function MEM.load_props_dictionary(model_table, ignored_models)
	ignored_models = ignored_models or {}
	local current_name = ""
	
	local function find_section_old(tab, model_index, name, tree_section)
		if type(tab) == "table" then
			current_name = tab.name or current_name
			if tab.materials then
				for key, val in ipairs(tab.materials) do
					table.insert(MEM.art_data.model_list[model_index].parts, val)
					table.insert(MEM.art_data.part_names[name], current_name)
				end
			elseif tab.subMeshes then
				local mesh_tab = {}
				if tab.subMeshes then
					for key, val in ipairs(tab.subMeshes) do
						mesh_tab[key] = {IndexStart = val.IndexStart + 1, IndexEnd = val.IndexCount + val.IndexStart, verts = tab.verts, tris = tab.tris, normals = tab.normals}
					end
					for key, val in ipairs(mesh_tab) do
						table.insert(MEM.art_data.mesh_list[name], val)
					end
				end
			else
				for key, val in pairs(tab) do
					find_section(val, model_index, name)
				end
			end
		end
	end
	local function find_section(tab, model_index, name, tree_section)
		if type(tab) == "table" then
			current_name = tab.name or current_name
			if tab.components then
				for key, val in ipairs(tab.components) do
					if val.type == "Transform" then
						tree_section.transform = val.values
					elseif val.materials then
						for k, v in ipairs(val.materials) do
							table.insert(MEM.art_data.model_list[model_index].parts, v)
							table.insert(MEM.art_data.part_names[name], current_name)
						end
					elseif val.subMeshes then
						local mesh_tab = {}
						for k, v in ipairs(val.subMeshes) do
							mesh_tab[k] = {IndexStart = v.IndexStart + 1, IndexEnd = v.IndexCount + v.IndexStart, verts = val.verts, tris = val.tris, normals = val.normals}
						end
						tree_section.meshes = {}
						for k, v in ipairs(mesh_tab) do
							table.insert(MEM.art_data.mesh_list[name], v)
							tree_section.meshes[k] = #MEM.art_data.mesh_list[name]
						end
					end
				end
			end
			if tab.children then
				for key, val in ipairs(tab.children) do
					if not (val.name == "Colliders") then
						table.insert(tree_section, {})
						find_section(val, model_index, name, tree_section[#tree_section])
					end
				end
			end
			if not (tab.children or tab.components) then
				for key, val in pairs(tab) do
					find_section(val, model_index, name, tree_section)
				end
			end
		end
	end
	for k, v in ipairs(model_table) do
		if k > 1 and v.key and not (ignored_models[v.key]) then
			local tween
			if #v.object.components > 1 then
				tween = {}
				local tween_working, tween_script = true
				for key, val in ipairs(v.object.components) do
					if val.type == "LevelEventReceiver" then
						tween.signal = val.EventId
					elseif val.type == "ScriptedTween" then
						tween.script = {}
						local script_str = val.Script
						local safety = #script_str / 3
						repeat
							local str_end
							tween_working, tween_script, str_end = pcall(MEM.parse_tween, script_str)
							safety = safety - 1
							if safety < 0 or (not tween_working) then
								tween_working = false
								msg.post("/navbar#navbar", hash("update_status"), {text = "Malformed tween script in model "..v.key..". Skipping."})
								tween = {}
								break
							else
								script_str = string.sub(script_str, str_end)
								table.insert(tween.script, tween_script)
							end
						until #script_str < 1
						if not tween_working then
							break
						end
					end
				end
				if tween.script and #tween.script > 0 then
					MEM.art_data.dynamic_models[v.key] = true
				else
					tween = nil
				end
			end
			table.insert(MEM.art_data.model_names, v.key)
			table.insert(MEM.art_data.model_list, {name = v.key, parts = {}, dynamic = MEM.art_data.dynamic_models[v.key], tween = tween})
			MEM.art_data.part_names[v.key] = {}
			MEM.art_data.mesh_list[v.key] = {}
			MEM.art_data.model_tree[v.key] = {}
			find_section(v, #MEM.art_data.model_list, v.key, MEM.art_data.model_tree[v.key])
			if tween then
				local tween_root = MEM.get_root_transform(v)
				local all_parts_found = true
				for tween_key, tween_val in ipairs(tween.script) do
					if tween_val.part then
						local part_found = false
						for key, val in ipairs(MEM.art_data.model_list[#MEM.art_data.model_list].parts) do
							if MEM.art_data.part_names[v.key][key] == tween_val.part then
								tween_val.part = key
								part_found = true
								break
							elseif tween_root == tween_val.part then
								tween_val.part = 0
								part_found = true
								break
							end
						end
						if not part_found then
							all_parts_found = false
							tween_val.part = 0
						end
					end
				end
				if not all_parts_found then
					msg.post("/navbar#navbar", hash("update_status"), {text = "Tween of model "..v.key.." refers to a wrong part. Defaulting to tweening the whole model."})
				end
			end
		end
	end
end

function load.pw_art(data, filename)
	local model_table, data = G.safe_decode(data, filename)
	if not (model_table and G.check_version(data, filename)) then return end

	MEM.art_data.table_static_props = model_table.staticProps or {}
	MEM.art_data.table_dynamic_props = model_table.dynamicProps or {}
	MEM.art_data.table_culling_ranges = model_table.staticCullingRanges or {}
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
	MEM.art_data.mesh_list = {}
	MEM.art_data.model_tree = {}
	MEM.art_data.colours = {}
	local colour_check = {}
	for key, val in ipairs(model_table.colors) do
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

	MEM.load_props_dictionary(model_table.propsDictionary)

	local colours_end = string.find(data, "]") + 1
	local dictionary_start = string.find(data, "propsDictionary")
		
	MEM.art_data.string_colours = string.sub(data, 1, colours_end)
	local string_props_dictionary = string.sub(data, dictionary_start - 1)

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
	MEM.art_reloaded = true
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