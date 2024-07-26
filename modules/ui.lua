local UI = {active = {}, text_fields = {}}
local SET = require "modules.settings"
local MOD = require "main.model_viewer.model"

UI.COLOUR_DEFAULT = vmath.vector4(0.35, 0.75, 0.15, 1)
UI.COLOUR_DISABLED = vmath.vector4(0.1, 0.1, 0.1, 1)
UI.COLOUR_ERROR = vmath.vector4(0.05, 0.45, 0.05, 1)
UI.COLOUR_WHITE = vmath.vector4(1)
UI.COLOUR_BLACK = vmath.vector4(0, 0, 0, 1)

UI.BUTTON_FLASH_TIME = 0.2
UI.BUTTON_PRESS_TIME = 0.05
UI.EMPTY_VECTOR = vmath.vector3()

UI.input_enabled = true

UI.current_tab = "tab_file"

UI.tab = {
	tab_file = {path = "/file#tab_file", state = "active", render_order = 1, buttons = {}, fields = {}},
	tab_level = {path = "/level#tab_level", state = false, render_order = 1, buttons = {}, fields = {}},
	tab_event = {path = "/event#tab_event", state = false, render_order = 1, buttons = {}, fields = {}},
	tab_geo = {path = "/geo#tab_geo", state = false, render_order = 1, buttons = {}, fields = {}},
	tab_beat = {path = "/beat#tab_beat", state = false, render_order = 1, buttons = {}, fields = {}},
	tab_meta = {path = "/meta#tab_meta", state = false, render_order = 1, buttons = {}, fields = {}},
	tab_sequence = {path = "/sequence#tab_sequence", state = false, render_order = 1, buttons = {}, fields = {}},
	tab_art = {path = "/art#tab_art", state = false, render_order = 1, buttons = {}, fields = {}},
	dialog_nobeat = {buttons = {}, fields = {}},
	dialog_event = {buttons = {}, fields = {}},
	dialog_event_multiple = {buttons = {}, fields = {}},
	dialog_tempo = {buttons = {}, fields = {}},
	dialog_import = {buttons = {}, fields = {}},
	dialog_replace = {buttons = {}, fields = {}},
	dialog_rename_model = {buttons = {}, fields = {}},
	dialog_tween = {path = "/tween#dialog_tween", buttons = {}, fields = {}, scrolling_lists = {}, scrolling = {}},
	dialog_tween_action = {path = "/tween_action#dialog_tween_action", buttons = {}, fields = {}},
	dialog_tween_copy = {path = "/tween_copy#dialog_tween_copy", buttons = {}, fields = {}, scrolling_lists = {}, scrolling = {}},
	dialog_tween_part = {path = "/tween_part#dialog_tween_part", buttons = {}, fields = {}, scrolling_lists = {}, scrolling = {}},
	dialog_replace_enemy = {path = "/dialog#dialog_replace_enemy", buttons = {}, fields = {}},
	dialog_change_sequence = {path = "/sequence#dialog_change_sequence", buttons = {}, fields = {}, scrolling_lists = {}, scrolling = {}},
	dialog_bulk_sequence = {path = "/sequence_bulk#dialog_bulk_sequence", buttons = {}, fields = {}, scrolling_lists = {}, scrolling = {}},
	dialog_change_enemy_type = {path = "/type#dialog_change_enemy_type", buttons = {}, fields = {}},
	model_viewer = {path = "not_used_anywhere_actually_why_do_I_bother", buttons = {}, fields = {}},
	dialog_colours = {path = "screw this", buttons = {}, fields = {}, scrolling_lists = {}, scrolling = {}},
	dialog_easing = {path = "whatever", buttons = {}, fields = {}, scrolling_lists = {}, scrolling = {}},
	dialog_filter = {path = "", buttons = {}, fields = {}, scrolling_lists = {}, scrolling = {}}
}

local mouse_held, r_ctr_held, l_ctr_held
local hover = {}

function UI.load_template(template, tab)
	if type(template) == "table" then
		for key, val in ipairs(template) do
			UI.load_template(val, tab)
		end
		return
	end
	for key, val in ipairs(UI.tab[tab].buttons) do
		if val.template == template then
			return
		end
	end
	local node = gui.get_node(template.."/button_white")
	local text = gui.get_node(template.."/text")
	table.insert(UI.tab[tab].buttons, {template = template, node = node, text = text})
end

function UI.load_text_field(template, char_limit, tab, validation)
	for key, val in ipairs(UI.tab[tab].fields) do
		if val.template == template then
			return
		end
	end
	table.insert(UI.tab[tab].fields, {template = template, char_limit = char_limit, node = gui.get_node(template.."/box"), text = gui.get_node(template.."/text"), validation = validation})
end

