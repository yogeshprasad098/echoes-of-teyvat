class_name CharacterBase
extends CharacterBody2D
## Shared base for all playable characters. Extend this for Kira, Marina, Ryne.

const PhysicsModel := preload("res://scripts/core/game_physics.gd")

# === Signals ===
signal health_changed(current: float, maximum: float)
signal died

# === Exports ===
@export var max_health: float = 100.0
@export var move_speed: float = PhysicsModel.PLAYER_RUN_SPEED_PX_PER_SEC
@export var jump_velocity: float = PhysicsModel.PLAYER_JUMP_VELOCITY_PX_PER_SEC
@export var acceleration: float = PhysicsModel.PLAYER_ACCELERATION_PX_PER_SEC2
@export var friction: float = PhysicsModel.PLAYER_FRICTION_PX_PER_SEC2
@export var coyote_time_sec: float = PhysicsModel.COYOTE_TIME_SEC
@export var jump_buffer_time_sec: float = PhysicsModel.JUMP_BUFFER_TIME_SEC

# === Public Variables ===
var current_health: float
var facing_direction: int = 1  # 1 = right, -1 = left

# === Private Variables ===
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _is_defeated: bool = false
var _coyote_time_remaining: float = 0.0
var _jump_buffer_remaining: float = 0.0

func _ready() -> void:
	collision_layer = PhysicsModel.PLAYER_LAYER
	collision_mask = PhysicsModel.WORLD_LAYER
	current_health = max_health

## Reduces health, emits [signal health_changed], and dies at zero.
func take_damage(amount: float) -> void:
	if _is_defeated:
		return
	_play_audio_sfx(&"player_hurt", -1.0)
	current_health = max(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		die()

## Emits [signal died] and disables active play until the respawn flow resets the character.
func die() -> void:
	if _is_defeated:
		return
	_is_defeated = true
	collision_layer = 0
	collision_mask = 0
	velocity = Vector2.ZERO
	died.emit()

## Restores health, position, velocity, visibility, and cooldown state for a new run.
func reset_for_run(spawn_position: Vector2) -> void:
	_is_defeated = false
	current_health = max_health
	health_changed.emit(current_health, max_health)
	global_position = spawn_position
	velocity = Vector2.ZERO
	facing_direction = 1
	collision_layer = PhysicsModel.PLAYER_LAYER
	collision_mask = PhysicsModel.WORLD_LAYER
	_reset_jump_assist()
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	var skill_timer := get_node_or_null("%SkillCooldownTimer") as Timer
	if skill_timer:
		skill_timer.stop()

func _update_jump_assist(delta: float) -> void:
	if is_on_floor():
		_coyote_time_remaining = coyote_time_sec
	else:
		_coyote_time_remaining = maxf(0.0, _coyote_time_remaining - delta)
	_jump_buffer_remaining = maxf(0.0, _jump_buffer_remaining - delta)

func _buffer_jump_input() -> void:
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_remaining = jump_buffer_time_sec

func _consume_buffered_jump() -> bool:
	if _jump_buffer_remaining <= 0.0 or _coyote_time_remaining <= 0.0:
		return false
	_jump_buffer_remaining = 0.0
	_coyote_time_remaining = 0.0
	velocity.y = jump_velocity
	return true

func _apply_platformer_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

func _apply_horizontal_input(delta: float) -> float:
	var direction: float = Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * move_speed, acceleration * delta)
		facing_direction = int(sign(direction))
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	return direction

func _start_tile_dodge() -> void:
	velocity.x = facing_direction * PhysicsModel.DODGE_SPEED_PX_PER_SEC

func _reset_jump_assist() -> void:
	_coyote_time_remaining = 0.0
	_jump_buffer_remaining = 0.0

func _request_dialogue_line(event_name: StringName, speaker_hint: String = "") -> void:
	var tree := get_tree()
	if tree == null:
		return
	var api_client := tree.root.get_node_or_null("GenshinAPIClient")
	if api_client and api_client.has_method("request_dialogue_line"):
		api_client.request_dialogue_line(event_name, speaker_hint)

func _play_audio_sfx(cue: StringName, volume_offset_db: float = 0.0, pitch_jitter: float = 0.035) -> void:
	var tree := get_tree()
	if tree == null:
		return
	var audio := tree.root.get_node_or_null("AudioManager")
	if audio and audio.has_method("play_sfx"):
		audio.play_sfx(cue, volume_offset_db, pitch_jitter)
