local UI = {active = {}}

UI.COLOUR_DEFAULT = vmath.vector4(0.35, 0.75, 0.15, 1)
UI.COLOUR_DISABLED = vmath.vector4(0.1, 0.1, 0.1, 1)
UI.COLOUR_ERROR = vmath.vector4(0.05, 0.45, 0.05, 1)
UI.COLOUR_WHITE = vmath.vector4(1)
UI.COLOUR_BLACK = vmath.vector4(0, 0, 0, 1)

UI.BUTTON_FLASH_TIME = 0.2
UI.BUTTON_PRESS_TIME = 0.05
UI.EMPTY_VECTOR = vmath.vector3()

UI.input_enabled = true

local mouse_held, hover

function UI.load_template(template)
	local node, node_text
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
	if pcall(gui.get_node, template.."/button_white") then
		node = gui.get_node(template.."/button_white")
	end
	table.insert(UI.active, {template = template, type = hash("button_white"), node = node})
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
		gui.set_color(text_node, vmath.vector4(0, 0, 0, 1))
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
					if hover > key then
						hover = hover - 1
					elseif hover == key then
						remove_hover()
					end
					--gui.play_flipbook(val.node, "button_white")
					--local text_node = gui.get_node(template.."/text")
					--gui.set_color(text_node, vmath.vector4(0, 0, 0, 1))
					--gui.set_position(text_node, UI.EMPTY_VECTOR)
					table.remove(UI.active, key)
					return
				end
			end
		end
	else
		UI.active = {}
	end
end

local function template_clicked(button, fn)
	local button_data = UI.active[button]

	gui.play_flipbook(button_data.node, "button_white_up")
	local text_node = gui.get_node(button_data.template.."/text")
	gui.animate(text_node, "position", UI.EMPTY_VECTOR, go.EASING_LINEAR, UI.BUTTON_PRESS_TIME)
	fn(button_data.template)
	--SND.play("#beep")
end

function UI.on_input(self, action_id, action, button_fn)
	mouse_held = action.pressed or (mouse_held and not action.released)
	if not UI.input_enabled then return end
	if action_id == hash("touch") then
		if action.released then
			for key, val in ipairs(UI.active) do
				if gui.pick_node(val.node, action.x, action.y) then
					template_clicked(key, button_fn)
					break
				end
			end
		elseif action.pressed then
			for key, val in ipairs(UI.active) do
				if gui.pick_node(val.node, action.x, action.y) then
					gui.play_flipbook(val.node, "button_white_down")
					local text_node = gui.get_node(val.template.."/text")
					gui.set_color(text_node, vmath.vector4(0, 0, 0, 1))
					gui.set_position(text_node, UI.EMPTY_VECTOR)
					gui.animate(text_node, "position", vmath.vector3(5, -5, 0), go.EASING_LINEAR, UI.BUTTON_PRESS_TIME)
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
				gui.set_color(text_node, vmath.vector4(0, 0, 0, 1))
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

local text_field
local text_field_text = ""
local char_limit
local cursor_timer
local cursor_visible = false
local placeholder_text = ""

local function text_field_cursor()
	cursor_visible = not cursor_visible
	if cursor_visible then
		gui.set_text(text_field, text_field_text.."|")
	else
		gui.set_text(text_field, text_field_text)
	end
	cursor_timer = timer.delay(0.5, false, text_field_cursor)
end

function UI.enable_text_field(node, remove_text, set_char_limit, placeholder)
	placeholder_text = placeholder or ""
	char_limit = set_char_limit
	text_field = node
	if remove_text then
		text_field_text = ""
	else
		text_field_text = gui.get_text(node)
	end
	gui.show_keyboard(gui.KEYBOARD_TYPE_DEFAULT, false)
	cursor_visible = false
	text_field_cursor()
end

function UI.disable_text_field(remove_text)
	gui.hide_keyboard()
	if text_field then
		if remove_text then
			gui.set_text(text_field, remove_text)
			text_field_text = placeholder_text
		else
			if #text_field_text > 0 then
				gui.set_text(text_field, text_field_text)
			else
				gui.set_text(text_field, placeholder_text)
			end
		end
		timer.cancel(cursor_timer)
		text_field = nil
		char_limit = nil
	end
end

function UI.check_text_field(x, y)
	if text_field and not gui.pick_node(text_field, x, y) then
		UI.disable_text_field()
	end
end

function UI.enter_text(text)
	if text_field then
		local new_text = text_field_text..text
		if char_limit and #new_text > char_limit then
			return
		end
		text_field_text = new_text
		gui.set_text(text_field, text_field_text)
		timer.cancel(cursor_timer)
		cursor_visible = false
		text_field_cursor()
	end
end

function UI.backspace()
	if text_field and #text_field_text > 0 then
		text_field_text = string.sub(text_field_text, 1, -2)
		gui.set_text(text_field, text_field_text)
		timer.cancel(cursor_timer)
		cursor_visible = false
		text_field_cursor()
	end
end

function UI.reset_text_field(node)
	gui.set_text(node, placeholder_text)
end

return UI