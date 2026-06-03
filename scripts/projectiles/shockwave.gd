class_name Shockwave
extends Area2D
## Ryne's skill projectile. Brief forward cone — applies electro aura
## to all enemies in arc and damages them once.

const PhysicsModel := preload("res://scripts/core/game_physics.gd")

const DAMAGE: float = 30.0
const RANGE: float = PhysicsModel.TILE_SIZE_PX * PhysicsModel.RYNE_SHOCKWAVE_RANGE_TILES
const LIFETIME_SEC: float = 0.30
const RYNE_ELECTRO_EFFECT := preload("res://scripts/effects/ryne_electro_effect.gd")
const REACTION_PROJECTILE_OVERLAY := preload("res://scripts/effects/reaction_projectile_overlay.gd")

@onready var lifetime_timer: Timer = %LifetimeTimer
@onready var sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var reaction_overlay: AnimatedSprite2D = %ReactionOverlay
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _facing: int = 1
var _damage: float = DAMAGE
var _hit_targets: Array[EnemyBase] = []
var _source_character: StringName = &"Ryne"

func _ready() -> void:
	collision_layer = PhysicsModel.PROJECTILE_LAYER
	collision_mask = PhysicsModel.ENEMY_LAYER
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	lifetime_timer.timeout.connect(_release)
	reset_projectile()

## Restarts lifetime and collision state when reused from the projectile pool.
func reset_projectile() -> void:
	monitoring = true
	monitorable = true
	_damage = DAMAGE
	_hit_targets.clear()
	_source_character = &"Ryne"
	_sync_facing()
	call_deferred("_damage_current_overlaps")
	if sprite:
		sprite.visible = true
		sprite.play(&"wave")
	_refresh_reaction_overlay()
	if lifetime_timer:
		lifetime_timer.start(LIFETIME_SEC)

## Sets the cone orientation after spawning.
func set_facing(dir: int) -> void:
	_facing = dir
	_sync_facing()

## Sets per-cast tuned damage from CombatBalance.
func set_damage(value: float) -> void:
	_damage = value

## Sets the playable character that owns this projectile for map-reaction feedback.
func set_source_character(character_name: StringName) -> void:
	_source_character = character_name
	_refresh_reaction_overlay()

func _sync_facing() -> void:
	var facing := 1 if _facing >= 0 else -1
	_facing = facing
	if sprite:
		sprite.flip_h = facing == -1
		sprite.position.x = RANGE * 0.5 * float(facing)
	if reaction_overlay:
		reaction_overlay.flip_h = facing == -1
		reaction_overlay.position.x = RANGE * 0.5 * float(facing)
	if collision_shape:
		var shape := ConvexPolygonShape2D.new()
		var points := PackedVector2Array()
		for point in _right_facing_points():
			points.append(Vector2(point.x * float(facing), point.y))
		shape.points = points
		collision_shape.shape = shape

static func _right_facing_points() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0.0, -16.0),
		Vector2(RANGE, -36.0),
		Vector2(RANGE, 36.0),
		Vector2(0.0, 16.0),
	])

func _on_body_entered(body: Node) -> void:
	if body is EnemyBase:
		_damage_enemy(body)

func _on_area_entered(area: Area2D) -> void:
	var enemy := _enemy_from_area(area)
	if enemy:
		_damage_enemy(enemy)

func _damage_current_overlaps() -> void:
	await get_tree().physics_frame
	if not monitoring:
		return
	for body in get_overlapping_bodies():
		if body is EnemyBase:
			_damage_enemy(body)
	for area in get_overlapping_areas():
		var enemy := _enemy_from_area(area)
		if enemy:
			_damage_enemy(enemy)

func _damage_enemy(enemy: EnemyBase) -> void:
	if _hit_targets.has(enemy):
		return
	_hit_targets.append(enemy)
	enemy.take_damage(_damage, "electro")
	_spawn_map_reaction_feedback(enemy.global_position)
	RYNE_ELECTRO_EFFECT.spawn_impact(enemy.global_position + Vector2(0, -8))

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
