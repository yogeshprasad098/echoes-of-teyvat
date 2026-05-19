class_name Kira
extends CharacterBase
## Kira — Pyro Warrior. Handles all player input, state machine, and combat.

# === Enums ===
enum State { IDLE, RUN, JUMP, ATTACK, THROW, SKILL, DODGE, HURT, DEAD }

# === Constants ===
const FIRE_BOMB_SCENE: PackedScene = preload("res://scenes/projectiles/fire_bomb.tscn")
const FIRE_ORB_SCENE: PackedScene = preload("res://scenes/projectiles/fire_orb.tscn")
const ATTACK_COOLDOWN_SEC: float = 0.45
const THROW_COOLDOWN_SEC: float = 0.45
const THROW_CAST_DELAY_SEC: float = 0.12
const DODGE_SPEED: float = PhysicsModel.DODGE_SPEED_PX_PER_SEC
const SKILL_LOCK_DURATION: float = 0.4
const DODGE_DURATION_SEC: float = PhysicsModel.DODGE_DURATION_SEC
const ATTACK_RANGE: float = PhysicsModel.TILE_SIZE_PX * PhysicsModel.KIRA_MELEE_RANGE_TILES
const ATTACK_HITBOX_OFFSET: float = 32.0
const ATTACK_HITBOX_DURATION: float = 0.14
const SKILL_RANGE: float = PhysicsModel.TILE_SIZE_PX * PhysicsModel.KIRA_FIRE_BOMB_RANGE_TILES
const ATTACK_DAMAGE: Array[float] = [10.0, 12.0, 16.0]
const THROW_DAMAGE: float = 12.0
const SKILL_DAMAGE: float = 50.0
const SPRITE_BASE_SCALE: Vector2 = Vector2(0.72, 0.72)
const SPRITE_BASE_POSITION: Vector2 = Vector2(0.0, -23.0)

# === Public Variables ===
var current_state: State = State.IDLE
var is_invincible: bool = false  # true during dodge i-frames

# === Private Variables ===
var _combo_step: int = 0  # 0-2 for 3-hit combo
var _throw_cd: float = 0.0
var _skill_lock_remaining: float = 0.0
var _attack_window_token: int = 0
var _hit_targets: Array[EnemyBase] = []

# === Onready ===
@onready var sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var hitbox: Area2D = %HitboxArea2D
@onready var hitbox_shape: CollisionShape2D = %HitboxCollisionShape
@onready var skill_timer: Timer = %SkillCooldownTimer
@onready var dodge_timer: Timer = %DodgeTimer
@onready var combo_timer: Timer = %AttackComboTimer
@onready var camera: Camera2D = get_parent().get_node_or_null("Camera2D") if get_parent() else null
@onready var skill_aura: Polygon2D = %SkillAura
@onready var attack_range_guide: Polygon2D = %AttackRangeGuide
@onready var skill_range_guide: Line2D = %SkillRangeGuide

func _ready() -> void:
	super._ready()
	_reset_sprite_visual_transform()
	hitbox_shape.disabled = true
	# Permanently hide dev-time debug overlays.
	skill_aura.visible = false
	attack_range_guide.visible = false
	skill_range_guide.visible = false
	skill_aura.modulate.a = 0.0
	attack_range_guide.modulate.a = 0.0
	skill_range_guide.modulate.a = 0.0
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	dodge_timer.timeout.connect(_on_dodge_timer_timeout)
	combo_timer.timeout.connect(_on_combo_timer_timeout)
	sprite.animation_finished.connect(_on_sprite_animation_finished)

func _physics_process(delta: float) -> void:
	_throw_cd = maxf(0.0, _throw_cd - delta)
	_update_jump_assist(delta)
	_buffer_jump_input()
	_apply_platformer_gravity(delta)
	_update_skill_lock(delta)
	_handle_input(delta)
	move_and_slide()
	_update_animation()

# === Input Handling ===

func _handle_input(delta: float) -> void:
	if current_state == State.DEAD:
		return
	if current_state == State.DODGE:
		return  # no input override during roll
	if current_state == State.ATTACK:
		_check_next_combo()
		return
	if current_state == State.THROW or current_state == State.SKILL:
		return

	_handle_movement(delta)

	if _consume_buffered_jump():
		_change_state(State.JUMP)

	if Input.is_action_just_pressed("attack"):
		_start_attack()

	if Input.is_action_just_pressed("throw"):
		_start_throw()

	if Input.is_action_just_pressed("skill") and skill_timer.is_stopped():
		_use_skill()

	if Input.is_action_just_pressed("dodge"):
		_start_dodge()

func _handle_movement(delta: float) -> void:
	var direction := _apply_horizontal_input(delta)
	if direction != 0.0:
		sprite.flip_h = facing_direction == -1
		if is_on_floor() and current_state not in [State.ATTACK, State.SKILL]:
			_change_state(State.RUN)
	else:
		if is_on_floor() and current_state == State.RUN:
			_change_state(State.IDLE)
	if not is_on_floor():
		if current_state not in [State.JUMP, State.ATTACK, State.THROW, State.SKILL, State.DODGE, State.HURT, State.DEAD]:
			_change_state(State.JUMP)
	elif current_state == State.JUMP:
		_change_state(State.IDLE)

