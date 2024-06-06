local G_S = {}

local MEM = require "modules.memory"
local S = require "modules.status"
local G = require "modules.global"

G_S.volumes = {}
local image_data = {}
local filter = 0
local filter_threshold = 128
local invert = false
local create_additive = true
local create_subtractive = false
local current_preview = 1
local show_path = true
local separate_group_index = true
local z_depth = 1
local processing_order = "1500"
local MIN_X, MAX_X, MIN_Y, MAX_Y = -84, 82, -80, 85
local min_x, max_x, min_y, max_y = MIN_X, MAX_X, MIN_Y, MAX_Y


function G_S.reset()
	G_S.volumes = {}
	image_data = {}
	current_preview = 1
end

local vol_1 = "{\"type\":\""
local vol_1b= "\",\"offset\":\"("
local vol_2 = ")\",\"scale\":\"("
local vol_3 = ")\",\"worldPosition\":\"("
local vol_4 = ")\",\"localScale\":\"("
local vol_5 = ")\",\"groupIndex\":\""
local vol_6 = "\",\"processingOrder\":\""
local vol_7 = "\"}"
local comma = ", "
local volume_type = {[true] = "Additive", [false] = "Subtractive"}

local function set_preview_image(image)
	current_preview = image or current_preview
	gui.set_texture(gui.get_node("preview"), tostring(image_data[current_preview].z))
	gui.set_text(gui.get_node("preview_label"), "Z position: "..tostring(image_data[current_preview].z))
end

local text_field_button_data = {}
text_field_button_data.min_x_down = {change = -1, node_id = "min_x"}
text_field_button_data.min_x_up = {change = 1, node_id = "min_x"}
text_field_button_data.max_x_down = {change = -1, node_id = "max_x"}
text_field_button_data.max_x_up = {change = 1, node_id = "max_x"}
text_field_button_data.min_y_down = {change = -1, node_id = "min_y"}
text_field_button_data.min_y_up = {change = 1, node_id = "min_y"}
text_field_button_data.max_y_down = {change = -1, node_id = "max_y"}
text_field_button_data.max_y_up = {change = 1, node_id = "max_y"}
text_field_button_data.depth_up = {change = 1, node_id = "depth"}
text_field_button_data.depth_down = {change = -1, node_id = "depth"}

local function set_stencil_size()
	local w = (max_x - min_x + 1) * 4
	local h = (max_y - min_y + 1) * 4
	local x = -334 + (min_x + math.abs(MIN_X)) * 4
	local y = -332 + (min_y + math.abs(MIN_Y)) * 4
	gui.set_size(gui.get_node("crop_stencil"), vmath.vector3(w, h, 1))
	gui.set_position(gui.get_node("crop_stencil"), vmath.vector3(x, y, 0))
	gui.set_position(gui.get_node("range_box"), vmath.vector3(min_x * -4 - 340 + 4, min_y * -4 - 328 + 8, 0))
end

local function node_text_to_number(node)
	return tonumber(gui.get_text(gui.get_node(node)))
end

function G_S.evaluate_input(field, text)
	local value
	local text_node = gui.get_node(field.."/text")
	if field == "depth" then
		value = tonumber(text)
		if not value or value < 1 then
			value = 1
		end
		z_depth = value
		gui.set_text(text_node, value)
	elseif field == "min_x" then
		value = tonumber(text) or 0
		local max_value = node_text_to_number("max_x/text")
		if value > max_value then
			value = max_value
		elseif value < MIN_X then
			value = MIN_X
		end
		min_x = value
		gui.set_text(text_node, value)
		set_stencil_size()
	elseif field == "min_y" then
		value = tonumber(text) or 0
		local max_value = node_text_to_number("max_y/text")
		if value > max_value then
			value = max_value
		elseif value < MIN_Y then
			value = MIN_Y
		end
		min_y = value
		gui.set_text(text_node, value)
		set_stencil_size()
	elseif field == "max_x" then
		value = tonumber(text) or 0
		local min_value = node_text_to_number("min_x/text")
		if value > MAX_X then
			value = MAX_X
		elseif value < min_value then
			value = min_value
		end
		max_x = value
		gui.set_text(text_node, value)
		set_stencil_size()
	elseif field == "max_y" then
		value = tonumber(text) or 0
		local min_value = node_text_to_number("min_y/text")
		if value > MAX_Y then
			value = MAX_Y
		elseif value < min_value then
			value = min_value
		end
		max_y = value
		gui.set_text(text_node, value)
		set_stencil_size()
	elseif field == "processing_order" then
		value = tonumber(text) or 0
		gui.set_text(text_node, value)
		processing_order = value
	end
