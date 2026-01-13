@tool
extends Node

const SPEED_OF_LIGHT: float = 299_792_458.0 ## m/s
const GRAVITY: float = 9.81 ## m/s^2
const GRAVITATIONAL_CONSTANT: float = 6.674e-11 ## N m^2/kg^2

## Emitted when the drawing origin (of the player) is modified. 
## Ignore the local_position property.
signal sector_origin_modified(new_origin: SpacePosition)

## Registry of all ingame objects, that might be moved suddenly.
var space_object_registry: Array[Node2D] = []

## The sector that the origin of the world currently represents.
## Setting this value emits Util.sector_origin_modified with the 
## new value.
var sector_origin: SpacePosition = SpacePosition.new(0, 0, Vector2.ZERO):
	set(value):
		sector_origin_modified.emit(value)

## True if the player is currently using 'supercruise' physics.
## This means that all other bodies should be prepared to use
## supercruise mode.
var in_supercruise: bool = false

## This value regulates the time scale in supercruise, because 
## Godot's Engine.time_scale > ~100 can start to be very finicky,
## and we need to have time scale values in the hundreds of 
## thousands.
var supercruise_time_scale: float:
	get:
		return time_scale_values[time_scale_index]

## Index for Util.time_scale_values.
var time_scale_index: int = 0:
	set(value):
		time_scale_index = value
		CustomLogger.info("Supercruise time scale changed to %f" % supercruise_time_scale)

## Values used by the supercruise time scale.
const time_scale_values: Array[float] = [1.0, 10.0, 50.0, 100.0, 500.0, 1_000.0, 10_000.0, 100_000.0]

## Calculate the acceleration based on a force. [br]
## body_length: meters [br]
## body_mass: kilograms [br]
## max_rot_force: newtons [br]
## returns: radians / second^2 [br]
func calculate_rotation_accel(rotation_input: float, body_length: float, body_mass: float, max_rot_force: float, length_widt_coeff: float) -> float:
	var rotation_direction: int = sign(rotation_input)
	var rotation_power: float = abs(rotation_input)
	var rotation_torque := (max_rot_force * (body_length / 2.0)) * rotation_power
	var moment_of_inertia := length_widt_coeff * body_mass * body_length**2
	return (rotation_torque / moment_of_inertia) * rotation_direction

## Calculate fuel usage based on max thruster force. [br]
## thruster_force: newtons
## efficiency: specific impulse (idk just use 300)
## returns: kilograms / second
func calculate_fuel_usage(thruster_force: float, efficiency: float) -> float:
	return thruster_force / (efficiency * GRAVITY)

func scale_pow(x: float, a: float, b: float) -> float:
	return a * (x / a) ** b

func get_viewport_position() -> Vector2:
	if Engine.is_editor_hint():
		var editor_viewport_2d = EditorInterface.get_editor_viewport_2d()
		var transform: Transform2D = editor_viewport_2d.global_canvas_transform
		var viewport_center_screen_pos: Vector2 = editor_viewport_2d.size / 2.0
		return transform.affine_inverse() * viewport_center_screen_pos
	else:
		return get_viewport().get_camera_2d().global_position

## Takes m1 (kg), m2 (kg), and distance (m) and returns 
## force (N)
func calculate_gravity(m1: float, m2: float, distance: float) -> float:
	return GRAVITATIONAL_CONSTANT * ((m1 * m2) / distance ** 2)

func calculate_gravity_positions(m1: float, m2:float, p1: Vector2, p2: Vector2) -> float:
	return calculate_gravity(m1, m2, p1.distance_to(p2))

## Calculate a velocity tangential to the planet to have 
## a circular orbit.
func calculate_ideal_orbit(dist: float, other_mass: float) -> float:
	return sqrt((GRAVITATIONAL_CONSTANT * other_mass) / dist)

func get_meters_per_pixel(camera: Camera2D) -> float:
	return 1.0 / camera.zoom.length()

func get_gravitational_param(m1: float, m2: float) -> float:
	return GRAVITATIONAL_CONSTANT * m1 * m2

func orbital_prediction(craft_pos: Vector2, planet_pos: Vector2, craft_vel: Vector2, planet_vel: Vector2, gravitational_param: float, angle: float) -> Vector2:
	var r := planet_pos - craft_pos
	var v := craft_vel - planet_vel
	var distance := r.length()
	var orbital_energy := v.dot(v) / 2.0 - gravitational_param / distance
	var a := -(gravitational_param / (2.0 * orbital_energy))
