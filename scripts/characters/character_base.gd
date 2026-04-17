class_name CharacterBase
extends CharacterBody2D
## Shared base for all playable characters. Extend this for Kira, Marina, Ryne.

# === Signals ===
signal health_changed(current: float, maximum: float)
signal died

# === Exports ===
@export var max_health: float = 100.0
@export var move_speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var acceleration: float = 1500.0
@export var friction: float = 1200.0

# === Public Variables ===
var current_health: float
var facing_direction: int = 1  # 1 = right, -1 = left

# === Private Variables ===
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	current_health = max_health

# Reduce health and emit signal; trigger die() at zero.
func take_damage(amount: float) -> void:
	current_health = max(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		die()

func die() -> void:
	died.emit()
	queue_free()
