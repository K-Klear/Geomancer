local EVENT = {}
local MEM = require "modules.memory"
local UI = require "modules.ui"

local use_samples = true
local nobeat_page, event_page, tempo_page = 0, 0, 0
local nobeat_page_max, event_page_max, tempo_page_max = 0, 0, 0
local nobeat_track_index, event_track_index

function EVENT.setup()

end

function EVENT.update_labels()
	for key, val in ipairs(MEM.event_data.table.eventsData) do
		if val.track == "NoBeat" then
			nobeat_track_index = key
		elseif val.track == "Event" then
			event_track_index = key
		end
	end
	local nobeat_count = #MEM.event_data.table.eventsData[nobeat_track_index].events
	local event_count = #MEM.event_data.table.eventsData[event_track_index].events
	local tempo_count = #MEM.event_data.table.tempoSections
	nobeat_page_max = math.floor((nobeat_count - 1) / 10)
	event_page_max = math.floor((event_count - 1) / 10)
	tempo_page_max = math.floor((tempo_count - 1) / 10)
	for i = 1, 10 do
		local str_i = tostring(i)
		if i + (10 * nobeat_page) > nobeat_count then
			gui.set_enabled(gui.get_node("nobeat_panel_"..str_i), false)
			UI.unload_template("nobeat_edit_"..str_i)
			UI.unload_template("nobeat_remove_"..str_i)
		else
			gui.set_enabled(gui.get_node("nobeat_panel_"..str_i), true)
			local start_sample = MEM.event_data.table.eventsData[nobeat_track_index].events[i + (10 * nobeat_page)].startSample
			local end_sample = MEM.event_data.table.eventsData[nobeat_track_index].events[i + (10 * nobeat_page)].endSample
			if not use_samples then
				start_sample = math.floor((start_sample / MEM.sample_rate) * 100) * 0.01
				end_sample = math.floor((end_sample / MEM.sample_rate) * 100) * 0.01
			end
			gui.set_text(gui.get_node("nobeat_start_"..str_i), "Start: "..tostring(start_sample))
			gui.set_text(gui.get_node("nobeat_end_"..str_i), "End: "..tostring(end_sample))
			UI.load_template("nobeat_edit_"..str_i)
			UI.load_template("nobeat_remove_"..str_i)
		end
		if nobeat_count < 11 then
			gui.set_enabled(gui.get_node("nobeat_page_up/button_white"), false)
			gui.set_enabled(gui.get_node("nobeat_page_down/button_white"), false)
			gui.set_enabled(gui.get_node("nobeat_page"), false)
			UI.unload_template("nobeat_page_up")
			UI.unload_template("nobeat_page_down")
		else
			gui.set_enabled(gui.get_node("nobeat_page_up/button_white"), true)
			gui.set_enabled(gui.get_node("nobeat_page_down/button_white"), true)
			gui.set_enabled(gui.get_node("nobeat_page"), true)
			UI.load_template("nobeat_page_up")
			UI.load_template("nobeat_page_down")
			gui.set_text(gui.get_node("nobeat_page"), nobeat_page.."/"..nobeat_page_max + 1)
		end

		if i + (10 * event_page) > event_count then
			gui.set_enabled(gui.get_node("event_panel_"..str_i), false)
			UI.unload_template("event_edit_"..str_i)
			UI.unload_template("event_remove_"..str_i)
		else
			gui.set_enabled(gui.get_node("event_panel_"..str_i), true)
			local start_sample = MEM.event_data.table.eventsData[event_track_index].events[i + (10 * event_page)].startSample
			local end_sample = MEM.event_data.table.eventsData[event_track_index].events[i + (10 * event_page)].endSample or start_sample
			if not use_samples then
				start_sample = math.floor((start_sample / MEM.sample_rate) * 100) * 0.01
				end_sample = math.floor((end_sample / MEM.sample_rate) * 100) * 0.01
			end
			gui.set_text(gui.get_node("event_start_"..str_i), "Start: "..tostring(start_sample))
			gui.set_text(gui.get_node("event_end_"..str_i), "End: "..tostring(end_sample))
			gui.set_text(gui.get_node("event_signal_"..str_i), "Signal: "..MEM.event_data.table.eventsData[event_track_index].events[i + (10 * event_page)].payload)
			UI.load_template("event_edit_"..str_i)
			UI.load_template("event_remove_"..str_i)
		end
		if event_count < 11 then
			gui.set_enabled(gui.get_node("event_page_up/button_white"), false)
			gui.set_enabled(gui.get_node("event_page_down/button_white"), false)
			gui.set_enabled(gui.get_node("event_page"), false)
			UI.unload_template("event_page_up")
			UI.unload_template("event_page_down")
		else
			gui.set_enabled(gui.get_node("event_page_up/button_white"), true)
			gui.set_enabled(gui.get_node("event_page_down/button_white"), true)
			gui.set_enabled(gui.get_node("event_page"), true)
			UI.load_template("event_page_up")
			UI.load_template("event_page_down")
			gui.set_text(gui.get_node("event_page"), event_page.."/"..event_page_max + 1)
		end

		if i + (10 * tempo_page) > tempo_count then
			gui.set_enabled(gui.get_node("tempo_panel_"..str_i), false)
			UI.unload_template("tempo_edit_"..str_i)
			UI.unload_template("rempo_remove_"..str_i)
		else
			gui.set_enabled(gui.get_node("tempo_panel_"..str_i), true)
			local start_sample = MEM.event_data.table.tempoSections[i + (10 * tempo_page)].startSample
			local tempo_measure = MEM.event_data.table.tempoSections[i + (10 * tempo_page)].beatsPerMeasure
			local tempo_spb = MEM.event_data.table.tempoSections[i + (10 * tempo_page)].samplesPerBeat
			if not use_samples then
				start_sample = math.floor((start_sample / MEM.sample_rate) * 100) * 0.01
			end
			gui.set_text(gui.get_node("tempo_start_"..str_i), "Start: "..tostring(start_sample))
			gui.set_text(gui.get_node("tempo_meaure"..str_i), "Beats per measure: "..tostring(tempo_measure))
			gui.set_text(gui.get_node("tempo_spb"..str_i), "Samples per beat: "..tostring(tempo_spb))
			UI.load_template("tempo_edit_"..str_i)
			UI.load_template("rempo_remove_"..str_i)
		end
		if tempo_count < 11 then
			gui.set_enabled(gui.get_node("tempo_page_up/button_white"), false)
			gui.set_enabled(gui.get_node("tempo_page_down/button_white"), false)
			gui.set_enabled(gui.get_node("tempo_page"), false)
			UI.unload_template("tempo_page_up")
			UI.unload_template("tempo_page_down")
		else
			gui.set_enabled(gui.get_node("tempo_page_up/button_white"), true)
			gui.set_enabled(gui.get_node("tempo_page_down/button_white"), true)
			gui.set_enabled(gui.get_node("tempo_page"), true)
			UI.load_template("tempo_page_up")
			UI.load_template("tempo_page_down")
			gui.set_text(gui.get_node("tempo_page"), tempo_page.."/"..tempo_page_max + 1)
		end
	end
