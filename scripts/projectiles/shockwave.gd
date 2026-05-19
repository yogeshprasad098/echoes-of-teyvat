class_name Shockwave
extends Area2D
## Ryne's skill projectile. Brief forward cone — applies electro aura
## to all enemies in arc and damages them once.

const DAMAGE: float = 30.0
const RANGE: float = 96.0
const LIFETIME_SEC: float = 0.25
const RYNE_ELECTRO_EFFECT := preload("res://scripts/effects/ryne_electro_effect.gd")

@onready var lifetime_timer: Timer = %LifetimeTimer
@onready var sprite: AnimatedSprite2D = %AnimatedSprite2D

var _facing: int = 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	lifetime_timer.timeout.connect(_release)
	reset_projectile()

## Restarts lifetime and collision state when reused from the projectile pool.
func reset_projectile() -> void:
	monitoring = true
	monitorable = true
	scale.x = float(_facing)
	if sprite:
		sprite.visible = true
		sprite.play(&"wave")
	if lifetime_timer:
		lifetime_timer.start(LIFETIME_SEC)

## Sets the cone orientation after spawning.
func set_facing(dir: int) -> void:
	_facing = dir
	scale.x = float(dir)

func _on_body_entered(body: Node) -> void:
	if body is EnemyBase:
		body.take_damage(DAMAGE, "electro")
		RYNE_ELECTRO_EFFECT.spawn_impact(body.global_position + Vector2(0, -8))

func _release() -> void:
	monitoring = false
	if lifetime_timer:
		lifetime_timer.stop()
	var pool := _projectile_pool()
	if pool and pool.has_method("release_projectile"):
		pool.release_projectile(self)
	else:
		queue_free()

func _projectile_pool() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("ProjectilePool")
