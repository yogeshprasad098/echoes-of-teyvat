class_name WaterBurst
extends Area2D
## Marina's skill projectile. Travels forward, bursts, applies hydro, and heals once.

const DIRECT_DAMAGE: float = 18.0
const HEAL_AMOUNT: float = 12.0
const SPEED: float = 320.0
const MAX_RANGE: float = 300.0
const LIFETIME_SEC: float = 2.0

var _direction: int = 1
var _start_position: Vector2 = Vector2.ZERO
var _is_bursting: bool = false

@onready var lifetime_timer: Timer = %LifetimeTimer
@onready var sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var visuals: Node2D = %Visuals

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	lifetime_timer.timeout.connect(_burst)

func reset_projectile() -> void:
	_start_position = global_position
	_is_bursting = false
	monitoring = true
	monitorable = true
	if lifetime_timer:
		lifetime_timer.start(LIFETIME_SEC)
	if sprite:
		sprite.visible = true
		sprite.flip_h = _direction == -1
		sprite.scale = Vector2(0.22, 0.22)
		sprite.play(&"fly")
	if visuals:
		visuals.visible = true
	_heal_active()

func _physics_process(delta: float) -> void:
	if _is_bursting:
		return
	position += Vector2(_direction * SPEED * delta, 0.0)
	if global_position.distance_to(_start_position) >= MAX_RANGE:
		_burst()

func set_direction(dir: int) -> void:
	_direction = dir
	if sprite:
		sprite.flip_h = dir == -1

func _heal_active() -> void:
	var switcher: Node = get_tree().root.get_node_or_null("CharacterSwitcher")
	if switcher == null or not switcher.has_method("active"):
		return
	var active: CharacterBase = switcher.active()
	if active == null:
		return
	active.current_health = min(active.max_health, active.current_health + HEAL_AMOUNT)
	active.health_changed.emit(active.current_health, active.max_health)

func _on_body_entered(body: Node) -> void:
	if body is CharacterBase:
		return
	if body is EnemyBase:
		_burst_at(body)

func _burst() -> void:
	if _is_bursting:
		return
	_is_bursting = true
	for body in get_overlapping_bodies():
		_deal_damage(body)
	await _play_burst()
	_release()

func _burst_at(body: Node) -> void:
	if _is_bursting:
		return
	_is_bursting = true
	_deal_damage(body)
	await _play_burst()
	_release()

func _deal_damage(body: Node) -> void:
	if body is EnemyBase:
		body.take_damage(DIRECT_DAMAGE, "hydro")
		HitSparks.burst_at(body.global_position)

func _play_burst() -> void:
	if sprite == null or sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(&"burst"):
		return
	sprite.flip_h = false
	sprite.scale = Vector2(0.42, 0.42)
	sprite.play(&"burst")
	await sprite.animation_finished

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
