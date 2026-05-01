class_name EnemyBase
extends CharacterBody2D
## Shared base for all enemies. Holds an element aura with a 3-second decay timer
## and routes damage through the ElementalReactions resolver.

# === Signals ===
signal health_changed(current: float, maximum: float)
signal died
signal reaction_triggered(reaction: int, final_damage: float, world_position: Vector2)

# === Constants ===
const AURA_DURATION_SEC: float = 3.0
const REACTION_NONE: int = 0
const REACTION_OVERLOADED: int = 3
const REACTION_ELECTRO_CHARGED: int = 4

# === Exports ===
@export var max_health: float = 50.0
@export var damage: float = 6.0
@export var move_speed: float = 80.0

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

# Apply / refresh an element aura. Sets the timer to AURA_DURATION_SEC.
func apply_element(element: String) -> void:
	if element == "":
		return
	_aura = element
	_aura_timer.stop()
	_aura_timer.start(AURA_DURATION_SEC)

func get_aura() -> String:
	return _aura

# Damage entry point. Routes through ElementalReactions.
# Subclasses override and call super.take_damage(amount, element);
# then read self.last_damage_taken to display the post-multiplier value.
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

func die() -> void:
	died.emit()

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

func get_spawn_position() -> Vector2:
	return _spawn_position

func _on_aura_timer_timeout() -> void:
	_aura = ""

func _on_reaction_triggered(reaction: int, final_damage: float, world_position: Vector2) -> void:
	ReactionPopupSpawner.spawn(world_position, reaction, final_damage)
	ReactionBurstSpawner.play_at(world_position, reaction)
	if reaction == REACTION_OVERLOADED:
		_apply_overload_aoe(world_position, final_damage)
	elif reaction == REACTION_ELECTRO_CHARGED:
		_apply_electrocharge_chain(world_position, final_damage)

# OVERLOADED: enemies within 60px take final_damage * 0.4 (no chained reactions).
func _apply_overload_aoe(world_position: Vector2, final_damage: float) -> void:
	var splash: float = final_damage * 0.4
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == self or not (enemy is EnemyBase):
			continue
		if enemy.global_position.distance_to(world_position) <= 60.0:
			enemy.take_damage(splash, "")

# ELECTRO_CHARGED: chains to nearest enemy within 100px with hydro/electro aura,
# for final_damage * 0.5 (no chained reactions).
func _apply_electrocharge_chain(world_position: Vector2, final_damage: float) -> void:
	var chain_dmg: float = final_damage * 0.5
	var best: EnemyBase = null
	var best_dist: float = INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == self or not (enemy is EnemyBase):
			continue
		var aura: String = enemy.get_aura()
		if aura != "hydro" and aura != "electro":
			continue
		var d: float = enemy.global_position.distance_to(world_position)
		if d <= 100.0 and d < best_dist:
			best = enemy
			best_dist = d
	if best != null:
		best.take_damage(chain_dmg, "")

func _elemental_reactions() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("ElementalReactions")
