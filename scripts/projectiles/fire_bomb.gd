class_name FireBomb
extends Area2D
## Kira's Elemental Skill projectile. Travels horizontally, explodes on contact or timeout.

# === Constants ===
const PhysicsModel := preload("res://scripts/core/game_physics.gd")
const REACTION_PROJECTILE_OVERLAY := preload("res://scripts/effects/reaction_projectile_overlay.gd")

const SPEED: float = PhysicsModel.TILE_SIZE_PX * PhysicsModel.PROJECTILE_SPEED_TILES_PER_SEC
const DAMAGE: float = 50.0
const MAX_RANGE: float = PhysicsModel.TILE_SIZE_PX * PhysicsModel.KIRA_FIRE_BOMB_RANGE_TILES

# === Private Variables ===
var _direction: int = 1  # set by spawner via set_direction()
var _start_position: Vector2 = Vector2.ZERO
var _is_exploding: bool = false
var _damage: float = DAMAGE
var _damaged_targets: Array[EnemyBase] = []
var _source_character: StringName = &"Kira"

# === Onready ===
@onready var lifetime_timer: Timer = %LifetimeTimer
@onready var sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var reaction_overlay: AnimatedSprite2D = %ReactionOverlay
@onready var visuals: Node2D = %Visuals

func _ready() -> void:
	collision_layer = PhysicsModel.PROJECTILE_LAYER
	collision_mask = PhysicsModel.ENEMY_LAYER
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	lifetime_timer.timeout.connect(_explode)
	reset_projectile()
	if sprite:
		sprite.play(&"fly")

## Resets travel, collision, and lifetime state when reused from the projectile pool.
func reset_projectile() -> void:
	_start_position = global_position
	_is_exploding = false
	_damage = DAMAGE
	_damaged_targets.clear()
	_source_character = &"Kira"
	monitoring = true
	monitorable = true
	call_deferred("_explode_current_overlaps")
	if lifetime_timer:
		lifetime_timer.start()
	if sprite:
		sprite.visible = true
		sprite.play(&"fly")
	_refresh_reaction_overlay()
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
	if reaction_overlay:
		reaction_overlay.flip_h = dir == -1

## Sets per-cast tuned damage from CombatBalance.
func set_damage(value: float) -> void:
	_damage = value

## Sets the playable character that owns this projectile for map-reaction feedback.
func set_source_character(character_name: StringName) -> void:
	_source_character = character_name
	_refresh_reaction_overlay()

func _on_body_entered(body: Node) -> void:
	if body is CharacterBase:
		return
	_explode_at(body)

func _on_area_entered(area: Area2D) -> void:
	var enemy := _enemy_from_area(area)
	if enemy:
		_explode_at(enemy)

func _explode_current_overlaps() -> void:
	await get_tree().physics_frame
	if _is_exploding or not monitoring:
		return
	for body in get_overlapping_bodies():
		if body is EnemyBase:
			_explode_at(body)
			return
	for area in get_overlapping_areas():
		var enemy := _enemy_from_area(area)
		if enemy:
			_explode_at(enemy)
			return

func _explode() -> void:
	if _is_exploding:
		return
	_is_exploding = true
	# Deal damage to all enemies within overlap radius on timer expiry.
	for body in get_overlapping_bodies():
		_deal_damage(body)
	for area in get_overlapping_areas():
		_deal_damage(area)
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
	REACTION_PROJECTILE_OVERLAY.hide(reaction_overlay)
	sprite.flip_h = false
	sprite.play(&"burst")
	await sprite.animation_finished

func _deal_damage(body: Node) -> void:
	var enemy := body as EnemyBase
	if enemy == null and body is Area2D:
		enemy = _enemy_from_area(body)
	if enemy == null or _damaged_targets.has(enemy):
		return
	_damaged_targets.append(enemy)
	enemy.take_damage(_damage, "pyro")
	_spawn_map_reaction_feedback(enemy.global_position)
	KiraVfxEffect.spawn_hit_spark(enemy.global_position + Vector2(0.0, -8.0), _direction)
	# Mark enemy with burn flag for later DoT wiring.
	if enemy.has_method("apply_element"):
		enemy.apply_element("burn")

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
