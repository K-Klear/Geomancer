local UI = {active = {}, text_fields = {}}

UI.COLOUR_DEFAULT = vmath.vector4(0.35, 0.75, 0.15, 1)
UI.COLOUR_DISABLED = vmath.vector4(0.1, 0.1, 0.1, 1)
UI.COLOUR_ERROR = vmath.vector4(0.05, 0.45, 0.05, 1)
UI.COLOUR_WHITE = vmath.vector4(1)
UI.COLOUR_BLACK = vmath.vector4(0, 0, 0, 1)

UI.BUTTON_FLASH_TIME = 0.2
UI.BUTTON_PRESS_TIME = 0.05
UI.EMPTY_VECTOR = vmath.vector3()

UI.input_enabled = true

local current_tab = "tab_file"

UI.tab = {
	tab_file = {state = "active", buttons = {"exit", "load_dir", "load_file", "load_zip", "unload_all", "export_all", "export_overwrite"}},
	tab_level = {state = false, buttons = {"btn_enemies", "btn_obstacles", "btn_materials", "btn_movement"}, fields = {{template = "preview_time", char_limit = 3}}},
	tab_event = {state = false, buttons = {"sample_48000", "sample_44100", "btn_time_units", "nobeat_add", "event_add", "tempo_add"}, fields = {{template = "sample_rate_field", char_limit = 5}}},
	tab_geo = {state = false, buttons = {"geo_collision", "geo_visual"}},
	tab_beat = {state = false, buttons = {}},
	tab_meta = {state = false, buttons = {
		"load_images", "create", "subtractive", "additive", "invert", "left", "right", "min_y_down", "max_y_down",
		"min_y_up", "max_y_up", "min_x_down", "min_x_up", "max_x_up", "max_x_down", "depth_down", "depth_up",
		"show_path", "filter_white", "filter_alpha", "image_group"
	}, fields = {
		{template = "depth", char_limit = 3},
		{template = "min_x", char_limit = 3},
		{template = "max_x", char_limit = 3},
		{template = "min_y", char_limit = 3},
		{template = "max_y", char_limit = 3},
		{template = "processing_order", char_limit = 4},
	}},
	tab_sequence = {state = false, buttons = {}},
	tab_art = {state = false, buttons = {"sort", "button_replace", "button_rename", "import_model_data", "colour_guide", "import_models"}}
}

local state_gfx = {
	active = "tab_active",
	[true] = "tab_normal",
	[false] = "tab_disabled"
}

function UI.update_tabs()
	for key, val in pairs(UI.tab) do
		if key == current_tab then
			val.state = "active"
		else
			gui.play_flipbook(gui.get_node(key), state_gfx[val.state])
		end
	end
end

local mouse_held, hover

function UI.load_template(template)
	if type(template) == "table" then
		for key, val in ipairs(template) do
			UI.load_template(val)
		end
		return
	end
	for key, val in ipairs(UI.active) do
		if val.template == template then
			return
		end
	end
	local node = gui.get_node(template.."/button_white")
	table.insert(UI.active, {template = template, node = node})
end

function UI.load_text_field(template, char_limit)
	for key, val in ipairs(UI.text_fields) do
		if val.template == template then
			return
		end
	end
	table.insert(UI.text_fields, {template = template, char_limit = char_limit, node = gui.get_node(template.."/box"), text = gui.get_node(template.."/text")})
end

local function remove_hover()
	if hover then
		local button = UI.active[hover]
		if mouse_held then
			gui.play_flipbook(button.node, "button_white_up", function()
				gui.play_flipbook(button.node, "button_white")
			end)
		else
			gui.play_flipbook(button.node, "button_white")
		end
		local text_node = gui.get_node(button.template.."/text")
		--gui.set_color(text_node, vmath.vector4(0, 0, 0, 1))
		gui.animate(text_node, "position", UI.EMPTY_VECTOR, go.EASING_LINEAR, UI.BUTTON_PRESS_TIME)
		hover = nil
	end
end

