local MEM = {}

MEM.level_data = {}
MEM.meta_data = {}
MEM.beat_data = {}
MEM.event_data = {}
MEM.geo_data = {}
MEM.sequence_data = {}
MEM.art_data = {}

local load = {}
function load.pw(path)
	local f = io.open(path, "rb")
	if f then
		MEM.level_data.string = f:read("*a")
		local tab = json.decode(MEM.level_data.string)
		MEM.level_data.enemy_set = tab.enemySet
		MEM.level_data.obstacle_set = tab.obstacleSet
		MEM.level_data.material_set = tab.materialPropertiesSet
		MEM.level_data.preview_time = tab.previewTime
		MEM.level_data.move_mode = tab.moveMode
		MEM.level_data.song_length = tonumber(tab.songLength)
		io.close(f)
	end
end

function load.pw_meta(path)
	local f = io.open(path, "rb")
	if f then
		MEM.meta_data.string = f:read("*a")
		--MEM.meta_data.table = json.decode(MEM.meta_data.string)
		io.close(f)
	end
end

function load.pw_beat(path, filename)
	local f = io.open(path, "rb")
	if f then
		MEM.beat_data.string = f:read("*a")
		MEM.beat_data.filename = filename
		--MEM.beat_data.table = json.decode(MEM.beat_data.string)
		if string.find(MEM.beat_data.string, "FlyingBomb") or string.find(MEM.beat_data.string, "Trap Enemy") then
			print("that file is fucked yo")
		end
		io.close(f)
	end
end

function load.pw_event(path, filename)
	local f = io.open(path, "rb")
	if f then
		MEM.event_data.string = f:read("*a")
		MEM.event_data.filename = filename
		MEM.event_data.table = json.decode(MEM.event_data.string)
		if not (#MEM.event_data.table.tempoSections == 1) then
			print("fucked again")
		end
		io.close(f)
	end
end

function load.pw_geo(path, filename)
	local f = io.open(path, "rb")
	if f then
		MEM.geo_data.string = f:read("*a")
		MEM.geo_data.filename = filename
		io.close(f)
	end
end

function load.pw_seq(path, filename)
	local f = io.open(path, "rb")
	if f then
		MEM.sequence_data.string = f:read("*a")
		MEM.sequence_data.filename = filename
		io.close(f)
	end
end

function load.pw_art(path, filename)
	local f = io.open(path, "rb")
	if f then
		MEM.art_data.string = f:read("*a")
		MEM.art_data.table = json.decode(MEM.art_data.string)
		MEM.art_data.filename = filename
		if MEM.art_data.table.dynamicProps or MEM.art_data.table.dynamicCullingRanges then
			print("so totally fucked")
		end
		io.close(f)
	end
end


function MEM.load_file(path)
	local htap = string.reverse(path)
	local filename = string.reverse(string.sub(htap, 1, string.find(htap, "\\") - 1))
	local ext = string.find(htap, "%.")
	if ext then
		local extension = string.reverse(string.sub(htap, 1, ext - 1))
		if extension and load[extension] then
			load[extension](path, filename)
			print(path, filename)
		end
	end
end

return MEM