local LVL = {}
local MEM = require "modules.memory"
local UI = require "modules.ui"

local enemy_set_names = {}
enemy_set_names.Normal = "Henchmen"
enemy_set_names.Robots = "Robots"
enemy_set_names.Outlaws = "Bandits"
enemy_set_names.Targets = "Targets"
enemy_set_names.Majesty = "Knights"
enemy_set_names.Skeletons = "Skeletons"

local obstacle_list = {}
obstacle_list.obsNormal = "Normal"
obstacle_list.Pipes = "Pipes"
obstacle_list.Rocks = "Rocks"
obstacle_list.Colony = "Colony"
obstacle_list.Tower = "Tower"
obstacle_list.Crates = "Crates"
obstacle_list.Train = "Train"
obstacle_list.Earthcracker = "Earthcracker"
obstacle_list.ShredPipes = "ShredPipes"
obstacle_list.Vaporwave = "Vaporwave"
obstacle_list.Castle = "Castle"
obstacle_list.Spooky = "Spooky"
obstacle_list.AirDrop = "AirDrop"

local material_list = {}
material_list.default = "Default"
material_list.heartbreaker = "Heartbreaker"
material_list.alien_planet = "Alien Planet"
material_list.arbiter = "Arbiter"
material_list.robot_facilities = "2089 - Robot Facilities"
material_list.strange_creatures = "2089 - Strange Creatures"
material_list.cave = "AP2 Cave"
material_list.desert = "AP2 Desert"
material_list.western = "Western Town"
material_list.oldwest_train = "OldWest Train"
material_list.castle_mat = "Castle"
material_list.shred = "ShredFactory"
material_list.halloween = "HalloweenParty"
material_list.art_deco = "ArtDeco"
material_list.my_mind = "MyMind"

function LVL.setup()
	for key, val in pairs(obstacle_list) do
		gui.set_text(gui.get_node(key.."/text"), val)
	end
	for key, val in pairs(material_list) do
		gui.set_text(gui.get_node(key.."/text"), val)
	end
end

function LVL.update_labels()
	gui.set_text(gui.get_node("btn_enemies/text"), enemy_set_names[MEM.level_data.enemy_set])
	gui.set_text(gui.get_node("btn_obstacles/text"), MEM.level_data.obstacle_set)
	gui.set_text(gui.get_node("btn_materials/text"), MEM.level_data.material_set)
	gui.set_text(gui.get_node("btn_movement/text"), MEM.level_data.move_mode)
	gui.set_text(gui.get_node("preview_time/text"), MEM.level_data.preview_time)
end

function LVL.evaluate_input(field, text)
	local value
	local text_node = gui.get_node(field.."/text")
	if field == "preview_time" then
		local value = tonumber(text)
		if value then
			value = math.floor(value)
			if value < 0 then
				value = 0
			elseif value > MEM.level_data.song_length then
				value = math.floor(MEM.level_data.song_length)
			end
			MEM.level_data.preview_time = value
		end
		gui.set_text(gui.get_node("preview_time/text"), MEM.level_data.preview_time)
	end
end

local function close_dialogs()
	gui.set_enabled(gui.get_node("enemy_box"), false)
	gui.set_enabled(gui.get_node("obstacle_box"), false)
	gui.set_enabled(gui.get_node("material_box"), false)
end

function LVL.evaluate_button(button)
	local checkbox_text = {[true] = "X", [false] = ""}
	if button == "btn_enemies" then
		gui.set_enabled(gui.get_node("enemy_box"), true)
		UI.unload_template()
		for key in pairs(enemy_set_names) do
			UI.load_template(key)
		end
		UI.switch_cleanup = close_dialogs
	elseif enemy_set_names[button] then
		UI.unload_template()
		UI.switch_tab("tab_level")
		gui.set_enabled(gui.get_node("enemy_box"), false)
		MEM.level_data.enemy_set = button
		gui.set_text(gui.get_node("btn_enemies/text"), enemy_set_names[MEM.level_data.enemy_set])
		UI.tabs_active = true
		UI.switch_cleanup = nil
	elseif button == "btn_obstacles" then
		gui.set_enabled(gui.get_node("obstacle_box"), true)
		UI.unload_template()
		for key in pairs(obstacle_list) do
			UI.load_template(key)
		end
		UI.switch_cleanup = close_dialogs
	elseif obstacle_list[button] then
		UI.unload_template()
		UI.switch_tab("tab_level")
		gui.set_enabled(gui.get_node("obstacle_box"), false)
		MEM.level_data.obstacle_set = obstacle_list[button]
		gui.set_text(gui.get_node("btn_obstacles/text"), MEM.level_data.obstacle_set)
		UI.switch_cleanup = nil
	elseif button == "btn_materials" then
		gui.set_enabled(gui.get_node("material_box"), true)
		UI.unload_template()
		for key in pairs(material_list) do
			UI.load_template(key)
		end
		UI.switch_cleanup = close_dialogs
	elseif material_list[button] then
		UI.unload_template()
		UI.switch_tab("tab_level")
		gui.set_enabled(gui.get_node("material_box"), false)
		MEM.level_data.material_set = material_list[button]
		gui.set_text(gui.get_node("btn_materials/text"), MEM.level_data.material_set)
		UI.switch_cleanup = nil
	elseif button == "btn_movement" then
		if MEM.level_data.move_mode == "Moving" then
			MEM.level_data.move_mode = "Stationary"
		else
			MEM.level_data.move_mode = "Moving"
		end
		gui.set_text(gui.get_node("btn_movement/text"), MEM.level_data.move_mode)
	end
end


return LVL