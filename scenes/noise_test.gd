extends Node2D

@export var noise: FastNoiseLite

func _draw() -> void:
	for i in range(0, 1000):
		var percent = (float(i) / 1000.0) * (TAU)
		var pos = Vector2(cos(percent) * 100, sin(percent) * 100)
		var height = 200 + (noise.get_noise_2d(pos.x, pos.y)) * 30
		print(height)
		draw_circle(Vector2(cos(percent) * height, sin(percent) * height), 2, Color.WHITE)
