local BEAT = {}
local MEM = require "modules.memory"
local UI = require "modules.ui"
local S = require "modules.status"

local enemy_to_change

local enemy_names = {
	normal = "Normal",
	tough = "Tough",
	chuck = "Heavy",
	horse = "Horse Rider",
	shield = "Shielded",
	turret = "Normal Turret",
	minigun = "Minigun Turret",
	skull = "Flying Skull",
	trap = "Glitched Enemy"
}

local internal_names = {
	normal = "Normal",
	tough = "Tough",
	chuck = "ChuckNorris",
	horse = "Mounted Enemy",
	shield = "Shield",
	turret = "Normal Turret",
	minigun = "Minigun Turret",
	skull = "FlyingBomb",
	trap = "Trap Enemy"
}

function BEAT.update_buttons()
	for key, val in pairs(MEM.beat_data.enemy_types) do
		gui.set_enabled(gui.get_node(key.."/button_white"), val)
		if val then
			UI.load_template(key)
		else
			UI.unload_template(key)
		end
		S.update("Select an enemy type to replace.", true)
	end
end

local function close_box()
	UI.switch_cleanup = nil
	gui.set_enabled(gui.get_node("beat_enemy_box"), false)
	UI.switch_tab("tab_beat")
	BEAT.update_buttons()
	enemy_to_change = nil
end

local function replace(new_type)
	local pos = string.find(MEM.beat_data.string, internal_names[enemy_to_change])
	if pos then
		local string_start = string.sub(MEM.beat_data.string, 1, pos - 1)
		local string_end = string.sub(MEM.beat_data.string, pos + #internal_names[enemy_to_change])
		MEM.beat_data.string = string_start..internal_names[new_type]..string_end
		return replace(new_type)
	end
end

function BEAT.evaluate_button(button)
	if MEM.beat_data.enemy_types[button] then
		UI.unload_template()
		gui.set_enabled(gui.get_node("beat_enemy_box"), true)
		for key in pairs(MEM.beat_data.enemy_types) do
			UI.load_template("choice_"..key)
		end
		UI.load_template("choice_cancel")
		UI.switch_cleanup = close_box
		enemy_to_change = button
		S.update("Select replacement for "..enemy_names[enemy_to_change]..".", true)
	elseif button == "choice_cancel" then
		close_box()
	else
		local b = string.sub(button, 8)
		for key, val in pairs(MEM.beat_data.enemy_types) do
			if key == b then
				if b == enemy_to_change then
					S.update("Select a different enemy type.", true)
					return
				else
					S.update("Replacing "..enemy_names[enemy_to_change].." with "..enemy_names[b]..".", true)
					replace(b)
					MEM.beat_data.enemy_types[b] = true
					MEM.beat_data.enemy_types[enemy_to_change] = false
					close_box()
				end
			end
		end
	end
end

function BEAT.export(path)
	local f = io.output(path)
	io.write(MEM.beat_data.string)
	io.close(f)
end

return BEAT