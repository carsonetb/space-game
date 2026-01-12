class_name SpaceObject 
extends Node

@export var object: Node2D

var position: SpacePosition = SpacePosition.new(0, 0, Vector2.ZERO)

func _process(delta: float) -> void:
	position.local_position = object.global_position