end

function EVENT.evaluate_input(field, text)
	local value
	local text_node = gui.get_node(field.."/text")
	if field == "sample_rate_field" then
		local value = tonumber(text)
		if value then
			value = math.floor(value)
			if value < 0 then
				value = 0
			end
			MEM.sample_rate = value
		end
		gui.set_text(gui.get_node("sample_rate_field/text"), MEM.sample_rate)
	end
end

local function open_edit_box_nobeat(index)
	UI.unload_template()
	UI.load_template({"edit_box_ok", "edit_box_cancel"})
	UI.load_text_field("edit_box_start", 8)
	UI.load_text_field("edit_box_end", 8)
	gui.set_enabled(gui.get_node("edit_box_start/box"), true)
	gui.set_enabled(gui.get_node("edit_box_end/box"), true)
	gui.set_enabled(gui.get_node("edit_box_signal/box"), false)
	gui.set_enabled(gui.get_node("edit_box_spg/box"), false)
	gui.set_enabled(gui.get_node("edit_box_measure/box"), false)
	gui.set_enabled(gui.get_node("lbl_event_start"), true)
	gui.set_enabled(gui.get_node("lbl_event_end"), true)
	gui.set_enabled(gui.get_node("lbl_event_signal"), false)
	gui.set_enabled(gui.get_node("lbl_event_sbp"), false)
	gui.set_enabled(gui.get_node("lbl_event_measure"), false)
	if index then
		gui.set_text(gui.get_node("edit_box_start/text"), MEM.event_data.table.eventsData[nobeat_track_index].events[index].startSample)
		gui.set_text(gui.get_node("edit_box_end/text"), MEM.event_data.table.eventsData[nobeat_track_index].events[index].endSample)
	else
		gui.set_text(gui.get_node("edit_box_start/text"), "0")
		gui.set_text(gui.get_node("edit_box_end/text"), "0")
	end
	UI.switch_cleanup = function() gui.set_enabled(gui.get_node("event_edit_box"), false) end
	gui.set_enabled(gui.get_node("event_edit_box"), true)
end

function EVENT.evaluate_button(button)
	local checkbox_text = {[true] = "X", [false] = ""}
	if button == "sample_48000" then
		MEM.sample_rate = 48000
		gui.set_text(gui.get_node("sample_rate_field/text"), MEM.sample_rate)
		EVENT.update_labels()
	elseif button == "sample_44100" then
		MEM.sample_rate = 44100
		gui.set_text(gui.get_node("sample_rate_field/text"), MEM.sample_rate)
		EVENT.update_labels()
	elseif button == "btn_time_units" then
		use_samples = not use_samples
		if use_samples then
			gui.set_text(gui.get_node("btn_time_units/text"), "Samples")
		else
			gui.set_text(gui.get_node("btn_time_units/text"), "Seconds")
		end
		EVENT.update_labels()
	elseif button == "nobeat_add" then
		open_edit_box_nobeat()
	else
		for i = 1, 10 do
			if button == "nobeat_remove_"..i then
				table.remove(MEM.event_data.table.eventsData[nobeat_track_index].events, i + (10 * nobeat_page))
				EVENT.update_labels()
				return
			elseif button == "event_remove_"..i then
				table.remove(MEM.event_data.table.eventsData[event_track_index].events, i + (10 * event_page))
				EVENT.update_labels()
				return
			elseif button == "rempo_remove_"..i then
				if #MEM.event_data.table.tempoSections > 1 then
					table.remove(MEM.event_data.table.tempoSections, i + (10 * event_page))
					EVENT.update_labels()
					return
				end
			end
		end
	end
end


return EVENT