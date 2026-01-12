class_name Player
extends CharacterBody2D

enum State {
	NEWTONIAN,
	SUPERCRUISE
}

@export var input: PlayerInput
@export var ship: ShipResource

var angular_velocity: float = 0.0

var peer_id: int = 0
var space_pos: SpacePosition = SpacePosition.new(0, 0, Vector2.ZERO)
var state := State.NEWTONIAN

var ship_mass: float:
	get:
		return _calculate_mass()

var main_propellant_mass: float ## Kilograms
var rcs_mass: float ## Kilograms

var length_width_coefficient: float = 1.0 / 10.0

var was_jump_pressed: bool = false

func _ready() -> void:
	add_child(ship.scene.instantiate())
	main_propellant_mass = ship.main_propellant_mass
	rcs_mass = ship.rcs_mass

func _process(delta: float) -> void:
	input.process_inputs()
	
	match state:
		State.NEWTONIAN:
			_newtonian(delta)
			return
		State.SUPERCRUISE:
			_supercruise(delta)
			return

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
		var direction := global_position.direction_to(as_massive.get_position().local_position)
		var force := Util.calculate_gravity_positions(ship_mass, as_massive.mass, global_position, as_massive.get_position().local_position)
		print(ship_mass, " ", as_massive.mass, " ", global_position.distance_to(as_massive.get_position().local_position))
		velocity += (force / ship_mass) * direction * delta

func _newtonian(delta: float) -> void:
	_movement(delta)
	_gravity(delta)

	move_and_slide()

	_update_sector()

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
	position += velocity * delta

	_update_sector()

	if input.increase_time_speed && Util.time_scale_index < Util.time_scale_values.size() - 1:
		Util.time_scale_index += 1
	if input.decrease_time_speed && Util.time_scale_index > 0:
		Util.time_scale_index -= 1

	if velocity.length() < 3_000.0 && Util.time_scale_index == 0:
		CustomLogger.info("Switching from supercruise mode to newtonian mode (reason: velocity < 3,000m/s AND time_scale = 1x).")
		state = State.NEWTONIAN

func _calculate_mass() -> float:
	return ship.dry_mass + main_propellant_mass + rcs_mass

func _update_sector() -> void:
	var old_sector_x := space_pos.sector_x
	var old_sector_y := space_pos.sector_y
	space_pos.set_and_normalize(position)

	if old_sector_x != space_pos.sector_x || old_sector_y != space_pos.sector_y:
		Util.sector_origin = space_pos

func _check_jump() -> bool:
	if !was_jump_pressed && input.jump:
		was_jump_pressed = true
		return true
	
	was_jump_pressed = input.jump
	return false
