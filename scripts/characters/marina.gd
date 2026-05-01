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

func _fire_water_orb() -> void:
	_attack_cd = ATTACK_COOLDOWN_SEC
	var orb: WaterOrb = WATER_ORB_SCENE.instantiate() as WaterOrb
	orb.global_position = global_position + Vector2(facing_direction * 18.0, -4.0)
	orb.set_direction(facing_direction)
	# Add to area sibling of enemies — get_parent() is Party, get_parent().get_parent() is the area.
	get_parent().get_parent().add_child(orb)

func _cast_water_burst() -> void:
	skill_timer.start(SKILL_COOLDOWN_SEC)
	var burst: WaterBurst = WATER_BURST_SCENE.instantiate() as WaterBurst
	burst.global_position = global_position + Vector2(facing_direction * SKILL_OFFSET_X, 0)
	get_parent().get_parent().add_child(burst)
