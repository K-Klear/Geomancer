local ART = {}
local MEM = require "modules.memory"
local UI = require "modules.ui"
local S = require "modules.status"
local G = require "modules.global"

local material_highlight, part_highlight, model_highlight
local material_highlight_base, part_highlight_base, model_highlight_base
local model_page, part_page = 0, 0
local model_page_max, part_page_max = 0, 0
local tween_page, tween_page_max = 0, 0
local selected_model_index, selected_part_index, current_material
local selected_model = false

local replace_model_index
local replace_model = false

local selection_mode

local current_tween_action

--local TWEEN_NEW_BASE_Y = 220

function ART.reset()
	model_page, part_page = 0, 0
	model_page_max, part_page_max = 0, 0
	selected_model_index, selected_part_index, current_material = nil
	selected_model = false
	gui.set_enabled(material_highlight, false)
	gui.set_enabled(model_highlight, false)
	gui.set_enabled(part_highlight, false)
end

local material_list = {
	-- default
	"(DoNotEdit)LiveMat_Props",
	"(DoNotEdit)LiveMat_LevelGeoSimple",
	"(DoNotEdit)LiveMat_Glow",
	"(DoNotEdit)LiveMat_GlowInvert",
	--white
	"(DoNotEdit)LiveMat_EnemyGlow",
	"(DoNotEdit)LiveMat_EnemyGlow_Gun",
	"(DoNotEdit)LiveMat_ParticleMesh_EnviroColor",
	"(DoNotEdit)LiveMat_ParticleMesh_Glow",
	--black
	"(DoNotEdit)LiveMat_MegaHitTrail",
	"(DoNotEdit)LiveMat_Gunmat New Three Color",
	--transparent
	"(DoNotEdit)LiveMat_Player_MuzzleFlashSquirtgun",
	"(DoNotEdit)LiveMat_Squirtgun_drops",
	--variants of standard
	"(DoNotEdit)LiveMat_Pedestrians_Dissolve",
	"(DoNotEdit)LiveMat_Continental Interior 1",
	"(DoNotEdit)LiveMat_Continental Interior 2",
	"(DoNotEdit)LiveMat_FrontEnd_Building",
	"(DoNotEdit)LiveMat_LevelGeoComplex",
	"(DoNotEdit)LiveMat_Enemies_Targets",
	-- combinations
	"(DoNotEdit)LiveMat_Obstacles",
	"(DoNotEdit)LiveMat_MRObstacles",
	"(DoNotEdit)LiveMat_Props_NoDistortion",
	"(DoNotEdit)LiveMat_ParticleMesh_GlowMultiply",
	"(DoNotEdit)LiveMat_Pedestrians",
	"(DoNotEdit)LiveMat_PedestriansAlt",
	-- unique
	"(DoNotEdit)LiveMat_Enemies_Shielded",
	"(DoNotEdit)LiveMat_Beatcubes_mat",
	"(DoNotEdit)LiveMat_Enemies_DeadBody",
	-- chaotic
	"(DoNotEdit)LiveMat_Enemies",
	"(DoNotEdit)LiveMat_Boss",
	"(DoNotEdit)LiveMat_PlayerRingOuter2"
}

local known_dynamic_list = {
	
}

function ART.setup()
	for i = 1, 32 do
		if material_list[i] then
			gui.set_text(gui.get_node("mat_"..i.."/text"), string.sub(material_list[i], 20))
		else
			gui.set_enabled(gui.get_node("mat_"..i.."/button_white"), false)
		end
	end
	material_highlight = gui.get_node("button_highlight")
	model_highlight = gui.get_node("model_highlight")
	part_highlight = gui.get_node("part_highlight")
	gui.set_enabled(material_highlight, false)
	gui.set_enabled(model_highlight, false)
	gui.set_enabled(part_highlight, false)
	model_highlight_base = gui.get_position(gui.get_node("model_list_1/button_white"))
	part_highlight_base = gui.get_position(gui.get_node("part_list_1/button_white"))
	material_highlight_base = gui.get_position(gui.get_node("mat_1/button_white"))
	gui.set_enabled(gui.get_node("tween_box"), false)
	gui.set_enabled(gui.get_node("action_type_box"), false)
end

local function show_model_pages()
	if model_page_max > 0 then
		gui.set_enabled(gui.get_node("model_page_up/button_white"), true)
		gui.set_enabled(gui.get_node("model_page_down/button_white"), true)
		gui.set_enabled(gui.get_node("model_page"), true)
		UI.load_template({"model_page_up", "model_page_down"})
	else
		gui.set_enabled(gui.get_node("model_page_up/button_white"), false)
		gui.set_enabled(gui.get_node("model_page_down/button_white"), false)
		gui.set_enabled(gui.get_node("model_page"), false)
		UI.unload_template({"model_page_up", "model_page_down"})
	end
end

local function show_part_pages()
	if part_page_max > 0 then
		gui.set_enabled(gui.get_node("part_page_up/button_white"), true)
		gui.set_enabled(gui.get_node("part_page_down/button_white"), true)
		gui.set_enabled(gui.get_node("part_page"), true)
		UI.load_template({"part_page_up", "part_page_down"})
	else
		gui.set_enabled(gui.get_node("part_page_up/button_white"), false)
		gui.set_enabled(gui.get_node("part_page_down/button_white"), false)
		gui.set_enabled(gui.get_node("part_page"), false)
		UI.unload_template({"part_page_up", "part_page_down"})
	end
end

local function show_tween_pages()
	if tween_page_max > 0 then
		gui.set_enabled(gui.get_node("tween_page_up/button_white"), true)
		gui.set_enabled(gui.get_node("tween_page_down/button_white"), true)
		gui.set_enabled(gui.get_node("tween_page"), true)
		UI.load_template({"tween_page_up", "tween_page_down"})
	else
		gui.set_enabled(gui.get_node("tween_page_up/button_white"), false)
		gui.set_enabled(gui.get_node("tween_page_down/button_white"), false)
		gui.set_enabled(gui.get_node("tween_page"), false)
		UI.unload_template({"tween_page_up", "tween_page_down"})
	end
end

local function highlight_model()
	if selected_model_index and selected_model_index > (model_page * 10) and (selected_model_index - 1) < (model_page + 1) * 10 then
		local pos = vmath.vector3(model_highlight_base.x, model_highlight_base.y - (selected_model_index - 1 - (model_page * 10)) * 60, 0)
		gui.set_position(model_highlight, pos)
		gui.set_enabled(model_highlight, true)
	else
		gui.set_enabled(model_highlight, false)
	end
end

