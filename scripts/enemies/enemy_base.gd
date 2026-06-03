class_name EnemyBase
extends CharacterBody2D
## Shared base for all enemies. Holds an element aura with a 3-second decay timer
## and routes damage through the ElementalReactions resolver.

const PhysicsModel := preload("res://scripts/core/game_physics.gd")

# === Signals ===
signal health_changed(current: float, maximum: float)
signal died
signal reaction_triggered(reaction: int, final_damage: float, world_position: Vector2)

# === Constants ===
const AURA_DURATION_SEC: float = 3.0
const REACTION_NONE: int = 0
const REACTION_OVERLOADED: int = 3
const REACTION_ELECTRO_CHARGED: int = 4
const REACTION_POPUP_SPAWNER := preload("res://scripts/ui/reaction_popup.gd")
const REACTION_BURST_SPAWNER := preload("res://scripts/effects/reaction_burst.gd")

# === Exports ===
@export var max_health: float = 50.0
@export var damage: float = 6.0
@export var move_speed: float = 96.0
@export var snap_spawn_to_floor: bool = true
@export var spawn_floor_probe_px: float = PhysicsModel.TILE_SIZE_PX * 5.0

# === Public Variables ===
var current_health: float
# Subclasses can read this after super.take_damage() to display the post-multiplier value.
var last_damage_taken: float = 0.0

# === Private Variables ===
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _spawn_position: Vector2 = Vector2.ZERO
var _spawn_collision_layer: int = 0
var _spawn_collision_mask: int = 0
var _aura: String = ""
var _aura_timer: Timer = null

func _ready() -> void:
	collision_layer = PhysicsModel.ENEMY_LAYER
	collision_mask = PhysicsModel.WORLD_LAYER
	motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	floor_snap_length = 10.0
	current_health = max_health
	_spawn_position = global_position
	_spawn_collision_layer = collision_layer
	_spawn_collision_mask = collision_mask
	_aura_timer = Timer.new()
	_aura_timer.one_shot = true
	_aura_timer.wait_time = AURA_DURATION_SEC
	_aura_timer.timeout.connect(_on_aura_timer_timeout)
	add_child(_aura_timer)
	add_to_group("enemies")
	reaction_triggered.connect(_on_reaction_triggered)
	if snap_spawn_to_floor:
		call_deferred("_snap_spawn_to_floor")

# Apply / refresh an element aura. Sets the timer to AURA_DURATION_SEC.
## Applies an elemental aura to this enemy.
func apply_element(element: String) -> void:
	if element == "":
		return
	_aura = element
	_aura_timer.stop()
	_aura_timer.start(AURA_DURATION_SEC)

## Returns the currently stored elemental aura.
func get_aura() -> String:
	return _aura

# Damage entry point. Routes through ElementalReactions.
# Subclasses override and call super.take_damage(amount, element);
# then read self.last_damage_taken to display the post-multiplier value.
## Applies damage, resolves elemental reactions, and emits health updates.
func take_damage(amount: float, element: String = "") -> void:
	var reaction: int = REACTION_NONE
	var reactions := _elemental_reactions()
	if element != "":
		reaction = reactions.resolve(element, _aura) if reactions and reactions.has_method("resolve") else REACTION_NONE
	var mult: float = reactions.multiplier(reaction) if reactions and reactions.has_method("multiplier") else 1.0
	var final_damage: float = amount * mult
	last_damage_taken = final_damage

	if reaction != REACTION_NONE:
		_aura = ""
		_aura_timer.stop()
		reaction_triggered.emit(reaction, final_damage, global_position)
	elif element != "":
		apply_element(element)

	current_health = max(0.0, current_health - final_damage)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		die()
	else:
		_play_audio_sfx(&"enemy_hit", -2.0)

## Emits death state and disables active play for this enemy.
func die() -> void:
	died.emit()

## Restores this enemy to its spawn state for a new run.
func reset_for_run() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)
	global_position = _spawn_position
	velocity = Vector2.ZERO
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	collision_layer = _spawn_collision_layer
	collision_mask = _spawn_collision_mask
	_aura = ""
	last_damage_taken = 0.0
	if _aura_timer != null:
		_aura_timer.stop()
	if snap_spawn_to_floor:
		call_deferred("_snap_spawn_to_floor")

## Returns this enemy's original spawn position.
func get_spawn_position() -> Vector2:
	return _spawn_position

func _snap_spawn_to_floor() -> void:
	if not is_inside_tree():
		return
	var world := get_world_2d()
	if world == null:
		return
	var bottom_offset := _collision_bottom_offset()
	var ray_start := global_position - Vector2(0.0, maxf(bottom_offset + 8.0, 16.0))
	var ray_end := global_position + Vector2(0.0, bottom_offset + spawn_floor_probe_px)
	var query := PhysicsRayQueryParameters2D.create(ray_start, ray_end, PhysicsModel.WORLD_LAYER, [self])
	query.hit_from_inside = false
	var hit := world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	global_position.y = float(hit.position.y) - bottom_offset + 0.5
	_spawn_position = global_position

