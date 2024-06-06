local SET = {}

SET.scroll_speed = 150
SET.scroll_time = 0.6

-- events
SET.sample_rate = 48000
<<<<<<< HEAD
SET.default_sample_rate = 48000
SET.new_event_sample_offset = 0
SET.autodetect_sample_rate = true

-- colours
SET.background_colour = vmath.vector4(0.15, 1.03, 0.12, 1)
=======

-- colours
SET.background_colour = vmath.vector4(1, 0.2, 0.8, 1) * 0.15
>>>>>>> 74cacd0c955b57b0bc6e1a41c52ef82e057f07eb

SET.colour_highlight_material = vmath.vector4(0.8, 0.8, 0.35, 1)
SET.colour_highlight_dynamic = vmath.vector4(0.6, 0.75, 1, 1)
SET.colour_highlight_tween = vmath.vector4(0.3, 0.55, 1, 1)
SET.colour_model_import_selection = vmath.vector4(0.5, 0.5, 0.7, 1)
SET.colour_model_replace = vmath.vector4(1, 0.7, 0.7, 1)
<<<<<<< HEAD
SET.colour_unsupported_obstacle = vmath.vector4(0.8, 0.2, 0.2, 1)
SET.colour_current_enemy_set = vmath.vector4(0.2, 0.4, 0.8, 1)
=======
>>>>>>> 74cacd0c955b57b0bc6e1a41c52ef82e057f07eb

-- model
SET.restrict_rotations_to_360 = true

-- tween
SET.tween_action_type_dialog = true
SET.tween_part_dialog = true
<<<<<<< HEAD
SET.tween_extra_add_buttons = false
=======
>>>>>>> 74cacd0c955b57b0bc6e1a41c52ef82e057f07eb


SET.debug = false

return SET