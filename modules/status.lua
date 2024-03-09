local S = {}

local status_text = {"Welcome to Geomancer!", "", "Start by loading a map file, folder or separate files."}
local status_text_node, status_background, status_font

function S.update(text, clear)
	if clear then
		status_text = {text}
	elseif text then
		table.insert(status_text, text)
	end
	local str = ""
	local line_breaks = 0
	local width = gui.get_size(status_background).x
	for key, val in ipairs(status_text) do
		local metrics = resource.get_text_metrics(status_font, val)
		line_breaks = line_breaks + math.floor(metrics.width / width)
		str = str..val.."\n"
	end
	gui.set_text(status_text_node, str)
	metrics = resource.get_text_metrics(status_font, str)
	gui.set_size(status_background, vmath.vector3(width, metrics.height + (line_breaks * 14), 1))
end

function S.setup()
	status_background = gui.get_node("status_background")
	status_text_node = gui.get_node("status_text")
	status_font = gui.get_font_resource(gui.get_font(status_text_node)) 
end


return S