local function remove_hover(tab)
	if hover[tab] then
		local button = UI.tab[tab].buttons[hover[tab]]
		if mouse_held then
			gui.play_flipbook(button.node, "button_white_up", function()
				gui.play_flipbook(button.node, "button_white")
			end)
		else
			gui.play_flipbook(button.node, "button_white")
		end
		gui.animate(button.text, "position", UI.EMPTY_VECTOR, go.EASING_LINEAR, UI.BUTTON_PRESS_TIME)
		hover[tab] = nil
	end
end

local active_text_field
local text_field_text = ""
local cursor_timer
local cursor_visible = false
local text_field_cursor

function UI.unload_template(tab, template)
	if template then
		if type(template) == "table" then
			for key, val in ipairs(template) do
				UI.unload_template(val, tab)
			end
			return
		else
			for key, val in ipairs(UI.tab[tab].buttons) do
				if val.template == template then
					if hover[tab] then
						if hover[tab] > key then
							hover[tab] = hover[tab] - 1
						elseif hover[tab] == key then
							remove_hover(tab)
						end
					end
					gui.play_flipbook(val.node, "button_white")
					gui.set_position(val.text, UI.EMPTY_VECTOR)
					table.remove(UI.tab[tab].buttons, key)
					return
				end
			end
		end
	else
		for key, val in ipairs(UI.tab[tab].buttons) do
			gui.play_flipbook(val.node, "button_white")
			gui.set_position(val.text, UI.EMPTY_VECTOR)
		end
		UI.tab[tab].buttons = {}
		UI.tab[tab].fields = {}
		hover[tab] = nil
	end
end


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
			gui.set_text(active_text_field.text, text_field_text)
			reset_cursor_timer()
		end
	elseif action_id == hash("text") then
		if #text_field_text + #action.text > active_text_field.char_limit and not SET.ignore_char_limit then
			return
		end
		text_field_text = text_field_text..action.text
		gui.set_text(active_text_field.text, text_field_text)
		reset_cursor_timer()
	elseif action_id == hash("paste") then
		local pasted_text = string.sub(clipboard.paste(), 1, active_text_field.char_limit)
		text_field_text = pasted_text
		gui.set_text(active_text_field.text, pasted_text)
		reset_cursor_timer()
	end
end

function text_field_cursor()
	--[[  USE THIS IF YOU GET DELETED NODE ERRORS
	if not active_text_field then
		cursor_visible = false
		if cursor_timer then
			timer.cancel(cursor_timer)
		end
		cursor_timer = nil
	else
		--]]
	cursor_visible = not cursor_visible
	if cursor_visible then
		gui.set_text(active_text_field.text, text_field_text.."|")
	else
		gui.set_text(active_text_field.text, text_field_text)
	end
	cursor_timer = timer.delay(0.5, false, text_field_cursor)
	--end
end

local function text_field_clicked(text_field)
	active_text_field = text_field
	text_field_text = gui.get_text(active_text_field.text)
	cursor_visible = false
	text_field_cursor()
end

local function template_clicked(tab, button, fn, no_anim)
	local button_data = UI.tab[tab].buttons[button]
	if not no_anim then
		gui.play_flipbook(button_data.node, "button_white_up")
		gui.animate(button_data.text, "position", UI.EMPTY_VECTOR, go.EASING_LINEAR, UI.BUTTON_PRESS_TIME)
	end
	fn(button_data.template, button_data.item)
	--SND.play("#beep")
end

