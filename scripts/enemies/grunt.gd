class_name Grunt
extends EnemyBase
## Basic patrol enemy. Walks back and forth, chases Kira, then uses a readable attack wind-up.

# === Enums ===
enum State { PATROL, CHASE, ATTACK, DEAD }

# === Constants ===
const CHASE_SPEED: float = 120.0
const CONTACT_COOLDOWN: float = 1.0
const ATTACK_RANGE: float = 58.0
const ATTACK_WINDUP: float = 0.34
const ATTACK_RECOVERY: float = 0.28
const DEATH_CLEANUP_DELAY: float = 0.7
const PERSONAL_SPACE: float = 46.0
const SEPARATION_Y_RANGE: float = 48.0
const RETREAT_SPEED: float = 95.0
const PLAYER_LAYER := 2
const ENEMY_LAYER := 4

# === Private Variables ===
var _state: State = State.PATROL
var _patrol_direction: int = 1
var _target: CharacterBase = null
var _contact_cooldown: float = 0.0
var _attack_windup_remaining: float = 0.0
var _attack_recovery_remaining: float = 0.0
var _attack_has_hit: bool = false
var _life_version: int = 0

# === Onready ===
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_alert: Label = $AttackAlert
@onready var attack_arc: Polygon2D = $AttackArc
@onready var hit_spark: Polygon2D = $HitSpark
@onready var damage_popup: Label = $DamagePopup
@onready var health_bar: Node2D = $HealthBar
@onready var health_fill: ColorRect = $HealthBar/Fill
@onready var ray_left: RayCast2D = $PatrolRayLeft
@onready var ray_right: RayCast2D = $PatrolRayRight
@onready var hurtbox: Area2D = $Hurtbox
@onready var detection: Area2D = $DetectionArea2D
@onready var patrol_timer: Timer = $PatrolTimer

func _ready() -> void:
	super._ready()
	detection.body_entered.connect(_on_detection_body_entered)
	detection.body_exited.connect(_on_detection_body_exited)
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	patrol_timer.timeout.connect(_on_patrol_timer_timeout)
	attack_alert.visible = false
	attack_arc.visible = false
	hit_spark.visible = false
	damage_popup.visible = false
	_update_health_bar()
	sprite.play("walk")

func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		return

	_contact_cooldown = max(0.0, _contact_cooldown - delta)
	velocity.y += gravity * delta

	match _state:
		State.PATROL:
			_process_patrol()
		State.CHASE:
			_process_chase()
		State.ATTACK:
			_process_attack(delta)

	_apply_soft_spacing()
	move_and_slide()

# === Patrol ===

func _process_patrol() -> void:
	var active_ray := ray_right if _patrol_direction == 1 else ray_left
	var has_ground: bool = active_ray.is_colliding()
	var wall_hit: bool = is_on_wall()

	# Reverse direction at ledges or walls.
	if not has_ground or wall_hit:
		_patrol_direction *= -1

	velocity.x = _patrol_direction * move_speed
	sprite.flip_h = _patrol_direction == -1

func _on_patrol_timer_timeout() -> void:
	_patrol_direction *= -1

# === Chase ===

func _process_chase() -> void:
	if not is_instance_valid(_target):
		_state = State.PATROL
		return

	_face_target()
	var horizontal_distance: float = absf(_target.global_position.x - global_position.x)
	var vertical_distance: float = absf(_target.global_position.y - global_position.y)
	if horizontal_distance < PERSONAL_SPACE and vertical_distance < SEPARATION_Y_RANGE:
		velocity.x = -_patrol_direction * RETREAT_SPEED
		return
	if horizontal_distance <= ATTACK_RANGE and vertical_distance < SEPARATION_Y_RANGE and _contact_cooldown <= 0.0:
		_start_attack()
		return

	velocity.x = _patrol_direction * CHASE_SPEED

func _start_attack() -> void:
	_state = State.ATTACK
	velocity.x = 0.0
	_attack_windup_remaining = ATTACK_WINDUP
	_attack_recovery_remaining = ATTACK_RECOVERY
	_attack_has_hit = false
	_face_target()
	attack_alert.visible = true
	attack_arc.visible = false
	sprite.modulate = Color(1.0, 0.72, 0.48)
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(&"attack"):
		sprite.play(&"attack")

func _process_attack(delta: float) -> void:
	velocity.x = 0.0
	if not is_instance_valid(_target):
		_finish_attack()
		return

	_face_target()
	if _attack_windup_remaining > 0.0:
		_attack_windup_remaining = max(0.0, _attack_windup_remaining - delta)
		if _attack_windup_remaining <= 0.0:
			_apply_attack_hit()
		return

	_attack_recovery_remaining = max(0.0, _attack_recovery_remaining - delta)
	if _attack_recovery_remaining <= 0.0:
		_finish_attack()

func _apply_attack_hit() -> void:
	attack_alert.visible = false
	attack_arc.visible = true
	sprite.modulate = Color.WHITE
	if _attack_has_hit:
		return

	_attack_has_hit = true
	_contact_cooldown = CONTACT_COOLDOWN
	var target_delta: Vector2 = _target.global_position - global_position if is_instance_valid(_target) else Vector2(INF, INF)
	if absf(target_delta.x) <= ATTACK_RANGE + 8.0 and absf(target_delta.y) < SEPARATION_Y_RANGE:
		_target.take_damage(damage)

