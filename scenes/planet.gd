@tool
class_name Planet
extends Node2D

@export_custom(PROPERTY_HINT_NONE, "suffix:kg") var mass: float = 10_000_000_000.0

@export_group("Procedural")
@export var noise: FastNoiseLite
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var radius: float = 10_000.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var mountain_height: float = 8_000.0
@export var density: float = 5_000.0
@export var pow_a: float = 1.0
@export var pow_b: float = 2.0

var quality_divider: float = 16.0

var full_line: Array[Vector2]

func _process(delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var viewport_zoom: float = get_viewport().get_final_transform().x.x
	quality_divider = 2.0 / min(viewport_zoom, 2.0)
	var line: Array[Vector2] = []
	var circumference: float = radius * TAU
	var points: int = int(float(circumference) / quality_divider)
	var camera_pos := Util.get_viewport_position()
	var camera_width = get_viewport_rect().size.x / viewport_zoom
	var camera_height = get_viewport_rect().size.y / viewport_zoom
	var camera_diagonal = sqrt(camera_width**2 + camera_height**2)
	for i in range(0, points):
		var percent = (float(i) / float(points)) * (TAU)
		var direction = Vector2(cos(percent), sin(percent))
		var noise_pos = direction * density
		if camera_pos.distance_squared_to(global_position + direction * radius) > camera_diagonal ** 2:
			if i % 100 == 0:
				line.append(direction * radius)
			continue
		var height = radius + Util.scale_pow(noise.get_noise_2d(noise_pos.x, noise_pos.y) + 1, pow_a, pow_b) * mountain_height
		line.append(Vector2(cos(percent) * height, sin(percent) * height))
	
	draw_colored_polygon(line, Color.WHITE)