function UI.unload_template(template)
	if template then
		if type(template) == "table" then
			for key, val in ipairs(template) do
				UI.unload_template(val)
			end
			return
		else
			for key, val in ipairs(UI.active) do
				if val.template == template then
					if hover then
						if hover > key then
							hover = hover - 1
						elseif hover == key then
							remove_hover()
						end
					end
					gui.play_flipbook(val.node, "button_white")
					local text_node = gui.get_node(val.template.."/text")
					gui.set_position(text_node, UI.EMPTY_VECTOR)
					table.remove(UI.active, key)
					return
				end
			end
		end
	else
		for key, val in ipairs(UI.active) do
			gui.play_flipbook(val.node, "button_white")
			local text_node = gui.get_node(val.template.."/text")
			gui.set_position(text_node, UI.EMPTY_VECTOR)
		end
		UI.active = {}
		UI.text_fields = {}
		hover = nil
	end
end

function UI.switch_tab(tab)
	UI.tab[current_tab].state = true
	gui.play_flipbook(gui.get_node(current_tab), state_gfx[true])
	gui.set_enabled(UI.tab[current_tab].panel_node, false)
	if UI.switch_cleanup then
		UI.switch_cleanup()
	end
	UI.switch_cleanup = nil
	current_tab = tab
	UI.tab[current_tab].state = "active"
	gui.play_flipbook(gui.get_node(current_tab), state_gfx.active)
	gui.set_enabled(UI.tab[current_tab].panel_node, true)
	UI.unload_template()
	UI.load_template(UI.tab[current_tab].buttons)
	if UI.tab[current_tab].fields then
		for key, val in ipairs(UI.tab[current_tab].fields) do
			UI.load_text_field(val.template, val.char_limit)
		end
	end
end



local active_text_field
local text_field_text = ""
local cursor_timer
local cursor_visible = false

local function text_field_done(text_field_fn)
	timer.cancel(cursor_timer)
	cursor_visible = false
	gui.set_text(UI.text_fields[active_text_field].text, text_field_text)
	text_field_fn(UI.text_fields[active_text_field].template, text_field_text)
	active_text_field = nil
end

local text_field_cursor
local function reset_cursor_timer(hide_cursor)
	if cursor_timer then
		timer.cancel(cursor_timer)
		cursor_visible = hide_cursor
		text_field_cursor()
	end
end

local function text_field_input(action_id, action)
	if action_id == hash("backspace") and (action.pressed or action.repeated) then
		if #text_field_text > 0 then
			text_field_text = string.sub(text_field_text, 1, -2)
			gui.set_text(UI.text_fields[active_text_field].text, text_field_text)
			reset_cursor_timer()
		end
	elseif action_id == hash("text") then
		local field_data = UI.text_fields[active_text_field]
		if #text_field_text + #action.text > field_data.char_limit then
			return
		end
		text_field_text = text_field_text..action.text
		gui.set_text(field_data.text, text_field_text)
		reset_cursor_timer()
	elseif action_id == hash("paste") then
		local field_data = UI.text_fields[active_text_field]
		local pasted_text = string.sub(clipboard.paste(), 1, field_data.char_limit)
		text_field_text = pasted_text
		gui.set_text(field_data.text, pasted_text)
		reset_cursor_timer()
	end
end

function text_field_cursor()
	cursor_visible = not cursor_visible
	if cursor_visible then
		gui.set_text(UI.text_fields[active_text_field].text, text_field_text.."|")
	else
		gui.set_text(UI.text_fields[active_text_field].text, text_field_text)
	end
	cursor_timer = timer.delay(0.5, false, text_field_cursor)
end

local function text_field_clicked(text_field)
	active_text_field = text_field
	text_field_text = gui.get_text(UI.text_fields[active_text_field].text)
	cursor_visible = false
	text_field_cursor()
end

local function template_clicked(button, fn, no_anim)
	local button_data = UI.active[button]
	if not no_anim then
		gui.play_flipbook(button_data.node, "button_white_up")
		local text_node = gui.get_node(button_data.template.."/text")
		gui.animate(text_node, "position", UI.EMPTY_VECTOR, go.EASING_LINEAR, UI.BUTTON_PRESS_TIME)
	end
	fn(button_data.template)
	--SND.play("#beep")
end

