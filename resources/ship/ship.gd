class_name ShipResource
extends Resource

@export var scene: PackedScene

@export_group("Measurement")
@export_custom(PROPERTY_HINT_NONE, "suffix:kg") var dry_mass: float ## Kilograms
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var length: float = 500.0 ## Meters
@export var length_width_coef: float = 1.0 / 10.0

@export_group("Main", "main_")
@export_custom(PROPERTY_HINT_NONE, "suffix:kg") var main_propellant_mass: float ## Kilograms
@export_custom(PROPERTY_HINT_NONE, "suffix:kg/m\u00b23") var main_propellant_density: float ## Kilograms / meter^3
@export_custom(PROPERTY_HINT_NONE, "suffix:Ns") var main_engine_efficiency: float ## Newton seconds
@export_custom(PROPERTY_HINT_NONE, "suffix:N") var main_engine_thrust_force: float ## Newtons

@export_group("RCS", "rcs_")
@export_custom(PROPERTY_HINT_NONE, "suffix:kg") var rcs_mass: float ## Kilograms
@export_custom(PROPERTY_HINT_NONE, "suffix:kg/m\u00b23") var rcs_monopropellant_density: float ## Kilograms / meter^3
@export_custom(PROPERTY_HINT_NONE, "suffix:Ns") var rcs_efficiency: float ## Newton seconds
@export_custom(PROPERTY_HINT_NONE, "suffix:N") var rcs_rotation_force: float ## Newtons

var radius: float:
	get:
		return length / 2.0
	set(value):
		length = value * 2.0
