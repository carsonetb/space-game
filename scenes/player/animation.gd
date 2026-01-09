@abstract
class_name ShipAnimationHandler
extends Node2D

@export var supports_life: bool = true

var _state_machines: Array[StateMachine]

func _ready() -> void:
	_validate_and_add(
		_register_main_sm(), 
		["start_engines", "stop_engines"]
	)
	_validate_and_add(
		_register_rcs_sm(),
		[
			"start_rcs_left", "stop_rcs_left",
			"start_rcs_right", "stop_rcs_right",
		]
	)
	_validate_and_add(
		_register_hab_sm(), 
		[
			"hybernate", "dehybernate", 
			"start_accel", "stop_accel", 
			"lose_power", "gain_power", "emergency_power",
		]
	)
	if supports_life:
		_validate_and_add(
			_register_life_support_sm(),
			[]
		)

func _validate_and_add(sm: StateMachine, events: Array[String]) -> void:
	_validate_sm(sm, events)
	_state_machines.append(sm)

func _validate_sm(sm: StateMachine, events: Array[String]) -> void:
	for state_name in events:
		assert(sm.events.get(state_name))

func _process(delta: float) -> void:
	for state_machine in _state_machines:
		state_machine.process(delta)

@abstract func _register_main_sm() -> StateMachine
@abstract func _register_rcs_sm() -> StateMachine
@abstract func _register_hab_sm() -> StateMachine
@abstract func _register_life_support_sm() -> StateMachine
