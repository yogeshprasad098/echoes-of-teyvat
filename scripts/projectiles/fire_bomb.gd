class_name FireBomb
extends Area2D
## Kira's Elemental Skill projectile. Travels horizontally, explodes on contact or timeout.

# === Constants ===
const SPEED: float = 300.0
const DAMAGE: float = 50.0
const MAX_RANGE: float = 420.0

# === Private Variables ===
var _direction: int = 1  # set by spawner via set_direction()
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
	# Straight horizontal projectile. Despawns at MAX_RANGE.
	position += Vector2(_direction * SPEED * delta, 0.0)
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
	_apply_impact_feedback()
	queue_free()

func _explode_at(body: Node) -> void:
	_deal_damage(body)
	_apply_impact_feedback()
	queue_free()

func _deal_damage(body: Node) -> void:
	if body is EnemyBase:
		body.take_damage(DAMAGE, "pyro")
		HitSparks.burst_at(body.global_position)
		# Mark enemy with burn flag for later DoT wiring.
		if body.has_method("apply_element"):
			body.apply_element("burn")

func _apply_impact_feedback() -> void:
	ScreenShake.add_trauma(0.85)
	HitStop.freeze(0.166)  # 10 frames @ 60 fps
