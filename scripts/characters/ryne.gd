class_name Ryne
extends CharacterBase
## Electro striker. 4-hit gauntlet (6/7/8/12 dmg, range 36),
## Shockwave skill (30 dmg cone, range 96).

const ATTACK_DAMAGE: Array[float] = [6.0, 7.0, 8.0, 12.0]
const ATTACK_RANGE: float = 48.0
const ATTACK_STEP_COOLDOWN: float = 0.18
const COMBO_RESET_SEC: float = 0.6
const SKILL_COOLDOWN_SEC: float = 8.0
const DODGE_SPEED: float = PhysicsModel.DODGE_SPEED_PX_PER_SEC
const DODGE_DURATION_SEC: float = PhysicsModel.DODGE_DURATION_SEC
const SHOCKWAVE_SCENE: PackedScene = preload("res://scenes/projectiles/shockwave.tscn")
const RYNE_ELECTRO_EFFECT := preload("res://scripts/effects/ryne_electro_effect.gd")
const SHOCKWAVE_OFFSET_X: float = 24.0
const SPRITE_BASE_SCALE: Vector2 = Vector2(0.72, 0.72)
const SPRITE_BASE_POSITION: Vector2 = Vector2(0.0, -23.0)

var _combo_step: int = 0
var _hit_targets: Array[EnemyBase] = []
var _is_dodging: bool = false

@onready var sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var hitbox: Area2D = %HitboxArea2D
@onready var hitbox_shape: CollisionShape2D = %HitboxCollisionShape
@onready var attack_timer: Timer = %AttackTimer
@onready var combo_timer: Timer = %ComboTimer
@onready var skill_timer: Timer = %SkillCooldownTimer
@onready var dodge_timer: Timer = %DodgeTimer

func _ready() -> void:
	super._ready()
	_reset_sprite_visual_transform()
	hitbox_shape.disabled = true
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	attack_timer.timeout.connect(_close_attack_window)
	combo_timer.timeout.connect(_reset_combo)
	dodge_timer.timeout.connect(_on_dodge_timer_timeout)
	sprite.animation_finished.connect(_on_sprite_animation_finished)
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(&"idle"):
		sprite.play(&"idle")

func _physics_process(delta: float) -> void:
	_update_jump_assist(delta)
	_buffer_jump_input()
	_apply_platformer_gravity(delta)
	if _is_dodging:
		move_and_slide()
		return
	var direction := _apply_horizontal_input(delta)
	if direction != 0.0:
		if sprite:
			sprite.flip_h = facing_direction == -1
	_consume_buffered_jump()
	if Input.is_action_just_pressed("attack"):
		_swing_combo()
	if Input.is_action_just_pressed("skill") and skill_timer.is_stopped():
		_cast_shockwave()
	if Input.is_action_just_pressed("dodge"):
		_start_dodge()
	move_and_slide()
	_update_idle_run_anim()

func _update_idle_run_anim() -> void:
	if sprite == null:
		return
	if sprite.animation in [&"attack_1", &"attack_2", &"attack_3", &"skill", &"dodge", &"hurt", &"death"] and sprite.is_playing():
		return
	var moving: bool = absf(velocity.x) > 1.0
	var anim: StringName = &"run" if moving and is_on_floor() else &"idle"
	if not is_on_floor():
		anim = &"jump"
	if sprite.animation != anim and sprite.sprite_frames and sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)

func _swing_combo() -> void:
	_hit_targets.clear()
	hitbox.position = Vector2(facing_direction * (ATTACK_RANGE * 0.5), -4.0)
	hitbox_shape.disabled = false
	attack_timer.start(ATTACK_STEP_COOLDOWN)
	combo_timer.start(COMBO_RESET_SEC)
	_play_combo_anim()
	_play_audio_sfx(&"electro_strike", -3.0 + float(_combo_step) * 0.5)
	RYNE_ELECTRO_EFFECT.spawn_punch_impact_spark(global_position + Vector2(facing_direction * 26.0, -16.0), facing_direction, 0.62)
	for body in hitbox.get_overlapping_bodies():
		_damage(body)

func _on_hitbox_body_entered(body: Node) -> void:
	_damage(body)

