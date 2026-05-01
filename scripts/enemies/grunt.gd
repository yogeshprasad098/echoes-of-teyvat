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
var _death_cleanup_timer: Timer = null
var _death_cleanup_deadline_ms: int = 0

# === Onready ===
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_alert: Label = $AttackAlert
@onready var attack_arc: SwordTrail = $AttackArc
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
	hit_spark.visible = false
	damage_popup.visible = false
	_update_health_bar()
	sprite.play("walk")
	# Override the SwordTrail's default hero palette with a darker claw palette.
	var claw: Gradient = Gradient.new()
	claw.set_color(0, Color(0.25, 0.04, 0.02, 0.0))
	claw.add_point(0.4, Color(0.78, 0.12, 0.04, 0.95))
	claw.set_color(1, Color(1.0, 0.42, 0.12, 1.0))
	attack_arc.gradient = claw
	attack_arc.default_color = Color(1.0, 0.32, 0.08, 1.0)

func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		if _death_cleanup_deadline_ms > 0 and Time.get_ticks_msec() >= _death_cleanup_deadline_ms:
			_finish_death_cleanup(_life_version)
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
	attack_alert.modulate = Color(1.0, 0.8, 0.1, 1.0)
	sprite.modulate = Color(1.0, 0.72, 0.48)
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(&"attack"):
		sprite.play(&"attack")
	# Wind-up tell: alert label pulses twice. Body animation is driven by sprite_frames, don't fight it.
	_play_windup_tell()

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
	sprite.modulate = Color.WHITE
	# Play the procedural claw-slash at the Grunt's strike origin (in front of its body).
	var claw_origin: Vector2 = global_position + Vector2(14.0 * _patrol_direction, -6.0)
	attack_arc.play_slash(claw_origin, _patrol_direction, 1.1, 0.22)
	if _attack_has_hit:
		return

	_attack_has_hit = true
	_contact_cooldown = CONTACT_COOLDOWN
	var target_delta: Vector2 = _target.global_position - global_position if is_instance_valid(_target) else Vector2(INF, INF)
	var connected: bool = absf(target_delta.x) <= ATTACK_RANGE + 8.0 and absf(target_delta.y) < SEPARATION_Y_RANGE
	if connected:
		_target.take_damage(damage)
		# Player-side feedback when the enemy's strike lands.
		_add_screen_shake(0.4)
		_freeze_hit_stop(0.08)
		HitSparks.burst_at(_target.global_position + Vector2(0, -8))

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

# Wind-up tell: alert-label twin-pulse to telegraph the incoming strike.
# Body animation is left to sprite_frames — don't fight the 2-frame flicker with scale tweens.
func _play_windup_tell() -> void:
	var alert_tween: Tween = create_tween().set_loops(2)
	alert_tween.tween_property(attack_alert, "modulate:a", 0.25, 0.08)
	alert_tween.tween_property(attack_alert, "modulate:a", 1.0, 0.08)

func _finish_attack() -> void:
	attack_alert.visible = false
	sprite.modulate = Color.WHITE
	attack_arc.clear_points()
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
	# attack_arc orientation is handled by SwordTrail.play_slash(facing_dir) on strike — nothing to sync here.

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
	_show_damage_feedback(last_damage_taken)
	if _state != State.DEAD:
		HurtFlash.play(sprite)

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
	attack_arc.clear_points()
	hit_spark.visible = false
	damage_popup.visible = false
	health_bar.visible = false
	collision_layer = 0
	collision_mask = 0
	hurtbox.collision_layer = 0
	detection.collision_mask = 0
	sprite.modulate = Color.WHITE
	sprite.play("death")
	_death_cleanup_deadline_ms = Time.get_ticks_msec() + int(DEATH_CLEANUP_DELAY * 1000.0)
	if DisplayServer.get_name() == "headless":
		_finish_death_cleanup(death_version)
		return
	if _death_cleanup_timer != null:
		_death_cleanup_timer.queue_free()
	_death_cleanup_timer = Timer.new()
	_death_cleanup_timer.one_shot = true
	_death_cleanup_timer.process_callback = Timer.TIMER_PROCESS_IDLE
	_death_cleanup_timer.ignore_time_scale = true
	add_child(_death_cleanup_timer)
	_death_cleanup_timer.timeout.connect(_finish_death_cleanup.bind(death_version), CONNECT_ONE_SHOT)
	_death_cleanup_timer.start(DEATH_CLEANUP_DELAY)

func _finish_death_cleanup(death_version: int) -> void:
	if _death_cleanup_timer != null:
		_death_cleanup_timer.queue_free()
		_death_cleanup_timer = null
	_death_cleanup_deadline_ms = 0
	if death_version != _life_version or _state != State.DEAD:
		return
	super.die()
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED

func reset_for_run() -> void:
	_life_version += 1
	if _death_cleanup_timer != null:
		_death_cleanup_timer.queue_free()
		_death_cleanup_timer = null
	_death_cleanup_deadline_ms = 0
	super.reset_for_run()
	_state = State.PATROL
	_patrol_direction = 1
	_target = null
	_contact_cooldown = 0.0
	_attack_windup_remaining = 0.0
	_attack_recovery_remaining = 0.0
	_attack_has_hit = false
	attack_alert.visible = false
	attack_arc.clear_points()
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
