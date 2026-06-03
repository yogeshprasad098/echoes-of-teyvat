class_name WaterBurst
extends Area2D
## Marina's skill projectile. Travels forward, bursts, applies hydro, and heals once.

const PhysicsModel := preload("res://scripts/core/game_physics.gd")
const REACTION_PROJECTILE_OVERLAY := preload("res://scripts/effects/reaction_projectile_overlay.gd")

const DIRECT_DAMAGE: float = 18.0
const HEAL_AMOUNT: float = 12.0
const SPEED: float = PhysicsModel.TILE_SIZE_PX * PhysicsModel.PROJECTILE_SPEED_TILES_PER_SEC
const MAX_RANGE: float = PhysicsModel.TILE_SIZE_PX * PhysicsModel.MARINA_WATER_BURST_RANGE_TILES
const LIFETIME_SEC: float = 2.0

var _direction: int = 1
var _start_position: Vector2 = Vector2.ZERO
var _is_bursting: bool = false
var _damage: float = DIRECT_DAMAGE
var _damaged_targets: Array[EnemyBase] = []
var _source_character: StringName = &"Marina"

@onready var lifetime_timer: Timer = %LifetimeTimer
@onready var sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var reaction_overlay: AnimatedSprite2D = %ReactionOverlay

func _ready() -> void:
	collision_layer = PhysicsModel.PROJECTILE_LAYER
	collision_mask = PhysicsModel.ENEMY_LAYER
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	lifetime_timer.timeout.connect(_burst)

func reset_projectile() -> void:
	_start_position = global_position
	_is_bursting = false
	_damage = DIRECT_DAMAGE
	_damaged_targets.clear()
	_source_character = &"Marina"
	monitoring = true
	monitorable = true
	call_deferred("_burst_current_overlaps")
	if lifetime_timer:
		lifetime_timer.start(LIFETIME_SEC)
	if sprite:
		sprite.visible = true
		sprite.flip_h = _direction == -1
		sprite.scale = Vector2(0.62, 0.62)
		sprite.play(&"fly")
	_refresh_reaction_overlay()
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
	if reaction_overlay:
		reaction_overlay.flip_h = dir == -1

## Sets per-cast tuned damage from CombatBalance.
func set_damage(value: float) -> void:
	_damage = value

## Sets the playable character that owns this projectile for map-reaction feedback.
func set_source_character(character_name: StringName) -> void:
	_source_character = character_name
	_refresh_reaction_overlay()

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

func _on_area_entered(area: Area2D) -> void:
	var enemy := _enemy_from_area(area)
	if enemy:
		_burst_at(enemy)

func _burst_current_overlaps() -> void:
	await get_tree().physics_frame
	if _is_bursting or not monitoring:
		return
	for body in get_overlapping_bodies():
		if body is EnemyBase:
			_burst_at(body)
			return
	for area in get_overlapping_areas():
		var enemy := _enemy_from_area(area)
		if enemy:
			_burst_at(enemy)
			return

func _burst() -> void:
	if _is_bursting:
		return
	_is_bursting = true
	for body in get_overlapping_bodies():
		_deal_damage(body)
	for area in get_overlapping_areas():
		_deal_damage(area)
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
	var enemy := body as EnemyBase
	if enemy == null and body is Area2D:
		enemy = _enemy_from_area(body)
	if enemy == null or _damaged_targets.has(enemy):
		return
	_damaged_targets.append(enemy)
	enemy.take_damage(_damage, "hydro")
	_spawn_map_reaction_feedback(enemy.global_position)
	MarinaVfxEffect.spawn_water_splash_impact(enemy.global_position + Vector2(0.0, -8.0), _direction)
	HitSparks.burst_at(enemy.global_position)

func _enemy_from_area(area: Area2D) -> EnemyBase:
	var parent := area.get_parent()
	if parent is EnemyBase:
		return parent
	if area.owner is EnemyBase:
		return area.owner
	return null

func _spawn_map_reaction_feedback(world_position: Vector2) -> void:
	var tree := get_tree()
	if tree == null:
		return
	var balance := tree.root.get_node_or_null("CombatBalance")
	if balance and balance.has_method("spawn_character_reaction_feedback"):
		balance.spawn_character_reaction_feedback(_source_character, world_position)

func _refresh_reaction_overlay() -> void:
	REACTION_PROJECTILE_OVERLAY.apply_to(reaction_overlay, get_tree(), _source_character)

func _play_burst() -> void:
	if sprite == null or sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(&"burst"):
		return
	REACTION_PROJECTILE_OVERLAY.hide(reaction_overlay)
	sprite.flip_h = false
	sprite.scale = Vector2(0.62, 0.62)
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
