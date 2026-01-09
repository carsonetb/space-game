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

var ship_dry_mass: float = 15_000_000.0 ## Kilograms
var ship_mass: float:
	get:
		return _calculate_mass()

var main_propellant_mass: float = 87_000_000.0 ## Kilograms
var main_propellant_density: float = 71.0 ## Kilograms / meter^3
var main_engine_efficiency: float = 12_000.0 ## Newton seconds
var rcs_mass: float = 300_000.0 ## Kilograms
var rcs_monopropellant_density: float = 1_020.0 ## Kilograms / meter^3
var rcs_efficiency: float = 350.0 ## Newton seconds

var ship_length: float = 500.0 ## Meters
var ship_radius: float: ## Meters
	get:
		return ship_length / 2.0
	set(value):
		ship_length = value * 2.0

var thrust_force: float = 1_000_000_000.0 ## Newtons
var rcs_rotation_force: float = 400_000.0 ## Newtons

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
			velocity += (thrust_force / ship_mass) * force_percentage * heading * delta
			main_propellant_mass -= Util.calculate_fuel_usage(thrust_force, main_engine_efficiency) * force_percentage * delta

			if main_propellant_mass <= 0:
				main_propellant_mass = 0.0

		if rcs_mass > 0.0:
			var rot_force_percentage := input.reactionary_rotation
			angular_velocity += Util.calculate_rotation_accel(rot_force_percentage, ship_length, ship_mass, rcs_rotation_force, length_width_coefficient) * delta
			rcs_mass -= Util.calculate_fuel_usage(rcs_rotation_force, rcs_efficiency) * rot_force_percentage * delta

			if rcs_mass < 0.0:
				rcs_mass = 0.0

	rotation += angular_velocity * delta

	if velocity.length() > Util.SPEED_OF_LIGHT:
		velocity = velocity.normalized() * Util.SPEED_OF_LIGHT

func _newtonian(delta: float) -> void:
	_movement(delta)

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
	return ship_dry_mass + main_propellant_mass + rcs_mass

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