func _damage(body: Node) -> void:
	if body == self or hitbox_shape.disabled:
		return
	if body is EnemyBase and not _hit_targets.has(body):
		_hit_targets.append(body)
		var dmg: float = ATTACK_DAMAGE[_combo_step]
		body.take_damage(dmg, "electro")
		if _combo_step == 3:
			RYNE_ELECTRO_EFFECT.spawn_impact(body.global_position + Vector2(0, -8))
		_pulse_feel(_combo_step == 3)

func _pulse_feel(is_finisher: bool) -> void:
	# Indirect autoload access for headless test context safety.
	var ml := get_tree()
	if ml == null:
		return
	var ss := ml.root.get_node_or_null("ScreenShake")
	var hs := ml.root.get_node_or_null("HitStop")
	if ss and ss.has_method("add_trauma"):
		ss.add_trauma(0.45 if is_finisher else 0.3)
	if hs and hs.has_method("freeze"):
		hs.freeze(0.12 if is_finisher else 0.05)

func _close_attack_window() -> void:
	hitbox_shape.disabled = true
	_combo_step = mini(_combo_step + 1, 3)

func _reset_combo() -> void:
	_combo_step = 0
	_hit_targets.clear()
	hitbox_shape.disabled = true

func _cast_shockwave() -> void:
	_request_dialogue_line(&"skill_Ryne", "Ryne")
	skill_timer.start(SKILL_COOLDOWN_SEC)
	_play_audio_sfx(&"electro_strike", -1.0, 0.01)
	_play_anim(&"skill")
	RYNE_ELECTRO_EFFECT.spawn_electric_burst(global_position + Vector2(facing_direction * 16.0, -20.0), facing_direction, 0.48)
	RYNE_ELECTRO_EFFECT.spawn_shockwave_ring(global_position + Vector2(facing_direction * 26.0, -4.0), facing_direction, 0.42)
	var sw: Shockwave = _spawn_pooled(SHOCKWAVE_SCENE, global_position + Vector2(facing_direction * SHOCKWAVE_OFFSET_X, 0)) as Shockwave
	sw.set_facing(facing_direction)

func _start_dodge() -> void:
	_is_dodging = true
	_start_tile_dodge()
	_play_audio_sfx(&"dodge", -3.0)
	_play_anim(&"dodge")
	RYNE_ELECTRO_EFFECT.spawn_dodge_afterimage(global_position + Vector2(-facing_direction * 8.0, -22.0), facing_direction, 0.64)
	dodge_timer.start(DODGE_DURATION_SEC)

func _on_dodge_timer_timeout() -> void:
	_is_dodging = false
	_reset_sprite_visual_transform()

func _play_combo_anim() -> void:
	var anim_name: StringName = &"attack_1"
	var speed: float = 1.35
	match _combo_step:
		1:
			anim_name = &"attack_2"
			speed = 1.45
		2:
			anim_name = &"attack_3"
			speed = 1.4
		3:
			anim_name = &"attack_3"
			speed = 1.65
	_play_anim(anim_name)
	if sprite:
		sprite.speed_scale = speed

func _play_anim(anim_name: StringName) -> void:
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		_reset_sprite_visual_transform()
		sprite.play(anim_name)

func _on_sprite_animation_finished() -> void:
	if sprite.animation in [&"attack_1", &"attack_2", &"attack_3", &"skill", &"dodge", &"hurt"]:
		sprite.speed_scale = 1.0
		_reset_sprite_visual_transform()

func _reset_sprite_visual_transform() -> void:
	if sprite == null:
		return
	sprite.scale = SPRITE_BASE_SCALE
	sprite.position = SPRITE_BASE_POSITION

func _spawn_pooled(scene: PackedScene, spawn_position: Vector2) -> Node:
	var parent := _projectile_parent()
	var pool := _projectile_pool()
	if pool and pool.has_method("spawn_projectile"):
		return pool.spawn_projectile(scene, parent, spawn_position)
	var instance := scene.instantiate() as Node2D
	instance.global_position = spawn_position
	parent.add_child(instance)
	return instance

func _projectile_pool() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("ProjectilePool")

func _projectile_parent() -> Node:
	var parent := get_parent()
	if parent == null:
		return self
	var grandparent := parent.get_parent()
	if grandparent == null or grandparent == get_tree().root:
		return parent
	return grandparent