local function highlight_part()
	if selected_part_index and selected_part_index > (part_page * 10) and (selected_part_index - 1) < (part_page + 1) * 10 then
		local pos = vmath.vector3(part_highlight_base.x, part_highlight_base.y - (selected_part_index - 1 - (part_page * 10)) * 60, 0)
		gui.set_position(part_highlight, pos)
		gui.set_enabled(part_highlight, true)
	else
		gui.set_enabled(part_highlight, false)
	end
	if current_material then
		gui.set_enabled(material_highlight, true)
		local material_index
		for key, val in ipairs(material_list) do
			gui.set_enabled(gui.get_node("mat_"..key.."/button_white"), true)
			UI.load_template("mat_"..key)
			if val == current_material then
				material_index = key
			end
		end
		local pos = vmath.vector3(material_highlight_base)
		if material_index > 15 then
			pos.x = pos.x + 221
			pos.y = pos.y - (40 * (material_index - 16))
		else
			pos.y = pos.y - (40 * (material_index - 1))
		end
		gui.set_position(material_highlight, pos)
	else
		gui.set_enabled(material_highlight, false)
		for key, val in ipairs(material_list) do
			gui.set_enabled(gui.get_node("mat_"..key.."/button_white"), false)
			UI.unload_template("mat_"..key)
		end
	end
end

local function populate_model_list()
	for i = 1, 10 do
		local template_name = "model_list_"..tostring(i)
		local node_name = template_name.."/button_white"
		local node = gui.get_node(node_name)
		local node_text = gui.get_node(template_name.."/text")
		local model_data = MEM.art_data.model_list[i + (10 * model_page)]

		if model_data then
			gui.set_enabled(node, true)
			gui.set_text(node_text, model_data.name)
			UI.load_template(template_name)
			template_name = "dynamic_"..tostring(i)
			gui.set_enabled(gui.get_node(template_name.."/button_white"), true)
			if model_data.dynamic then
				gui.set_text(gui.get_node(template_name.."/text"), "X")
			else
				gui.set_text(gui.get_node(template_name.."/text"), "")
			end
			UI.load_template(template_name)
			template_name = "tween_"..tostring(i)
			gui.set_enabled(gui.get_node(template_name.."/button_white"), true)
			if model_data.tween then
				gui.set_text(gui.get_node(template_name.."/text"), "X")
			else
				gui.set_text(gui.get_node(template_name.."/text"), "")
			end
			UI.load_template(template_name)
		else
			gui.set_enabled(node, false)
			gui.set_text(node_text, "")
			UI.unload_template(template_name)
			template_name = "dynamic_"..tostring(i)
			gui.set_enabled(gui.get_node(template_name.."/button_white"), false)
			template_name = "tween_"..tostring(i)
			gui.set_enabled(gui.get_node(template_name.."/button_white"), false)
		end
	end
	gui.set_text(gui.get_node("model_page"), tostring(model_page + 1).."/"..tostring(model_page_max + 1))
	show_model_pages()
	highlight_model()
end

