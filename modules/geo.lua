local GEO = {}
local MEM = require "modules.memory"
local S = require "modules.status"

local function load_geo_data()
	local geo_data
	local num, path = diags.open("zip,pw_geo")
	if path then
		local f = io.open(path, "rb")
		if f then
			if string.sub(path, -3) == "zip" then
				local zip_data = f:read("*a")
				local archive = zip.open(zip_data)
				local file_index = zip.get_number_of_entries(archive) - 1
				for i = 0, file_index do
					local file = zip.extract_by_index(archive, i)
					if string.sub(file.name, -6) == "pw_geo" then
						geo_data = file.content
						break
					end
				end
			else
				geo_data = f:read("*a")
			end
		end
		io.close(f)
	end
	return geo_data
end

function GEO.evaluate_button(button)
	if button == "geo_visual" then
		local geo_data = load_geo_data()
		if geo_data then
			local chunk = string.find(geo_data, "chunkData")
			local slices = string.find(geo_data, "chunkSlices")
			MEM.geo_data.slices = string.sub(geo_data, slices - 1)
			S.update("Visual data replaced.", true)
		else
			S.update("Error loading geo data.", true)
		end
	elseif button == "geo_collision" then
		local geo_data = load_geo_data()
		if geo_data then
			local chunk = string.find(geo_data, "chunkData")
			local slices = string.find(geo_data, "chunkSlices")
			MEM.geo_data.chunk = string.sub(geo_data, chunk - 1, slices - 2)
			S.update("Collision data replaced.", true)
		else
			S.update("Error loading geo data.", true)
		end
	end
end

function GEO.export(path)
	local f = io.output(path)
	io.write(MEM.geo_data.start..MEM.geo_data.chunk..MEM.geo_data.slices)
	io.close(f)
end


return GEO