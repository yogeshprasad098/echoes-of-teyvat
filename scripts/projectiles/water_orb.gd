class_name WaterOrb
extends Area2D
## Marina's normal attack — straight-line travelling projectile (8 dmg, range 280, hydro).

const SPEED: float = 320.0
const DAMAGE: float = 8.0
const MAX_RANGE: float = 280.0

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
		body.take_damage(DAMAGE, "hydro")
	queue_free()
