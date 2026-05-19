class_name GamePhysics
extends RefCounted

const TILE_SIZE_PX: float = 32.0
const GRAVITY_PX_PER_SEC2: float = 980.0

const PLAYER_RUN_SPEED_PX_PER_SEC: float = 192.0
const PLAYER_JUMP_VELOCITY_PX_PER_SEC: float = -434.0
const PLAYER_ACCELERATION_PX_PER_SEC2: float = 1600.0
const PLAYER_FRICTION_PX_PER_SEC2: float = 1400.0
const COYOTE_TIME_SEC: float = 0.10
const JUMP_BUFFER_TIME_SEC: float = 0.10

const SAFE_JUMP_RISE_TILES: float = 2.5
const SAFE_FLAT_JUMP_GAP_TILES: float = 5.0
const DODGE_DISTANCE_TILES: float = 4.0

const KIRA_MELEE_RANGE_TILES: float = 2.0
const RYNE_MELEE_RANGE_TILES: float = 1.5
const GRUNT_ATTACK_RANGE_TILES: float = 2.0
const GRUNT_DETECTION_RANGE_TILES: float = 6.0
const SMALL_PROJECTILE_RANGE_TILES: float = 5.0
const KIRA_FIRE_BOMB_RANGE_TILES: float = 13.0
const MARINA_WATER_BURST_RANGE_TILES: float = 10.0
const RYNE_SHOCKWAVE_RANGE_TILES: float = 3.0

static func tiles_to_pixels(tiles: float) -> float:
	return tiles * TILE_SIZE_PX

static func pixels_to_tiles(pixels: float) -> float:
	return pixels / TILE_SIZE_PX

static func jump_height_px(jump_velocity: float = PLAYER_JUMP_VELOCITY_PX_PER_SEC) -> float:
	return pow(absf(jump_velocity), 2.0) / (2.0 * GRAVITY_PX_PER_SEC2)

static func same_height_airtime_sec(jump_velocity: float = PLAYER_JUMP_VELOCITY_PX_PER_SEC) -> float:
	return 2.0 * absf(jump_velocity) / GRAVITY_PX_PER_SEC2

static func run_jump_distance_px(
	run_speed: float = PLAYER_RUN_SPEED_PX_PER_SEC,
	jump_velocity: float = PLAYER_JUMP_VELOCITY_PX_PER_SEC
) -> float:
	return run_speed * same_height_airtime_sec(jump_velocity)

static func dodge_distance_px(dodge_speed: float, dodge_duration: float) -> float:
	return dodge_speed * dodge_duration
