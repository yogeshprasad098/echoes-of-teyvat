class_name FireOrb
extends Area2D
## Kira's normal attack — straight-line travelling fire projectile (12 dmg, range 280, pyro).
## Same shape as Marina's WaterOrb, different element + colors.

const SPEED: float = 340.0
const DAMAGE: float = 12.0
const MAX_RANGE: float = 140.0

var _direction: int = 1
var _start_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	_start_position = global_position
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += Vector2(_direction * SPEED * delta, 0.0)
	if global_position.distance_to(_start_position) >= MAX_RANGE:
		queue_free()

func set_direction(dir: int) -> void:
	_direction = dir

func _on_body_entered(body: Node) -> void:
	if body is CharacterBase:
		return
	if body is EnemyBase:
		body.take_damage(DAMAGE, "pyro")
	queue_free()
