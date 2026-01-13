class_name SpaceObject 
extends Node

signal sector_changed(new_x: float, new_y: float)

@export var object: Node2D

var position: SpacePosition = SpacePosition.new(0, 0, Vector2.ZERO)

func update(delta: float) -> void:
	var old_sector_x: int = position.sector_x
	var old_sector_y: int = position.sector_y

	position.local_position = object.global_position
	position.set_and_normalize(object.global_position)

	if old_sector_x != position.sector_x || old_sector_y != position.sector_y:
		sector_changed.emit(position.sector_x, position.sector_y)
