class_name PlayerInput
extends Node

var reactionary_rotation: float = 0.0
var thrust: float = 0.0
var increase_time_speed: bool
var decrease_time_speed: bool
var zoom_in: bool
var zoom_out: bool

func process_inputs() -> void:
	reactionary_rotation = Input.get_axis("move_left", "move_right")
	thrust = Input.get_action_strength("jump")
	increase_time_speed = Input.is_action_just_pressed("arrow_up")
	decrease_time_speed = Input.is_action_just_pressed("arrow_down")
	zoom_in = Input.is_action_just_released("zoom_in")
	zoom_out = Input.is_action_just_released("zoom_out")
