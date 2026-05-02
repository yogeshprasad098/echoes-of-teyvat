class_name Marina
extends CharacterBase
## Hydro support. Mid-range water-orb normal attack (8 dmg, range 280),
## Water Burst skill (18 dmg + 12 HP heal to active char, range 240).

const ATTACK_COOLDOWN_SEC: float = 0.45
const SKILL_COOLDOWN_SEC: float = 8.0
const SKILL_OFFSET_X: float = 60.0
const WATER_ORB_SCENE: PackedScene = preload("res://scenes/projectiles/water_orb.tscn")
const WATER_BURST_SCENE: PackedScene = preload("res://scenes/projectiles/water_burst.tscn")

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var skill_timer: Timer = $SkillCooldownTimer

var _attack_cd: float = 0.0

func _ready() -> void:
	super._ready()
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
	var orb: WaterOrb = WATER_ORB_SCENE.instantiate() as WaterOrb
	orb.global_position = spawn_pos
	orb.set_direction(facing_direction)
	# Add to area sibling of enemies — get_parent() is Party, get_parent().get_parent() is the area.
	get_parent().get_parent().add_child(orb)
	MuzzleFlash.spawn(spawn_pos, facing_direction, Color(0.55, 0.92, 1.0))

# Scale punch as a cast tell — avoids using the sword-swing attack frames.
func _cast_pulse() -> void:
	if sprite == null:
		return
	var base: Vector2 = Vector2(1.25, 1.25)
	sprite.scale = Vector2(1.45, 1.1)
	var tween: Tween = create_tween()
	tween.tween_property(sprite, "scale", base, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _cast_water_burst() -> void:
	skill_timer.start(SKILL_COOLDOWN_SEC)
	_play_anim(&"skill")
	var burst: WaterBurst = WATER_BURST_SCENE.instantiate() as WaterBurst
	burst.global_position = global_position + Vector2(facing_direction * SKILL_OFFSET_X, 0)
	get_parent().get_parent().add_child(burst)

func _play_anim(anim_name: StringName) -> void:
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