local function create_list_item(tab, list_index, item)
	local list_tab = UI.tab[tab].scrolling_lists[list_index]
	local height_adjust = (item - 1) * list_tab.item_height
	if list_tab.exclusive_button and not list_tab.exclusive_button.list[item] and 
	(not list_tab.exclusive_button.enabled or list_tab.exclusive_button.enabled(item)) then
		local new = gui.clone_tree(list_tab.exclusive_button.node)
		local button_box = new[list_tab.exclusive_button.node_id]
		gui.set_parent(button_box, list_tab.root_node)
		gui.set(button_box, "position.y", gui.get(button_box, "position.y") - height_adjust)
		gui.set_text(new[list_tab.exclusive_button.text_id], list_tab.exclusive_button.value_fn(item))
		gui.set_enabled(button_box, true)
		list_tab.exclusive_button.list[item] = new
		if item == list_tab.exclusive_button.selected then
			gui.play_flipbook(button_box, "button_exclusive_press_5")
		end
		if list_tab.exclusive_button.tint then
			gui.set_color(button_box, list_tab.exclusive_button.tint(item))
		end
	end
	for key, val in ipairs(list_tab.backgrounds) do
		if not val.list[item] and (not (val.enabled) or val.enabled(item)) then
			local new = gui.clone(val.node)
			gui.set_parent(new, list_tab.root_node)
			gui.set(new, "position.y", gui.get(new, "position.y") - height_adjust)
			gui.set_enabled(new, true)
			val.list[item] = new
			if val.tint then
				gui.set_color(new, val.tint(item))
			end
		end
	end
	for key, val in ipairs(list_tab.buttons) do
		if not val.list[item] and (not (val.enabled) or val.enabled(item)) then
			local new = gui.clone_tree(val.node)
			gui.set_parent(new[val.node_id], list_tab.root_node)
			gui.set(new[val.node_id], "position.y", gui.get(new[val.node_id], "position.y") - height_adjust)
			gui.set_text(new[val.text_id], val.value_fn(item))
			gui.set_enabled(new[val.node_id], true)
			val.list[item] = new
			table.insert(UI.tab[tab].buttons, {template = val.template..item, node = new[val.node_id], text = new[val.text_id], item = item, stencil = list_tab.stencil_node})
			if val.tint then
				gui.set_color(new[val.node_id], val.tint(item))
			end
		end
	end
	for key, val in ipairs(list_tab.labels) do
		if not val.list[item] and (not val.enabled or val.enabled(item)) then
			local new = gui.clone(val.node)
			gui.set_parent(new, list_tab.root_node)
			gui.set(new, "position.y", gui.get(new, "position.y") - height_adjust)
			gui.set_text(new, val.value_fn(item))
			gui.set_enabled(new, true)
			val.list[item] = new
			if val.tint then
				gui.set_color(new, val.tint(item))
			end
		end
	end
	for key, val in ipairs(list_tab.fields) do
		if not val.list[item] and (not val.enabled or val.enabled(item)) then
			local new = gui.clone_tree(val.node)
			gui.set_parent(new[val.node_id], list_tab.root_node)
			gui.set(new[val.node_id], "position.y", gui.get(new[val.node_id], "position.y") - height_adjust)
			gui.set_text(new[val.text_id], val.value_fn(item))
			gui.set_enabled(new[val.node_id], true)
			val.list[item] = new
			table.insert(UI.tab[tab].fields, {
				template = val.template..item,
				char_limit = val.char_limit,
				node = new[val.node_id],
				text = new[val.text_id],
				validation = val.validation,
				item = item,
				stencil = list_tab.stencil_node
			})
			if val.tint then
				gui.set_color(new[val.node_id], val.tint(item))
			end
		end
	end
end

local function delete_list_item(tab, list_index, item)
	local list_tab = UI.tab[tab].scrolling_lists[list_index]
	if list_tab.exclusive_button and list_tab.exclusive_button.list[item] then
		for k, v in pairs(list_tab.exclusive_button.list[item]) do
			gui.delete_node(v)
		end
		list_tab.exclusive_button.list[item] = nil
	end
	for key, val in ipairs(list_tab.buttons) do
		if val.list[item] then
			UI.unload_template(tab, val.template..item)
			for k, v in pairs(val.list[item]) do
				gui.delete_node(v)
			end
			val.list[item] = nil
		end
	end
	for key, val in ipairs(list_tab.fields) do
		if val.list[item] then
			local temp = val.template..item
			for k, v in ipairs(UI.tab[tab].fields) do
				if v.template == temp then
					table.remove(UI.tab[tab].fields, k)
					break
				end
			end
			for k, v in pairs(val.list[item]) do
				gui.delete_node(v)
			end
			val.list[item] = nil
		end
	end
	for key, val in ipairs(list_tab.labels) do
		if val.list[item] then
			gui.delete_node(val.list[item])
			val.list[item] = nil
		end
	end
	for key, val in ipairs(list_tab.backgrounds) do
		if val.list[item] then
			gui.delete_node(val.list[item])
			val.list[item] = nil
		end
	end
end

local function set_grip_size(tab, list_index)
	local list_tab = UI.tab[tab].scrolling_lists[list_index]
	local height = list_tab.size_y - 64
	local full_height = list_tab.item_height * list_tab.item_count - 64
	local grip_size = (height / full_height) * height
	local grip_list = {"scroll_grip", "scroll_background", "scroll_up", "scroll_down"}
	if not (list_tab.item_count > list_tab.max_item_count) or (grip_size > height) then
		grip_size = height
		if list_tab.scroll_bar_visible then
			for key, val in ipairs(grip_list) do
				gui.animate(list_tab[val], "color.w", 0, gui.EASING_INOUTSINE, 0.25)
			end
			list_tab.scroll_bar_visible = false
		end
	else
		if not list_tab.scroll_bar_visible then
			for key, val in ipairs(grip_list) do
				gui.animate(list_tab[val], "color.w", 1, gui.EASING_INOUTSINE, 0.25)
			end
			list_tab.scroll_bar_visible = true
		end
	end
	if grip_size < 32 then grip_size = 32 end 
	gui.set(list_tab.scroll_grip, "position.y", -32)
	gui.set(list_tab.scroll_grip, "size.y", grip_size)
	list_tab.grip_size = grip_size
	list_tab.grip_pos_min = -32
	list_tab.grip_pos_max = -(height - grip_size + 32)
	list_tab.grip_pos_range = list_tab.grip_pos_max - list_tab.grip_pos_min