function UI.on_input(self, action_id, action, button_fn, text_field_fn)
	mouse_held = action.pressed or (mouse_held and not action.released)
	if not UI.input_enabled then return end
	if active_text_field then
		if action_id == hash("touch") or action_id == hash("enter") then
			text_field_done(text_field_fn)
		elseif action_id == hash("copy") then
			reset_cursor_timer(true)
			clipboard.copy(gui.get_text(UI.text_fields[active_text_field].text))
		elseif action_id == hash("paste") then
			text_field_input(hash("paste"))
		else
			text_field_input(action_id, action)
		end
	end
	if action_id == hash("touch") then
		if action.released then
			for key, val in ipairs(UI.active) do
				if gui.pick_node(val.node, action.x, action.y) then
					template_clicked(key, button_fn)
					break
				end
			end
			for key, val in ipairs(UI.text_fields) do
				if gui.pick_node(val.node, action.x, action.y) then
					text_field_clicked(key)
				end
			end
		elseif action.pressed then
			for key, val in ipairs(UI.active) do
				if gui.pick_node(val.node, action.x, action.y) then
					gui.play_flipbook(val.node, "button_white_down")
					local text_node = gui.get_node(val.template.."/text")
					--gui.set_color(text_node, vmath.vector4(0, 0, 0, 1))
					gui.set_position(text_node, UI.EMPTY_VECTOR)
					gui.animate(text_node, "position", vmath.vector3(5, -5, 0), go.EASING_LINEAR, UI.BUTTON_PRESS_TIME)
					break
				end
			end
		elseif action.repeated then
			for key, val in ipairs(UI.active) do
				if gui.pick_node(val.node, action.x, action.y) then
					template_clicked(key, button_fn, true)
					break
				end
			end
		end
	elseif not action_id then
		local new_hover
		for key, val in ipairs(UI.active) do
			local node = gui.get_node(val.template.."/button_white")
			if gui.pick_node(node, action.x, action.y) then
				new_hover = key
				break
			end
		end
		if new_hover then
			if not (hover == new_hover) then
				--SND.play("#hover")
				remove_hover()
				hover = new_hover
				local hover_anim = "button_white_hover"
				local text_node = gui.get_node(UI.active[hover].template.."/text")
				--gui.set_color(text_node, vmath.vector4(0, 0, 0, 1))
				if mouse_held then
					gui.play_flipbook(UI.active[hover].node, "button_white_down")
					gui.animate(text_node, "position", vmath.vector3(5, -5, 0), go.EASING_LINEAR, UI.BUTTON_PRESS_TIME)
				else
					gui.play_flipbook(UI.active[hover].node, hover_anim)
				end
			end
		else
			remove_hover()
		end
	end
end

function UI.create_button(item)
	if not UI.button_list[item] and item > 0 and item < UI.item_count + 1 then
		local new = gui.clone_tree(UI.button)
		gui.set_position(new[UI.button_id], gui.get_position(new[UI.button_id]) - vmath.vector3(0, item * UI.item_size_y, 0))
		gui.set_text(new[UI.text_id], UI.buttons.test.values[item])
		gui.set_enabled(new[UI.button_id], true)
		UI.button_list[item] = new
	end
end

function UI.delete_button(item)
	if UI.button_list[item] then
		for key, val in pairs(UI.button_list[item]) do
			gui.delete_node(val)
			UI.button_list[item] = nil
		end
	end
end

function UI.create_list(stencil_node, buttons)
	local item_size_x, item_size_y
	local list_size_y = gui.get_size(stencil_node).y
	local button, text_id
	local root_node = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(1, 1, 1))
	gui.set_parent(root_node, stencil_node)
	gui.set_visible(root_node, false)
	for key, val in pairs(buttons) do
		gui.set_parent(val.button, root_node)
		local size = gui.get_size(val.button)
		item_size_x, item_size_y = size.x, size.y
		gui.set_position(val.button, vmath.vector3(size.x * 0.5, 0, 0))
		button = val.button
		text_id = gui.get_id(val.text)
	end
	gui.set_size(stencil_node, vmath.vector3(item_size_x, list_size_y, 0))
	gui.set(root_node, "position.y", item_size_y * 0.5)
	local item_max = math.ceil(list_size_y / item_size_y)
	local item_count = 236
	local button_id = gui.get_id(button)
	UI.button_list = {}
	UI.item_count = 236
	UI.item_max = item_max
	UI.button = button
	UI.button_id = button_id
	UI.text_id = text_id
	UI.buttons = buttons
	UI.item_size_y = item_size_y
	for item = 1, item_max do
		UI.create_button(item)
	end
	UI.min_target = item_size_y * -0.5
	UI.max_target = (item_count - item_max + 1) * item_size_y + item_size_y * .5
	gui.set_enabled(button, false)
	UI.list = root_node
	UI.root_node = root_node
	UI.scroll_target = gui.get(root_node, "position.y")
end

return UI