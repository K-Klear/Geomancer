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
					table.remove(UI.active, key)
					--gui.play_flipbook(node, "button_white")
					--local text_node = gui.get_node(template.."/text")
					--gui.set_color(text_node, vmath.vector4(0, 0, 0, 1))
					--gui.set_position(text_node, UI.EMPTY_VECTOR)
					return
				end
			end
		end
	else
		UI.active = {}
		UI.text_fields = {}
		hover = nil
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
local function reset_cursor_timer()
	if cursor_timer then
		timer.cancel(cursor_timer)
		cursor_visible = false
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
					gui.set_color(text_node, vmath.vector4(0, 0, 0, 1))
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


return UI