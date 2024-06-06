local BEAT = {}
local MEM = require "modules.memory"
local UI = require "modules.ui"
local S = require "modules.status"
local G = require "modules.global"

local enemy_to_change

local obstacle_page, obstacle_page_max = 0
local obstacle_count = 0
local selected_obstacle_index = 1
local OBSTACLE_LIST_SIZE = 25

function BEAT.reset()
	obstacle_page, obstacle_page_max = 0, 0
	obstacle_count = 0
	selected_obstacle_index = 1
end

MEM.beat_data.changed_obstacles = {}

local obstacle_types = {}
obstacle_types.Normal = {Sidestep = true, LimboTall = true, LimboShort = true}
obstacle_types.Pipes = {Sidestep = true, LimboTall = true, LimboShort = true, Wall = true, TunnelTall = true, TunnelShort = true}
obstacle_types.Rocks = {Sidestep = true, LimboTall = true, LimboShort = true, Wall = true, TunnelTall = true, TunnelShort = true}
obstacle_types.Colony = {Sidestep = true, LimboTall = true, LimboShort = true, Wall = true}
obstacle_types.Tower = {Sidestep = true, LimboTall = true, LimboShort = true}
obstacle_types.Crates = {Sidestep = true, LimboTall = true, LimboShort = true, Wall = true, TunnelTall = true, TunnelShort = true}
obstacle_types.Train = {Sidestep = true, LimboTall = true, LimboShort = true}
obstacle_types.EarthCracker = {LimboTall = true, LimboShort = true}
obstacle_types.ShredPipes = {Sidestep = true, LimboTall = true, LimboShort = true, Wall = true, TunnelTall = true, TunnelShort = true}
obstacle_types.Vaporwave = {Sidestep = true, LimboTall = true, LimboShort = true, Wall = true, TunnelTall = true, TunnelShort = true}
obstacle_types.Castle = {Sidestep = true, LimboTall = true, LimboShort = true, Wall = true}
obstacle_types.Spooky = {LimboTall = true, LimboShort = true}
obstacle_types.AirDrop = {Sidestep = true, LimboTall = true, LimboShort = true}

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

--local obstacle_types = {"Sidestep", "LimboTall", "LimboShort", "Wall", "TunnelTall", "TunnelShort"}
--local obstacle_positions = {"Right", "FarRight", "EvenMoreRight"}
--obstacle_positions[0] = "Center"
--obstacle_positions[-1] = "Left"
--obstacle_positions[-2] = "FarLeft"
--obstacle_positions[-3] = "EvenMoreLeft"

local function set_obstacle_properties_visible(visible)
	gui.set_enabled(gui.get_node("sidestep/button_white"), visible)
	gui.set_enabled(gui.get_node("limbo_tall/button_white"), visible)
	gui.set_enabled(gui.get_node("limbo_short/button_white"), visible)
	gui.set_enabled(gui.get_node("wall/button_white"), visible)
	gui.set_enabled(gui.get_node("tunnel_tall/button_white"), visible)
	gui.set_enabled(gui.get_node("tunnel_short/button_white"), visible)
	gui.set_enabled(gui.get_node("obstacle_props"), visible)
	gui.set_enabled(gui.get_node("obstacle_highlight"), visible)
end

function BEAT.update_buttons()
	for key, val in pairs(MEM.beat_data.enemy_types) do
		gui.set_enabled(gui.get_node(key.."/button_white"), val)
		if val then
			UI.load_template(key)
		else
			UI.unload_template(key)
		end
		S.update("Select an enemy type or obstacle to replace.", true)
	end
	if obstacle_count > 0 then
		if obstacle_page_max > 0 then
			UI.load_template("obstacle_page_up")
			UI.load_template("obstacle_page_down")
		end
		for i = 1, OBSTACLE_LIST_SIZE do
			if MEM.beat_data.obstacle_list[i + (obstacle_page * OBSTACLE_LIST_SIZE)] then
				UI.load_template("obstacle_list_"..i)
			end
		end
		UI.load_template({"sidestep", "limbo_tall", "limbo_short", "wall", "tunnel_tall", "tunnel_short"})
	end
end

local function populate_obstacle_list()
	for i = 1, OBSTACLE_LIST_SIZE do
		if MEM.beat_data.obstacle_list[i + (obstacle_page * OBSTACLE_LIST_SIZE)] then
			gui.set_enabled(gui.get_node("obstacle_list_"..i.."/button_white"), true)
			UI.load_template("obstacle_list_"..i)
			local obst = MEM.beat_data.obstacle_list[i + (obstacle_page * OBSTACLE_LIST_SIZE)]
			gui.set_text(gui.get_node("obstacle_list_"..i.."/text"), obst.type.." ("..obst.time..")")
			if selected_obstacle_index == i then
				gui.set_text(gui.get_node("obstacle_props"), "Time: "..obst.time.."\nType: "..obst.type.."\nPosition: "..obst.placement)
				gui.set_position(gui.get_node("obstacle_highlight"), gui.get_position(gui.get_node("obstacle_list_1/button_white")))
			end
		else
			gui.set_enabled(gui.get_node("obstacle_list_"..i.."/button_white"), false)
			UI.unload_template("obstacle_list_"..i)
		end
	end
	if obstacle_page_max > 0 then
		gui.set_text(gui.get_node("obstacle_page"), (obstacle_page + 1).."/"..(obstacle_page_max + 1))
	end
