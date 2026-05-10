class_name Marina
extends CharacterBase
## Hydro support. Water-ball combo, travelling burst skill, and quick dodge.

const ATTACK_COOLDOWN_SEC: float = 0.45
const SKILL_COOLDOWN_SEC: float = 8.0
const SKILL_OFFSET_X: float = 60.0
const DODGE_SPEED: float = 380.0
const ATTACK_DAMAGE: Array[float] = [8.0, 10.0, 14.0]
const WATER_ORB_SCENE: PackedScene = preload("res://scenes/projectiles/water_orb.tscn")
const WATER_BURST_SCENE: PackedScene = preload("res://scenes/projectiles/water_burst.tscn")
const SPRITE_BASE_SCALE: Vector2 = Vector2(0.625, 0.625)
const SPRITE_BASE_POSITION: Vector2 = Vector2(0.0, -6.0)

var _attack_cd: float = 0.0
var _combo_step: int = 0
var _is_dodging: bool = false
var _skill_lock_remaining: float = 0.0

@onready var sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var skill_timer: Timer = %SkillCooldownTimer
@onready var dodge_timer: Timer = %DodgeTimer
@onready var combo_timer: Timer = %AttackComboTimer

func _ready() -> void:
	super._ready()
	_reset_sprite_visual_transform()
	dodge_timer.timeout.connect(_on_dodge_timer_timeout)
	combo_timer.timeout.connect(_on_combo_timer_timeout)
	sprite.animation_finished.connect(_on_sprite_animation_finished)
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(&"idle"):
		sprite.play(&"idle")

func _physics_process(delta: float) -> void:
	_attack_cd = max(0.0, _attack_cd - delta)
	_update_skill_lock(delta)
	if not is_on_floor():
		velocity.y += gravity * delta
	if _is_dodging:
		move_and_slide()
		return
	_handle_movement(delta)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	if Input.is_action_just_pressed("attack"):
		_start_or_continue_combo()
	if Input.is_action_just_pressed("skill") and skill_timer.is_stopped():
		_cast_water_burst()
	if Input.is_action_just_pressed("dodge"):
		_start_dodge()
	move_and_slide()
	_update_idle_run_anim()

func _handle_movement(delta: float) -> void:
	var direction: float = Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * move_speed, acceleration * delta)
		facing_direction = int(sign(direction))
		if sprite:
			sprite.flip_h = facing_direction == -1
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

func _update_idle_run_anim() -> void:
	if sprite == null:
		return
	if sprite.animation in [&"attack_1", &"attack_2", &"attack_3", &"throw", &"skill", &"dodge", &"hurt", &"death"] and sprite.is_playing():
		return
	var moving: bool = absf(velocity.x) > 1.0
	var anim: StringName = &"run" if moving and is_on_floor() else &"idle"
	if not is_on_floor():
		anim = &"jump"
	if sprite.animation != anim and sprite.sprite_frames and sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)

func _start_or_continue_combo() -> void:
	if _attack_cd > 0.0:
		return
	_attack_cd = ATTACK_COOLDOWN_SEC
	if not combo_timer.is_stopped():
		_combo_step = mini(_combo_step + 1, ATTACK_DAMAGE.size() - 1)
	else:
		_combo_step = 0
	_play_attack_animation()
	combo_timer.start(0.6)
	call_deferred("_launch_combo_water_orb", ATTACK_DAMAGE[_combo_step])

func _play_attack_animation() -> void:
	_reset_sprite_visual_transform()
	if sprite and sprite.sprite_frames:
		match _combo_step:
			0:
				sprite.play(&"attack_1")
				sprite.speed_scale = 1.4
			1:
				sprite.play(&"attack_2")
				sprite.speed_scale = 1.5
			2:
				sprite.play(&"attack_3")
				sprite.speed_scale = 1.3

func _launch_combo_water_orb(damage: float) -> void:
	var spawn_pos: Vector2 = global_position + Vector2(facing_direction * 18.0, -4.0)
	var orb: WaterOrb = _spawn_pooled(WATER_ORB_SCENE, spawn_pos) as WaterOrb
	orb.set_direction(facing_direction)
	orb.set_damage(damage)
	MuzzleFlash.spawn(spawn_pos, facing_direction, Color(0.55, 0.92, 1.0))

func _cast_water_burst() -> void:
	skill_timer.start(SKILL_COOLDOWN_SEC)
	_skill_lock_remaining = 0.35
	_play_anim(&"skill")
	var burst := _spawn_pooled(WATER_BURST_SCENE, global_position + Vector2(facing_direction * SKILL_OFFSET_X, -4.0)) as WaterBurst
	burst.set_direction(facing_direction)
	_add_screen_shake(0.25)

func _start_dodge() -> void:
	_is_dodging = true
	velocity.x = facing_direction * DODGE_SPEED
	_play_anim(&"dodge")
	dodge_timer.start()

func _on_dodge_timer_timeout() -> void:
	_is_dodging = false
	_reset_sprite_visual_transform()

func _on_combo_timer_timeout() -> void:
	_combo_step = 0
	sprite.speed_scale = 1.0
	_reset_sprite_visual_transform()

func _on_sprite_animation_finished() -> void:
	if sprite.animation in [&"attack_1", &"attack_2", &"attack_3", &"throw", &"skill", &"hurt"]:
		sprite.speed_scale = 1.0
		_reset_sprite_visual_transform()

func _update_skill_lock(delta: float) -> void:
	if _skill_lock_remaining <= 0.0:
		return
	_skill_lock_remaining = maxf(0.0, _skill_lock_remaining - delta)
	if _skill_lock_remaining <= 0.0:
		_reset_sprite_visual_transform()

func _play_anim(anim_name: StringName) -> void:
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		_reset_sprite_visual_transform()
		sprite.play(anim_name)

func _reset_sprite_visual_transform() -> void:
	if sprite == null:
		return
	sprite.scale = SPRITE_BASE_SCALE
	sprite.position = SPRITE_BASE_POSITION

func _add_screen_shake(amount: float) -> void:
	var tree := get_tree()
	if tree == null:
		return
	var screen_shake := tree.root.get_node_or_null("ScreenShake")
	if screen_shake and screen_shake.has_method("add_trauma"):
		screen_shake.add_trauma(amount)

func _spawn_pooled(scene: PackedScene, spawn_position: Vector2) -> Node:
	var parent := _projectile_parent()
	var pool := _projectile_pool()
	if pool and pool.has_method("spawn_projectile"):
		return pool.spawn_projectile(scene, parent, spawn_position)
	var instance := scene.instantiate() as Node2D
	instance.global_position = spawn_position
	parent.add_child(instance)
	if instance.has_method("reset_projectile"):
		instance.reset_projectile()
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
