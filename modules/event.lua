local EVENT = {}
local MEM = require "modules.memory"
local UI = require "modules.ui"

local use_samples = true
local nobeat_page, event_page, tempo_page = 0, 0, 0
local nobeat_page_max, event_page_max, tempo_page_max = 0, 0, 0
local nobeat_track_index, event_track_index

local edit_index, edit_box, edit_start, edit_end, edit_signal, edit_spb, edit_measure

function EVENT.setup()

end

local function samples_to_seconds(samples)
	if use_samples then
		return samples
	else
		return math.floor((samples / MEM.sample_rate) * 1000) * 0.001
	end
end

local function seconds_to_samples(seconds)
	return math.floor(seconds * MEM.sample_rate)
end

local update_edit_box = {}
function update_edit_box.nobeat()
	gui.set_text(gui.get_node("edit_box_start/text"), samples_to_seconds(edit_start))
	gui.set_text(gui.get_node("edit_box_end/text"), samples_to_seconds(edit_end))
end

function update_edit_box.event()
	gui.set_text(gui.get_node("edit_box_start/text"), samples_to_seconds(edit_start))
	gui.set_text(gui.get_node("edit_box_end/text"), samples_to_seconds(edit_end))
	gui.set_text(gui.get_node("edit_box_signal/text"), edit_signal)
end

function update_edit_box.tempo()
	gui.set_text(gui.get_node("edit_box_start/text"), samples_to_seconds(edit_start))
	gui.set_text(gui.get_node("edit_box_measure/text"), edit_measure)
	gui.set_text(gui.get_node("edit_box_spb/text"), edit_spb)
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
	nobeat_page_max = math.max(math.floor((nobeat_count - 1) / 10), 0)
	event_page_max = math.max(math.floor((event_count - 1) / 10), 0)
	tempo_page_max = math.max(math.floor((tempo_count - 1) / 10), 0)
	if nobeat_page > nobeat_page_max then nobeat_page = nobeat_page_max end
	if event_page > event_page_max then event_page = event_page_max end
	if tempo_page > tempo_page_max then tempo_page = tempo_page_max end
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
			start_sample = samples_to_seconds(start_sample)
			end_sample = samples_to_seconds(end_sample)
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
			gui.set_text(gui.get_node("nobeat_page"), (nobeat_page + 1).."/"..nobeat_page_max + 1)
		end

		if i + (10 * event_page) > event_count then
			gui.set_enabled(gui.get_node("event_panel_"..str_i), false)
			UI.unload_template("event_edit_"..str_i)
			UI.unload_template("event_remove_"..str_i)
		else
			gui.set_enabled(gui.get_node("event_panel_"..str_i), true)
			local start_sample = MEM.event_data.table.eventsData[event_track_index].events[i + (10 * event_page)].startSample
			local end_sample = MEM.event_data.table.eventsData[event_track_index].events[i + (10 * event_page)].endSample or start_sample
			start_sample = samples_to_seconds(start_sample)
			end_sample = samples_to_seconds(end_sample)
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
			gui.set_text(gui.get_node("event_page"), (event_page + 1).."/"..event_page_max + 1)
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
			start_sample = samples_to_seconds(start_sample)
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
			gui.set_text(gui.get_node("tempo_page"), (tempo_page + 1).."/"..tempo_page_max + 1)
		end
	end
	if edit_box then
		update_edit_box[edit_box]()
	end
end

function EVENT.evaluate_input(field, text)
	local value = tonumber(text)
	local text_node = gui.get_node(field.."/text")
	if field == "sample_rate_field" then
		if value then
			value = math.floor(value)
			if value < 0 then
				value = 0
			end
			MEM.sample_rate = value
		end
		gui.set_text(text_node, MEM.sample_rate)
	elseif field == "edit_box_start" then
		if value then
			if value < 0 then
				value = 0
			elseif not use_samples then
				value = seconds_to_samples(value)
			end
			if MEM.level_data.song_length and value > (MEM.level_data.song_length * MEM.sample_rate) then
				value = MEM.level_data.song_length * MEM.sample_rate
			end
		end
		edit_start = value or edit_start
		if edit_end < edit_start then
			edit_end = edit_start
		end
		update_edit_box[edit_box]()
	elseif field == "edit_box_end" then
		if value then
			if not use_samples then
				value = seconds_to_samples(value)
			end
			if value < edit_start then
				value = edit_start
			elseif MEM.level_data.song_length and value > (MEM.level_data.song_length * MEM.sample_rate) then
				value = MEM.level_data.song_length * MEM.sample_rate
			end
		end
		edit_end = value or edit_end
		update_edit_box[edit_box]()
	elseif field == "edit_box_signal" then
		edit_signal = text
	elseif field == "edit_box_spb" then
		if value and value < 1 then
			value = 1
		end
		edit_spb = value or edit_spb
	elseif field == "edit_box_measure" then
		if value then
			value = math.floor(value)
			if value < 1 then
				value = 1
			end
		end
		edit_measure = value or edit_measure
	end
