class_name FireBomb
extends Area2D
## Kira's Elemental Skill projectile. Travels horizontally, explodes on contact or timeout.

# === Constants ===
const SPEED: float = 300.0
const DAMAGE: float = 50.0
const MAX_RANGE: float = 420.0

# === Private Variables ===
var _direction: int = 1  # set by spawner via set_direction()
var _gravity_velocity: float = 0.0
var _start_position: Vector2 = Vector2.ZERO

# === Onready ===
@onready var lifetime_timer: Timer = $LifetimeTimer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var visuals: Node2D = $Visuals

func _ready() -> void:
	_start_position = global_position
	body_entered.connect(_on_body_entered)
	lifetime_timer.timeout.connect(_explode)
	lifetime_timer.start()
	if sprite:
		sprite.play(&"fly")

func _physics_process(delta: float) -> void:
	# Arc trajectory: gravity pulls bomb downward over time.
	_gravity_velocity += ProjectSettings.get_setting("physics/2d/default_gravity") * delta * 0.4
	position += Vector2(_direction * SPEED * delta, _gravity_velocity * delta)
	if global_position.distance_to(_start_position) >= MAX_RANGE:
		_explode()

# Called by Kira after instantiation to set travel direction.
func set_direction(dir: int) -> void:
	_direction = dir
	if sprite:
		sprite.flip_h = dir == -1

func _on_body_entered(body: Node) -> void:
	if body is CharacterBase:
		return
	_explode_at(body)

func _explode() -> void:
	# Deal damage to all enemies within overlap radius on timer expiry.
	for body in get_overlapping_bodies():
		_deal_damage(body)
	queue_free()

func _explode_at(body: Node) -> void:
	_deal_damage(body)
	queue_free()

func _deal_damage(body: Node) -> void:
	if body is EnemyBase:
		body.take_damage(DAMAGE, "pyro")
		# Mark enemy with burn flag for later DoT wiring.
		if body.has_method("apply_element"):
			body.apply_element("burn")
