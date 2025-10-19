local SET = {}

SET.I_am_Klear = false
SET.debug = false

local configurable = {
	"unload_data_before_loading_zip",
	"unload_data_before_loading_folder",
	"map_preview_partition_size",
	"tween_padding_start",
	"tween_padding_end",
	"default_tween_time_in_beats",
	"default_create_folder_on_export",
	"default_import_changes_from_zip",
	"default_import_level_changes",
	"default_import_event_changes",
	"default_import_model_changes",
	"default_import_beat_changes",
	"default_new_event_sample_offset",
	"default_show_transform_edit_warning",
	"default_model_show_grid",
	"default_show_transform",
	"default_path_load_zip",
	"default_path_load_directory",
	"default_path_load_file",
	"default_path_export",
	"default_path_export_overwrite",
	"default_path_import_model_data",
	"default_path_import_models",
	"default_path_save_tween",
	"background_colour",
	"colour_active_text_field",
	"colour_highlight_material",
	"colour_highlight_dynamic",
	"colour_highlight_tween",
	"colour_model_import_selection",
	"colour_model_replace",
	"colour_unsupported_obstacle",
	"colour_current_enemy_set",
	"colour_selection_change_enemy_type",
	"colour_highlight_replace_enemy",
	"colour_current_enemy_type",
	"colour_tween_move",
	"colour_tween_rotate",
	"colour_tween_scale",
	"colour_tween_wait",
	"use_default_transform_name",
	"default_transform_name",
	"add_root_transform_if_missing",
	"root_transform_default_name",
	"allow_tweening_base_transform",
	"allow_mesh_delete",
	"confirm_transform_delete",
	"restrict_rotations_to_360",
	"tween_action_type_dialog",
	"tween_part_dialog",
	"tween_extra_add_buttons",
	"ask_before_overwriting_tween_file",
	"tween_timeline_bar_height",
	"auto_set_tween_preview_prop",
	"easing_node_scale",
	"easing_curve_thickness",
	"easing_node_colour",
	"easing_node_highlight_colour",
	"easing_curve_colour",
	"model_rotation_sensitivity",
	"model_move_sensitivity",
	"model_zoom_sensitivity",
	"default_camera_zoom",
	"default_camera_rotation",
	"default_camera_pitch",
	"default_model_z_position",
	"default_colour_set",
	"custom_colour_main",
	"custom_colour_fog",
	"custom_colour_glow",
	"custom_colour_enemy",
	"collider_colour",
	"autodetect_sample_rate",
	"default_sample_rate",
	"add_opens_edit_box",
	"hide_model_count",
	"mesh_flash_time",
	"mesh_flash_frequency",
	"mesh_flash_colour",
	"rotate_multiple_axes",
	"default_rotation_rounding",
	"confirm_file_overwrite",
	"bulk_sequence_sort",
	"ignore_char_limit",
	"degeomance_sequence",
	"degeomance_glitched_enemy",
	"degeomance_skull",
	"confirm_degeomance",
	"I_am_Klear"
}

function SET.save_config()
	if sys.exists("geomancer.cfg") then
		os.remove("geomancer.cfg")
	end
	local t = {}
	for key, val in ipairs(configurable) do
		if type(SET[val]) == "userdata" then
			t[val] = {SET[val].x, SET[val].y, SET[val].z, SET[val].w}
		else
			t[val] = SET[val]
		end
	end
	local f = io.output("geomancer.cfg")
	io.write(json.encode(t))
	io.close(f)
end


SET.scroll_speed = 150
SET.scroll_time = 0.6

SET.ignore_char_limit = false

-- defaults

SET.default_show_transform_edit_warning = true
SET.default_model_show_grid = 1
SET.default_show_transform = 1
SET.default_new_event_sample_offset = 0
SET.default_create_folder_on_export = true
SET.default_import_changes_from_zip = false
SET.default_import_level_changes = true
SET.default_import_event_changes = true
SET.default_import_model_changes = true
SET.default_import_beat_changes = true
SET.default_tween_time_in_beats = false

-- file

SET.default_path_load_directory = ""
SET.default_path_load_zip = ""
SET.default_path_load_file = ""
SET.default_path_export = ""
SET.default_path_export_overwrite = ""
SET.default_path_import_models = ""
SET.default_path_import_model_data = ""
SET.default_path_save_tween = ""
SET.confirm_file_overwrite = true
SET.import_changes_from_zip = false
SET.create_folder_on_export = true

SET.unload_data_before_loading_zip = true
SET.unload_data_before_loading_folder = true

SET.preload_models = false
SET.recalculate_normals = false