end

local function is_geo(pixels, width, x, y)
	local index = y * width * 4 + x * 4 + 1
	local value = pixels[index + filter]
	if invert then
		return value < filter_threshold
	end
	return value > filter_threshold
end

local function get_volume(pos_x, pos_y, pos_z, scale_x, scale_y, scale_z, group_index, is_additive)
	local vol = vol_1..volume_type[is_additive]..vol_1b..tostring(pos_x)..comma..tostring(pos_y)..comma..tostring(pos_z)..vol_2..tostring(scale_x)..comma..tostring(scale_y)..comma..tostring(scale_z)
	vol = vol..vol_3..tostring(((scale_x * 0.5) + pos_x) * 0.5)..comma..tostring(((scale_y * 0.5) + pos_y) * 0.5)..comma..tostring(((scale_z * 0.5) + pos_z) * 0.5)
	vol = vol..vol_4..tostring(scale_x * 0.5)..comma..tostring(scale_y * 0.5)..comma..tostring(scale_z * 0.5)..vol_5..group_index..vol_6..processing_order..vol_7
	return vol
end

local function divide_picture(index, group_index)
	local pixel_values = {}
	local width = max_x - min_x + 1
	local height = max_y - min_y + 1
	local volume_created = false
	for i = 1, width * height do
		local x = (i - 1) % width + (min_x - MIN_X)
		local y = math.floor((i - 1) / width) + (min_y - MIN_Y)
		table.insert(pixel_values, is_geo(image_data[index].pixels, image_data[index].w, x, y))
	end
	for starting_pixel = 1, width * height do
		if not (pixel_values[starting_pixel] == nil) then
			local volume_width = 1
			local volume_height = 0
			local is_additive = pixel_values[starting_pixel]
			pixel_values[starting_pixel] = nil
			repeat
				if (starting_pixel + volume_width - 1) % width == 0 then
					break
				end
				if pixel_values[starting_pixel + volume_width] == is_additive then
					pixel_values[starting_pixel + volume_width] = nil
					volume_width = volume_width + 1
				else
					break
				end
			until false
			local height_found
			repeat
				volume_height = volume_height + 1
				for i = 1, volume_width do
					if not (pixel_values[starting_pixel + width * volume_height + i - 1] == is_additive) then
						height_found = true
						break
					end
				end
				if not height_found then
					for i = 1, volume_width do
						pixel_values[starting_pixel + width * volume_height + i - 1] = nil
					end
				end
			until height_found
			if (is_additive and create_additive) or (create_subtractive and not is_additive) then
				local x = min_x + (starting_pixel - 1) % width
				local y = min_y + math.floor(starting_pixel / width)
				table.insert(G_S.volumes, get_volume(x, y, image_data[index].z, volume_width, volume_height, z_depth, group_index, is_additive))
				volume_created = true
			end
		end
	end
	return volume_created
end

