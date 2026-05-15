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
var _is_exploding: bool = false

# === Onready ===
@onready var lifetime_timer: Timer = %LifetimeTimer
@onready var sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var visuals: Node2D = %Visuals

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	lifetime_timer.timeout.connect(_explode)
	reset_projectile()
	if sprite:
		sprite.play(&"fly")

## Resets travel, collision, and lifetime state when reused from the projectile pool.
func reset_projectile() -> void:
	_start_position = global_position
	_is_exploding = false
	monitoring = true
	monitorable = true
	if lifetime_timer:
		lifetime_timer.start()
	if sprite:
		sprite.visible = true
		sprite.play(&"fly")
	if visuals:
		visuals.visible = true

func _physics_process(delta: float) -> void:
	if _is_exploding:
		return
	# Straight horizontal projectile. Despawns at MAX_RANGE.
	position += Vector2(_direction * SPEED * delta, 0.0)
	if global_position.distance_to(_start_position) >= MAX_RANGE:
		_explode()

## Sets horizontal travel direction after spawning.
func set_direction(dir: int) -> void:
	_direction = dir
	if sprite:
		sprite.flip_h = dir == -1

func _on_body_entered(body: Node) -> void:
	if body is CharacterBase:
		return
	_explode_at(body)

func _explode() -> void:
	if _is_exploding:
		return
	_is_exploding = true
	# Deal damage to all enemies within overlap radius on timer expiry.
	for body in get_overlapping_bodies():
		_deal_damage(body)
	_apply_impact_feedback()
	await _play_burst()
	_release()

func _explode_at(body: Node) -> void:
	if _is_exploding:
		return
	_is_exploding = true
	_deal_damage(body)
	_apply_impact_feedback()
	await _play_burst()
	_release()

func _play_burst() -> void:
	if sprite == null or sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(&"burst"):
		return
	sprite.flip_h = false
	sprite.play(&"burst")
	await sprite.animation_finished

func _deal_damage(body: Node) -> void:
	if body is EnemyBase:
		body.take_damage(DAMAGE, "pyro")
		KiraVfxEffect.spawn_hit_spark(body.global_position + Vector2(0.0, -8.0), _direction)
		# Mark enemy with burn flag for later DoT wiring.
		if body.has_method("apply_element"):
			body.apply_element("burn")

func _apply_impact_feedback() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var screen_shake := tree.root.get_node_or_null("ScreenShake")
	var hit_stop := tree.root.get_node_or_null("HitStop")
	if screen_shake and screen_shake.has_method("add_trauma"):
		screen_shake.add_trauma(0.85)
	if hit_stop and hit_stop.has_method("freeze"):
		hit_stop.freeze(0.166)  # 10 frames @ 60 fps

func _release() -> void:
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
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