local function populate_part_list()
	if selected_model then
		part_page_max = math.floor((#MEM.art_data.part_names[selected_model] - 1) / 10)
	end
	for i = 1, 10 do
		local template_name = "part_list_"..tostring(i)
		local node_name = template_name.."/button_white"
		local node = gui.get_node(node_name)
		local node_text = gui.get_node(template_name.."/text")

		local part_data
		if selected_model then
			part_data = MEM.art_data.part_names[selected_model][i + (10 * part_page)]
		end

		if part_data then
			gui.set_enabled(node, true)
			gui.set_text(node_text, part_data)
			UI.load_template(template_name)
		else
			gui.set_enabled(node, false)
			gui.set_text(node_text, "")
			UI.unload_template(template_name)
		end
	end
	gui.set_text(gui.get_node("part_page"), tostring(part_page + 1).."/"..tostring(part_page_max + 1))
	show_part_pages()
	highlight_model()
	highlight_part()
end

local function sort_models()
	if selection_mode then
		close_replace_box()
	end
	table.sort(MEM.art_data.model_names, function(a, b) return string.lower(a) < string.lower(b) end)
	table.sort(MEM.art_data.model_list, function(a, b) return string.lower(a.name) < string.lower(b.name) end)
	if selected_model then
		for key, val in ipairs(MEM.art_data.model_names) do
			if val == selected_model then
				selected_model_index = key
				break
			end
		end
	end
	populate_model_list()
end

local function set_model_as_dynamic(key, value)
	local model_name = MEM.art_data.model_list[key].name
	if value == nil then
		value = not MEM.art_data.dynamic_models[model_name]
	end
	if MEM.art_data.model_list[key].tween then
		value = true
	end
	MEM.art_data.model_list[key].dynamic = value
	MEM.art_data.dynamic_models[model_name] = value
	return value
end

local function close_action_type_box()
	UI.unload_template()
	gui.set_enabled(gui.get_node("action_type_box"), false)
	current_tween_action = nil
end

local function open_action_type_box()
	UI.unload_template()
	UI.load_template({"action_move", "action_scale", "action_rotate", "action_wait", "action_delete"})
	gui.set_enabled(gui.get_node("action_type_box"), true)
end

local function close_tween_box()
	close_action_type_box()
	if #MEM.art_data.model_list[selected_model_index].tween.script < 1 then
		MEM.art_data.model_list[selected_model_index].tween = nil
		set_model_as_dynamic(selected_model_index, false)
	else
		set_model_as_dynamic(selected_model_index, true)
	end
	gui.set_enabled(gui.get_node("tween_box"), false)
	UI.unload_template()
	UI.load_template(UI.tab.tab_art.buttons)
	populate_model_list()
	populate_part_list()
	tween_page, tween_page_max = 0, 0
	UI.switch_cleanup = nil
end

local function calculate_tween_speed(tween_script)
	local v1 = vmath.vector3(tween_script.start_state.x, tween_script.start_state.y, tween_script.start_state.z)
	local v2 = vmath.vector3(tween_script.end_state.x, tween_script.end_state.y, tween_script.end_state.z)
	local speed = vmath.length(v1 - v2) / tween_script.time
	if not (speed == speed) then
		speed = 1/0
	end
	return math.floor(speed * 100) / 100
end

local function calculate_tween_time(tween_script, speed)
	local v1 = vmath.vector3(tween_script.start_state.x, tween_script.start_state.y, tween_script.start_state.z)
	local v2 = vmath.vector3(tween_script.end_state.x, tween_script.end_state.y, tween_script.end_state.z)
	local time = vmath.length(v1 - v2) / speed
	if not (time == time) or (time == 1/0) then
		time = 0
	end
	return math.floor(time * 100) / 100
end

local function populate_tween_list(tween_script)
	local action_types = {R = "Rotate", T = "Move", S = "Scale", W = "Wait"}
	for i = 1, 10 do
		local tween_index = i + (10 * tween_page)
		if tween_script[tween_index] then
			if tween_index > 1 then
				gui.set_enabled(gui.get_node("tween_up_"..i.."/button_white"), true)
				UI.load_template("tween_up_"..i)
			end
			if tween_index < #tween_script then
				gui.set_enabled(gui.get_node("tween_down_"..i.."/button_white"), true)
				UI.load_template("tween_down_"..i)
			else
				gui.set_enabled(gui.get_node("tween_down_"..i.."/button_white"), false)
			end
			gui.set_enabled(gui.get_node("tween_type_"..i.."/button_white"), true)
			gui.set_text(gui.get_node("tween_type_"..i.."/text"), action_types[tween_script[tween_index].type])
			UI.load_template("tween_type_"..i)
			gui.set_enabled(gui.get_node("tween_time_"..i.."/box"), true)
			gui.set_text(gui.get_node("tween_time_"..i.."/text"), tonumber(tween_script[tween_index].time))
			UI.load_text_field("tween_time_"..i, 6)

			if tween_script[tween_index].type == "W" then
				gui.set_enabled(gui.get_node("tween_start_x_"..i.."/box"), false)
				gui.set_enabled(gui.get_node("tween_start_y_"..i.."/box"), false)
				gui.set_enabled(gui.get_node("tween_start_z_"..i.."/box"), false)
				gui.set_enabled(gui.get_node("tween_end_x_"..i.."/box"), false)
				gui.set_enabled(gui.get_node("tween_end_y_"..i.."/box"), false)
				gui.set_enabled(gui.get_node("tween_end_z_"..i.."/box"), false)
				gui.set_enabled(gui.get_node("tween_speed_"..i.."/box"), false)
				gui.set_enabled(gui.get_node("tween_part_"..i.."/button_white"), false)
			else
				gui.set_enabled(gui.get_node("tween_start_x_"..i.."/box"), true)
				gui.set_enabled(gui.get_node("tween_start_y_"..i.."/box"), true)
				gui.set_enabled(gui.get_node("tween_start_z_"..i.."/box"), true)
				gui.set_text(gui.get_node("tween_start_x_"..i.."/text"), tween_script[tween_index].start_state.x)
				gui.set_text(gui.get_node("tween_start_y_"..i.."/text"), tween_script[tween_index].start_state.y)
				gui.set_text(gui.get_node("tween_start_z_"..i.."/text"), tween_script[tween_index].start_state.z)
				UI.load_text_field("tween_start_x_"..i, 7)
				UI.load_text_field("tween_start_y_"..i, 7)
				UI.load_text_field("tween_start_z_"..i, 7)
				gui.set_enabled(gui.get_node("tween_end_x_"..i.."/box"), true)
				gui.set_enabled(gui.get_node("tween_end_y_"..i.."/box"), true)
				gui.set_enabled(gui.get_node("tween_end_z_"..i.."/box"), true)
				gui.set_text(gui.get_node("tween_end_x_"..i.."/text"), tween_script[tween_index].end_state.x)
				gui.set_text(gui.get_node("tween_end_y_"..i.."/text"), tween_script[tween_index].end_state.y)
				gui.set_text(gui.get_node("tween_end_z_"..i.."/text"), tween_script[tween_index].end_state.z)
				UI.load_text_field("tween_end_x_"..i, 7)
				UI.load_text_field("tween_end_y_"..i, 7)
				UI.load_text_field("tween_end_z_"..i, 7)
				if tween_script[tween_index].type == "T" then
					gui.set_enabled(gui.get_node("tween_speed_"..i.."/box"), true)
					gui.set_text(gui.get_node("tween_speed_"..i.."/text"), calculate_tween_speed(tween_script[tween_index]))
					UI.load_text_field("tween_speed_"..i, 7)
				else
					gui.set_enabled(gui.get_node("tween_speed_"..i.."/box"), false)
				end
				gui.set_enabled(gui.get_node("tween_part_"..i.."/button_white"), true)
				local part_name = MEM.art_data.part_names[selected_model][tween_script[tween_index].part]
				gui.set_text(gui.get_node("tween_part_"..i.."/text"), part_name)
				UI.load_template("tween_part_"..i)
			end
		else
			gui.set_enabled(gui.get_node("tween_up_"..i.."/button_white"), false)
			gui.set_enabled(gui.get_node("tween_down_"..i.."/button_white"), false)
			gui.set_enabled(gui.get_node("tween_type_"..i.."/button_white"), false)
			gui.set_enabled(gui.get_node("tween_time_"..i.."/box"), false)
			gui.set_enabled(gui.get_node("tween_start_x_"..i.."/box"), false)
			gui.set_enabled(gui.get_node("tween_start_y_"..i.."/box"), false)
			gui.set_enabled(gui.get_node("tween_start_z_"..i.."/box"), false)
			gui.set_enabled(gui.get_node("tween_end_x_"..i.."/box"), false)
			gui.set_enabled(gui.get_node("tween_end_y_"..i.."/box"), false)
			gui.set_enabled(gui.get_node("tween_end_z_"..i.."/box"), false)
			gui.set_enabled(gui.get_node("tween_speed_"..i.."/box"), false)
			gui.set_enabled(gui.get_node("tween_part_"..i.."/button_white"), false)
		end
	end
	local new_tween_offset = math.min(#tween_script - (10 * tween_page), 10) * 50
	gui.set_text(gui.get_node("tween_page"), tostring(tween_page + 1).."/"..tostring(tween_page_max + 1))
	show_tween_pages()
	--gui.set_position(gui.get_node("tween_new/button_white"), vmath.vector3(0, TWEEN_NEW_BASE_Y - new_tween_offset, 0))
	UI.load_template("tween_new")
end

local function open_tween_box()
	UI.unload_template()
	local model_tab = MEM.art_data.model_list[selected_model_index]
	if not model_tab.tween then
		model_tab.tween = {signal = "tween", script = {}}
	end
	tween_page_max = math.floor((#model_tab.tween.script - 1) / 10)
	tween_page = math.min(tween_page, tween_page_max)
	populate_tween_list(model_tab.tween.script)
	
	UI.load_template("tween_box_close")
	gui.set_text(gui.get_node("lbl_tween_model"), "Model: "..model_tab.name)
	UI.load_text_field("tween_signal", 14)
	gui.set_enabled(gui.get_node("tween_box"), true)
	gui.set_text(gui.get_node("tween_signal/text"), model_tab.tween.signal)
	UI.switch_cleanup = close_tween_box
end

local function import_models()
	local model_data
	local num, path = diags.open("zip,pw_art")
	if path then
		local f = io.open(path, "rb")
		if f then
			if string.sub(path, -3) == "zip" then
				local zip_data = f:read("*a")
				local archive = zip.open(zip_data)
				local file_index = zip.get_number_of_entries(archive) - 1
				for i = 0, file_index do
					local file = zip.extract_by_index(archive, i)
					if string.sub(file.name, -6) == "pw_art" then
						model_data = file.content
						break
					end
				end
			else
				model_data = f:read("*a")
			end
		end
		io.close(f)
	end
	if model_data then
		local model_count = 0
		local data
		model_data, data = G.safe_decode(model_data, "Selected pw_art file")
		if not (model_data and G.check_version(data, "Selected pw_art file")) then return end
		local ignore_list = {}
		for key, val in ipairs(MEM.art_data.model_list) do
			ignore_list[val.name] = true
		end
		local existing_model_count = #MEM.art_data.model_list
		MEM.load_props_dictionary(model_data.propsDictionary, ignore_list)
		
		local dictionary_start = string.find(data, "propsDictionary")
		local string_props_dictionary = string.sub(data, dictionary_start - 1)
		local start_index = 1018
		local search_string = "{\"key"
		local key_indices = {}
		repeat
			local next_key_index = string.find(string_props_dictionary, search_string, start_index)
			if next_key_index then
				if not ignore_list[model_data.propsDictionary[#key_indices + 2].key] then
					table.insert(key_indices, next_key_index)
					model_count = model_count + 1
				end
				start_index = next_key_index + 5
			end
		until not next_key_index
		for i = 1, #key_indices - 1 do
			MEM.art_data.model_list[existing_model_count + i].string = string.sub(string_props_dictionary, key_indices[i], key_indices[i + 1] - 2)
		end
		if #key_indices > 0 then
			MEM.art_data.model_list[existing_model_count + #key_indices].string = string.sub(string_props_dictionary, key_indices[#key_indices], -3)
		end
		if existing_model_count < 1 and model_count > 0 then
			MEM.art_data.string_dictionary = string.sub(MEM.art_data.string_dictionary, 1, -2)..","
		end
		return model_count
	end
end

local function import_model_data()
	local model_data
	local num, path = diags.open("zip,pw_art")
	if path then
		local f = io.open(path, "rb")
		if f then
			if string.sub(path, -3) == "zip" then
				local zip_data = f:read("*a")
				local archive = zip.open(zip_data)
				local file_index = zip.get_number_of_entries(archive) - 1
				for i = 0, file_index do
					local file = zip.extract_by_index(archive, i)
					if string.sub(file.name, -6) == "pw_art" then
						model_data = file.content
						break
					end
				end
			else
				model_data = f:read("*a")
			end
		end
		io.close(f)
	end
	if model_data then
		local data
		model_data, data = G.safe_decode(model_data, "Selected pw_art file")
		if not (model_data and G.check_version(data, filename)) then return end
		local model_list = {}
		for key, val in ipairs(MEM.art_data.model_list) do
			model_list[val.name] = key
		end
		local checked_models = {}
		for key, val in ipairs(model_data.staticProps or {}) do
			if (not checked_models[val.name]) and model_list[val.name] then
				set_model_as_dynamic(model_list[val.name], false)
				checked_models[val.name] = true
			end
		end
		for key, val in ipairs(model_data.dynamicProps or {}) do
			if (not checked_models[val.name]) and model_list[val.name] then
				set_model_as_dynamic(model_list[val.name], true)
				checked_models[val.name] = true
			end
		end
		for _key, _val in ipairs(model_data.staticCullingRanges or {}) do
			for key, val in ipairs(_val.members) do
				if (not checked_models[val.name]) and model_list[val.name] then
					set_model_as_dynamic(model_list[val.name], false)
					checked_models[val.name] = true
				end
			end
		end
		for _key, _val in ipairs(model_data.dynamicCullingRanges or {}) do
			for key, val in ipairs(_val.members) do
				if (not checked_models[val.name]) and model_list[val.name] then
					set_model_as_dynamic(model_list[val.name], true)
					checked_models[val.name] = true
				end
			end
		end

		local part_index
		local function set_materials(tab, key)
			if type(tab) == "table" then
				if tab.materials then
					for k, val in ipairs(tab.materials) do
						if MEM.art_data.model_list[key].parts[part_index] then
							local old_material = MEM.art_data.model_list[key].parts[part_index]
							MEM.art_data.model_list[key].parts[part_index] = val
							local function find_substring(string, substring, count, index)
								index = index or 1
								repeat
									local found = string.find(string, substring, index)
									if found then
										index = found + 1
										count = count - 1
									else
										return nil
									end
								until count < 1
								return index - 1
							end
							local model_tab = MEM.art_data.model_list[key]
							local str_start = find_substring(model_tab.string, "(DoNotEdit)", part_index) - 2
							local str_end = str_start + #old_material + 1
							model_tab.string = string.sub(model_tab.string, 1, str_start)..val..string.sub(model_tab.string, str_end)

							part_index = part_index + 1
						else
							S.update("Model "..MEM.art_data.model_list[key].name.." has too few parts. Skipping the rest.")
							break
						end
					end
				else
					for k, val in pairs(tab) do
						set_materials(val, key)
					end
				end
			end
		end
		local model_count = 0
		for k, v in ipairs(model_data.propsDictionary) do
			if k > 1 and v.key and model_list[v.key] then
				part_index = 1
				set_materials(v, model_list[v.key])
				model_count = model_count + 1
				local tween
				if #v.object.components > 1 then
					tween = {}
					local tween_working = true
					local tween_script
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
									S.update("Malformed tween script in model "..v.key..". Skipping.")
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
						set_model_as_dynamic(model_list[v.key], true)
					else
						tween = nil
					end
				end
				local model_table = MEM.art_data.model_list[model_list[v.key]]
				if tween then
					local tween_replaced = not not model_table.tween
					model_table.tween = tween
					local all_parts_found = true
					for tween_key, tween_val in ipairs(tween.script) do
						if tween_val.part then
							local part_found = false
							for key, val in ipairs(model_table.parts) do
								if MEM.art_data.part_names[v.key][key] == tween_val.part then
									tween_val.part = key
									part_found = true
								end
							end
							if not part_found then
								all_parts_found = false
								tween_val.part = 1
							end
						end
					end
					if not all_parts_found then
						S.update("Tween of model "..v.key.." refers to a wrong part. Defaulting to the first one.")
					end
					if tween_replaced then
						S.update("Model "..v.key.." had its existing tween replaced.")
					end
				end
			end
		end
		populate_model_list()
		populate_part_list()
		current_material = nil
		highlight_part()
		return model_count
	end
end

local function select_model(i)
	if i then
		selected_model_index = i + (10 * model_page)
	end
	if not (selected_model == MEM.art_data.model_list[selected_model_index].name) then
		selected_model = MEM.art_data.model_list[selected_model_index].name
		part_page = 0
		selected_part_index = 1
		current_material = MEM.art_data.model_list[selected_model_index].parts[selected_part_index]
		populate_part_list()
	end
end

function ART.evaluate_input(field, text)
	local text_node = gui.get_node(field.."/text")
	if field == "tween_signal" then
		MEM.art_data.model_list[selected_model_index].tween.signal = text
		gui.set_text(text_node, text)
	elseif field == "rename_name" then
		
	else
		local value = tonumber(text)
		local tween_script = MEM.art_data.model_list[selected_model_index].tween.script
		for i = 1, 10 do
			local tween_index = i + (10 * tween_page)
			if field == "tween_time_"..i then
				if value then
					if value < 0 then value = 0 end
					tween_script[tween_index].time = value
				end
				gui.set_text(text_node, tween_script[tween_index].time)
				if tween_script[tween_index].type == "T" then
					gui.set_text(gui.get_node("tween_speed_"..i.."/text"), calculate_tween_speed(tween_script[tween_index]))
				end
			elseif field == "tween_start_x_"..i then
				if value then
					tween_script[tween_index].start_state.x = value
				end
				gui.set_text(text_node, tween_script[tween_index].start_state.x)
				gui.set_text(gui.get_node("tween_speed_"..i.."/text"), calculate_tween_speed(tween_script[tween_index]))
			elseif field == "tween_start_y_"..i then
				if value then
					tween_script[tween_index].start_state.y = value
				end
				gui.set_text(text_node, tween_script[tween_index].start_state.y)
				gui.set_text(gui.get_node("tween_speed_"..i.."/text"), calculate_tween_speed(tween_script[tween_index]))
			elseif field == "tween_start_z_"..i then
				if value then
					tween_script[tween_index].start_state.z = value
				end
				gui.set_text(text_node, tween_script[tween_index].start_state.z)
				gui.set_text(gui.get_node("tween_speed_"..i.."/text"), calculate_tween_speed(tween_script[tween_index]))
			elseif field == "tween_end_x_"..i then
				if value then
					tween_script[tween_index].end_state.x = value
				end
				gui.set_text(text_node, tween_script[tween_index].end_state.x)
				gui.set_text(gui.get_node("tween_speed_"..i.."/text"), calculate_tween_speed(tween_script[tween_index]))
			elseif field == "tween_end_y_"..i then
				if value then
					tween_script[tween_index].end_state.y = value
				end
				gui.set_text(text_node, tween_script[tween_index].end_state.y)
				gui.set_text(gui.get_node("tween_speed_"..i.."/text"), calculate_tween_speed(tween_script[tween_index]))
			elseif field == "tween_end_z_"..i then
				if value then
					tween_script[tween_index].end_state.z = value
				end
				gui.set_text(text_node, tween_script[tween_index].end_state.z)
				gui.set_text(gui.get_node("tween_speed_"..i.."/text"), calculate_tween_speed(tween_script[tween_index]))
			elseif field == "tween_speed_"..i then
				if value then
					if value < 0 then
						value = 0
					end
				end
				gui.set_text(text_node, value)
				tween_script[tween_index].time = calculate_tween_time(tween_script[tween_index], value)
				gui.set_text(gui.get_node("tween_time_"..i.."/text"), tween_script[tween_index].time)
			end
		end
	end
end

local function get_part_for_tween()
	for i = #MEM.art_data.model_list[selected_model_index].tween.script, 1, -1 do
		if MEM.art_data.model_list[selected_model_index].tween.script[i].part then
			return MEM.art_data.model_list[selected_model_index].tween.script[i].part
		end
	end
	return 1
end

local function close_rename_box()
	gui.set_enabled(gui.get_node("rename_box"), false)
	UI.unload_template()
	UI.load_template(UI.tab.tab_art.buttons)
	populate_model_list()
	populate_part_list()
	UI.switch_cleanup = nil
end

local function rename_model(new_name)
	local model_string = MEM.art_data.model_list[selected_model_index].string
	local object = string.find(model_string, "\"object\":")
	if object then
		local name_length = #selected_model
		model_string = string.sub(model_string, 1, 8)..new_name..string.sub(model_string, 9 + name_length, 28 + name_length)..new_name..string.sub(model_string, 2 * name_length + 29)
	else
		S.update("Problem when renaming model. Aborted.")
	end
	MEM.art_data.model_list[selected_model_index].name = new_name
	for key, val in ipairs(MEM.art_data.table_static_props) do
		if val.name == selected_model then
			val.name = new_name
		end
	end
	for key, val in ipairs(MEM.art_data.table_dynamic_props) do
		if val.name == selected_model then
			val.name = new_name
		end
	end
	for key, val in ipairs(MEM.art_data.table_culling_ranges) do
		for k, v in ipairs(val.members) do
			if v.name == selected_model then
				v.name = new_name
			end
		end
	end
	for key, val in ipairs(MEM.art_data.table_dynamic_culling_ranges) do
		for k, v in ipairs(val.members) do
			if v.name == selected_model then
				v.name = new_name
			end
		end
	end
	MEM.art_data.part_names[new_name] = MEM.art_data.part_names[selected_model]
	MEM.art_data.part_names[selected_model] = nil
	if MEM.art_data.dynamic_models[selected_model] then
		MEM.art_data.dynamic_models[selected_model] = nil
		MEM.art_data.dynamic_models[new_name] = true
	end
	selected_model = new_name
end

local function model_replace()
	for key, val in ipairs(MEM.art_data.model_list[replace_model_index].parts) do
		if MEM.art_data.model_list[selected_model_index].parts[key] then
			MEM.art_data.model_list[replace_model_index].parts[key] = MEM.art_data.model_list[selected_model_index].parts[key]
		else
			break
		end
	end
	MEM.art_data.model_list[replace_model_index].dynamic = MEM.art_data.model_list[selected_model_index].dynamic
	if MEM.art_data.model_list[selected_model_index].tween then
		local new_model_part_count = #MEM.art_data.model_list[replace_model_index].parts
		for key, val in ipairs(MEM.art_data.model_list[selected_model_index].tween.script) do
			if val.part > new_model_part_count then
				val.part = 1
			end
		end
	end
	MEM.art_data.model_list[replace_model_index].tween = MEM.art_data.model_list[selected_model_index].tween
	MEM.art_data.model_list[selected_model_index] = MEM.art_data.model_list[replace_model_index]
	MEM.art_data.model_list[selected_model_index].name = selected_model
	MEM.art_data.model_list[selected_model_index].string = string.gsub(MEM.art_data.model_list[selected_model_index].string, replace_model, selected_model, 2)
	for key, val in ipairs(MEM.art_data.table_static_props) do
		if val.name == replace_model then
			val.name = selected_model
		end
	end
	for key, val in ipairs(MEM.art_data.table_dynamic_props) do
		if val.name == replace_model then
			val.name = selected_model
		end
	end
	for key, val in ipairs(MEM.art_data.table_culling_ranges) do
		for k, v in ipairs(val.members) do
			if v.name == replace_model then
				v.name = selected_model
			end
		end
	end
	for key, val in ipairs(MEM.art_data.table_dynamic_culling_ranges) do
		for k, v in ipairs(val.members) do
			if v.name == replace_model then
				v.name = selected_model
			end
		end
	end
	MEM.art_data.part_names[replace_model] = nil
	MEM.art_data.dynamic_models[replace_model] = nil
	S.update("All instances of "..selected_model.." have been replaced by "..replace_model.." keeping the original model name and properties.", true)
	table.remove(MEM.art_data.model_list, replace_model_index)
	for key, val in ipairs(MEM.art_data.model_list) do
		if val.name == selected_model then
			selected_model_index = key
			break
		end
	end
	select_model()
end

local function close_replace_box(keep_replace_model)
	UI.switch_cleanup = nil
	selection_mode = nil
	if not keep_replace_model then
		replace_model, replace_model_index = nil
	end
	gui.set_enabled(gui.get_node("replace_box"), false)
	UI.unload_template()
	UI.load_template(UI.tab.tab_art.buttons)
	populate_model_list()
	populate_part_list()
end

local function open_replace_box()
	gui.set_enabled(gui.get_node("replace_box"), true)
	selection_mode = nil
	UI.switch_cleanup = close_replace_box
	UI.unload_template()
	UI.load_template({"replace_confirm", "replace_cancel", "replace_model_new", "replace_model_old"})
	gui.set_text(gui.get_node("replace_model_old/text"), selected_model)
	gui.set_text(gui.get_node("replace_model_new/text"), replace_model)
end

function ART.evaluate_button(button)
	if button == "sort" then
		sort_models()
	elseif button == "button_replace" then
		if not selected_model then
			S.update("Select a model first", true)
		else
			if not replace_model then
				selection_mode = hash("replace")
				UI.switch_cleanup = function() selection_mode, replace_model, replace_model_index = nil end
				S.update("Select model with to replace "..selected_model)
			else
				open_replace_box()
			end
		end
	elseif button == "replace_confirm" then
		model_replace()
		close_replace_box()
	elseif button == "replace_cancel" then
		close_replace_box()
	elseif button == "replace_model_new" then
		close_replace_box()
		selection_mode = hash("replace")
		S.update("Select model with to replace "..selected_model)
	elseif button == "replace_model_old" then
		close_replace_box(true)
		selection_mode = hash("replace_old")
		S.update("Select model to be replaced by "..replace_model)
	elseif button == "button_rename" then
		if not selected_model then
			S.update("Select a model first", true)
		else
			gui.set_enabled(gui.get_node("rename_box"), true)
			UI.unload_template()
			UI.load_template({"rename_confirm", "rename_cancel"})
			UI.load_text_field("rename_name", 31)
			gui.set_text(gui.get_node("rename_name/text"), selected_model)
			if UI.switch_cleanup then UI.switch_cleanup() end
			UI.switch_cleanup = close_rename_box
		end
	elseif button == "rename_cancel" then
		close_rename_box()
	elseif button == "rename_confirm" then
		local new_name = gui.get_text(gui.get_node("rename_name/text"))
		if new_name == selected_model then
			S.update("Enter a different name first.", true)
		elseif new_name == "" then
			S.update("Are you *trying* to brick your map?", true)
		else
			for key, val in ipairs(MEM.art_data.model_list) do
				if val.name == new_name then
					S.update("Model with that name already exists.", true)
					return
				end
			end
			rename_model(new_name)
			S.update("Changed model name to "..new_name)
			close_rename_box()
		end
	elseif button == "import_model_data" then
		if selection_mode then
			close_replace_box()
		end
		local model_count = import_model_data()
		if model_count then
			S.update("Updated properties of "..model_count.." models.")
		else
			S.update("Error loading model data.", false)
		end
	elseif button == "import_models" then
		if selection_mode then
			close_replace_box()
		end
		local model_count = import_models()
		if model_count then
			S.update("Imported "..model_count.." models.")
			ART.update_model_list()
		else
			S.update("Error loading model data.", false)
		end
	elseif button == "model_page_up" then
		if model_page < model_page_max then
			model_page = model_page + 1
			populate_model_list()
		end
	elseif button == "model_page_down" then
		if model_page > 0 then
			model_page = model_page - 1
			populate_model_list()
		end
	elseif button == "part_page_up" then
		if part_page < part_page_max then
			part_page = part_page + 1
			populate_part_list()
		end
	elseif button == "part_page_down" then
		if part_page > 0 then
			part_page = part_page - 1
			populate_part_list()
		end
	elseif button == "tween_page_up" then
		if tween_page < tween_page_max then
			tween_page = tween_page + 1
			open_tween_box()
		end
	elseif button == "tween_page_down" then
		if tween_page > 0 then
			tween_page = tween_page - 1
			open_tween_box()
		end
	elseif button == "colour_guide" then
		sys.open_url("https://mod.io/g/pistol-whip/r/advanced-color-hack-guide")
	elseif button == "tween_box_close" then
		close_tween_box()
	elseif button == "action_move" then
		local tween_action = MEM.art_data.model_list[selected_model_index].tween.script[current_tween_action]
		tween_action.type = "T"
		if not tween_action.start_state then
			tween_action.start_state = {x = 0, y = 0, z = 0}
		end
		if not tween_action.end_state then
			tween_action.end_state = {x = tween_action.start_state.x, y = tween_action.start_state.y, z = tween_action.start_state.z}
		end
		if not tween_action.part then
			tween_action.part = get_part_for_tween()
		end
		close_action_type_box()
		open_tween_box()
	elseif button == "action_rotate" then
		local tween_action = MEM.art_data.model_list[selected_model_index].tween.script[current_tween_action]
		tween_action.type = "R"
		if not tween_action.start_state then
			tween_action.start_state = {x = 0, y = 0, z = 0}
		end
		if not tween_action.end_state then
			tween_action.end_state = {x = tween_action.start_state.x, y = tween_action.start_state.y, z = tween_action.start_state.z}
		end
		if not tween_action.part then
			tween_action.part = get_part_for_tween()
		end
		close_action_type_box()
		open_tween_box()
	elseif button == "action_scale" then
		local tween_action = MEM.art_data.model_list[selected_model_index].tween.script[current_tween_action]
		tween_action.type = "S"
		if not tween_action.start_state then
			tween_action.start_state = {x = 1, y = 1, z = 1}
		end
		if not tween_action.end_state then
			tween_action.end_state = {x = tween_action.start_state.x, y = tween_action.start_state.y, z = tween_action.start_state.z}
		end
		if not tween_action.part then
			tween_action.part = get_part_for_tween()
		end
		close_action_type_box()
		open_tween_box()
	elseif button == "action_wait" then
		local tween_action = MEM.art_data.model_list[selected_model_index].tween.script[current_tween_action]
		tween_action.type = "W"
		tween_action.start_state = nil
		tween_action.end_state = nil
		tween_action.part = nil
		close_action_type_box()
		open_tween_box()
	elseif button == "action_delete" then
		table.remove(MEM.art_data.model_list[selected_model_index].tween.script, current_tween_action)
		close_action_type_box()
		open_tween_box()
	elseif button == "tween_new" then
		local tab = {type = "T", start_state = {x = 0, y = 0, z = 0}, end_state = {x = 0, y = 0, z = 0}, time = 1, part = get_part_for_tween()}
		table.insert(MEM.art_data.model_list[selected_model_index].tween.script, tab)
		tween_page = tween_page + 1
		open_tween_box()
	else
		for i = 1, 32 do
			if i < 11 then
				if button == "model_list_"..i then
					if not selection_mode then
						select_model(i)
						return
					elseif selection_mode == hash("replace") then
						replace_model_index = i + (10 * model_page)
						if selected_model == MEM.art_data.model_list[replace_model_index].name then
							S.update("Choose a different model", true)
							replace_model_index = nil
						else
							replace_model = MEM.art_data.model_list[replace_model_index].name
							open_replace_box()
						end
					else
						select_model(i)
						if i + (10 * model_page) == replace_model_index then
							S.update("Choose a different model", true)
						else
							open_replace_box()
						end
					end
				elseif button == "part_list_"..i then
					selected_part_index = i + (10 * part_page)
					current_material = MEM.art_data.model_list[selected_model_index].parts[selected_part_index]
					highlight_part()
					return
				elseif button == "dynamic_"..i then
					if set_model_as_dynamic(i + (10 * model_page)) then
						gui.set_text(gui.get_node("dynamic_"..i.."/text"), "X")
					else
						gui.set_text(gui.get_node("dynamic_"..i.."/text"), "")
					end
					return
				elseif button == "tween_down_"..i then
					local tab = table.remove(MEM.art_data.model_list[selected_model_index].tween.script, i + (10 * tween_page))
					table.insert(MEM.art_data.model_list[selected_model_index].tween.script, i + (10 * tween_page) + 1, tab)
					populate_tween_list(MEM.art_data.model_list[selected_model_index].tween.script)
				elseif button == "tween_up_"..i then
					local tab = table.remove(MEM.art_data.model_list[selected_model_index].tween.script, i + (10 * tween_page))
					table.insert(MEM.art_data.model_list[selected_model_index].tween.script, i + (10 * tween_page) - 1, tab)
					populate_tween_list(MEM.art_data.model_list[selected_model_index].tween.script)
				elseif button == "tween_type_"..i then
					current_tween_action = i + (10 * tween_page)
					open_action_type_box()
				elseif button == "tween_part_"..i then
					local tween_script = MEM.art_data.model_list[selected_model_index].tween.script[i + (10 * tween_page)]
					tween_script.part = tween_script.part + 1
					if tween_script.part > #MEM.art_data.part_names[selected_model] then
						tween_script.part = 1
					end
					local part_name = MEM.art_data.part_names[selected_model][tween_script.part]
					gui.set_text(gui.get_node("tween_part_"..i.."/text"), part_name)
				end
			end
			if button == "mat_"..i then
				local function find_substring(string, substring, count, index)
					index = index or 1
					repeat
						local found = string.find(string, substring, index)
						if found then
							index = found + 1
							count = count - 1
						else
							return nil
						end
					until count < 1
					return index - 1
				end
				local model_tab = MEM.art_data.model_list[selected_model_index]
				local str_start = find_substring(model_tab.string, "(DoNotEdit)", selected_part_index) - 2
				local str_end = str_start + #current_material + 1
				current_material = material_list[i]
				model_tab.parts[selected_part_index] = current_material
				model_tab.string = string.sub(model_tab.string, 1, str_start)..current_material..string.sub(model_tab.string, str_end)
				highlight_part()
			elseif button == "tween_"..i then
				if selection_mode then
					close_replace_box()
				end
				select_model(i)
				open_tween_box()
			end
		end
	end
end

function ART.update_model_list()
	--model_page = 0
	model_page_max = math.floor((#MEM.art_data.model_list - 1) / 10)

	populate_model_list()
	populate_part_list()
end

function ART.export(path)
	local static_ranges_changed, dynamic_ranges_changed
	local existing_ranges, existing_dynamic_ranges = {}, {}
	for key, val in ipairs(MEM.art_data.table_culling_ranges) do
		existing_ranges[val.range] = val
	end
	for key, val in ipairs(MEM.art_data.table_dynamic_culling_ranges) do
		existing_dynamic_ranges[val.range] = val
	end
	local tab_iter = MEM.art_data.table_static_props
	for i = #tab_iter, 1, -1 do
		if MEM.art_data.dynamic_models[tab_iter[i].name] then
			local r = table.remove(tab_iter, i)
			table.insert(MEM.art_data.table_dynamic_props, r)
		end
	end
	tab_iter = MEM.art_data.table_dynamic_props
	for i = #tab_iter, 1, -1 do
		if not MEM.art_data.dynamic_models[tab_iter[i].name] then
			local r = table.remove(tab_iter, i)
			table.insert(MEM.art_data.table_static_props, r)
		end
	end
	tab_iter = MEM.art_data.table_culling_ranges
	local range
	local test = false
	for i = #tab_iter, 1, -1 do
		range = tab_iter[i].range
		test = (range == "24,25")
		local member_count = #tab_iter[i].members
		for j = #tab_iter[i].members, 1, -1 do
			if MEM.art_data.dynamic_models[tab_iter[i].members[j].name] then
				local r = table.remove(tab_iter[i].members, j)
				if existing_dynamic_ranges[range] then
					table.insert(existing_dynamic_ranges[range].members, r)
				else
					MEM.art_data.table_dynamic_culling_ranges[#MEM.art_data.table_dynamic_culling_ranges + 1] = {range = range, members = {r}}
					existing_dynamic_ranges[range] = MEM.art_data.table_dynamic_culling_ranges[#MEM.art_data.table_dynamic_culling_ranges]
					dynamic_ranges_changed = true
				end
				member_count = member_count - 1
			end
		end
		if member_count < 1 then
			table.remove(tab_iter, i)
		end
	end
	tab_iter = MEM.art_data.table_dynamic_culling_ranges
	local range
	for i = #tab_iter, 1, -1 do
		range = tab_iter[i].range
		local member_count = #tab_iter[i].members
		for j = #tab_iter[i].members, 1, -1 do
			if not MEM.art_data.dynamic_models[tab_iter[i].members[j].name] then
				local r = table.remove(tab_iter[i].members, j)
				if existing_ranges[range] then
					table.insert(existing_ranges[range].members, r)
				else
					MEM.art_data.table_culling_ranges[#MEM.art_data.table_culling_ranges + 1] = {range = range, members = {r}}
					existing_ranges[range] = MEM.art_data.table_culling_ranges[#MEM.art_data.table_culling_ranges]
					static_ranges_changed = true
				end
				member_count = member_count - 1
			end
		end
		if member_count < 1 then
			table.remove(tab_iter, i)
		end
	end

	local function range_to_number(range_str)
		local comma = string.find(range_str, ",")
		local first = tonumber(string.sub(range_str, 1, comma - 1))
		local second = tonumber(string.sub(range_str, comma +1))
		return first + (second * 0.001)
	end

	if static_ranges_changed then
		table.sort(MEM.art_data.table_culling_ranges, function(a, b) return range_to_number(a.range) < range_to_number(b.range) end)
	end
	if dynamic_ranges_changed then
		table.sort(MEM.art_data.table_dynamic_culling_ranges, function(a, b) return range_to_number(a.range) < range_to_number(b.range) end)
	end
	
	local final_string = MEM.art_data.string_colours.."\"staticProps\":["
	local str = ""
	for key, val in ipairs(MEM.art_data.table_static_props) do
		str = str.."{\"name\":\""..val.name.."\",\"point\":\""..val.point.."\",\"scale\":\""..val.scale.."\"}"
		if not (key == #MEM.art_data.table_static_props) then
			str = str..","
		end
	end
	final_string = final_string..str.."],\"staticCullingRanges\":["
	str = ""
	for key, val in ipairs(MEM.art_data.table_culling_ranges) do
		str = str.."{\"range\":\""..val.range.."\",\"members\":["
		for k, v in ipairs(val.members) do
			str = str.."{\"name\":\""..v.name.."\",\"point\":\""..v.point.."\",\"scale\":\""..v.scale.."\"}"
			if not (k == #val.members) then
				str = str..","
			else
				str = str.."]}"
			end
		end
		if not (key == #MEM.art_data.table_culling_ranges) then
			str = str..","
		end
	end
	final_string = final_string..str.."],"

	if next(MEM.art_data.dynamic_models) then
		str = "\"dynamicProps\":["
		for key, val in ipairs(MEM.art_data.table_dynamic_props) do
			str = str.."{\"name\":\""..val.name.."\",\"point\":\""..val.point.."\",\"scale\":\""..val.scale.."\"}"
			if not (key == #MEM.art_data.table_dynamic_props) then
				str = str..","
			end
		end
		final_string = final_string..str.."],\"dynamicCullingRanges\":["
		str = ""
		for key, val in ipairs(MEM.art_data.table_dynamic_culling_ranges) do
			str = str.."{\"range\":\""..val.range.."\",\"members\":["
			for k, v in ipairs(val.members) do
				str = str.."{\"name\":\""..v.name.."\",\"point\":\""..v.point.."\",\"scale\":\""..v.scale.."\"}"
				if not (k == #val.members) then
					str = str..","
				else
					str = str.."]}"
				end
			end
			if not (key == #MEM.art_data.table_dynamic_culling_ranges) then
				str = str..","
			end
		end
		final_string = final_string..str.."],"
	end

	local function get_tween_string(tween_data, model_name)
		if not tween_data then
			return ""
		else
			local str = ",{\"type\":\"ScriptedTween\",\"Script\":\""
			for key, val in ipairs(tween_data.script) do
				str = str..val.type
				if val.type == "W" then
					str = str..val.time..";"
				else
					str = str..MEM.art_data.part_names[model_name][val.part]..";"..val.start_state.x..","..val.start_state.y..","
					str = str..val.start_state.z..";"..val.end_state.x..","..val.end_state.y..","..val.end_state.z..";"..val.time..";"
				end
			end
			return str.."\"},{\"type\":\"LevelEventReceiver\",\"EventId\":\""..tween_data.signal.."\",\"ActionType\":\"ScriptedTweenTrigger\"}"
		end
	end
	
	str = ""
	for key, val in ipairs(MEM.art_data.model_list) do
		local cursor_start = string.find(val.string, "\"components\"") + 14
		local cursor_end = string.find(val.string, "]", cursor_start) - 1


		local component_string = string.sub(val.string, cursor_start, cursor_end)
		local component_string_length = #component_string

		local script_pos = string.find(component_string, "{\"type\":\"ScriptedTween\"")
		if script_pos then
			local script_end = string.find(component_string, "}", script_pos)
			component_string = string.sub(component_string, 1, script_pos - 1)..string.sub(component_string, script_end + 1)
		end
		local trigger_pos = string.find(component_string, "{\"type\":\"LevelEventReceiver\"")
		if trigger_pos then
			local trigger_end = string.find(component_string, "}", trigger_pos)
			component_string = string.sub(component_string, 1, trigger_pos - 1)..string.sub(component_string, trigger_end + 1)
		end
		
		component_string = G.sanitise_json(component_string..get_tween_string(val.tween, val.name))

		val.string = string.sub(val.string, 1, cursor_start - 1)..component_string..string.sub(val.string, cursor_end + 1)
		
		if key < #MEM.art_data.model_list then
			str = str..val.string..","
		else
			str = str..val.string.."]"
		end
	end

	final_string = final_string..MEM.art_data.string_dictionary..str.."}"

	if not G.safe_decode(final_string, "Output pw_art file") then
		S.update("Model data might be corrupted. Use with caution.")
	end

	local f = io.output(path)
	io.write(final_string)
	io.close(f)
end


return ART