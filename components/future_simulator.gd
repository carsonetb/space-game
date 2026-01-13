class_name FutureSimulator 
extends Node

@export var object: Node
@export var simulate_function: String
@export var preserve_properties: Array[String]

func get_properties() -> Dictionary[String, Variant]:
	var out: Dictionary[String, Variant] = {}
	
	for property in preserve_properties:
		out[property] = object.get(property)
	
	return out

func simulate(steps: int, detail: float = 1.0) -> Array[ObjectState]:
	var out: Array[ObjectState]
	var start_properties := get_properties()
	
	for i in range(steps):
		object.call(simulate_function, detail / 60.0)
		out.append(ObjectState.new(get_properties()))
	
	for key in start_properties.keys():
		object.set(key, start_properties[key])
	
	return out

class ObjectState:
	func _init(prop: Dictionary[String, Variant]) -> void:
		properties = prop
	
	var properties: Dictionary[String, Variant]
