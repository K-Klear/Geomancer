local G = {}

local current_version = 0.4

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

function G.check_version(str, filename)
	filename = filename or "file"
	local pos = string.find(str, "\"version\":")
	if not pos then
		msg.post("/navbar#navbar", hash("update_status"), {text = "Unknown format of "..filename.."."})
		return
	else
		local ver = tonumber(string.sub(str, pos + 11, pos + 13))
		if not ver then
			msg.post("/navbar#navbar", hash("update_status"), {text = "Error reading version information of "..filename..". File not loaded."})
			return
		elseif ver < current_version then
			msg.post("/navbar#navbar", hash("update_status"), {text = "Version of "..filename.." is lower than "..current_version..". Resave it with the current Pistol Mix version."})
			return
		elseif ver > current_version then
			msg.post("/navbar#navbar", hash("update_status"), {text = "Version of "..filename.." is higher than "..current_version..". This may cause unknown issues. Be careful."})
			return true
		else
			return true
		end
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

return G