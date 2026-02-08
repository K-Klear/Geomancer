local UI = require "modules.ui"
local G = require "modules.global"
local SET = require "modules.settings"
local MOD = require "modules.models"
local SND = require "modules.sound"
local COL = require "modules.colours"

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
	if not path then
		return
	end
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
					io.write(val)
					if key_count > 1 then
						io.write(",")
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
	expected_values.pw_meta = {"NORMALSection", "Volume", "Decor", "DecorGroups"}
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
	local tab = MEM.parse_json(data)
	if MEM.check(tab, "pw_meta", "do_not_ship.pw_meta") then
		UI.tab.tab_meta.state = true
		MEM.meta_data = tab
		local expected_group_index = 1
		local fix_applied = false
		for key, val in ipairs(tab.Volume) do
			local index_num = tonumber(val.groupIndex)
			if not index_num then
				break
			end
			if index_num > expected_group_index then
				val.groupIndex = expected_group_index
				fix_applied = true
				expected_group_index = expected_group_index + 1
			elseif index_num == expected_group_index then
				expected_group_index = expected_group_index + 1
			end
		end
		if fix_applied then
			G.update_navbar("Volume index information corruption detected and fixed.")
		end
		return true
	else
		MEM.meta_data = {}
		UI.tab.tab_meta.state = false
	end
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
		local obstacle_positions = {EvenMoreLeft = -0.7, FarLeft = -0.6, Left = -0.375, Center = 0, Right = 0.375, FarRight = 0.6, EvenMoreRight = 0.7}
		for key, val in ipairs(tab.beatData) do
			for k, v in ipairs(val.obstacles) do
				local time = tonumber(val.time)
				local z = (time * 3) + 0.375 + 0.125
				local position = {x = obstacle_positions[v.placement] or 0, y = 0, z = -z}
				local base_range = math.floor(z / 16)
				local t = {
					beat_data_key = key,
					obstacles_key = k,
					tab = v,
					time = time,
					type = v.type,
					position = position,
					spawn_range = base_range - 3,
					despawn_range = base_range + 4,
					ranges = {}
				}
				table.insert(obstacle_list, t)
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

function MEM.parse_chunk_data(chunk_tab)
	for key, val in ipairs(MEM.geo_data.chunks or {}) do
		if val.buffer_resource then
			MOD.buffer_resource_released(val.buffer_resource)
		end
	end
	local chunks = {}
	for key, val in ipairs(chunk_tab) do
		local id = G.parse_values(val.id)
		if #val.verts > 0 then
			local verts_parsed, triangles, normals = {}, {}, {}
			for k, v in ipairs(val.verts) do
				verts_parsed[k] = G.parse_values(v)
			end
			for i = 1, #val.tris, 3 do
				local vec_a = vmath.vector3(verts_parsed[val.tris[i + 0] + 1][1], verts_parsed[val.tris[i + 0] + 1][2], verts_parsed[val.tris[i + 0] + 1][3])
				local vec_b = vmath.vector3(verts_parsed[val.tris[i + 1] + 1][1], verts_parsed[val.tris[i + 1] + 1][2], verts_parsed[val.tris[i + 1] + 1][3])
				local vec_c = vmath.vector3(verts_parsed[val.tris[i + 2] + 1][1], verts_parsed[val.tris[i + 2] + 1][2], verts_parsed[val.tris[i + 2] + 1][3])
				local norm = vmath.normalize(vmath.cross(vec_b - vec_a, vec_c - vec_a))
				for j = 0, 2 do
					local vertex = val.tris[i + j] + 1
					table.insert(triangles, verts_parsed[vertex][1])
					table.insert(triangles, verts_parsed[vertex][2])
					table.insert(triangles, verts_parsed[vertex][3])
					table.insert(normals, norm.x)
					table.insert(normals, norm.y)
					table.insert(normals, norm.z)
				end
			end
			local t = {
				triangles = triangles,
				normals_parsed = normals,
				IndexStart = 1,
				IndexEnd = #val.tris,
			}
			MOD.create_mesh(t)
			table.insert(chunks, {
				buffer_resource = t.buffer_resource, id = id, id_str = val.id, triangles = triangles, verts_parsed = verts_parsed,
				normals_parsed = normals, verts = val.verts, tris = val.tris, meshSizes = val.meshSizes
			})
			if #val.meshSizes > 2 then
				val.meshSizes[2] = val.meshSizes[2] + val.meshSizes[3]
				val.meshSizes[3] = nil
				val.meshSizes._pure_array = nil
			end
		else
			table.insert(chunks, {id = id, id_str = val.id, empty = true})
		end
	end
	return chunks