end

local function close_edit_box()
	gui.set_enabled(gui.get_node("edit_box"), false)
	UI.switch_cleanup = nil
	edit_index, edit_box, edit_start, edit_end, edit_signal, edit_spb, edit_measure = nil
end

local function open_edit_box_nobeat()
	UI.unload_template()
	UI.load_template({"edit_box_ok", "edit_box_cancel", "btn_time_units", "sample_48000", "sample_44100"})
	UI.load_text_field("edit_box_start", 8)
	UI.load_text_field("edit_box_end", 8)
	gui.set_enabled(gui.get_node("edit_box"), true)
	gui.set_enabled(gui.get_node("edit_box_end/box"), true)
	gui.set_enabled(gui.get_node("lbl_event_end"), true)
	gui.set_enabled(gui.get_node("edit_box_signal/box"), false)
	gui.set_enabled(gui.get_node("lbl_signal"), false)
	gui.set_enabled(gui.get_node("edit_box_spb/box"), false)
	gui.set_enabled(gui.get_node("lbl_spb"), false)
	gui.set_enabled(gui.get_node("edit_box_measure/box"), false)
	gui.set_enabled(gui.get_node("lbl_measure"), false)
	if edit_index then
		edit_start = tonumber(MEM.event_data.table.eventsData[nobeat_track_index].events[edit_index].startSample)
		edit_end = tonumber(MEM.event_data.table.eventsData[nobeat_track_index].events[edit_index].endSample)
	else
		edit_start, edit_end = 0, 0
		edit_index = #MEM.event_data.table.eventsData[nobeat_track_index].events + 1
	end
	edit_box = "nobeat"
	update_edit_box.nobeat()
	UI.switch_cleanup = close_edit_box
end

local function open_edit_box_event()
	UI.unload_template()
	UI.load_template({"edit_box_ok", "edit_box_cancel", "btn_time_units", "sample_48000", "sample_44100"})
	UI.load_text_field("edit_box_start", 8)
	UI.load_text_field("edit_box_end", 8)
	UI.load_text_field("edit_box_signal", 20)
	gui.set_enabled(gui.get_node("edit_box"), true)
	gui.set_enabled(gui.get_node("edit_box_end/box"), true)
	gui.set_enabled(gui.get_node("lbl_event_end"), true)
	gui.set_enabled(gui.get_node("edit_box_signal/box"), true)
	gui.set_enabled(gui.get_node("lbl_signal"), true)
	gui.set_enabled(gui.get_node("edit_box_spb/box"), false)
	gui.set_enabled(gui.get_node("lbl_spb"), false)
	gui.set_enabled(gui.get_node("edit_box_measure/box"), false)
	gui.set_enabled(gui.get_node("lbl_measure"), false)
	if edit_index then
		edit_start = tonumber(MEM.event_data.table.eventsData[event_track_index].events[edit_index].startSample)
		edit_end = tonumber(MEM.event_data.table.eventsData[event_track_index].events[edit_index].endSample)
		edit_signal = MEM.event_data.table.eventsData[event_track_index].events[edit_index].payload
	else
		edit_start, edit_end = 0, 0
		edit_signal = ""
		edit_index = #MEM.event_data.table.eventsData[event_track_index].events + 1
	end
	edit_box = "event"
	update_edit_box.event()
	UI.switch_cleanup = close_edit_box
end

