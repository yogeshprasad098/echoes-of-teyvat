class_name EnemyBase
extends CharacterBody2D
## Shared base for all enemies. Element param future-proofs reaction system (Milestone 2).

# === Signals ===
signal health_changed(current: float, maximum: float)
signal died

# === Exports ===
@export var max_health: float = 30.0
@export var damage: float = 5.0
@export var move_speed: float = 80.0

# === Public Variables ===
var current_health: float

# === Private Variables ===
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	current_health = max_health

# Element string reserved for reaction wiring in Milestone 2.
func take_damage(amount: float, element: String = "") -> void:
	current_health = max(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		die()

# Stub for Milestone 2 elemental status application.
func apply_element(_element: String) -> void:
	pass

func die() -> void:
	died.emit()
	queue_free()
