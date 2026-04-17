class_name Kira
extends CharacterBase
## Kira — Pyro Warrior. Handles all player input, state machine, and combat.

# === Enums ===
enum State { IDLE, RUN, JUMP, ATTACK, SKILL, DODGE, HURT, DEAD }

# === Constants ===
const FIRE_BOMB_SCENE: PackedScene = preload("res://scenes/projectiles/fire_bomb.tscn")
const DODGE_SPEED: float = 400.0

# === Public Variables ===
var current_state: State = State.IDLE
var is_invincible: bool = false  # true during dodge i-frames

# === Private Variables ===
var _combo_step: int = 0  # 0-2 for 3-hit combo

# === Onready ===
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $HitboxArea2D
@onready var hitbox_shape: CollisionShape2D = $HitboxArea2D/CollisionShape2D
@onready var skill_timer: Timer = $SkillCooldownTimer
@onready var dodge_timer: Timer = $DodgeTimer
@onready var combo_timer: Timer = $AttackComboTimer
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	super._ready()
	hitbox_shape.disabled = true
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	dodge_timer.timeout.connect(_on_dodge_timer_timeout)
	combo_timer.timeout.connect(_on_combo_timer_timeout)

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
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
	combo_timer.start()

func _check_next_combo() -> void:
	if Input.is_action_just_pressed("attack") and not combo_timer.is_stopped():
		_combo_step = mini(_combo_step + 1, 2)
		_play_attack_animation()
		combo_timer.start()

func _play_attack_animation() -> void:
	match _combo_step:
		0: sprite.play("attack_1")
		1: sprite.play("attack_2")
		2: sprite.play("attack_3")

func _on_hitbox_body_entered(body: Node) -> void:
	# Deal 10 damage to any EnemyBase in the hitbox.
	if body.has_method("take_damage"):
		body.take_damage(10.0, "pyro")

func _on_combo_timer_timeout() -> void:
	_combo_step = 0
	hitbox_shape.disabled = true
	if current_state == State.ATTACK:
		_change_state(State.IDLE)

# === Elemental Skill ===

func _use_skill() -> void:
	_change_state(State.SKILL)
	sprite.play("skill")
	skill_timer.start()
	var bomb: Node2D = FIRE_BOMB_SCENE.instantiate()
	get_parent().add_child(bomb)
	bomb.global_position = global_position
	bomb.set_direction(facing_direction)

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

# === State Machine ===

func _change_state(new_state: State) -> void:
	if current_state == new_state:
		return
	current_state = new_state

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