# === Combat ===

func _start_attack() -> void:
	if not combo_timer.is_stopped():
		return
	_combo_step = 0
	_change_state(State.ATTACK)
	_play_attack_animation()
	combo_timer.start(0.6)

func _cast_pulse() -> void:
	_reset_sprite_visual_transform()

func _check_next_combo() -> void:
	if not Input.is_action_just_pressed("attack"):
		return
	_combo_step = mini(_combo_step + 1, ATTACK_DAMAGE.size() - 1)
	_play_attack_animation()
	combo_timer.start(0.6)

func _fire_fire_orb(damage: float = ATTACK_DAMAGE[0]) -> void:
	var spawn_pos: Vector2 = global_position + Vector2(facing_direction * 18.0, -4.0)
	var orb: FireOrb = _spawn_pooled(FIRE_ORB_SCENE, spawn_pos) as FireOrb
	orb.set_direction(facing_direction)
	orb.set_damage(damage)
	KiraVfxEffect.spawn_hit_spark(spawn_pos + Vector2(facing_direction * 8.0, -2.0), facing_direction, 0.45)
	_add_screen_shake(0.18)

func _play_attack_animation() -> void:
	_hit_targets.clear()
	_reset_sprite_visual_transform()
	# Sync character-sprite anim speed to the slash VFX so they finish together (~0.5s).
	match _combo_step:
		0:
			sprite.play("attack_1")
			sprite.speed_scale = 1.4
		1:
			sprite.play("attack_2")
			sprite.speed_scale = 1.5
		2:
			sprite.play("attack_3")
			sprite.speed_scale = 1.3
	hitbox_shape.disabled = true
	_show_attack_effect()
	_open_attack_window()

func _open_attack_window() -> void:
	_attack_window_token += 1
	var token := _attack_window_token
	_sync_attack_hitbox()
	hitbox_shape.disabled = false
	_damage_current_hitbox_overlaps()
	await get_tree().create_timer(ATTACK_HITBOX_DURATION).timeout
	if token == _attack_window_token:
		hitbox_shape.disabled = true

func _on_hitbox_body_entered(body: Node) -> void:
	_damage_enemy(body)

func _on_combo_timer_timeout() -> void:
	_combo_step = 0
	_hit_targets.clear()
	_attack_window_token += 1
	hitbox_shape.disabled = true
	sprite.speed_scale = 1.0
	attack_range_guide.visible = false
	attack_range_guide.modulate.a = 0.0
	if current_state == State.ATTACK:
		_change_state(State.IDLE)
	_reset_sprite_visual_transform()

func _apply_smear() -> void:
	_reset_sprite_visual_transform()

func _damage_current_hitbox_overlaps() -> void:
	if hitbox_shape.disabled:
		return
	for body in hitbox.get_overlapping_bodies():
		_damage_enemy(body)

func _damage_enemy(body: Node) -> void:
	if body == self:
		return
	if body is EnemyBase and not _hit_targets.has(body):
		_hit_targets.append(body)
		body.take_damage(ATTACK_DAMAGE[_combo_step], "pyro")
		KiraVfxEffect.spawn_hit_spark(body.global_position + Vector2(0.0, -8.0), facing_direction)
		var is_finisher: bool = _combo_step == 2
		# Trauma-model shake + best-practice hitstop (4-frame light, 8-frame finisher @ 60 fps).
		_add_screen_shake(0.55 if is_finisher else 0.35)
		_freeze_hit_stop(0.133 if is_finisher else 0.066)

# === Throw ===

func _start_throw() -> void:
	if _throw_cd > 0.0:
		return
	_throw_cd = THROW_COOLDOWN_SEC
	_change_state(State.THROW)
	_reset_sprite_visual_transform()
	hitbox_shape.disabled = true
	_hit_targets.clear()
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(&"throw"):
		sprite.play(&"throw")
		sprite.speed_scale = 1.45
	_launch_throw_after_cast()

func _launch_throw_after_cast() -> void:
	await get_tree().create_timer(THROW_CAST_DELAY_SEC).timeout
	if not is_inside_tree() or current_state != State.THROW:
		return
	_fire_fire_orb(THROW_DAMAGE)

# === Elemental Skill ===

func _use_skill() -> void:
	_change_state(State.SKILL)
	sprite.play("skill")
	_show_skill_effect()
	_skill_lock_remaining = SKILL_LOCK_DURATION
	skill_timer.start()
	var bomb := _spawn_pooled(FIRE_BOMB_SCENE, global_position + Vector2(24.0 * facing_direction, -4.0)) as FireBomb
	bomb.set_direction(facing_direction)
	if camera:
		var zoom_tween: Tween = create_tween()
		var start_zoom: Vector2 = camera.zoom
		zoom_tween.tween_property(camera, "zoom", start_zoom * 0.92, 0.2)
		zoom_tween.tween_property(camera, "zoom", start_zoom, 0.2)
	_add_screen_shake(0.35)

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

