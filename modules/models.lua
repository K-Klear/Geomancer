local MOD = {}

MOD.target_x = 0
MOD.target_y = 15
MOD.cam_target_x = 0
MOD.cam_target_y = 0
MOD.cam_target_z = 8
MOD.tween_preview = false
MOD.inverted = false

local buffer_list = {}
local buffer_name_index = 0
local function get_buffer_name()
	local name
	repeat
		buffer_name_index = buffer_name_index + 1
		name = "/buffer"..buffer_name_index..".bufferc"
	until not buffer_list[hash(name)]
	return name
end

function MOD.create_buffer(buf)
	local res = resource.create_buffer(get_buffer_name(), {buffer = buf})
	buffer_list[res] = 0
	return res
end

function MOD.mesh_created(buf)
	buffer_list[buf] = buffer_list[buf] + 1
end

function MOD.mesh_deleted(buf)
	buffer_list[buf] = buffer_list[buf] - 1
end

function MOD.release_model_resources()
	msg.post("/model_viewer#model_viewer", hash("remove_model"))
	buffer_name_index = 0
	for key, val in pairs(buffer_list) do
		if val == 0 then
			resource.release(key)
			--buffer_list[key] = nil
			timer.delay(0.01, false, function() buffer_list[key] = nil end)
		end
	end
	collectgarbage()
end

return MOD