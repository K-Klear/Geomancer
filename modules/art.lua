local ART = {}
local MEM = require "modules.memory"
local UI = require "modules.ui"
local S = require "modules.status"

local material_highlight, part_highlight, model_highlight
local material_highlight_base, part_highlight_base, model_highlight_base
local model_page, part_page = 0, 0
local model_page_max, part_page_max = 0, 0
local selected_model_index, selected_part_index, current_material
local selected_model = false

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
	"(DoNotEdit)LiveMat_LevelGeoSimple",
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
		if material_index > 16 then
			pos.x = pos.x + 230
			pos.y = pos.y - (40 * (material_index - 17))
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
		else
			gui.set_enabled(node, false)
			gui.set_text(node_text, "")
			UI.unload_template(template_name)
			template_name = "dynamic_"..tostring(i)
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

function ART.evaluate_button(button)
	if button == "sort" then
		sort_models()
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
	else
		for i = 1, 32 do
			if i < 11 then
				if button == "model_list_"..i then
					selected_model_index = i + (10 * model_page)
					selected_model = MEM.art_data.model_list[selected_model_index].name
					part_page = 0
					selected_part_index = 1
					current_material = MEM.art_data.model_list[selected_model_index].parts[selected_part_index]
					populate_part_list()
					highlight_part()
					return
				elseif button == "part_list_"..i then
					selected_part_index = i + (10 * part_page)
					current_material = MEM.art_data.model_list[selected_model_index].parts[selected_part_index]
					highlight_part()
					return
				elseif button == "dynamic_"..i then
					local model_name = MEM.art_data.model_list[i + (10 * model_page)].name
					if MEM.art_data.dynamic_models[model_name] then
						MEM.art_data.model_list[i + (10 * model_page)].dynamic = false
						MEM.art_data.dynamic_models[model_name] = nil
						gui.set_text(gui.get_node("dynamic_"..i.."/text"), "")
					else
						MEM.art_data.model_list[i + (10 * model_page)].dynamic = true
						MEM.art_data.dynamic_models[model_name] = true
						gui.set_text(gui.get_node("dynamic_"..i.."/text"), "X")
					end
					return
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
			end
		end
	end
end

function ART.update_model_list()
	model_page = 0
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
	for i = #tab_iter, 1, -1 do
		range = tab_iter[i].range
		local member_count = #tab_iter[i].members
		for j = #tab_iter[i].members, 1, -1 do
			if MEM.art_data.dynamic_models[tab_iter[i].members[j].name] then
				local r = table.remove(tab_iter[i].members, j)
				if existing_dynamic_ranges[range] then
					table.insert(existing_dynamic_ranges[range], r)
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
					table.insert(existing_ranges[range], r)
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
	
	str = ""
	for key, val in ipairs(MEM.art_data.model_list) do
		if key < #MEM.art_data.model_list then
			str = str..val.string..","
		else
			str = str..val.string
		end
	end

	final_string = final_string..MEM.art_data.string_dictionary..str.."]}"
	local err, msg = pcall(json.decode, final_string)
	if not err then
		S.update("Model data might be corrupted. Use with caution.")
	end

	local f = io.output(path)
	io.write(final_string)
	io.close(f)
end


return ART