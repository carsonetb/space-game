class_name MassiveObject
extends Node

@export var object: Node2D
@export var space_object: SpaceObject
@export_custom(PROPERTY_HINT_NONE, "suffix:kg") var mass: float

func _ready() -> void:
	add_to_group("massive_objects")

func get_position() -> SpacePosition:
	return space_object.position