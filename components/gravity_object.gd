@tool
class_name PCGravityObject
extends Area2D

@export var sphere_of_influence: float ## meters
@export var msv_obj: MassiveObject
@export var object: Node2D

var body_stack: Array[PCGravityObject] = []
var mass: float:
	get:
		return msv_obj.mass

func get_gravity_force() -> float:
	if !has_patched():
		return 0.0
	var patched := get_patched()
	var distance := object.global_position.distance_to(patched.object.global_position)
	return Util.GRAVITATIONAL_CONSTANT * ((mass * patched.mass) / distance**2)

func has_patched() -> bool:
	return !body_stack.is_empty()

func get_patched() -> PCGravityObject:
	assert(has_patched())
	return body_stack.back()

func _ready() -> void:
	if !Engine.is_editor_hint():
		area_entered.connect(_on_area_entered)
		area_exited.connect(_on_area_exited)

	if get_node_or_null("Shape"):
		var existing: CollisionShape2D = get_node("Shape")
		existing.shape.radius = sphere_of_influence
		return

	for child in get_children():
		child.queue_free()
	
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = sphere_of_influence
	collision.shape = shape
	add_child(collision)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		_ready()

func _on_area_entered(area: Area2D) -> void:
	if area is PCGravityObject:
		if body_stack.is_empty():
			body_stack.append(area)
			return
		for i in range(body_stack.size() - 1, -1, -1):
			if area.sphere_of_influence < body_stack[i].sphere_of_influence:
				body_stack.insert(i, area)

func _on_area_exited(area: Area2D) -> void:
	if area is PCGravityObject:
		body_stack.remove_at(body_stack.find(area))
