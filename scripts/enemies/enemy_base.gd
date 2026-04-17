class_name EnemyBase
extends CharacterBody2D
## Shared base for all enemies. Element param future-proofs the reaction system.

# === Signals ===
signal health_changed(current: float, maximum: float)
signal died

# === Exports ===
@export var max_health: float = 50.0
@export var damage: float = 6.0
@export var move_speed: float = 80.0

# === Public Variables ===
var current_health: float

# === Private Variables ===
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _spawn_position: Vector2 = Vector2.ZERO
var _spawn_collision_layer: int = 0
var _spawn_collision_mask: int = 0

func _ready() -> void:
	current_health = max_health
	_spawn_position = global_position
	_spawn_collision_layer = collision_layer
	_spawn_collision_mask = collision_mask

# Element string reserved for reaction wiring.
func take_damage(amount: float, _element: String = "") -> void:
	current_health = max(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		die()

# Stub for elemental status application.
func apply_element(_element: String) -> void:
	pass

func die() -> void:
	died.emit()

func reset_for_run() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)
	global_position = _spawn_position
	velocity = Vector2.ZERO
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	collision_layer = _spawn_collision_layer
	collision_mask = _spawn_collision_mask

func get_spawn_position() -> Vector2:
	return _spawn_position
