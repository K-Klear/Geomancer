local G = {}

local current_version = 0.4

function G.round(num, decimals)
	local divisor = 0.1 ^ decimals
	return math.floor((num + 0.5 * divisor) * 10 ^ decimals) * divisor
end

function G.update_navbar(text, clear)
	msg.post("/navbar#navbar", hash("update_status"), {text = text, clear = clear})
end

function G.find_substring(string, substring, count, index)
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

function G.sanitise_json(str)
	local json_error
	repeat
		json_error = string.find(str, "},]") or string.find(str, "],}") or string.find(str, "\",}") or string.find(str, ",,")
		if json_error then
			str = string.sub(str, 1, json_error)..string.sub(str, json_error + 2)
		end
	until not json_error
	return str
end

function G.safe_decode(json_str, filename)
	json_str = G.sanitise_json(json_str)
	filename = filename or "File"
	local err, table = pcall(json.decode, json_str)
	if not err then
		msg.post("/navbar#navbar", hash("update_status"), {text = filename.." doesn't seem to be valid JSON."})
		msg.post("/navbar#navbar", hash("update_status"), {text = table})
		return
	else
		return table, json_str
	end
end

function G.safe_output(path)
	local works, f = pcall(io.output, path)
	if works then
		return f
	else
		msg.post("/navbar#navbar", hash("update_status"), {text = "Error when writing into a file. Operation aborted.", clear = true})
	end
end

function G.check_version(tab, filename)
	local version = tonumber(tab.version)
	filename = filename or "file"
	if not version then
		G.update_navbar("Error reading version information of "..filename..". File not loaded.")
		return
	elseif version < current_version then
		G.update_navbar("Version of "..filename.." is lower than "..current_version..". Resave it with the current Pistol Mix version.")
		return
	elseif version > current_version then
		G.update_navbar("Version of "..filename.." is higher than "..current_version..". This may cause unknown issues. Be careful.")
		return true
	else
		return true
	end
end

function G.expand_repeat_actions(tween_script)
	local new_script = {}
	local deletion_count = 0
	local function copy_action(action_table)
		local new_tab = {type = action_table.type, part = action_table.part, time = action_table.time}
		if action_table.start_state then
			new_tab.start_state = {x = action_table.start_state.x, y = action_table.start_state.y, z = action_table.start_state.z}
		end
		if action_table.end_state then
			new_tab.end_state = {x = action_table.end_state.x, y = action_table.end_state.y, z = action_table.end_state.z}
		end
		if action_table.easing then
			new_tab.easing = action_table.easing
		end
		return new_tab
	end
	
	for key = #tween_script, 1, -1 do
		local val = tween_script[key]
		local ignore_repeat = false
		if val.type == "X" then
			local number_of_repetitions = val.number_of_repetitions
			local actions_to_repeat = val.actions_to_repeat
			for action_index = key - val.actions_to_repeat, key - 1 do
				if action_index < 1 or tween_script[action_index].type == "X" then
					--(tween_script[action_index].easing and tween_script[action_index].easing.vertex_count > 2) then
					deletion_count = deletion_count + 1
					ignore_repeat = true
					break
				end
			end
			if not ignore_repeat then
				for i = 1, number_of_repetitions do
					for action_index = key - 1, key - actions_to_repeat, -1 do
						table.insert(new_script, 1, copy_action(tween_script[action_index]))
					end
				end
			end
		else
			table.insert(new_script, 1, copy_action(val))
		end
	end
	return new_script, deletion_count
end

function G.parse_transform(str, inverted)
	local commas = {string.find(str, ",")}
	for i = 2, 9 do
		commas[i] = string.find(str, ",", commas[i - 1] + 1)
	end
	local values = {string.sub(str, 1, commas[1] - 1)}
	for i = 2, 9 do
		values[i] = string.sub(str, commas[i - 1] + 1, commas[i] - 1)
	end
	values[10] = string.sub(str, commas[9] + 1)
	local pos = vmath.vector3(values[1], values[2], values[3])
	local rot = vmath.quat(values[4], values[5], values[6], values[7])
	local sc = vmath.vector3(values[8], values[9], values[10])
	if sc.x < 0 then
		inverted = not inverted
	end
	if sc.y < 0 then
		inverted = not inverted
	end
	if sc.z < 0 then
		inverted = not inverted
	end
	return pos, rot, sc, inverted
end

local two_pi = 2 * math.pi
local half_pi = math.pi * 0.5
local negative_flip = -0.0001
local positive_flip = two_pi - 0.0001

function G.euler_to_quat(euler)
	local qx, qy, qz
	qx = vmath.quat_rotation_x(math.rad(euler.x))
	qy = vmath.quat_rotation_y(math.rad(euler.y))
	qz = vmath.quat_rotation_z(math.rad(euler.z))
	return qy * qx * qz
end

function G.quat_to_euler(q)
	local x = q.x
	local y = q.y
	local z = q.z
	local w = q.w
	local check = 2 * (y * z - w * x)
	if check < 0.999 then
		if check > -0.999 then
			local v = vmath.vector3(-math.asin(check),
			math.atan2(2 * (x * z + w * y), 1 - 2 * (x * x + y * y)),
			math.atan2(2 * (x * y + w * z), 1 - 2 * (x * x + z * z)))
			return math.deg(v)
		else
			local v = vmath.vector3(half_pi, math.atan2(2 * (x * y - w * z), 1 - 2 * (y * y + z * z)), 0)
			return math.deg(v)
		end
	else
		local v = vmath.vector3(-half_pi, math.atan2(-2 * (x * y - w * z), 1 - 2 * (y * y + z * z)), 0)
		return math.deg(v)
	end
end

function G.sanitise_euler(euler)
	if euler.x < negative_flip then
		euler.x = euler.x + two_pi
	elseif euler.x > positive_flip then
		euler.x = euler.x - two_pi
	end
	if euler.y < negative_flip then
		euler.y = euler.y + two_pi
	elseif euler.y > positive_flip then
		euler.y = euler.y - two_pi
	end
	if euler.z < negative_flip then
		euler.z = euler.z + two_pi
	elseif euler.z > positive_flip then
		euler.z = euler.z + two_pi
	end
	return euler
end


return G