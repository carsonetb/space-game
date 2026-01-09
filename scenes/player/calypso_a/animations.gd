class_name CalypsoAAnimations
extends ShipAnimationHandler

func _register_main_sm() -> StateMachine:
	return StateMachine.new(
		{
			
		}, 
		{
			"start_engines": func(): pass,
			"stop_engines": func(): pass
		}
	)

func _register_rcs_sm() -> StateMachine:
	return StateMachine.new(
		{
			
		},
		{
			"start_rcs_left": func(): pass,
			"start_rcs_right": func(): pass,
			"stop_rcs_left": func(): pass,
			"stop_rcs_right": func(): pass
		}
	)

func _register_hab_sm() -> StateMachine:
	return StateMachine.new(
		{
			
		},
		{
			"hybernate": func(): pass,
			"dehybernate": func(): pass,
			"start_accel": func(): pass,
			"stop_accel": func(): pass,
			"lose_power": func(): pass,
			"gain_power": func(): pass,
			"emergency_power": func(): pass,
		}
	)

func _register_life_support_sm() -> StateMachine:
	return StateMachine.new(
		{
			
		},
		{
			
		}
	)