func _collision_bottom_offset() -> float:
	var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null or collision_shape.shape == null:
		return PhysicsModel.TILE_SIZE_PX * 0.5
	var shape := collision_shape.shape
	if shape is CapsuleShape2D:
		return collision_shape.position.y + (shape as CapsuleShape2D).height * 0.5
	if shape is RectangleShape2D:
		return collision_shape.position.y + (shape as RectangleShape2D).size.y * 0.5
	if shape is CircleShape2D:
		return collision_shape.position.y + (shape as CircleShape2D).radius
	return PhysicsModel.TILE_SIZE_PX * 0.5

func _on_aura_timer_timeout() -> void:
	_aura = ""

func _on_reaction_triggered(reaction: int, final_damage: float, world_position: Vector2) -> void:
	REACTION_POPUP_SPAWNER.spawn(world_position, reaction, final_damage)
	REACTION_BURST_SPAWNER.play_at(world_position, reaction)
	_apply_reaction_dps(reaction)
	if reaction == REACTION_OVERLOADED:
		_apply_overload_aoe(world_position, final_damage)
	elif reaction == REACTION_ELECTRO_CHARGED:
		_apply_electrocharge_chain(world_position, final_damage)

# OVERLOADED: nearby enemies take configured splash damage (no chained reactions).
func _apply_overload_aoe(world_position: Vector2, final_damage: float) -> void:
	var balance := _combat_balance()
	var radius: float = 60.0
	var ratio: float = 0.4
	if balance and balance.has_method("overload_aoe_radius_px"):
		radius = float(balance.overload_aoe_radius_px())
	if balance and balance.has_method("overload_aoe_ratio"):
		ratio = float(balance.overload_aoe_ratio())
	var splash: float = final_damage * ratio
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == self or not (enemy is EnemyBase):
			continue
		if enemy.global_position.distance_to(world_position) <= radius:
			enemy.take_damage(splash, "")

# ELECTRO_CHARGED: chains to nearest configured-range enemy with hydro/electro aura.
func _apply_electrocharge_chain(world_position: Vector2, final_damage: float) -> void:
	var balance := _combat_balance()
	var radius: float = 100.0
	var ratio: float = 0.5
	if balance and balance.has_method("electro_charged_chain_radius_px"):
		radius = float(balance.electro_charged_chain_radius_px())
	if balance and balance.has_method("electro_charged_chain_ratio"):
		ratio = float(balance.electro_charged_chain_ratio())
	var chain_dmg: float = final_damage * ratio
	var best: EnemyBase = null
	var best_dist: float = INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == self or not (enemy is EnemyBase):
			continue
		var aura: String = enemy.get_aura()
		if aura != "hydro" and aura != "electro":
			continue
		var d: float = enemy.global_position.distance_to(world_position)
		if d <= radius and d < best_dist:
			best = enemy
			best_dist = d
	if best != null:
		best.take_damage(chain_dmg, "")

func _apply_reaction_dps(reaction: int) -> void:
	var balance := _combat_balance()
	if balance == null or not balance.has_method("reaction_dps_profile_for_reaction"):
		return
	var profile: Dictionary = balance.reaction_dps_profile_for_reaction(reaction)
	var bonus_dps := float(profile.get("bonus_dps", 0.0))
	var duration_sec := float(profile.get("duration_sec", 0.0))
	if bonus_dps <= 0.0 or duration_sec <= 0.0:
		return
	_run_reaction_dps(bonus_dps, duration_sec)

func _run_reaction_dps(bonus_dps: float, duration_sec: float) -> void:
	var tick_interval := 0.5
	var tick_count := maxi(1, int(ceil(duration_sec / tick_interval)))
	var tick_damage := bonus_dps * tick_interval
	for _index in tick_count:
		await get_tree().create_timer(tick_interval).timeout
		if current_health <= 0.0 or not is_inside_tree():
			return
		current_health = max(0.0, current_health - tick_damage)
		last_damage_taken = tick_damage
		health_changed.emit(current_health, max_health)
		if current_health <= 0.0:
			die()
			return

func _elemental_reactions() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("ElementalReactions")

func _combat_balance() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("CombatBalance")

func _play_audio_sfx(cue: StringName, volume_offset_db: float = 0.0, pitch_jitter: float = 0.035) -> void:
	var tree := get_tree()
	if tree == null:
		return
	var audio := tree.root.get_node_or_null("AudioManager")
	if audio and audio.has_method("play_sfx"):
		audio.play_sfx(cue, volume_offset_db, pitch_jitter)
