local G = {}
local S = require "modules.status"

local current_version = 0.4

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
		S.update(filename.." doesn't seem to be valid JSON.")
		S.update(table)
		return
	else
		return table, json_str
	end
end

function G.check_version(str, filename)
	local pos = string.find(str, "\"version\":")
	if not pos then
		S.update("Unknown format of "..filename..".")
		return
	else
		local ver = tonumber(string.sub(str, pos + 11, pos + 13))
		if not ver then
			S.update("Error reading version information of "..filename..". File not loaded.")
			return
		elseif ver < current_version then
			S.update("Version of "..filename.." is lower than "..current_version..". Resave it with the current Pistol Mix version.")
			return
		elseif ver > current_version then
			S.update("Version of "..filename.." is higher than "..current_version..". This may cause unknown issues. Be careful.")
			return true
		else
			return true
		end
	end
end

return G