end

local function end_scrolling(tab, list_index)
	UI.tab[tab].scrolling[list_index] = nil
end

function UI.select_exclusive_button(tab, list_index, selected, no_move, fast)
	local exclusive = UI.tab[tab].scrolling_lists[list_index].exclusive_button
	if not (exclusive.selected == selected) then
		if exclusive.list[exclusive.selected] then
			gui.play_flipbook(exclusive.list[exclusive.selected][exclusive.node_id], "button_exclusive_unpress")
		end
		exclusive.selected = selected
		if exclusive.list[exclusive.selected] then
			gui.play_flipbook(exclusive.list[exclusive.selected][exclusive.node_id], "button_exclusive_press")
		end
		UI.update_list(tab, list_index)
		if not no_move then
			UI.scroll_to_item(tab, list_index, selected, fast)
		end
	end
end

function UI.update_list(tab, list_index, item_count)
	local list_tab = UI.tab[tab].scrolling_lists[list_index]
	item_count = item_count or list_tab.item_count
	list_tab.item_count = item_count
	list_tab.target_max = math.max(list_tab.item_count - list_tab.max_item_count + 1, 1) * list_tab.item_height
	list_tab.target_min = -list_tab.item_height
	list_tab.scroll_max = list_tab.item_height * math.max(list_tab.item_count - list_tab.max_item_count, 0)
	if list_tab.scroll_target > list_tab.scroll_max then
		list_tab.scroll_target = list_tab.scroll_max
		gui.animate(list_tab.root_node, "position.y", list_tab.scroll_max, gui.EASING_LINEAR, SET.scroll_time * 0.5, 0, function() end_scrolling(tab, list_index) end)
		if not UI.tab[tab].scrolling[list_index] then
			UI.tab[tab].scrolling[list_index] = true
		end
	end
	if list_tab.exclusive_button and (list_tab.exclusive_button.selected > item_count) then
		list_tab.exclusive_button.selected = item_count
	end
	for item = list_tab.visible_range_min, list_tab.visible_range_max do
		delete_list_item(tab, list_index, item)
		if not (item > item_count) then
			create_list_item(tab, list_index, item)
		end
	end
	set_grip_size(tab, list_index)
	UI.move_list_root(tab, list_index, true)
end

