local SET = {}

SET.scroll_speed = 150
SET.scroll_time = 0.6

SET.ignore_char_limit = false

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

SET.import_level_changes = true
SET.import_event_changes = true
SET.import_model_changes = true
SET.import_beat_changes = true

SET.degeomance_sequence = "Dance_03"
SET.degeomance_glitched_enemy = "Normal"
SET.degeomance_skull = "Normal Turret"

-- events
SET.sample_rate = 48000
SET.default_sample_rate = 48000
SET.new_event_sample_offset = 0
SET.autodetect_sample_rate = true
SET.add_opens_edit_box = true

-- colours
SET.background_colour = vmath.vector4(0.15, 1.03, 0.12, 1)

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

SET.colour_tween_move = vmath.vector4(0, 0, 0.5, 1)
SET.colour_tween_rotate = vmath.vector4(0, 0.5, 0, 1)
SET.colour_tween_scale = vmath.vector4(0.5, 0.5, 0, 1)
SET.colour_tween_wait = vmath.vector4(0.3, 0.3, 0.3, 1)

-- model
SET.restrict_rotations_to_360 = true

-- model viewer
SET.model_rotation_sensitivity = 0.5
SET.model_move_sensitivity = 0.01
SET.model_zoom_sensitivity = 1
SET.default_camera_zoom = 8
SET.default_camera_pitch = 25
SET.default_camera_rotation = 0

SET.default_model_z_position = 8

SET.default_colour_set = 1
SET.custom_colour_main = "471537"
SET.custom_colour_fog = "C9C3C1"
SET.custom_colour_glow = "FCC69D"
SET.custom_colour_enemy = "000000"

SET.model_show_grid = 1
SET.model_grid_dots = false

SET.default_rotation = 0
SET.default_pitch = 25

SET.mesh_flash_time = 0.3
SET.mesh_flash_frequency = 1
SET.mesh_flash_colour = vmath.vector4(1, 0, 0, 0.4)

-- tween
SET.tween_action_type_dialog = true
SET.tween_part_dialog = true
SET.tween_extra_add_buttons = false
SET.ask_before_overwriting_tween_file = true

-- easing  													ALL IS NEW!!!
SET.easing_node_scale = 0.5
SET.easing_curve_thickness = 3
SET.easing_node_colour = vmath.vector4(0, 0, 0, 1)
SET.easing_node_highlight_colour = vmath.vector4(1, 0, 0, 1)
SET.easing_curve_colour = vmath.vector4(0, 0, 1, 1)

-- beat
SET.bulk_sequence_sort = false

SET.debug = false

return SET