end

function MEM.parse_slice_data(slice_tab)
	for slice_id, val in pairs(MEM.geo_data.slices or {}) do
		for k, v in ipairs(val) do
			if v.buffer_resource then
				MOD.buffer_resource_released(v.buffer_resource)
			end
		end
	end
	local slices = {}
	for key, val in ipairs(slice_tab) do
		local id_num = tonumber(val.id) or -1
		slices[id_num] = slices[id_num] or {}
		if #val.verts > 0 then
			local mesh_end = 0
			local verts_parsed = {}
			for k, v in ipairs(val.verts) do
				verts_parsed[k] = G.parse_values(v)
			end
			for mesh_index, mesh_size in ipairs(val.meshSizes) do
				local triangles, normals = {}, {}
				for i = mesh_end + 1, mesh_end + mesh_size, 3 do
					local vec_a = vmath.vector3(verts_parsed[val.tris[i + 0] + 1][1], verts_parsed[val.tris[i + 0] + 1][2], verts_parsed[val.tris[i + 0] + 1][3])
					local vec_b = vmath.vector3(verts_parsed[val.tris[i + 1] + 1][1], verts_parsed[val.tris[i + 1] + 1][2], verts_parsed[val.tris[i + 1] + 1][3])
					local vec_c = vmath.vector3(verts_parsed[val.tris[i + 2] + 1][1], verts_parsed[val.tris[i + 2] + 1][2], verts_parsed[val.tris[i + 2] + 1][3])
					local norm = vmath.normalize(vmath.cross(vec_b - vec_a, vec_c - vec_a))
					for j = 0, 2 do
						local vertex = val.tris[i + j] + 1
						table.insert(triangles, verts_parsed[vertex][1])
						table.insert(triangles, verts_parsed[vertex][2])
						table.insert(triangles, verts_parsed[vertex][3])
						table.insert(normals, norm.x)
						table.insert(normals, norm.y)
						table.insert(normals, norm.z)
					end
				end
				local t = {
					triangles = triangles,
					normals_parsed = normals
				}
				if #triangles > 0 then
					MOD.create_mesh(t)
					table.insert(slices[id_num], {
						buffer_resource = t.buffer_resource, mesh_index = mesh_index,
						triangles = triangles, verts_parsed = verts_parsed, id = id_num,
						normals_parsed = normals, verts = val.verts, tris = val.tris
					})
				else
					table.insert(slices[id_num], {
						mesh_index = mesh_index,
						triangles = triangles, verts_parsed = verts_parsed, id = id_num,
						normals_parsed = normals, verts = val.verts, tris = val.tris
					})
				end
				mesh_end = mesh_end + mesh_size
			end
			if #val.meshSizes > 2 then
				val.meshSizes[2] = val.meshSizes[2] + val.meshSizes[3]
				val.meshSizes[3] = nil
				val.meshSizes._pure_array = nil
			end
		end
	end
	return slices
end

function load.pw_geo(data, filename)
	local tab = MEM.parse_json(data)
	if MEM.check(tab, "pw_geo", filename) then
		local chunks = MEM.parse_chunk_data(tab.chunkData)
		local slices = MEM.parse_slice_data(tab.chunkSlices)
		MEM.geo_data = {table = tab, filename = filename, chunks = chunks, slices = slices}
		UI.tab.tab_geo.state = true
		return true
	else
		MEM.geo_data = {}
		UI.tab.tab_geo.state = false
	end