function UI.create_list(tab, stencil_node, item_features)
	local list_tab = {
		size_y = gui.get_size(stencil_node).y,
		root_node = gui.new_box_node(vmath.vector3(0, 0, 0), vmath.vector3(1, 1, 1)),
		backgrounds = {},
		labels = {},
		buttons = {},
		fields = {},
		scroll_target = 0,
		stencil_node = stencil_node,
		horizontal = item_features.horizontal,
		scroll_bar_visible = true
	}
	gui.set_parent(list_tab.root_node, stencil_node)
	gui.set_visible(list_tab.root_node, false)
	local min_y, max_y = 9999, -9999
	for key, val in ipairs(item_features) do
		if val.type == hash("background") then
			table.insert(list_tab.backgrounds, {
				node = val.node,
				list = {},
				tint = val.tint,
				enabled = val.enabled
			})
		elseif val.type == hash("exclusive_button") then
			list_tab.exclusive_button = {
				node = val.node,
				node_id = gui.get_id(val.node),
				text = val.text_node,
				text_id = gui.get_id(val.text_node),
				value_fn = val.value_fn,
				list = {},
				fn = val.fn,
				selected = 0,
				tint = val.tint,
				enabled = val.enabled
			}
			gui.set_enabled(val.node, false)
		elseif val.type == hash("label") then
			table.insert(list_tab.labels, {
				node = val.node,
				value_fn = val.value_fn,
				list = {},
				tint = val.tint,
				enabled = val.enabled
			})
		elseif val.type == hash("button") then
			table.insert(list_tab.buttons, {
				node = val.node,
				node_id = gui.get_id(val.node),
				text = val.text_node,
				text_id = gui.get_id(val.text_node),
				value_fn = val.value_fn,
				template = val.template,
				list = {},
				tint = val.tint,
				enabled = val.enabled
			})
		elseif val.type == hash("field") then
			table.insert(list_tab.fields, {
				node = val.node,
				node_id = gui.get_id(val.node),
				text = val.text_node,
				text_id = gui.get_id(val.text_node),
				value_fn = val.value_fn,
				template = val.template,
				list = {},
				tint = val.tint,
				enabled = val.enabled,
				char_limit = val.char_limit,
				validation = val.validation
			})
		end
		local size = gui.get_size(val.node)
		local pos = gui.get_position(val.node)
		local pivot = gui.get_pivot(val.node)
		if pivot == gui.PIVOT_N or pivot == gui.PIVOT_NE or pivot == gui.PIVOT_NW then
			min_y = math.min(min_y, pos.y - size.y)
			max_y = math.max(max_y, pos.y)
		elseif pivot == gui.PIVOT_CENTER or pivot == gui.PIVOT_E or pivot == gui.PIVOT_W then
			min_y = math.min(min_y, pos.y - size.y * 0.5)
			max_y = math.max(max_y, pos.y + size.y * 0.5)
		else
			min_y = math.min(min_y, pos.y + size.y)
			max_y = math.max(max_y, pos.y)
		end
		gui.set_enabled(val.node, false)
	end
	list_tab.item_height = max_y - min_y
	list_tab.max_item_count = math.floor(list_tab.size_y / list_tab.item_height)
	list_tab.size_y = list_tab.max_item_count * list_tab.item_height
	gui.set(list_tab.stencil_node, "size.y", list_tab.size_y)
	list_tab.visible_range_min = 1
	list_tab.visible_range_max = math.min(item_features.item_count, list_tab.max_item_count)
	list_tab.scroll_up = gui.get_node(item_features.scroll_prefix.."scroll_up")
	list_tab.scroll_down = gui.get_node(item_features.scroll_prefix.."scroll_down")
	list_tab.scroll_background = gui.get_node(item_features.scroll_prefix.."scroll_background")
	list_tab.scroll_grip = gui.get_node(item_features.scroll_prefix.."scroll_grip")

	local grip_list = {"scroll_grip", "scroll_background", "scroll_up", "scroll_down"}
	for key, val in ipairs(grip_list) do
		gui.set(list_tab[val], "color.w", 0)
	end

	local width = gui.get(list_tab.stencil_node, "size.x")
	gui.set_position(list_tab.scroll_down, vmath.vector3(width - 16, -(list_tab.size_y - 16), 0))
	gui.set_position(list_tab.scroll_up, vmath.vector3(width - 16, -16, 0))
	gui.set_position(list_tab.scroll_background, vmath.vector3(width - 16, -32, 0))
	gui.set_position(list_tab.scroll_grip, vmath.vector3(width - 16, -48, 0))
	gui.set(list_tab.scroll_background, "size.y", list_tab.size_y - 64)
	list_tab.scroll_grip_position = -48	
	UI.tab[tab].scrolling_lists = UI.tab[tab].scrolling_lists or {}
	UI.tab[tab].scrolling = UI.tab[tab].scrolling or {}
	table.insert(UI.tab[tab].scrolling_lists, list_tab)
	local list_index = #UI.tab[tab].scrolling_lists
	UI.update_list(tab, list_index, item_features.item_count)
	return list_index
end

function UI.move_list_root(tab, list_index, adjust_grip)
	local list_tab = UI.tab[tab].scrolling_lists[list_index]
	local root_height = gui.get(list_tab.root_node, "position.y")
	local item_height_half = list_tab.item_height * 0.5
	local range_min = math.max(1, math.floor((root_height - item_height_half) / list_tab.item_height))
	local range_max = math.min(list_tab.item_count, math.floor((root_height - item_height_half + (list_tab.max_item_count + 2) * list_tab.item_height) / list_tab.item_height))
	for item = list_tab.visible_range_min, list_tab.visible_range_max do
		if item > range_max or item < range_min then
			delete_list_item(tab, list_index, item)
		end
	end
	for item = range_min, range_max do
		create_list_item(tab, list_index, item)
	end
	list_tab.visible_range_min = range_min
	list_tab.visible_range_max = range_max
	if adjust_grip and list_tab.scroll_max > 0 then
		local pos_ratio = root_height / list_tab.scroll_max
		local target_y = list_tab.grip_pos_min + list_tab.grip_pos_range * pos_ratio
		target_y = math.min(math.max(list_tab.grip_pos_max, target_y), list_tab.grip_pos_min)
		gui.set(list_tab.scroll_grip, "position.y", target_y)
		list_tab.scroll_grip_position = target_y
	end
end