function G_S.evaluate_button(button)
	local checkbox_text = {[true] = "X", [false] = ""}
	if button == "load_images" then
		local num, path = diags.open_folder()
		if path then
			for key, val in ipairs(image_data) do
				gui.delete_texture(tostring(val.z))
			end
			image_data = {}
			local count = 0
			for filename in lfs.dir(path) do
				local ext_dot = string.find(filename, "%.")
				if ext_dot then
					local z = string.sub(filename, 1, ext_dot - 1)
					if z and tonumber(z) then
						local f = io.open(path.."/"..filename, "rb")
						if f then
							local image = f:read("*a")
							local buf, w, h = png.decode_rgba(image, true)
							if not (w == 167 and h == 166) then
								S.update("Image "..filename.." has wrong dimensions.")
							else
								local pixels = buffer.get_stream(buf, hash("pixels"))
								gui.new_texture(z, w, h, "rgba", buffer.get_bytes(buf, hash("pixels")), true)
								table.insert(image_data, {pixels = pixels, w = w, h = h, z = z})
								S.update(filename.." loaded.")
								count = count + 1
							end
							io.close(f)
						end
					end
				end
			end
			S.update("Loaded "..count.." images.")
			if count > 0 then
				table.sort(image_data, function(a, b) return tonumber(a.z) < tonumber(b.z) end)
				set_preview_image(1)
			end
		end
	elseif button == "left" then
		if current_preview > 1 then
			current_preview = current_preview - 1
			set_preview_image()
		end
	elseif button == "right" then
		if current_preview < #image_data then
			current_preview = current_preview + 1
			set_preview_image()
		end
	elseif button == "additive" then
		create_additive = not create_additive
		gui.set_text(gui.get_node("additive/text"), checkbox_text[create_additive])
	elseif button == "subtractive" then
		create_subtractive = not create_subtractive
		gui.set_text(gui.get_node("subtractive/text"), checkbox_text[create_subtractive])
	elseif button == "invert" then
		invert = not invert
		msg.post("@render:", hash("invert_preview"), {invert = invert})
		gui.set_text(gui.get_node("invert/text"), checkbox_text[invert])
	elseif button == "show_path" then
		show_path = not show_path
		gui.set_text(gui.get_node(button.."/text"), checkbox_text[show_path])
		gui.set_visible(gui.get_node("player_path"), show_path)
	elseif button == "image_group" then
		separate_group_index = not separate_group_index
		gui.set_text(gui.get_node(button.."/text"), checkbox_text[separate_group_index])
	elseif button == "filter_white" then
		filter = 0
		gui.set_text(gui.get_node("filter_white/text"), "X")
		gui.set_text(gui.get_node("filter_alpha/text"), "")
	elseif button == "filter_alpha" then
		filter = 3
		gui.set_text(gui.get_node("filter_white/text"), "")
		gui.set_text(gui.get_node("filter_alpha/text"), "X")
	elseif text_field_button_data[button] then
		local data = text_field_button_data[button]
		local new_val = node_text_to_number(data.node_id.."/text") + data.change
		G_S.evaluate_input(data.node_id, tostring(new_val))
	elseif button == "create" then
		if false and #image_data < 1 then
			S.update("No images loaded", true)
		elseif not (create_additive or create_subtractive) then
			S.update("No volumes created. Select additive or subtractive to generate volumes.", true)
		else
			G_S.volumes = {}
			local group_index = MEM.meta_data.free_group_index
			for index, val in ipairs(image_data) do
				if divide_picture(index, group_index) and separate_group_index then
					group_index = group_index + 1
				end
			end
			if #G_S.volumes > 1 then
				S.update(#G_S.volumes.." volumes created.", true)
				S.update("They will be added to the file on export.")
			elseif #G_S.volumes == 1 then
				S.update("One volume created.", true)
				S.update("It will be added to the file on export.")
			else
				S.update("No volumes created for whatever reason.", true)
			end
		end
	end
end

function G_S.export(path)
	local output_string = ""
	if #G_S.volumes < 1 then
		output_string = MEM.meta_data.string_start..MEM.meta_data.string_end
	else
		if #MEM.meta_data.volume_table > 0 then
			output_string = ","
		end
		for key, val in ipairs(G_S.volumes) do
			output_string = output_string..val
			if key < #G_S.volumes then
				output_string = output_string..","
			end
		end
		output_string = MEM.meta_data.string_start..output_string..MEM.meta_data.string_end
	end

	if not G.safe_decode(output_string, "do_not_ship.pw_meta") then
		msg.post("/navbar#navbar", hash("update_status"), {text = "Meta data might be corrupted. Use with caution."})
	end
	
	local f = io.output(path)
	io.write(output_string)
	io.close(f)
	--f = io.output("output/volume_data.txt")
	--io.write(output_string)
	--io.close(f)
end

return G_S