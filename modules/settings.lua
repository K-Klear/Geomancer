local SET = {}

SET.scroll_speed = 150
SET.scroll_time = 0.6

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

-- events
SET.sample_rate = 48000
SET.default_sample_rate = 48000
SET.new_event_sample_offset = 0
SET.autodetect_sample_rate = true

-- colours
SET.background_colour = vmath.vector4(0.15, 1.03, 0.12, 1)

SET.colour_highlight_material = vmath.vector4(0.8, 0.8, 0.35, 1)
SET.colour_highlight_dynamic = vmath.vector4(0.6, 0.75, 1, 1)
SET.colour_highlight_tween = vmath.vector4(0.3, 0.55, 1, 1)
SET.colour_model_import_selection = vmath.vector4(0.5, 0.5, 0.7, 1)
SET.colour_model_replace = vmath.vector4(1, 0.7, 0.7, 1)
SET.colour_unsupported_obstacle = vmath.vector4(0.8, 0.2, 0.2, 1)
SET.colour_current_enemy_set = vmath.vector4(0.2, 0.4, 0.8, 1)

-- model
SET.restrict_rotations_to_360 = true

-- tween
SET.tween_action_type_dialog = true
SET.tween_part_dialog = true
SET.tween_extra_add_buttons = false
SET.ask_before_overwriting_tween_file = true


SET.debug = false

return SET