function UI.scroll_to_item(tab, list_index, item, fast)
	local time_mult = 1
	if fast then time_mult = 0.75 end
	local list_tab = UI.tab[tab].scrolling_lists[list_index]
	if item == 0 then
		gui.set(list_tab.root_node, "position.y", 0)
		UI.tab[tab].scrolling[list_index] = nil
		list_tab.scroll_target = 0
	else
		list_tab.scroll_target = math.max(math.min((item - 1) * list_tab.item_height, list_tab.scroll_max), 0)
		gui.animate(list_tab.root_node, "position.y", list_tab.scroll_target, gui.EASING_LINEAR, SET.scroll_time * time_mult, 0, function() end_scrolling(tab, list_index) end)
		if not UI.tab[tab].scrolling[list_index] then
			UI.tab[tab].scrolling[list_index] = true
		end
	end
end

function UI.on_input(tab, action_id, action, button_fn, text_field_fn)
	mouse_held = action.pressed or (mouse_held and not action.released)
	if action_id == hash("lctrl") then
		l_ctr_held = not action.released
		return
	elseif action_id == hash("rctrl") then
		r_ctr_held = not action.released
		return
	elseif action_id == hash("v") then
		if action.pressed and (r_ctr_held or l_ctr_held) then
			action_id = hash("paste")
		else
			return
		end
	elseif action_id == hash("c") then
		if action.pressed and (r_ctr_held or l_ctr_held)  then
			action_id = hash("copy")
		else
			return
		end
	end
	if MOD.is_dragged then
		return
	end
	if active_text_field then
		if action_id == hash("touch") or action_id == hash("enter") then
			timer.cancel(cursor_timer)
			cursor_visible = false
			local valid = active_text_field.validation
			if valid then
				if valid.number or valid.integer then
					local f = loadstring("return "..text_field_text)
					if f then
						local env = math
						setfenv(f, env)
						local err, output = pcall(f)
						if err then
							text_field_text = output
						end
					end
					text_field_text = tonumber(text_field_text)
					if text_field_text then
						if math.abs(text_field_text) == 1/0 then
							text_field_text = 0
						end
						if valid.integer then
							text_field_text = math.floor(text_field_text)
						end
						if valid.max then
							text_field_text = math.min(text_field_text, valid.max(active_text_field.item))
						end
						if valid.min then
							text_field_text = math.max(text_field_text, valid.min(active_text_field.item))
						end
					else
						text_field_text = valid.default(active_text_field.item)
					end
				elseif valid.text then
					if valid.not_empty then
						if text_field_text == "" then
							text_field_text = valid.default()
						end
					end
					if valid.json_safe then
						--gsub or soemthing i duuno
					end
				end
			end
			gui.set_text(active_text_field.text, text_field_text)
			text_field_fn(active_text_field.template, text_field_text, active_text_field.item)
			active_text_field = nil
		elseif action_id == hash("copy") then
			reset_cursor_timer(true)
			clipboard.copy(gui.get_text(active_text_field.text))
		elseif action_id == hash("paste") then
			text_field_input(hash("paste"))
		else
			text_field_input(action_id, action)
		end
		return
	end
	if UI.tab[tab].scrolling_lists then
		for key, list_tab in ipairs(UI.tab[tab].scrolling_lists) do
			if gui.pick_node(list_tab.stencil_node, action.x, action.y) then
				if action_id == hash("scroll_down") then
					if action.value > 0 then
						list_tab.scroll_target = math.min(list_tab.scroll_target + SET.scroll_speed, list_tab.target_max)
						gui.animate(list_tab.root_node, "position.y", list_tab.scroll_target, gui.EASING_LINEAR, SET.scroll_time, 0, function() end_scrolling(tab, key) end)
						if not UI.tab[tab].scrolling[key] then
							UI.tab[tab].scrolling[key] = true
						end
					else
						local root_pos = gui.get(list_tab.root_node, "position.y")
						list_tab.scroll_target = math.min(root_pos + (list_tab.scroll_target - root_pos) * 0.6, list_tab.scroll_max)--list_tab.target_max)
						gui.animate(list_tab.root_node, "position.y", list_tab.scroll_target, gui.EASING_OUTSINE, SET.scroll_time * .5, 0, function() end_scrolling(tab, key) end)
					end
					return
				elseif action_id == hash("scroll_up") then
					if action.value > 0 then
						list_tab.scroll_target = math.max(list_tab.scroll_target - SET.scroll_speed, list_tab.target_min)
						gui.animate(list_tab.root_node, "position.y", list_tab.scroll_target, gui.EASING_LINEAR, SET.scroll_time, 0, function() end_scrolling(tab, key) end)
						if not UI.tab[tab].scrolling[key] then
							UI.tab[tab].scrolling[key] = true
						end
					else
						local root_pos = gui.get(list_tab.root_node, "position.y")
						list_tab.scroll_target = math.max(root_pos + (list_tab.scroll_target - root_pos) * 0.6, 0)
						gui.animate(list_tab.root_node, "position.y", list_tab.scroll_target, gui.EASING_OUTSINE, SET.scroll_time * 0.5, 0, function() end_scrolling(tab, key) end)
					end
					return
				elseif gui.pick_node(list_tab.scroll_grip, action.x, action.y) then
					if action_id == hash("touch") and not action.released then
						UI.tab[tab].scrolling_grip_held = key
					end
				elseif action.pressed and gui.pick_node(list_tab.scroll_background, action.x, action.y) then
					local pos = gui.get_screen_position(list_tab.scroll_grip)
					local page_height = (list_tab.max_item_count - 1) * list_tab.item_height
					if list_tab.horizontal then
						if action.x < pos.x then
							page_height = -page_height
						end
						list_tab.scroll_target = math.min(math.max(list_tab.scroll_target + page_height, 0), list_tab.scroll_max)
						gui.animate(list_tab.root_node, "position.y", list_tab.scroll_target, gui.EASING_LINEAR, SET.scroll_time * 0.7, 0, function() end_scrolling(tab, key) end)
						if not UI.tab[tab].scrolling[key] then
							UI.tab[tab].scrolling[key] = true
						end
					else
						if action.y > pos.y then
							page_height = -page_height
						end
						list_tab.scroll_target = math.min(math.max(list_tab.scroll_target + page_height, 0), list_tab.scroll_max)
						gui.animate(list_tab.root_node, "position.y", list_tab.scroll_target, gui.EASING_LINEAR, SET.scroll_time * 0.7, 0, function() end_scrolling(tab, key) end)
						if not UI.tab[tab].scrolling[key] then
							UI.tab[tab].scrolling[key] = true
						end
					end
				elseif action_id == hash("touch") and (action.pressed or action.repeated) and not (UI.tab[tab].scrolling_grip_held) then
					if gui.pick_node(list_tab.scroll_up, action.x, action.y) then
						list_tab.scroll_target = math.max(list_tab.scroll_target - list_tab.item_height, 0)
						gui.animate(list_tab.root_node, "position.y", list_tab.scroll_target, gui.EASING_LINEAR, SET.scroll_time * 0.5, 0, function() end_scrolling(tab, key) end)
						gui.play_flipbook(list_tab.scroll_up, "scrollbar_button_press")
						if not UI.tab[tab].scrolling[key] then
							UI.tab[tab].scrolling[key] = true
						end
					elseif gui.pick_node(list_tab.scroll_down, action.x, action.y) then
						list_tab.scroll_target = math.min(list_tab.scroll_target + list_tab.item_height, list_tab.scroll_max)
						gui.animate(list_tab.root_node, "position.y", list_tab.scroll_target, gui.EASING_LINEAR, SET.scroll_time * 0.5, 0, function() end_scrolling(tab, key) end)
						gui.play_flipbook(list_tab.scroll_down, "scrollbar_button_press")
						if not UI.tab[tab].scrolling[key] then
							UI.tab[tab].scrolling[key] = true
						end
					elseif list_tab.exclusive_button then
						for item, button in pairs(list_tab.exclusive_button.list) do
							if gui.pick_node(button[list_tab.exclusive_button.node_id], action.x, action.y) then
								if not (item == list_tab.exclusive_button.selected) then
									local node_id = list_tab.exclusive_button.node_id
									if list_tab.exclusive_button.list[list_tab.exclusive_button.selected] then
										gui.play_flipbook(list_tab.exclusive_button.list[list_tab.exclusive_button.selected][node_id], "button_exclusive_unpress")
									end
									list_tab.exclusive_button.selected = item
									gui.play_flipbook(button[node_id], "button_exclusive_press")
								end
								list_tab.exclusive_button.fn(key, item)
								break
							end
						end
					end
				end
			end
			if UI.tab[tab].scrolling_grip_held == key and (not action_id) and not (list_tab.grip_pos_range == 0) then
				gui.cancel_animation(list_tab.root_node, "position.y")
				if list_tab.horizontal then
					list_tab.scroll_grip_position = list_tab.scroll_grip_position - action.dx
				else
					list_tab.scroll_grip_position = list_tab.scroll_grip_position + action.dy
				end
				local target_y = math.min(math.max(list_tab.grip_pos_max, list_tab.scroll_grip_position), list_tab.grip_pos_min)
				gui.set(list_tab.scroll_grip, "position.y", target_y)
				local target_ratio = 1 - ((list_tab.grip_pos_max - target_y) / list_tab.grip_pos_range)
				target_y = target_ratio * list_tab.scroll_max
				gui.set(list_tab.root_node, "position.y", target_y)
				list_tab.scroll_target = target_y
				UI.move_list_root(tab, key)
			end
		end
	end
	if action_id == hash("touch") then
		if action.released then
			if UI.tab[tab].scrolling_grip_held then
				local list_tab = UI.tab[tab].scrolling_lists[UI.tab[tab].scrolling_grip_held]
				list_tab.scroll_grip_position = gui.get(list_tab.scroll_grip, "position.y")
				UI.tab[tab].scrolling_grip_held = nil
			else
				for key, val in ipairs(UI.tab[tab].buttons) do
					if gui.pick_node(val.node, action.x, action.y) then
						if not val.stencil or gui.pick_node(val.stencil, action.x, action.y) then
							template_clicked(tab, key, button_fn)
							break
						end
					end
				end
				for key, val in ipairs(UI.tab[tab].fields) do
					if gui.pick_node(val.node, action.x, action.y) then
						if not val.stencil or gui.pick_node(val.stencil, action.x, action.y) then
							text_field_clicked(val)
						end
					end
				end
			end
		elseif action.pressed then
			for key, val in ipairs(UI.tab[tab].buttons) do
				if gui.pick_node(val.node, action.x, action.y) then
					gui.play_flipbook(val.node, "button_white_down")
					gui.set_position(val.text, UI.EMPTY_VECTOR)
					gui.animate(val.text, "position", vmath.vector3(5, -5, 0), go.EASING_LINEAR, UI.BUTTON_PRESS_TIME)
					break
				end
			end
		elseif action.repeated and not (UI.tab[tab].scrolling_grip_held) then
			for key, val in ipairs(UI.tab[tab].buttons) do
				if gui.pick_node(val.node, action.x, action.y) then
					--template_clicked(tab, key, button_fn, true) -- this is causing the issue with buttons getting triggered when moused over while held.
					break
				end
			end
		end
	elseif not action_id and not (UI.tab[tab].scrolling_grip_held) then
		local new_hover
		for key, val in ipairs(UI.tab[tab].buttons) do
			if gui.pick_node(val.node, action.x, action.y) then
				new_hover = key
				break
			end
		end
		if new_hover then
			if not (hover[tab] == new_hover) then
				--SND.play("#hover")
				remove_hover(tab)
				hover[tab] = new_hover
				local hover_anim = "button_white_hover"
				if mouse_held then
					gui.play_flipbook(UI.tab[tab].buttons[hover[tab]].node, "button_white_down")
					gui.animate(UI.tab[tab].buttons[hover[tab]].text, "position", vmath.vector3(5, -5, 0), go.EASING_LINEAR, UI.BUTTON_PRESS_TIME)
				else
					gui.play_flipbook(UI.tab[tab].buttons[hover[tab]].node, hover_anim)
				end
			end
		else
			remove_hover(tab)
		end
	end
