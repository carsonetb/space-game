class_name StateMachine
extends RefCounted

var _current_state: String

var state_dict: Dictionary[String, State]
var events: Dictionary[String, Callable]
var sub_state_machines: Array[StateMachine]

func _init(states: Dictionary[String, State], event_dict: Dictionary[String, Callable]) -> void:
	state_dict = states
	events = event_dict

func process(delta: float) -> void:
	if !_current_state.is_empty():
		state_dict[_current_state].process.call(delta)
	
	for sm in sub_state_machines:
		sm.process(delta)

func add_state(state_name: String, state: State) -> void:
	state_dict[state_name] = state

func change_state(to: String) -> void:
	assert(state_dict.has(to))
	var previous := state_dict[_current_state]
	var current := state_dict[to]
	previous.exit.call()
	_current_state = to
	current.enter.call()

func event(event_name: String) -> void:
	assert(events.has(event))
	events[event_name].call()

class State:
	func _init(p_enter: Callable, p_process: Callable, p_exit: Callable) -> void:
		self.enter = p_enter
		self.process = p_process
		self.exit = p_exit
		
		assert(self.enter.get_argument_count() == 0)
		assert(self.process.get_argument_count() == 1)
		assert(self.exit.get_argument_count() == 0)
	
	var enter: Callable
	var process: Callable
	var exit: Callable