func _add_screen_shake(amount: float) -> void:
	var tree := get_tree()
	if tree == null:
		return
	var screen_shake := tree.root.get_node_or_null("ScreenShake")
	if screen_shake and screen_shake.has_method("add_trauma"):
		screen_shake.add_trauma(amount)

func _freeze_hit_stop(duration: float) -> void:
	var tree := get_tree()
	if tree == null:
		return
	var hit_stop := tree.root.get_node_or_null("HitStop")
	if hit_stop and hit_stop.has_method("freeze"):
		hit_stop.freeze(duration)

# === Dodge ===

func _start_dodge() -> void:
	_change_state(State.DODGE)
	is_invincible = true
	_start_tile_dodge()
	sprite.play("dodge")
	KiraVfxEffect.spawn_dust_puff(global_position + Vector2(-facing_direction * 10.0, 8.0), facing_direction)
	dodge_timer.start(DODGE_DURATION_SEC)

func _on_dodge_timer_timeout() -> void:
	is_invincible = false
	_change_state(State.IDLE)

# === Damage ===

## Applies damage unless Kira is invincible or already dead.
func take_damage(amount: float) -> void:
	if is_invincible or current_state == State.DEAD:
		return
	_change_state(State.HURT)
	sprite.play("hurt")
	HurtFlash.play(sprite)
	super.take_damage(amount)

## Plays the death animation before delegating to the base death flow.
func die() -> void:
	_change_state(State.DEAD)
	sprite.play("death")
	# Delay queue_free so death animation plays.
	await sprite.animation_finished
	super.die()

## Restores Kira's combat, cooldown, position, and animation state for a new run.
func reset_for_run(spawn_position: Vector2) -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)
	global_position = spawn_position
	velocity = Vector2.ZERO
	facing_direction = 1
	sprite.flip_h = false
	_combo_step = 0
	_skill_lock_remaining = 0.0
	is_invincible = false
	hitbox_shape.disabled = true
	attack_range_guide.visible = false
	skill_aura.visible = false
	skill_range_guide.visible = false
	skill_timer.stop()
	dodge_timer.stop()
	combo_timer.stop()
	_throw_cd = 0.0
	_attack_window_token += 1
	_reset_jump_assist()
	_change_state(State.IDLE)
	_reset_sprite_visual_transform()
	sprite.play("idle")

# === State Machine ===

func _change_state(new_state: State) -> void:
	if current_state == new_state:
		return
	var previous_state := current_state
	current_state = new_state
	if previous_state == State.SKILL and new_state != State.SKILL:
		_hide_skill_effect()

# === Animation ===

func _update_animation() -> void:
	# Animation is driven by state transitions; only handle idle/run/jump here.
	match current_state:
		State.IDLE:
			if sprite.animation != "idle":
				sprite.play("idle")
		State.RUN:
			if sprite.animation != "run":
				sprite.play("run")
		State.JUMP:
			if sprite.animation != "jump":
				sprite.play("jump")

func _show_attack_effect() -> void:
	var slash_pos := global_position + Vector2(facing_direction * 34.0, -12.0)
	KiraVfxEffect.spawn_slash_arc(slash_pos, facing_direction, 0.56 + float(_combo_step) * 0.04)
	if attack_range_guide:
		attack_range_guide.visible = false
		attack_range_guide.modulate.a = 0.0

func _reset_sprite_visual_transform() -> void:
	if sprite == null:
		return
	sprite.scale = SPRITE_BASE_SCALE
	sprite.position = SPRITE_BASE_POSITION

func _sync_attack_hitbox() -> void:
	hitbox.position = Vector2(ATTACK_HITBOX_OFFSET * facing_direction, -4.0)

func _show_skill_effect() -> void:
	skill_aura.visible = false
	skill_aura.modulate.a = 0.0
	skill_range_guide.visible = false
	skill_range_guide.modulate.a = 0.0

func _hide_skill_effect() -> void:
	skill_aura.visible = false
	skill_aura.modulate.a = 0.0
	skill_range_guide.visible = false
	skill_range_guide.modulate.a = 0.0
	_skill_lock_remaining = 0.0

func _update_skill_lock(delta: float) -> void:
	if current_state != State.SKILL:
		return
	_skill_lock_remaining = maxf(0.0, _skill_lock_remaining - delta)
	if _skill_lock_remaining <= 0.0:
		_finish_skill_state()

func _finish_skill_state() -> void:
	_hide_skill_effect()
	if current_state == State.SKILL:
		_change_state(State.IDLE)

func _on_sprite_animation_finished() -> void:
	if current_state == State.SKILL and sprite.animation == &"skill":
		_finish_skill_state()
	elif current_state == State.THROW and sprite.animation == &"throw":
		sprite.speed_scale = 1.0
		_reset_sprite_visual_transform()
		_change_state(State.IDLE)
	elif current_state == State.ATTACK and sprite.animation in [&"attack", &"attack_1", &"attack_2", &"attack_3"]:
		sprite.speed_scale = 1.0
		_reset_sprite_visual_transform()
	elif current_state == State.HURT and sprite.animation == &"hurt":
		_change_state(State.IDLE)
