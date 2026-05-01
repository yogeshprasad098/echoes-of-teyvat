class_name Shockwave
extends Area2D
## Ryne's skill projectile. Brief forward cone — applies electro aura
## to all enemies in arc and damages them once.

const DAMAGE: float = 30.0
const LIFETIME_SEC: float = 0.15

@onready var lifetime_timer: Timer = $LifetimeTimer

var _facing: int = 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	lifetime_timer.timeout.connect(queue_free)
	lifetime_timer.start(LIFETIME_SEC)

func set_facing(dir: int) -> void:
	_facing = dir
	scale.x = float(dir)

func _on_body_entered(body: Node) -> void:
	if body is EnemyBase:
		body.take_damage(DAMAGE, "electro")