end

function load.pw_seq(data, filename)
	MEM.sequence_data.string = data
	MEM.sequence_data.filename = filename
	return true
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


local tween_count, part_list, transform_list
local function explore_model_tree(source_tab, part_name, level, parent_tab, is_collider)
	part_name = source_tab.name or part_name
	table.insert(transform_list, {})
	local current_transform = transform_list[#transform_list]
	if source_tab.name == "Colliders" then
		is_collider = true
	end
	if source_tab.components then
		for k, v in ipairs(source_tab.components) do
			if v.type == "Transform" then
				current_transform.position, current_transform.rotation, current_transform.scale = G.parse_transform(v.values)
				current_transform.name = part_name
				current_transform.tab = source_tab
				current_transform.level = level
				current_transform.parent_tab = parent_tab
				current_transform.collider = is_collider
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
					mesh_tab[key] = {
						IndexStart = val.IndexStart + 1, IndexEnd = val.IndexCount + val.IndexStart, verts = v.verts, tris = v.tris,
						normals = v.normals, collider = is_collider}
					if SET.preload_models then
						MOD.create_mesh(mesh_tab[key])
					end
				end
				current_transform.meshes = {}
				for key, val in ipairs(mesh_tab) do
					current_transform.meshes[key] = val
				end
				current_transform.mesh_count = #mesh_tab
			elseif v.type == "MeshRenderer" then
				for key, val in ipairs(v.materials) do
					table.insert(part_list, {name = part_name, tab = v.materials, index = key, collider = is_collider})
				end
			end
		end
	end
	if source_tab.children and source_tab.children[1] then
		for k, v in ipairs(source_tab.children) do
			explore_model_tree(v, part_name, level + 1, current_transform, is_collider)
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

function MEM.create_prop_list(tab, reindex)
	MEM.art_data.prop_list = {}
	local function add_to_prop_list(prop_tab)
		local sc = G.parse_values(prop_tab.scale)
		local point = G.parse_values(prop_tab.point)
		local scale = vmath.vector3(sc[1], sc[2], sc[3])
		local pos = vmath.vector3(point[1], point[2], point[3])
		local rot = vmath.quat(point[4], point[5], point[6], point[7])
		return {position = pos, rotation = rot, scale = scale, name = prop_tab.name, prop_tab = prop_tab}
	end
	local dynamic_models, model_count = {}, {}
	for key, val in ipairs(tab.staticProps or {}) do
		model_count[val.name] = (model_count[val.name] or 0) + 1
		local t = add_to_prop_list(val)
		local base_range = math.floor(t.position.z / 16)
		t.spawn_range = base_range - 3
		t.despawn_range = base_range + 4
		table.insert(MEM.art_data.prop_list, t)
	end
	for key, val in ipairs(MEM.art_data.table.dynamicProps or {}) do
		model_count[val.name] = (model_count[val.name] or 0) + 1
		local t = add_to_prop_list(val)
		local base_range = math.floor(t.position.z / 16)
		t.spawn_range = base_range - 3
		t.despawn_range = base_range + 4
		t.dynamic = true
		dynamic_models[val.name] = true
		table.insert(MEM.art_data.prop_list, t)
	end

	for key, val in ipairs(MEM.art_data.table.staticCullingRanges or {}) do
		local range = G.parse_values(val.range)
		for k, v in ipairs(val.members) do
			model_count[v.name] = (model_count[v.name] or 0) + 1
			local t = add_to_prop_list(v)
			t.spawn_range = range[1] - 3
			t.despawn_range = range[2] + 3
			table.insert(MEM.art_data.prop_list, t)
		end
	end
	for key, val in ipairs(MEM.art_data.table.dynamicCullingRanges or {}) do
		local range = G.parse_values(val.range)
		for k, v in ipairs(val.members) do
			model_count[v.name] = (model_count[v.name] or 0) + 1
			local t = add_to_prop_list(v)
			t.spawn_range = range[1] - 3
			t.despawn_range = range[2] + 3
			t.dynamic = true
			dynamic_models[v.name] = true
			table.insert(MEM.art_data.prop_list, t)
		end
	end
	table.sort(MEM.art_data.prop_list, function(a, b) return a.position.z < b.position.z end)
	if reindex then
		local model_index_list = {}
		for key, val in ipairs(tab.propsDictionary) do
			model_index_list[val.key] = key
		end
		for key, val in ipairs(MEM.art_data.prop_list) do
			val.model_index = model_index_list[val.name]
			val.prop_list_index = key
		end
	end
	return dynamic_models, model_count
end

function load.pw_art(data, filename)
	local tab = MEM.parse_json(data)
	
	if MEM.check(tab, "pw_art", filename) then
		MOD.release_model_resources()
		if MOD.total_time then
			msg.post("/model_viewer", hash("move_scrubber"), {time = 0})
		end
		MEM.art_data = {table = tab, filename = filename, prop_list = {}}

		local dynamic_models, model_count =	MEM.create_prop_list(tab)
		
		if tab.propsDictionary[1] and tab.propsDictionary[1].object.name == "Placeholder" then
			MEM.art_data.placeholder = table.remove(tab.propsDictionary, 1)
		end

		local model_index_list = {}
		for key, val in ipairs(tab.propsDictionary) do
			if not (val.object.name == val.key) then
				val.object.name = val.key
				G.update_navbar("Found key/name mismatch is prop "..val.key..". It has been fixed.")
			end
			model_index_list[val.key] = key
			if val.key == "PF_CollisionCube_02_tall" then
				val.object = {
					components = {
						{
							values = "0,0,0,0,0,0,1,1,1,1",
							type = "Transform",
							_key_sort = {"type", "values"}
						}
					},
					children = {
						{
							components = {
								{
									values = "0,0,0,0,0,0,1,-1,1,1",
									type = "Transform",
									_key_sort = {"type", "values"}
								},
								{
									materials = {
										[1] = "(DoNotEdit)LiveMat_Props",
										_pure_array = "[\"(DoNotEdit)LiveMat_Props\"]"
									},
									type = "MeshRenderer",
									_key_sort = {"type", "materials"}
								},
								{
									tris = {0, 1, 2, 2, 3, 0, 4, 5, 6, 6, 7, 4, 8, 9, 10, 10, 11, 8, 12, 13, 14, 14, 15, 12, 16, 17, 18, 18, 19, 16, 20, 21, 22, 22, 23, 20, 
									_pure_array = "[0,1,2,2,3,0,4,5,6,6,7,4,8,9,10,10,11,8,12,13,14,14,15,12,16,17,18,18,19,16,20,21,22,22,23,20]"},
									verts = {
										"0.5,2,0.5", "0.5,2,-0.5", "-0.5,2,-0.5", "-0.5,2,0.5", "-0.5,0,0.5", "-0.5,2,0.5", "-0.5,2,-0.5", "-0.5,0,-0.5",
										"-0.5,0,-0.5", "-0.5,2,-0.5", "0.5,2,-0.5", "0.5,0,-0.5", "0.5,0,-0.5", "0.5,0,0.5", "-0.5,0,0.5", "-0.5,0,-0.5",
										"0.5,0,0.5", "0.5,2,0.5", "-0.5,2,0.5", "-0.5,0,0.5", "0.5,0,-0.5", "0.5,2,-0.5", "0.5,2,0.5", "0.5,0,0.5",
										_pure_array = "[\"0.5,2,0.5\",\"0.5,2,-0.5\",\"-0.5,2,-0.5\",\"-0.5,2,0.5\",\"-0.5,0,0.5\",\"-0.5,2,0.5\",\"-0.5,2,-0.5\",\"-0.5,0,-0.5\",\"-0.5,0,-0.5\",\"-0.5,2,-0.5\",\"0.5,2,-0.5\",\"0.5,0,-0.5\",\"0.5,0,-0.5\",\"0.5,0,0.5\",\"-0.5,0,0.5\",\"-0.5,0,-0.5\",\"0.5,0,0.5\",\"0.5,2,0.5\",\"-0.5,2,0.5\",\"-0.5,0,0.5\",\"0.5,0,-0.5\",\"0.5,2,-0.5\",\"0.5,2,0.5\",\"0.5,0,0.5\"]"
									},
									normals = {
										"0,1,0", "0,1,0", "0,1,0", "0,1,0", "-1,0,0", "-1,0,0", "-1,0,0", "-1,0,0", "0,0,-1", "0,0,-1",
										"0,0,-1", "0,0,-1", "0,-1,0", "0,-1,0", "0,-1,0", "0,-1,0", "0,0,1", "0,0,1", "0,0,1","0,0,1",
										"1,0,0", "1,0,0", "1,0,0", "1,0,0",
										_pure_array = "[\"0,1,0\",\"0,1,0\",\"0,1,0\",\"0,1,0\",\"-1,0,0\",\"-1,0,0\",\"-1,0,0\",\"-1,0,0\",\"0,0,-1\",\"0,0,-1\",\"0,0,-1\",\"0,0,-1\",\"0,-1,0\",\"0,-1,0\",\"0,-1,0\",\"0,-1,0\",\"0,0,1\",\"0,0,1\",\"0,0,1\",\"0,0,1\",\"1,0,0\",\"1,0,0\",\"1,0,0\",\"1,0,0\"]"
									},
									subMeshes = {
										{
											IndexCount = 36,
											BaseVertex = 0,
											Topology  = "Triangles",
											IndexStart = 0,
											_key_sort = {"IndexStart", "IndexCount", "Topology", "BaseVertex"}
										}
									},
									type = "MeshFilter",
									_key_sort = {"type", "verts", "tris", "normals", "subMeshes"}
								}
							},
							children = {},
							_key_sort = {"name", "components", "children"},
							name = "Colliders"
						}
					},
					_key_sort = {"name", "components", "children"},
					name = "PF_CollisionCube_02_tall"
				}
				val._key_sort = {"key", "object"}
				val.key = "PF_CollisionCube_02_tall"
			elseif val.key == "PF_CollisionCube_01_Flat" then
				val.object = {
					components = {
						{
							values = "0,0,0,0,0,0,1,1,1,1",
							type = "Transform",
							_key_sort = {"type", "values"}
						}
					},
					children = {
						{
							components = {
								{
									values = "0,0,0,0,0,0,1,-1,1,1",
									type = "Transform",
									_key_sort = {"type", "values"}
								},
								{
									materials = {
										[1] = "(DoNotEdit)LiveMat_Props",
										_pure_array = "[\"(DoNotEdit)LiveMat_Props\"]"
									},
									type = "MeshRenderer",
									_key_sort = {"type", "materials"}
								},
								{
									tris = {0,1,2,2,3,0,4,5,6,6,7,4,8,9,10,10,11,8,12,13,14,14,15,12,16,17,18,18,19,16,20,21,22,22,23,20, 
									_pure_array = "[0,1,2,2,3,0,4,5,6,6,7,4,8,9,10,10,11,8,12,13,14,14,15,12,16,17,18,18,19,16,20,21,22,22,23,20]"},
									verts = {
										"1.5,0.1,0.5","1.5,0.1,-0.5","-1.5,0.1,-0.5","-1.5,0.1,0.5","-1.5,-0.1,0.5","-1.5,0.1,0.5","-1.5,0.1,-0.5","-1.5,-0.1,-0.5",
										"-1.5,-0.1,-0.5","-1.5,0.1,-0.5","1.5,0.1,-0.5","1.5,-0.1,-0.5","1.5,-0.1,-0.5","1.5,-0.1,0.5","-1.5,-0.1,0.5","-1.5,-0.1,-0.5",
										"1.5,-0.1,0.5","1.5,0.1,0.5","-1.5,0.1,0.5","-1.5,-0.1,0.5","1.5,-0.1,-0.5","1.5,0.1,-0.5","1.5,0.1,0.5","1.5,-0.1,0.5",
										_pure_array = "[\"1.5,0.1,0.5\",\"1.5,0.1,-0.5\",\"-1.5,0.1,-0.5\",\"-1.5,0.1,0.5\",\"-1.5,-0.1,0.5\",\"-1.5,0.1,0.5\",\"-1.5,0.1,-0.5\",\"-1.5,-0.1,-0.5\",\"-1.5,-0.1,-0.5\",\"-1.5,0.1,-0.5\",\"1.5,0.1,-0.5\",\"1.5,-0.1,-0.5\",\"1.5,-0.1,-0.5\",\"1.5,-0.1,0.5\",\"-1.5,-0.1,0.5\",\"-1.5,-0.1,-0.5\",\"1.5,-0.1,0.5\",\"1.5,0.1,0.5\",\"-1.5,0.1,0.5\",\"-1.5,-0.1,0.5\",\"1.5,-0.1,-0.5\",\"1.5,0.1,-0.5\",\"1.5,0.1,0.5\",\"1.5,-0.1,0.5\"]"
									},
									normals = {
										"0,1,0","0,1,0","0,1,0",
										"0,1,0","-1,0,0","-1,0,0","-1,0,0","-1,0,0","0,0,-1","0,0,-1","0,0,-1","0,0,-1","0,-1,0",
										"0,-1,0","0,-1,0","0,-1,0","0,0,1","0,0,1","0,0,1","0,0,1","1,0,0","1,0,0","1,0,0","1,0,0",
										_pure_array = "[\"0,1,0\",\"0,1,0\",\"0,1,0\",\"0,1,0\",\"-1,0,0\",\"-1,0,0\",\"-1,0,0\",\"-1,0,0\",\"0,0,-1\",\"0,0,-1\",\"0,0,-1\",\"0,0,-1\",\"0,-1,0\",\"0,-1,0\",\"0,-1,0\",\"0,-1,0\",\"0,0,1\",\"0,0,1\",\"0,0,1\",\"0,0,1\",\"1,0,0\",\"1,0,0\",\"1,0,0\",\"1,0,0\"]"
									},
									subMeshes = {
										{
											IndexCount = 36,
											BaseVertex = 0,
											Topology  = "Triangles",
											IndexStart = 0,
											_key_sort = {"IndexStart", "IndexCount", "Topology", "BaseVertex"}
										}
									},
									type = "MeshFilter",
									_key_sort = {"type", "verts", "tris", "normals", "subMeshes"}
								}
							},
							children = {},
							_key_sort = {"name", "components", "children"},
							name = "Colliders"
						}
					},
					_key_sort = {"name", "components", "children"},
					name = "PF_CollisionCube_01_Flat"
				}
				val._key_sort = {"key", "object"}
				val.key = "PF_CollisionCube_01_Flat"
			end
			MEM.add_metadata(val)

			if dynamic_models[val.key] or (val.tween > 0) then
				val.dynamic = true
			end
			val.model_data.model_count = model_count[val.key] or 0
		end

		for key, val in ipairs(MEM.art_data.prop_list) do
			val.model_index = model_index_list[val.name]
			val.prop_list_index = key
		end

		MEM.art_data.colours = {}
		MEM.art_data.colour_list = {}
		local colour_check = {}
		for key, val in ipairs(tab.colors) do
			local time, end_time, duration = tonumber(val.secondsStart), tonumber(val.secondsEnd), tonumber(val.transitionTime)
			if time == end_time then end_time = nil end
			if duration < 0 then duration = 1 end
			local main = COL.str_to_colour(val.mainColor)
			local fog = COL.str_to_colour(val.fogColor)
			local glow = COL.str_to_colour(val.glowColor)
			local enemy = COL.str_to_colour(val.enemyColor)
			local h, s, v = COL.rgb_to_hsv(glow)
			h = (h - 0.5) % 1
			local glow_inv = COL.hsv_to_rgb(h, s, v)
			table.insert(MEM.art_data.colour_list, {
				main = main, fog = fog, glow = glow, enemy = enemy, glow_inv = glow_inv, time = time, end_time = end_time, duration = duration
			})
			local all_colours = val.mainColor..val.fogColor..val.glowColor..val.enemyColor
			if not colour_check[all_colours] then
				local t = {main = main, fog = fog, glow = glow, enemy = enemy}
				table.insert(MEM.art_data.colours, t)
				colour_check[all_colours] = true
			end
		end
		table.insert(MEM.art_data.colour_list, {time = math.huge})
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
				for k, v in pairs(val.tweens or {}) do
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

function load.ogg(data, filename)
	MEM.music_raw = data
	MEM.music = SND.load_music(data)
	if MEM.music then
		return true
	end
end

function load.png(data, filename)
	MEM.poster = data
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

function MEM.remove_geomanced_slice(slice_tab)
	if slice_tab.original_size then
		slice_tab[1].triangles = slice_tab[1].triangles or {}
		slice_tab[1].normals_parsed = slice_tab[1].normals_parsed or {}
		slice_tab[1].verts_parsed = slice_tab[1].verts_parsed or {}
		local triangles_first = #slice_tab[1].triangles
		for i = slice_tab.original_size, #slice_tab[2].tris - 1 do
			local j = i * 3
			slice_tab[1].tris[i + 1] = nil
			slice_tab[1].triangles[j + 1] = nil
			slice_tab[1].triangles[j + 2] = nil
			slice_tab[1].triangles[j + 3] = nil
			slice_tab[1].normals_parsed[j + 1] = nil
			slice_tab[1].normals_parsed[j + 2] = nil
			slice_tab[1].normals_parsed[j + 3] = nil
			slice_tab[2].tris[i + 1] = nil
			slice_tab[2].triangles[j + 1 - triangles_first] = nil
			slice_tab[2].triangles[j + 2 - triangles_first] = nil
			slice_tab[2].triangles[j + 3 - triangles_first] = nil
			slice_tab[2].normals_parsed[j + 1 - triangles_first] = nil
			slice_tab[2].normals_parsed[j + 2 - triangles_first] = nil
			slice_tab[2].normals_parsed[j + 3 - triangles_first] = nil
		end
		local highest_vert = 1
		for k, v in ipairs(slice_tab[1].tris) do
			highest_vert = math.max(highest_vert, v + 1)
		end
		for i = highest_vert + 1, #slice_tab[1].verts do
			slice_tab[1].verts[i] = nil
			slice_tab[1].verts_parsed = nil
			slice_tab[2].verts[i] = nil
			slice_tab[2].verts_parsed = nil
		end
		if slice_tab[1].buffer_resource then
			MOD.buffer_resource_released(slice_tab[1].buffer_resource)
		end
		if slice_tab[2].buffer_resource then
			MOD.buffer_resource_released(slice_tab[2].buffer_resource)
		end
		if #slice_tab[1].triangles > 0 then
			MOD.create_mesh(slice_tab[1])
		else
			slice_tab[1].buffer_resource = nil
		end
		if #slice_tab[2].triangles > 0 then
			MOD.create_mesh(slice_tab[2])
		else
			slice_tab[2].buffer_resource = nil
		end
		slice_tab.modified = true
		slice_tab.original_size = nil
		return 1
	else
		return 0
	end
end

function MEM.remove_geomanced_chunk(chunk_tab)
	if chunk_tab.original_size then
		for i = chunk_tab.original_size, #chunk_tab.tris - 1 do
			chunk_tab.tris[i + 1] = nil
			chunk_tab.triangles[i * 3 + 1] = nil
			chunk_tab.triangles[i * 3 + 2] = nil
			chunk_tab.triangles[i * 3 + 3] = nil
			chunk_tab.normals_parsed[i * 3 + 1] = nil
			chunk_tab.normals_parsed[i * 3 + 2] = nil
			chunk_tab.normals_parsed[i * 3 + 3] = nil
		end
		local highest_vert = 1
		for k, v in ipairs(chunk_tab.tris) do
			highest_vert = math.max(highest_vert, v + 1)
		end
		for i = highest_vert + 1, #chunk_tab.verts do
			chunk_tab.verts[i] = nil
			chunk_tab.verts_parsed = nil
		end
		if chunk_tab.buffer_resource then
			MOD.buffer_resource_released(chunk_tab.buffer_resource)
		end
		if #chunk_tab.triangles > 0 then
			MOD.create_mesh(chunk_tab)
		else
			chunk_tab.buffer_resource = nil
		end
		chunk_tab.modified = true
		chunk_tab.original_size = nil
		return 1
	else
		return 0
	end
end

function MEM.setup_culling_ranges()
	MOD.culling_ranges = {visible_slices = {}, visible_props = {}, visible_chunks = {}, visible_obstacles = {}, visible_enemies = {}}
	if MEM.geo_data.slices then
		for slice_id, val in pairs(MEM.geo_data.slices) do
			local range_spawn = math.max(slice_id - 3, 0)
			local range_despawn = math.max(slice_id + 4, 0)
			for i = range_spawn, range_despawn do
				MOD.culling_ranges[i] = MOD.culling_ranges[i] or {slices = {}, props = {}, signals = {}, chunks = {}, obstacles = {}, enemies = {}}
				for k, v in ipairs(val) do
					if v.triangles and #v.triangles > 0 then
						v.ranges = v.ranges or {}
						v.ranges[i] = true
						table.insert(MOD.culling_ranges[i].slices, v)
					end
				end
			end
		end
	end
	if MEM.geo_data.chunks then
		for key, val in ipairs(MEM.geo_data.chunks) do
			if val.triangles and #val.triangles > 0 then
				local range_spawn = math.max(val.id[3] - 3, 0)
				local range_despawn = math.max(val.id[3] + 4, 0)
				val.ranges = {}
				for i = range_spawn, range_despawn do
					MOD.culling_ranges[i] = MOD.culling_ranges[i] or {slices = {}, props = {}, signals = {}, chunks = {}, obstacles = {}, enemies = {}}
					table.insert(MOD.culling_ranges[i].chunks, val)
					val.ranges[i] = true
				end
			end
		end
	end
	local infinite_prop_list = {}
	if MEM.art_data.prop_list then
		for key, val in ipairs(MEM.art_data.prop_list) do
			val.ranges = {}
			if val.spawn_range > val.despawn_range then
				table.insert(infinite_prop_list, val)
			end
			for i = math.max(val.spawn_range, 0), math.max(val.despawn_range, 0) do
				MOD.culling_ranges[i] = MOD.culling_ranges[i] or {slices = {}, props = {}, signals = {}, chunks = {}, obstacles = {}, enemies = {}}
				table.insert(MOD.culling_ranges[i].props, val)
				val.ranges[i] = true
			end
		end
	end
	if MEM.beat_data.obstacle_list then
		for key, val in ipairs(MEM.beat_data.obstacle_list) do
			for i = math.max(val.spawn_range, 0), math.max(val.despawn_range, 0) do
				MOD.culling_ranges[i] = MOD.culling_ranges[i] or {slices = {}, props = {}, signals = {}, chunks = {}, obstacles = {}, enemies = {}}
				table.insert(MOD.culling_ranges[i].obstacles, val)
				val.ranges[i] = true
			end
		end
	end
	
	local max_range = 0
	for k, v in pairs(MOD.culling_ranges) do
		if type(k) == "number" then
			max_range = math.max(max_range, k)
		end
	end
	MOD.max_culling_range = max_range
	for key, val in ipairs(infinite_prop_list) do
		for i = math.max(val.spawn_range, 0), max_range do
			MOD.culling_ranges[i] = MOD.culling_ranges[i] or {slices = {}, props = {}, signals = {}, chunks = {}, obstacles = {}, enemies = {}}
			table.insert(MOD.culling_ranges[i].props, val)
			val.ranges[i] = true
		end
	end
end

return MEM