SET.import_level_changes = true
SET.import_event_changes = true
SET.import_model_changes = true
SET.import_beat_changes = true

SET.degeomance_sequence = "Dance_03"
SET.degeomance_glitched_enemy = "Normal"
SET.degeomance_skull = "Normal Turret"
SET.confirm_degeomance = true

-- events
SET.sample_rate = 48000
SET.default_sample_rate = 48000
SET.new_event_sample_offset = 0
SET.autodetect_sample_rate = true
SET.add_opens_edit_box = true

-- colours
SET.background_colour = vmath.vector4(0.15, 0.03, 0.12, 1)

SET.colour_active_text_field = vmath.vector4(0.65, 0.65, 0.65, 1)

SET.colour_highlight_material = vmath.vector4(0.8, 0.8, 0.35, 1)
SET.colour_highlight_dynamic = vmath.vector4(0.6, 0.75, 1, 1)
SET.colour_highlight_tween = vmath.vector4(0.3, 0.55, 1, 1)
SET.colour_model_import_selection = vmath.vector4(0.5, 0.5, 0.7, 1)
SET.colour_model_replace = vmath.vector4(1, 0.7, 0.7, 1)
SET.colour_unsupported_obstacle = vmath.vector4(0.8, 0.2, 0.2, 1)
SET.colour_current_enemy_set = vmath.vector4(0.2, 0.4, 0.8, 1)
SET.colour_highlight_replace_enemy = vmath.vector4(0.7, 0.1, 0.1, 1)
SET.colour_selection_change_enemy_type = vmath.vector4(0.1, 0.7, 0.1, 1)
SET.colour_current_enemy_type = vmath.vector4(0.1, 0.1, 0.1, 1)
SET.colour_signal_filter_selection = vmath.vector4(0.5, 0.5, 0.7, 1)
SET.colour_selected_transform_parent = vmath.vector4(0.5, 0.5, 0.7, 1)

SET.colour_tween_move = vmath.vector4(0, 0, 0.5, 1)
SET.colour_tween_rotate = vmath.vector4(0, 0.5, 0, 1)
SET.colour_tween_scale = vmath.vector4(0.5, 0.5, 0, 1)
SET.colour_tween_wait = vmath.vector4(0.3, 0.3, 0.3, 1)

-- art
SET.hide_model_count = false

-- model
SET.restrict_rotations_to_360 = true

-- model viewer
SET.run_speed_multiplier = 3.5

SET.model_rotation_sensitivity = 1
SET.model_move_sensitivity = 1
SET.default_camera_pitch = 25
SET.default_camera_rotation = 0

SET.default_model_z_position = 8

SET.default_colour_set = 1
SET.custom_colour_main = "471537"
SET.custom_colour_fog = "C9C3C1"
SET.custom_colour_glow = "FCC69D"
SET.custom_colour_enemy = "000000"
SET.collider_colour = vmath.vector4(0.5, 0.5, 1, 1)

SET.model_show_grid = 1

SET.show_transform = 1

SET.hide_geo = 1

SET.tween_timeline_bar_height = 20 -- make this 6+

SET.mesh_flash_time = 0.3
SET.mesh_flash_frequency = 1
SET.mesh_flash_colour = vmath.vector4(1, 0, 0, 0.4)

SET.map_preview_partition_size = 10

-- transform

SET.default_transform_name = "NewTransform"
SET.use_default_transform_name = false
SET.add_root_transform_if_missing = true
SET.root_transform_default_name = "Base"
SET.allow_tweening_base_transform = false
SET.confirm_transform_delete = true
SET.allow_mesh_delete = false
SET.show_transform_edit_warning = true

-- tween
SET.tween_action_type_dialog = true
SET.tween_part_dialog = true
SET.tween_extra_add_buttons = false
SET.ask_before_overwriting_tween_file = true
SET.auto_set_tween_preview_prop = true
SET.tween_time_in_beats = false
SET.tween_padding_start = 0.5
SET.tween_padding_end = 0.5

-- easing  													ALL IS NEW!!!
SET.easing_node_scale = 0.5
SET.easing_curve_thickness = 3
SET.easing_node_colour = vmath.vector4(0, 0, 0, 1)
SET.easing_node_highlight_colour = vmath.vector4(1, 0, 0, 1)
SET.easing_curve_colour = vmath.vector4(0, 0, 0.8, 1)

-- beat
SET.bulk_sequence_sort = false

-- enemy rotation
SET.rotate_multiple_axes = true
SET.default_rotation_rounding = 15

-- sound
SET.metronome_sound = 1

return SET