end

local DIALOG = {}

function DIALOG.setup(dialog_name)
	UI.tab[dialog_name] = {buttons = {}, fields = {}, path = msg.url("#"), dialog_open = false}
	msg.post("#", hash("disable"))
end

function DIALOG.open(tab, dialog_name, data)
	msg.post(UI.tab[dialog_name].path, hash("show"), data)
	UI.tab[dialog_name].render_order = UI.tab[tab].render_order + 1
	UI.tab[dialog_name].parent_name = tab
	msg.post("#", hash("release_input_focus"))
	UI.tab[tab].child_dialog = dialog_name
end

function DIALOG.show(DIALOG_DATA, parent)
	gui.set_render_order(DIALOG_DATA.render_order)
	DIALOG_DATA.parent_tab = parent
	msg.post("#", hash("acquire_input_focus"))
	msg.post("#", hash("enable"))
	DIALOG_DATA.dialog_open = true
end

function DIALOG.close(DIALOG_NAME, data)
	msg.post("#", hash("disable"))
	msg.post("#", hash("release_input_focus"))
	UI.tab[DIALOG_NAME].dialog_open = false
	data = data or {}
	data.dialog = DIALOG_NAME
	msg.post(UI.tab[DIALOG_NAME].parent_tab, hash("dialog_closed"), data)
	local parent = UI.tab[DIALOG_NAME].parent_name
	UI.tab[parent].child_dialog = nil
end

function DIALOG.hide(DIALOG_NAME)
	local dialog_path = UI.tab[DIALOG_NAME].path
	msg.post(dialog_path, hash("disable"))
	msg.post(dialog_path, hash("release_input_focus"))
	UI.tab[DIALOG_NAME].dialog_open = false
	if UI.tab[DIALOG_NAME].child_dialog then
		DIALOG.close_all(DIALOG_NAME)
	end
end

function DIALOG.close_all(TAB_NAME)
	if UI.tab[TAB_NAME].child_dialog then
		DIALOG.hide(UI.tab[TAB_NAME].child_dialog)
		UI.tab[TAB_NAME].child_dialog = nil
	end
end

UI.DIALOG = DIALOG

return UI