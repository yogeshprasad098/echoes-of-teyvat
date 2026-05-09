class_name Marina
extends CharacterBase
## Hydro support. Mid-range water-orb normal attack (8 dmg, range 280),
## Water Burst skill (18 dmg + 12 HP heal to active char, range 240).

const ATTACK_COOLDOWN_SEC: float = 0.45
const SKILL_COOLDOWN_SEC: float = 8.0
const SKILL_OFFSET_X: float = 60.0
const WATER_ORB_SCENE: PackedScene = preload("res://scenes/projectiles/water_orb.tscn")
const WATER_BURST_SCENE: PackedScene = preload("res://scenes/projectiles/water_burst.tscn")
const SPRITE_BASE_SCALE: Vector2 = Vector2(0.625, 0.625)
const SPRITE_BASE_POSITION: Vector2 = Vector2(0.0, -6.0)

var _attack_cd: float = 0.0

@onready var sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var skill_timer: Timer = %SkillCooldownTimer

func _ready() -> void:
	super._ready()
	_reset_sprite_visual_transform()
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(&"idle"):
		sprite.play(&"idle")

func _physics_process(delta: float) -> void:
	_attack_cd = max(0.0, _attack_cd - delta)
	if not is_on_floor():
		velocity.y += gravity * delta
	var direction: float = Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * move_speed, acceleration * delta)
		facing_direction = int(sign(direction))
		if sprite:
			sprite.flip_h = facing_direction == -1
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	if Input.is_action_just_pressed("attack") and _attack_cd <= 0.0:
		_fire_water_orb()
	if Input.is_action_just_pressed("skill") and skill_timer.is_stopped():
		_cast_water_burst()
	move_and_slide()
	_update_idle_run_anim()

func _update_idle_run_anim() -> void:
	if sprite == null:
		return
	# Don't clobber transient anims; let them finish.
	if sprite.animation in [&"attack_1", &"attack_2", &"attack_3", &"hurt", &"death"]:
		return
	# Throw / skill animations are brief — let them play out before resuming idle/run.
	if sprite.animation in [&"throw", &"skill"] and sprite.is_playing():
		return
	var moving: bool = absf(velocity.x) > 1.0
	var anim: StringName = &"run" if moving and is_on_floor() else &"idle"
	if not is_on_floor():
		anim = &"jump"
	if sprite.animation != anim and sprite.sprite_frames and sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)

func _fire_water_orb() -> void:
	_attack_cd = ATTACK_COOLDOWN_SEC
	if sprite and sprite.sprite_frames:
		if sprite.sprite_frames.has_animation(&"throw"):
			sprite.play(&"throw")
			sprite.speed_scale = 1.0  # 8 frames @ 24fps already feels brisk
		elif sprite.sprite_frames.has_animation(&"skill"):
			sprite.play(&"skill")
			sprite.speed_scale = 1.6
	_cast_pulse()
	var spawn_pos: Vector2 = global_position + Vector2(facing_direction * 18.0, -4.0)
	var orb: WaterOrb = _spawn_pooled(WATER_ORB_SCENE, spawn_pos) as WaterOrb
	orb.set_direction(facing_direction)
	MuzzleFlash.spawn(spawn_pos, facing_direction, Color(0.55, 0.92, 1.0))

func _cast_pulse() -> void:
	_reset_sprite_visual_transform()

func _cast_water_burst() -> void:
	skill_timer.start(SKILL_COOLDOWN_SEC)
	_play_anim(&"skill")
	_spawn_pooled(WATER_BURST_SCENE, global_position + Vector2(facing_direction * SKILL_OFFSET_X, 0))

func _play_anim(anim_name: StringName) -> void:
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		_reset_sprite_visual_transform()
		sprite.play(anim_name)

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