func _finish_attack() -> void:
	attack_alert.visible = false
	attack_arc.visible = false
	sprite.modulate = Color.WHITE
	if is_instance_valid(_target):
		_state = State.CHASE
	else:
		_state = State.PATROL
	if _state != State.DEAD and sprite.sprite_frames and sprite.sprite_frames.has_animation(&"walk"):
		sprite.play(&"walk")

func _face_target() -> void:
	if not is_instance_valid(_target):
		return
	var dir: float = sign(_target.global_position.x - global_position.x)
	if is_zero_approx(dir):
		dir = float(_patrol_direction)
	_patrol_direction = int(dir)
	sprite.flip_h = _patrol_direction == -1
	attack_arc.position.x = 14.0 * _patrol_direction
	attack_arc.scale.x = float(_patrol_direction)

func _apply_soft_spacing() -> void:
	if not is_instance_valid(_target) or _state == State.DEAD:
		return
	var delta_to_target := _target.global_position - global_position
	if absf(delta_to_target.y) >= SEPARATION_Y_RANGE or absf(delta_to_target.x) >= PERSONAL_SPACE:
		return
	var away_direction: float = -sign(delta_to_target.x)
	if is_zero_approx(away_direction):
		away_direction = -float(_patrol_direction)
	velocity.x = away_direction * RETREAT_SPEED

func _on_detection_body_entered(body: Node) -> void:
	if body is CharacterBase:
		_target = body
		_state = State.CHASE

func _on_detection_body_exited(body: Node) -> void:
	if body == _target:
		_target = null
		if _state != State.ATTACK:
			_state = State.PATROL
			sprite.play("walk")

# === Hurt / Death ===

func _on_hurtbox_area_entered(_area: Area2D) -> void:
	# Damage is dealt by Kira's hitbox via take_damage() directly; this handles AoE areas.
	pass

func take_damage(amount: float, element: String = "") -> void:
	if _state == State.DEAD:
		return
	super.take_damage(amount, element)
	_update_health_bar()
	_show_damage_feedback(amount)
	if _state != State.DEAD:
		var flash := create_tween()
		flash.tween_property(sprite, "modulate", Color.WHITE, 0.22).from(Color(1.0, 0.15, 0.08))

func _show_damage_feedback(amount: float) -> void:
	hit_spark.visible = true
	hit_spark.rotation = randf_range(-0.35, 0.35)
	hit_spark.scale = Vector2.ONE
	damage_popup.visible = true
	damage_popup.text = "-%d" % int(amount)
	damage_popup.position = Vector2(-11, -43)
	damage_popup.modulate = Color.WHITE

	var spark_tween := create_tween()
	spark_tween.tween_property(hit_spark, "scale", Vector2(1.45, 1.45), 0.08)
	spark_tween.tween_property(hit_spark, "scale", Vector2.ZERO, 0.12)
	spark_tween.tween_callback(func() -> void: hit_spark.visible = false)

	var popup_tween := create_tween()
	popup_tween.tween_property(damage_popup, "position", Vector2(-11, -60), 0.35)
	popup_tween.parallel().tween_property(damage_popup, "modulate", Color(1, 1, 1, 0), 0.35)
	popup_tween.tween_callback(func() -> void: damage_popup.visible = false)

func _update_health_bar() -> void:
	var ratio: float = clampf(current_health / max_health, 0.0, 1.0)
	health_bar.visible = current_health > 0.0
	health_fill.size.x = 30.0 * ratio
	if ratio > 0.5:
		health_fill.color = Color(0.38, 0.95, 0.2)
	elif ratio > 0.25:
		health_fill.color = Color(1.0, 0.76, 0.12)
	else:
		health_fill.color = Color(1.0, 0.16, 0.08)

func die() -> void:
	_life_version += 1
	var death_version := _life_version
	_state = State.DEAD
	velocity = Vector2.ZERO
	attack_alert.visible = false
	attack_arc.visible = false
	hit_spark.visible = false
	damage_popup.visible = false
	health_bar.visible = false
	collision_layer = 0
	collision_mask = 0
	hurtbox.collision_layer = 0
	detection.collision_mask = 0
	sprite.modulate = Color.WHITE
	sprite.play("death")
	await get_tree().create_timer(DEATH_CLEANUP_DELAY, true).timeout
	if death_version != _life_version or _state != State.DEAD:
		return
	super.die()
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED

func reset_for_run() -> void:
	_life_version += 1
	super.reset_for_run()
	_state = State.PATROL
	_patrol_direction = 1
	_target = null
	_contact_cooldown = 0.0
	_attack_windup_remaining = 0.0
	_attack_recovery_remaining = 0.0
	_attack_has_hit = false
	attack_alert.visible = false
	attack_arc.visible = false
	hit_spark.visible = false
	damage_popup.visible = false
	_update_health_bar()
	hurtbox.collision_layer = ENEMY_LAYER
	hurtbox.collision_mask = 0
	detection.collision_layer = 0
	detection.collision_mask = PLAYER_LAYER
	sprite.flip_h = false
	sprite.modulate = Color.WHITE
	if patrol_timer.is_stopped():
		patrol_timer.start()
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(&"walk"):
		sprite.play(&"walk")