local function open_edit_box_tempo()
	UI.unload_template()
	UI.load_template({"edit_box_ok", "edit_box_cancel", "btn_time_units", "sample_48000", "sample_44100"})
	UI.load_text_field("edit_box_start", 8)
	UI.load_text_field("edit_box_measure", 1)
	UI.load_text_field("edit_box_spb", 9)
	gui.set_enabled(gui.get_node("edit_box"), true)
	gui.set_enabled(gui.get_node("edit_box_end/box"), false)
	gui.set_enabled(gui.get_node("lbl_event_end"), false)
	gui.set_enabled(gui.get_node("edit_box_signal/box"), false)
	gui.set_enabled(gui.get_node("lbl_signal"), false)
	gui.set_enabled(gui.get_node("edit_box_spb/box"), true)
	gui.set_enabled(gui.get_node("lbl_spb"), true)
	gui.set_enabled(gui.get_node("edit_box_measure/box"), true)
	gui.set_enabled(gui.get_node("lbl_measure"), true)
	if edit_index then
		edit_start = tonumber(MEM.event_data.table.tempoSections[edit_index].startSample)
		edit_measure = tonumber(MEM.event_data.table.tempoSections[edit_index].beatsPerMeasure)
		edit_spb = tonumber(MEM.event_data.table.tempoSections[edit_index].samplesPerBeat)
	else
		edit_start, edit_end = 0, 0
		edit_measure = tonumber(MEM.event_data.table.tempoSections[1].beatsPerMeasure)
		edit_spb = tonumber(MEM.event_data.table.tempoSections[1].samplesPerBeat)
		edit_index = #MEM.event_data.table.tempoSections + 1
	end
	edit_box = "tempo"
	update_edit_box.tempo()
	UI.switch_cleanup = close_edit_box
end

function EVENT.evaluate_button(button)
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
	elseif button == "nobeat_page_up" then
		if nobeat_page < nobeat_page_max then
			nobeat_page = nobeat_page + 1
			EVENT.update_labels()
		end
	elseif button == "event_page_up" then
		if event_page < event_page_max then
			event_page = event_page + 1
			EVENT.update_labels()
		end
	elseif button == "tempo_page_up" then
		if tempo_page < tempo_page_max then
			tempo_page = tempo_page + 1
			EVENT.update_labels()
		end
	elseif button == "nobeat_page_down" then
		if nobeat_page > 0 then
			nobeat_page = nobeat_page - 1
			EVENT.update_labels()
		end
	elseif button == "event_page_down" then
		if event_page > 0 then
			event_page = event_page - 1
			EVENT.update_labels()
		end
	elseif button == "tempo_page_down" then
		if tempo_page > 0 then
			tempo_page = tempo_page - 1
			EVENT.update_labels()
		end
	elseif button == "nobeat_add" then
		open_edit_box_nobeat()
	elseif button == "event_add" then
		open_edit_box_event()
	elseif button == "tempo_add" then
		open_edit_box_tempo()
	elseif button == "edit_box_cancel" then
		close_edit_box()
		UI.switch_tab("tab_event")
		EVENT.update_labels()
	elseif button == "edit_box_ok" then
		local function sort_f(a, b)
			return tonumber(a.startSample) < tonumber(b.startSample)
		end
		if edit_box == "nobeat" then
			local t = {startSample = edit_start, endSample = edit_end, payload = ""}
			MEM.event_data.table.eventsData[nobeat_track_index].events[edit_index] = t
			table.sort(MEM.event_data.table.eventsData[nobeat_track_index].events, sort_f)
			close_edit_box()
			UI.switch_tab("tab_event")
			EVENT.update_labels()
		elseif edit_box == "event" then
			local t = {startSample = edit_start, endSample = edit_end, payload = edit_signal}
			MEM.event_data.table.eventsData[event_track_index].events[edit_index] = t
			table.sort(MEM.event_data.table.eventsData[event_track_index].events, sort_f)
			close_edit_box()
			UI.switch_tab("tab_event")
			EVENT.update_labels()
		elseif edit_box == "tempo" then
			local t = {startSample = edit_start, samplesPerBeat = edit_spb, beatsPerMeasure = edit_measure}
			MEM.event_data.table.tempoSections[edit_index] = t
			table.sort(MEM.event_data.table.tempoSections, sort_f)
			close_edit_box()
			UI.switch_tab("tab_event")
			EVENT.update_labels()
		end
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
			elseif button == "nobeat_edit_"..i then
				edit_index = i + (10 * nobeat_page)
				open_edit_box_nobeat()
				return
			elseif button == "event_edit_"..i then
				edit_index = i + (10 * event_page)
				open_edit_box_event()
				return
			elseif button == "tempo_edit_"..i then
				edit_index = i + (10 * tempo_page)
				open_edit_box_tempo()
				return
			end
		end
	end
end


return EVENT