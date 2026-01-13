class_name Player
extends CharacterBody2D

enum State {
	NEWTONIAN,
	SUPERCRUISE
}

@export var input: PlayerInput
@export var ship: ShipResource
@export var msv_obj: MassiveObject
@export var gravity: PCGravityObject
@export var space_object: SpaceObject
@export var sim: FutureSimulator
@export var camera: Camera2D
@export var test_planet: Planet

var angular_velocity: float = 0.0

var peer_id: int = 0
var state := State.NEWTONIAN

var ship_mass: float:
	get:
		return _calculate_mass()

var main_propellant_mass: float ## Kilograms
var rcs_mass: float ## Kilograms

var length_width_coefficient: float = 1.0 / 10.0

var was_jump_pressed: bool = false

var trajectory: Array[Vector2]

func _ready() -> void:
	add_child(ship.scene.instantiate())
	main_propellant_mass = ship.main_propellant_mass
	rcs_mass = ship.rcs_mass
	velocity.y = Util.calculate_ideal_orbit(global_position.distance_to(test_planet.global_position), test_planet.mass)

func _process(delta: float) -> void:
	input.process_inputs()
	msv_obj.mass = ship_mass

	_zoom()
	
	match state:
		State.NEWTONIAN:
			_newtonian(delta)
		State.SUPERCRUISE:
			_supercruise(delta)
	
	var out := sim.simulate(5000, 10.0) # TODO: This is sloooow
	trajectory.clear()
	for obj_state in out:
		trajectory.append(to_local(obj_state.properties["position"]))
	queue_redraw()

func _draw() -> void:
	if !trajectory.is_empty():
		draw_polyline(trajectory, Color.WHITE, 10.0)

func _future_simulate(delta: float) -> void:
	_gravity(delta)
	position += velocity * delta

func _zoom() -> void:
	if input.zoom_in:
		camera.zoom *= 1.1
	if input.zoom_out:
		camera.zoom /= 1.1

func _movement(delta: float, inputs_enabled: bool = true) -> void:
	if inputs_enabled:
		if main_propellant_mass > 0.0:
			var force_percentage := input.thrust
			var heading := Vector2.from_angle(rotation)
			velocity += (ship.main_engine_thrust_force / ship_mass) * force_percentage * heading * delta
			main_propellant_mass -= Util.calculate_fuel_usage(ship.main_engine_thrust_force, ship.main_engine_efficiency) * force_percentage * delta

			if main_propellant_mass <= 0:
				main_propellant_mass = 0.0

		if rcs_mass > 0.0:
			var rot_force_percentage := input.reactionary_rotation
			angular_velocity += Util.calculate_rotation_accel(rot_force_percentage, ship.length, ship_mass, ship.rcs_rotation_force, length_width_coefficient) * delta
			rcs_mass -= Util.calculate_fuel_usage(ship.rcs_rotation_force, ship.rcs_efficiency) * rot_force_percentage * delta

			if rcs_mass < 0.0:
				rcs_mass = 0.0

	rotation += angular_velocity * delta

	if velocity.length() > Util.SPEED_OF_LIGHT:
		velocity = velocity.normalized() * Util.SPEED_OF_LIGHT

func _gravity(delta: float) -> void:
	for node in get_tree().get_nodes_in_group("massive_objects"):
		assert(node is MassiveObject)
		var as_massive := node as MassiveObject
		if as_massive.object == self:
			continue
		var direction := global_position.direction_to(as_massive.get_position().local_position)
		var force := gravity.get_gravity_force()
		velocity.x += (force / ship_mass) * direction.x * delta
		velocity.y += (force / ship_mass) * direction.y * delta

func _newtonian(delta: float) -> void:
	_movement(delta)
	_gravity(delta)

	move_and_slide()

	space_object.update(delta)

	if velocity.length() > 3_000.0:
		CustomLogger.info("Switching from newtonian mode to supercruise mode (reason: velocity > 3,000m/s).")
		state = State.SUPERCRUISE
	
	if input.increase_time_speed:
		Engine.time_scale += 1
	if input.decrease_time_speed && Engine.time_scale > 1.0:
		Engine.time_scale -= 1
	
	if Engine.time_scale > 4:
		Engine.time_scale = 1
		Util.time_scale_index = 1
		CustomLogger.info("Switching from newtonian mode to supercruise mode (reason: User increased time scale above 4x).")
		state = State.SUPERCRUISE

func _supercruise(delta: float) -> void:
	delta *= Util.supercruise_time_scale

	_movement(delta, false)
	_gravity(delta)
	
	position += velocity * delta

	space_object.update(delta)

	if input.increase_time_speed && Util.time_scale_index < Util.time_scale_values.size() - 1:
		Util.time_scale_index += 1
	if input.decrease_time_speed && Util.time_scale_index > 0:
		Util.time_scale_index -= 1

	if velocity.length() < 3_000.0 && Util.time_scale_index == 0:
		CustomLogger.info("Switching from supercruise mode to newtonian mode (reason: velocity < 3,000m/s AND time_scale = 1x).")
		state = State.NEWTONIAN

func _calculate_mass() -> float:
	return ship.dry_mass + main_propellant_mass + rcs_mass

func _check_jump() -> bool:
	if !was_jump_pressed && input.jump:
		was_jump_pressed = true
		return true
	
	was_jump_pressed = input.jump
	return false
