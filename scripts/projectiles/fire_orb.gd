class_name FireOrb
extends Area2D
## Kira's normal attack — straight-line travelling fire projectile (12 dmg, range 280, pyro).
## Same shape as Marina's WaterOrb, different element + colors.

const SPEED: float = 340.0
const DAMAGE: float = 12.0
const MAX_RANGE: float = 140.0

var _direction: int = 1
var _start_position: Vector2 = Vector2.ZERO
var _damage: float = DAMAGE

@onready var sprite: AnimatedSprite2D = %AnimatedSprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	reset_projectile()
	if sprite:
		sprite.play(&"fly")

## Resets range tracking and collision state when reused from the projectile pool.
func reset_projectile() -> void:
	_start_position = global_position
	monitoring = true
	monitorable = true
	_damage = DAMAGE
	if sprite:
		sprite.visible = true
		sprite.play(&"fly")

func _physics_process(delta: float) -> void:
	position += Vector2(_direction * SPEED * delta, 0.0)
	if global_position.distance_to(_start_position) >= MAX_RANGE:
		_release()

## Sets horizontal travel direction after spawning.
func set_direction(dir: int) -> void:
	_direction = dir
	if sprite:
		sprite.flip_h = dir == -1

## Sets per-cast combo damage.
func set_damage(value: float) -> void:
	_damage = value

func _on_body_entered(body: Node) -> void:
	if body is CharacterBase:
		return
	if body is EnemyBase:
		body.take_damage(_damage, "pyro")
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