end

function BEAT.update_obstacles()
	obstacle_count = #MEM.beat_data.obstacle_list
	obstacle_page_max = math.floor((obstacle_count - 1) / OBSTACLE_LIST_SIZE)
	obstacle_page = 0
	if obstacle_count < 1 then
		set_obstacle_properties_visible(false)
		for i = 1, OBSTACLE_LIST_SIZE do
			gui.set_enabled(gui.get_node("obstacle_list_"..i.."/button_white"), false)
		end
	else
		set_obstacle_properties_visible(true)
		if obstacle_page_max > 0 then
			gui.set_enabled(gui.get_node("obstacle_page"), true)
			gui.set_enabled(gui.get_node("obstacle_page_up/button_white"), true)
			gui.set_enabled(gui.get_node("obstacle_page_down/button_white"), true)
			UI.load_template("obstacle_page_up")
			UI.load_template("obstacle_page_down")
		else
			gui.set_enabled(gui.get_node("obstacle_page"), false)
			gui.set_enabled(gui.get_node("obstacle_page_up/button_white"), false)
			gui.set_enabled(gui.get_node("obstacle_page_down/button_white"), false)
			UI.unload_template("obstacle_page_up")
			UI.unload_template("obstacle_page_down")
		end
		populate_obstacle_list()
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

local function set_new_type(obst_type)
	local obst = MEM.beat_data.obstacle_list[selected_obstacle_index]
	obst.type = obst_type
	gui.set_text(gui.get_node("obstacle_props"), "Time: "..obst.time.."\nType: "..obst.type.."\nPosition: "..obst.placement)
	local page_index = (selected_obstacle_index - 1) % OBSTACLE_LIST_SIZE + 1
	gui.set_text(gui.get_node("obstacle_list_"..page_index.."/text"), obst.type.." ("..obst.time..")")
	MEM.beat_data.changed_obstacles[obst.beat_data_key] = true
	MEM.beat_data.table[obst.beat_data_key].obstacles[obst.obstacles_key].type = obst.type
	if MEM.level_data.obstacle_set then
		if not obstacle_types[MEM.level_data.obstacle_set][obst_type] then
			S.update("Obstacle type "..obst_type.." may not be compatible with the loaded obstacle set ("..MEM.level_data.obstacle_set..")", true)
		end
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
	elseif button == "obstacle_page_up" and obstacle_page < obstacle_page_max then
		obstacle_page = obstacle_page + 1
		selected_obstacle_index = 1
		populate_obstacle_list()
	elseif button == "obstacle_page_down" and obstacle_page > 0 then
		obstacle_page = obstacle_page - 1
		selected_obstacle_index = 1
		populate_obstacle_list()
	elseif button == "sidestep" then
		set_new_type("Sidestep")
	elseif button == "limbo_tall" then
		set_new_type("LimboTall")
	elseif button == "limbo_short" then
		set_new_type("LimboShort")
	elseif button == "wall" then
		set_new_type("Wall")
	elseif button == "tunnel_tall" then
		set_new_type("TunnelTall")
	elseif button == "tunnel_short" then
		set_new_type("TunnelShort")
	elseif string.sub(button, 1, 14) == "obstacle_list_" then
		local button_index = string.sub(button, 15)
		selected_obstacle_index = button_index + (obstacle_page * OBSTACLE_LIST_SIZE)
		local obst = MEM.beat_data.obstacle_list[selected_obstacle_index]
		gui.set_text(gui.get_node("obstacle_props"), "Time: "..obst.time.."\nType: "..obst.type.."\nPosition: "..obst.placement)
		gui.set_position(gui.get_node("obstacle_highlight"), gui.get_position(gui.get_node("obstacle_list_"..button_index.."/button_white")))
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
	for beat_data_key, val in pairs(MEM.beat_data.changed_obstacles) do
		local t = MEM.beat_data.table[beat_data_key].time
		local find_time = string.find(MEM.beat_data.string, "\"time\":\""..t)
		local obstacles_start = string.find(MEM.beat_data.string, "\"obstacles\"", find_time) + 11
		local obstacles_end = string.find(MEM.beat_data.string, "]", obstacles_start, true) + 1
		local js = json.encode(MEM.beat_data.table[beat_data_key].obstacles)
		MEM.beat_data.string = string.sub(MEM.beat_data.string, 1, obstacles_start)..js..string.sub(MEM.beat_data.string, obstacles_end)
	end

	if not G.safe_decode(MEM.beat_data.string, "Output beat data file") then
		msg.post("/navbar#navbar", hash("update_status"), {text = "Beat data might be corrupted. Use with caution."})
	end

	local f = io.output(path)
	io.write(MEM.beat_data.string)
	io.close(f)
end

return BEAT