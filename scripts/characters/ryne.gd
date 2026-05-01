class_name Ryne
extends CharacterBase
## Electro striker. 4-hit gauntlet (6/7/8/12 dmg, range 36),
## Shockwave skill (30 dmg cone, range 96).

const ATTACK_DAMAGE: Array[float] = [6.0, 7.0, 8.0, 12.0]
const ATTACK_RANGE: float = 36.0
const ATTACK_STEP_COOLDOWN: float = 0.18
const COMBO_RESET_SEC: float = 0.6
const SKILL_COOLDOWN_SEC: float = 8.0
const SHOCKWAVE_SCENE: PackedScene = preload("res://scenes/projectiles/shockwave.tscn")
const SHOCKWAVE_OFFSET_X: float = 24.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $HitboxArea2D
@onready var hitbox_shape: CollisionShape2D = $HitboxArea2D/CollisionShape2D
@onready var attack_timer: Timer = $AttackTimer
@onready var combo_timer: Timer = $ComboTimer
@onready var skill_timer: Timer = $SkillCooldownTimer

var _combo_step: int = 0
var _hit_targets: Array[EnemyBase] = []

func _ready() -> void:
	super._ready()
	hitbox_shape.disabled = true
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	attack_timer.timeout.connect(_close_attack_window)
	combo_timer.timeout.connect(_reset_combo)
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(&"idle"):
		sprite.play(&"idle")

func _physics_process(delta: float) -> void:
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
	if Input.is_action_just_pressed("attack"):
		_swing_combo()
	if Input.is_action_just_pressed("skill") and skill_timer.is_stopped():
		_cast_shockwave()
	move_and_slide()

func _swing_combo() -> void:
	_hit_targets.clear()
	hitbox.position = Vector2(facing_direction * (ATTACK_RANGE * 0.5), -4.0)
	hitbox_shape.disabled = false
	attack_timer.start(ATTACK_STEP_COOLDOWN)
	combo_timer.start(COMBO_RESET_SEC)
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
	skill_timer.start(SKILL_COOLDOWN_SEC)
	var sw: Shockwave = SHOCKWAVE_SCENE.instantiate() as Shockwave
	sw.global_position = global_position + Vector2(facing_direction * SHOCKWAVE_OFFSET_X, 0)
	sw.set_facing(facing_direction)
	get_parent().get_parent().add_child(sw)
