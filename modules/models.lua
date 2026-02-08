local MOD = {}

local G = require "modules.global"
local SET = require "modules.settings"

MOD.move_terrain = true
MOD.pov_lock = true
MOD.target_x = 0
MOD.target_y = 15
MOD.cam_target_x = 0
MOD.cam_target_y = 0
MOD.cam_target_z = 8
MOD.cam_zoom = 8
MOD.tween_preview = false

MOD.playback = false

MOD.flash_list = {}

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

function MOD.buffer_resource_used(buf)
	buffer_list[buf] = buffer_list[buf] + 1
end

function MOD.buffer_resource_released(buf)
	buffer_list[buf] = buffer_list[buf] - 1
end

function MOD.release_model_resources()
	msg.post("/model_viewer#model_viewer", hash("remove_model"))
	buffer_name_index = 0
	for key, val in pairs(buffer_list) do
		if val == 0 then
			resource.release(key)
			buffer_list[key] = buffer_list[key] - 1
			--buffer_list[key] = nil
			--timer.delay(0.005, false, function()
				
			--end)
		end
	end
	collectgarbage()
end

function MOD.create_mesh(mesh_tab)
	if not mesh_tab.triangles then
		if SET.recalculate_normals then
			local verts_parsed
			if not mesh_tab.verts_parsed then
				verts_parsed = {}
				for k, v in ipairs(mesh_tab.verts) do
					verts_parsed[k] = G.parse_values(v)
				end
			else
				verts_parsed = mesh_tab.verts_parsed
			end
			local triangles, normals = {}, {}
			for i = mesh_tab.IndexStart, mesh_tab.IndexEnd, 3 do
				local vec_a = vmath.vector3(verts_parsed[mesh_tab.tris[i + 0] + 1][1], verts_parsed[mesh_tab.tris[i + 0] + 1][2], verts_parsed[mesh_tab.tris[i + 0] + 1][3])
				local vec_b = vmath.vector3(verts_parsed[mesh_tab.tris[i + 1] + 1][1], verts_parsed[mesh_tab.tris[i + 1] + 1][2], verts_parsed[mesh_tab.tris[i + 1] + 1][3])
				local vec_c = vmath.vector3(verts_parsed[mesh_tab.tris[i + 2] + 1][1], verts_parsed[mesh_tab.tris[i + 2] + 1][2], verts_parsed[mesh_tab.tris[i + 2] + 1][3])
				local norm = vmath.normalize(vmath.cross(vec_b - vec_a, vec_c - vec_a))
				for j = 0, 2 do
					local vertex = mesh_tab.tris[i + j] + 1
					table.insert(triangles, verts_parsed[vertex][1])
					table.insert(triangles, verts_parsed[vertex][2])
					table.insert(triangles, verts_parsed[vertex][3])
					table.insert(normals, norm.x)
					table.insert(normals, norm.y)
					table.insert(normals, norm.z)
				end		
			end
			mesh_tab.triangles = triangles
			mesh_tab.normals_parsed = normals
			mesh_tab.verts_parsed = verts_parsed
		else
			local verts_parsed
			local normals_parsed = {}
			if not mesh_tab.verts_parsed then
				verts_parsed = {}
				for k, v in ipairs(mesh_tab.verts) do
					verts_parsed[k] = G.parse_values(v)
					normals_parsed[k] = G.parse_values(mesh_tab.normals[k])
				end
			else
				verts_parsed = mesh_tab.verts_parsed
			end
			local triangles, normals = {}, {}
			for i = mesh_tab.IndexStart, mesh_tab.IndexEnd, 3 do
				for j = 0, 2 do
					local vertex = mesh_tab.tris[i + j] + 1
					table.insert(triangles, verts_parsed[vertex][1])
					table.insert(triangles, verts_parsed[vertex][2])
					table.insert(triangles, verts_parsed[vertex][3])
					table.insert(normals, normals_parsed[vertex][1])
					table.insert(normals, normals_parsed[vertex][2])
					table.insert(normals, normals_parsed[vertex][3])
				end
			end
			mesh_tab.triangles = triangles
			mesh_tab.normals_parsed = normals
			mesh_tab.verts_parsed = verts_parsed
		end
	end

	local buf = buffer.create(#mesh_tab.triangles / 3, {
		{name = hash("position"), type = buffer.VALUE_TYPE_FLOAT32, count = 3},
		{name = hash("normal"), type = buffer.VALUE_TYPE_FLOAT32, count = 3},
		{name = hash("texcoord0"), type = buffer.VALUE_TYPE_FLOAT32, count = 2}
	})

	local positions = buffer.get_stream(buf, "position")
	local normal = buffer.get_stream(buf, "normal")
	local texcoord0 = buffer.get_stream(buf, "texcoord0")

	local tex_index = 1
	for i, value in ipairs(mesh_tab.triangles) do
		positions[i] = mesh_tab.triangles[i]
		normal[i] = mesh_tab.normals_parsed[i]
		if not (i % 3 == 0) then
			texcoord0[tex_index] = mesh_tab.triangles[i] * 0.25
			tex_index = tex_index + 1
		end
	end
	mesh_tab.buffer_resource = MOD.create_buffer(buf)
end

return MOD