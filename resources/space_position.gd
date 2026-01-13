class_name SpacePosition
extends Serializable

const SECTOR_SIZE: float = 100_000
const SECTOR_RADIUS: float = SECTOR_SIZE / 2.0

# 1 sector = 10,000m
@export var sector_x: int
@export var sector_y: int 
@export var local_position: Vector2

func _init(p_sector_x: int, p_sector_y: int, p_local_position: Vector2) -> void:
	sector_x = p_sector_x
	sector_y = p_sector_y
	local_position = p_local_position

func _validate_comparable(other: SpacePosition) -> bool:
	if other.sector_x != sector_x || other.sector_y != sector_y:
		Util.generic_logger.error("[SpacePosition] Attempt to compare SpacePositions in different sectors.")
		return false
	
	return true

static func from_dict(dict: Dictionary[String, Variant]) -> SpacePosition:
	return SpacePosition.new(dict["sector_x"], dict["sector_y"], dict["local_position"])

func deserialize(dict: Dictionary[String, Variant]) -> void:
	sector_x = dict["sector_x"]
	sector_y = dict["sector_y"]
	local_position = dict["local_position"]

func serialize() -> Dictionary[String, Variant]:
	return {
		"sector_x": sector_x,
		"sector_y": sector_y,
		"local_position": local_position
	}

## Not a typical normalize, checks if the vector is outside of the maximum sector bounds 
## and if so, moves it back.
func normalize():
	if local_position.x >= SECTOR_RADIUS:
		var shifts = floor((local_position.x + SECTOR_RADIUS) / SECTOR_SIZE)
		sector_x += int(shifts)
		local_position.x -= shifts * SECTOR_SIZE
	
	elif local_position.x < -SECTOR_RADIUS:
		var shifts = floor((abs(local_position.x) + SECTOR_RADIUS) / SECTOR_SIZE)
		sector_x -= int(shifts)
		local_position.x += shifts * SECTOR_SIZE
	
	elif local_position.y >= SECTOR_RADIUS:
		var shifts = floor((local_position.y + SECTOR_RADIUS) / SECTOR_SIZE)
		sector_y += int(shifts)
		local_position.y -= shifts * SECTOR_SIZE
	
	elif local_position.y < -SECTOR_RADIUS:
		var shifts = floor((abs(local_position.y) + SECTOR_RADIUS) / SECTOR_SIZE)
		sector_y -= int(shifts)
		local_position.y += shifts * SECTOR_SIZE

func set_and_normalize(new_local: Vector2) -> void:
	local_position = new_local
	normalize()

func intersector_distance(other: SpacePosition) -> float:
	return sqrt( 
		( ( other.sector_x * SECTOR_SIZE + other.local_position.x ) - ( sector_x * SECTOR_SIZE + local_position.x ) )**2 + 
		( ( other.sector_y * SECTOR_SIZE + other.local_position.y ) - ( sector_y * SECTOR_SIZE + local_position.y ) )**2
	)

## Get distance from self to other.
func intrasector_distance(other: SpacePosition) -> float:
	if !_validate_comparable(other):
		return SECTOR_RADIUS # Rough estimate.
	
	return local_position.distance_to(other.local_position)

## Get the direction vector from self to other.
func intrasector_offset(other: SpacePosition) -> Vector2:
	if !_validate_comparable(other):
		return Vector2.ZERO
	
	return other.local_position - local_position
