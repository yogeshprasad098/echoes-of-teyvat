class_name WaterOrb
extends Area2D
## Marina's normal attack — straight-line travelling projectile (8 dmg, range 280, hydro).

const SPEED: float = 320.0
const DAMAGE: float = 8.0
const MAX_RANGE: float = 140.0

var _direction: int = 1
var _start_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	reset_projectile()

## Resets range tracking and collision state when reused from the projectile pool.
func reset_projectile() -> void:
	_start_position = global_position
	monitoring = true
	monitorable = true

func _physics_process(delta: float) -> void:
	position += Vector2(_direction * SPEED * delta, 0.0)
	if global_position.distance_to(_start_position) >= MAX_RANGE:
		_release()

## Sets horizontal travel direction after spawning.
func set_direction(dir: int) -> void:
	_direction = dir

func _on_body_entered(body: Node) -> void:
	if body is CharacterBase:
		return
	if body is EnemyBase:
		body.take_damage(DAMAGE, "hydro")
	_release()

func _release() -> void:
	monitoring = false
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
