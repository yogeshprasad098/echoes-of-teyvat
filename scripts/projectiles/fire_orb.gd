class_name FireOrb
extends Area2D
## Kira's normal attack — straight-line travelling fire projectile (12 dmg, range 280, pyro).
## Same shape as Marina's WaterOrb, different element + colors.

const PhysicsModel := preload("res://scripts/core/game_physics.gd")
const REACTION_PROJECTILE_OVERLAY := preload("res://scripts/effects/reaction_projectile_overlay.gd")

const SPEED: float = PhysicsModel.TILE_SIZE_PX * PhysicsModel.PROJECTILE_SPEED_TILES_PER_SEC
const DAMAGE: float = 12.0
const MAX_RANGE: float = PhysicsModel.TILE_SIZE_PX * PhysicsModel.SMALL_PROJECTILE_RANGE_TILES

var _direction: int = 1
var _start_position: Vector2 = Vector2.ZERO
var _damage: float = DAMAGE
var _has_hit: bool = false
var _source_character: StringName = &"Kira"

@onready var sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var reaction_overlay: AnimatedSprite2D = %ReactionOverlay

func _ready() -> void:
	collision_layer = PhysicsModel.PROJECTILE_LAYER
	collision_mask = PhysicsModel.ENEMY_LAYER
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	reset_projectile()
	if sprite:
		sprite.play(&"fly")

## Resets range tracking and collision state when reused from the projectile pool.
func reset_projectile() -> void:
	_start_position = global_position
	monitoring = true
	monitorable = true
	_damage = DAMAGE
	_has_hit = false
	_source_character = &"Kira"
	call_deferred("_hit_current_overlaps")
	if sprite:
		sprite.visible = true
		sprite.play(&"fly")
	_refresh_reaction_overlay()

func _physics_process(delta: float) -> void:
	position += Vector2(_direction * SPEED * delta, 0.0)
	if global_position.distance_to(_start_position) >= MAX_RANGE:
		_release()

## Sets horizontal travel direction after spawning.
func set_direction(dir: int) -> void:
	_direction = dir
	if sprite:
		sprite.flip_h = dir == -1
	if reaction_overlay:
		reaction_overlay.flip_h = dir == -1

## Sets per-cast combo damage.
func set_damage(value: float) -> void:
	_damage = value

## Sets the playable character that owns this projectile for map-reaction feedback.
func set_source_character(character_name: StringName) -> void:
	_source_character = character_name
	_refresh_reaction_overlay()

func _on_body_entered(body: Node) -> void:
	if body is CharacterBase:
		return
	if body is EnemyBase:
		_hit_enemy(body)

func _on_area_entered(area: Area2D) -> void:
	var enemy := _enemy_from_area(area)
	if enemy:
		_hit_enemy(enemy)

func _hit_current_overlaps() -> void:
	await get_tree().physics_frame
	if _has_hit or not monitoring:
		return
	for body in get_overlapping_bodies():
		if body is EnemyBase:
			_hit_enemy(body)
			return
	for area in get_overlapping_areas():
		var enemy := _enemy_from_area(area)
		if enemy:
			_hit_enemy(enemy)
			return

func _hit_enemy(enemy: EnemyBase) -> void:
	if _has_hit:
		return
	_has_hit = true
	enemy.take_damage(_damage, "pyro")
	_spawn_map_reaction_feedback(enemy.global_position)
	KiraVfxEffect.spawn_small_explosion(enemy.global_position + Vector2(0.0, -8.0), _direction)
	_release()

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
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
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
