class_name Kira
extends CharacterBase
## Kira — Pyro Warrior. Handles all player input, state machine, and combat.

# === Enums ===
enum State { IDLE, RUN, JUMP, ATTACK, SKILL, DODGE, HURT, DEAD }

# === Constants ===
const FIRE_BOMB_SCENE: PackedScene = preload("res://scenes/projectiles/fire_bomb.tscn")
const DODGE_SPEED: float = 400.0
const SKILL_LOCK_DURATION: float = 0.4
const ATTACK_RANGE: float = 58.0
const ATTACK_HITBOX_OFFSET: float = 32.0
const SKILL_RANGE: float = 420.0
const ATTACK_DAMAGE: Array[float] = [10.0, 12.0, 16.0]
const SKILL_DAMAGE: float = 50.0

# === Public Variables ===
var current_state: State = State.IDLE
var is_invincible: bool = false  # true during dodge i-frames

# === Private Variables ===
var _combo_step: int = 0  # 0-2 for 3-hit combo
var _skill_lock_remaining: float = 0.0
var _hit_targets: Array[EnemyBase] = []

# === Onready ===
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $HitboxArea2D
@onready var hitbox_shape: CollisionShape2D = $HitboxArea2D/CollisionShape2D
@onready var skill_timer: Timer = $SkillCooldownTimer
@onready var dodge_timer: Timer = $DodgeTimer
@onready var combo_timer: Timer = $AttackComboTimer
@onready var camera: Camera2D = $Camera2D
@onready var attack_slash: Polygon2D = $AttackSlash
@onready var skill_aura: Polygon2D = $SkillAura
@onready var attack_range_guide: Polygon2D = $AttackRangeGuide
@onready var skill_range_guide: Line2D = $SkillRangeGuide

func _ready() -> void:
	super._ready()
	hitbox_shape.disabled = true
	attack_slash.visible = false
	skill_aura.visible = false
	attack_range_guide.visible = false
	skill_range_guide.visible = false
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	dodge_timer.timeout.connect(_on_dodge_timer_timeout)
	combo_timer.timeout.connect(_on_combo_timer_timeout)
	sprite.animation_finished.connect(_on_sprite_animation_finished)

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_update_skill_lock(delta)
	_handle_input()
	move_and_slide()
	_update_animation()

# === Input Handling ===

func _handle_input() -> void:
	if current_state == State.DEAD:
		return
	if current_state == State.DODGE:
		return  # no input override during roll
	if current_state == State.ATTACK or current_state == State.SKILL:
		_check_next_combo()
		return

	_handle_movement()

	if Input.is_action_just_pressed("jump") and is_on_floor():
		_change_state(State.JUMP)
		velocity.y = jump_velocity

	if Input.is_action_just_pressed("attack"):
		_start_attack()

	if Input.is_action_just_pressed("skill") and skill_timer.is_stopped():
		_use_skill()

	if Input.is_action_just_pressed("dodge"):
		_start_dodge()

func _handle_movement() -> void:
	var direction: float = Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * move_speed, acceleration * get_physics_process_delta_time())
		facing_direction = int(sign(direction))
		sprite.flip_h = facing_direction == -1
		if is_on_floor() and current_state not in [State.ATTACK, State.SKILL]:
			_change_state(State.RUN)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * get_physics_process_delta_time())
		if is_on_floor() and current_state == State.RUN:
			_change_state(State.IDLE)

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
		if current_state not in [State.JUMP, State.ATTACK, State.SKILL, State.DODGE, State.HURT, State.DEAD]:
			_change_state(State.JUMP)
	else:
		if current_state == State.JUMP:
			_change_state(State.IDLE)

# === Combat ===

func _start_attack() -> void:
	_combo_step = 0
	_change_state(State.ATTACK)
	_play_attack_animation()
	hitbox_shape.disabled = false
	_sync_attack_hitbox()
	call_deferred("_damage_current_hitbox_overlaps")
	combo_timer.start()

func _check_next_combo() -> void:
	if Input.is_action_just_pressed("attack") and not combo_timer.is_stopped():
		_combo_step = mini(_combo_step + 1, 2)
		_play_attack_animation()
		combo_timer.start()

func _play_attack_animation() -> void:
	_hit_targets.clear()
	match _combo_step:
		0: sprite.play("attack_1")
		1: sprite.play("attack_2")
		2: sprite.play("attack_3")
	_sync_attack_hitbox()
	_show_attack_effect()
	call_deferred("_damage_current_hitbox_overlaps")

func _on_hitbox_body_entered(body: Node) -> void:
	_damage_enemy(body)

func _on_combo_timer_timeout() -> void:
	_combo_step = 0
	_hit_targets.clear()
	hitbox_shape.disabled = true
	attack_slash.visible = false
	attack_range_guide.visible = false
	if current_state == State.ATTACK:
		_change_state(State.IDLE)

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

# === Elemental Skill ===

func _use_skill() -> void:
	_change_state(State.SKILL)
	sprite.play("skill")
	_show_skill_effect()
	_skill_lock_remaining = SKILL_LOCK_DURATION
	skill_timer.start()
	var bomb := FIRE_BOMB_SCENE.instantiate() as FireBomb
	bomb.global_position = global_position + Vector2(24.0 * facing_direction, -4.0)
	bomb.set_direction(facing_direction)
	get_parent().add_child(bomb)

# === Dodge ===

func _start_dodge() -> void:
	_change_state(State.DODGE)
	is_invincible = true
	velocity.x = facing_direction * DODGE_SPEED
	sprite.play("dodge")
	dodge_timer.start()

func _on_dodge_timer_timeout() -> void:
	is_invincible = false
	_change_state(State.IDLE)

# === Damage ===

# Override to respect i-frames during dodge.
func take_damage(amount: float) -> void:
	if is_invincible or current_state == State.DEAD:
		return
	_change_state(State.HURT)
	sprite.play("hurt")
	super.take_damage(amount)

func die() -> void:
	_change_state(State.DEAD)
	sprite.play("death")
	# Delay queue_free so death animation plays.
	await sprite.animation_finished
	super.die()

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
	attack_slash.visible = false
	attack_range_guide.visible = false
	skill_aura.visible = false
	skill_range_guide.visible = false
	skill_timer.stop()
	dodge_timer.stop()
	combo_timer.stop()
	_change_state(State.IDLE)
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
	attack_slash.visible = true
	attack_range_guide.visible = true
	attack_slash.scale.x = float(facing_direction)
	attack_slash.position.x = 12.0 * facing_direction
	attack_range_guide.scale.x = float(facing_direction)
	attack_range_guide.position.x = 12.0 * facing_direction

func _sync_attack_hitbox() -> void:
	hitbox.position = Vector2(ATTACK_HITBOX_OFFSET * facing_direction, -4.0)

func _show_skill_effect() -> void:
	skill_aura.visible = true
	skill_range_guide.visible = true
	skill_range_guide.scale.x = float(facing_direction)
	skill_range_guide.points = PackedVector2Array([
		Vector2(18, -16),
		Vector2(88, -16),
	])

func _hide_skill_effect() -> void:
	skill_aura.visible = false
	skill_range_guide.visible = false
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
	elif current_state == State.HURT and sprite.animation == &"hurt":
		_change_state(State.IDLE)
