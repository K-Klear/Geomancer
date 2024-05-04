local G = {}
local S = require "modules.status"

function G.sanitise_json(str)
	local json_error
	repeat
		json_error = string.find(str, "},]") or string.find(str, "],}") or string.find(str, "\",}")
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

return G