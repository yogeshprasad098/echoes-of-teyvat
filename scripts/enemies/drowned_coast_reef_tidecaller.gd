class_name DrownedCoastReefTidecaller
extends EnemyBase

enum State { IDLE, CHASE, CAST, DEAD }
enum AttackKind { ORB, WAVE }

const ENEMY_VFX := preload("res://scripts/effects/enemy_vfx_effect.gd")
const ELITE_VFX_FRAMES := preload("res://resources/sprite_frames/drowned_coast_reef_tidecaller_vfx_sprite_frames.tres")
const BUBBLE_ORB_SCENE := preload("res://scenes/projectiles/enemy_bubble_orb.tscn")
const WAVE_SPIT_SCENE := preload("res://scenes/projectiles/enemy_wave_spit.tscn")

const CHASE_SPEED: float = PhysicsModel.TILE_SIZE_PX * 2.0
const PREFERRED_RANGE: float = PhysicsModel.TILE_SIZE_PX * 4.5
const MAX_ATTACK_RANGE: float = PhysicsModel.TILE_SIZE_PX * 8.0
const VERTICAL_TOLERANCE: float = PhysicsModel.TILE_SIZE_PX * 2.4
const ATTACK_COOLDOWN: float = 1.75
const CAST_WINDUP: float = 0.68
const CAST_RECOVERY: float = 0.38
const DEATH_CLEANUP_DELAY: float = 0.9
const WAVE_DAMAGE: float = 15.0
const WAVE_HIT_RADIUS: float = PhysicsModel.TILE_SIZE_PX * 1.9

var _state: State = State.IDLE
var _target: CharacterBase = null
var _facing: int = 1
var _attack_cooldown: float = 0.65
var _cast_windup_remaining: float = 0.0
var _cast_recovery_remaining: float = 0.0
var _current_attack: AttackKind = AttackKind.ORB
var _attack_index: int = 0
var _life_version: int = 0
var _death_cleanup_timer: Timer = null
var _death_cleanup_deadline_ms: int = 0

@onready var sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var attack_alert: Label = %AttackAlert
@onready var hit_spark: Polygon2D = %HitSpark
@onready var damage_popup: Label = %DamagePopup
@onready var health_bar: Node2D = %HealthBar
@onready var health_fill: ColorRect = %Fill
@onready var hurtbox: Area2D = %Hurtbox
@onready var detection: Area2D = %DetectionArea2D

func _ready() -> void:
	super._ready()
	max_health = maxf(max_health, 105.0)
	current_health = max_health
	damage = maxf(damage, 12.0)
	detection.body_entered.connect(_on_detection_body_entered)
	detection.body_exited.connect(_on_detection_body_exited)
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	attack_alert.visible = false
	hit_spark.visible = false
	damage_popup.visible = false
	_update_health_bar()
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(&"idle"):
		sprite.play(&"idle")

func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		if _death_cleanup_deadline_ms > 0 and Time.get_ticks_msec() >= _death_cleanup_deadline_ms:
			_finish_death_cleanup(_life_version)
		return

	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	velocity.y += gravity * delta
	match _state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, CHASE_SPEED * delta)
		State.CHASE:
			_process_chase(delta)
		State.CAST:
			_process_cast(delta)
	move_and_slide()

func _process_chase(delta: float) -> void:
	if not is_instance_valid(_target):
		_state = State.IDLE
		_play_body_loop(&"idle")
		return
	_face_target()
	var delta_to_target := _target.global_position - global_position
	var horizontal_distance := absf(delta_to_target.x)
	var vertical_distance := absf(delta_to_target.y)
	if horizontal_distance <= MAX_ATTACK_RANGE and vertical_distance <= VERTICAL_TOLERANCE and _attack_cooldown <= 0.0:
		_start_cast()
		return

	var direction: float = sign(delta_to_target.x)
	if horizontal_distance < PREFERRED_RANGE:
		direction = -direction
	if is_zero_approx(direction):
		direction = float(_facing)
	velocity.x = move_toward(velocity.x, direction * CHASE_SPEED, CHASE_SPEED * delta * 4.0)
	_play_body_loop(&"walk")

func _start_cast() -> void:
	_state = State.CAST
	velocity = Vector2.ZERO
	_cast_windup_remaining = CAST_WINDUP
	_cast_recovery_remaining = CAST_RECOVERY
	_attack_index += 1
	_current_attack = AttackKind.WAVE if _attack_index % 3 == 0 else AttackKind.ORB
	_face_target()
	attack_alert.visible = true
	attack_alert.modulate = Color(0.45, 0.95, 1.0, 1.0)
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(&"attack"):
		sprite.play(&"attack")
	ENEMY_VFX.spawn(get_parent(), ELITE_VFX_FRAMES, &"enemy_cast_charge", global_position + Vector2(0, -20), false, Vector2.ONE, 10)
	var alert_tween := create_tween().set_loops(3)
	alert_tween.tween_property(attack_alert, "modulate:a", 0.2, 0.08)
	alert_tween.tween_property(attack_alert, "modulate:a", 1.0, 0.08)

func _process_cast(delta: float) -> void:
	velocity = Vector2.ZERO
	if not is_instance_valid(_target):
		_finish_cast()
		return
	_face_target()
	if _cast_windup_remaining > 0.0:
		_cast_windup_remaining = maxf(0.0, _cast_windup_remaining - delta)
		if _cast_windup_remaining <= 0.0:
			_release_attack()
		return
	_cast_recovery_remaining = maxf(0.0, _cast_recovery_remaining - delta)
	if _cast_recovery_remaining <= 0.0:
		_finish_cast()

func _release_attack() -> void:
	attack_alert.visible = false
	_play_audio_sfx(&"boss_attack", -4.0)
	if _current_attack == AttackKind.WAVE:
		_release_wave_warning()
	else:
		_release_bubble_orb()
	_attack_cooldown = ATTACK_COOLDOWN

func _release_bubble_orb() -> void:
	var orb := BUBBLE_ORB_SCENE.instantiate() as EnemyHydroProjectile
	get_parent().add_child(orb)
	var origin := global_position + Vector2(24.0 * float(_facing), -20.0)
	var direction := (_target.global_position + Vector2(0, -12) - origin).normalized()
	orb.launch(origin, direction)

func _release_wave_warning() -> void:
	var target_position := _target.global_position + Vector2(0, -4)
	ENEMY_VFX.spawn(get_parent(), ELITE_VFX_FRAMES, &"area_warning_wave", target_position, false, Vector2.ONE, 8)
	var timer := get_tree().create_timer(0.34)
	timer.timeout.connect(_strike_wave.bind(target_position), CONNECT_ONE_SHOT)

func _strike_wave(target_position: Vector2) -> void:
	if _state == State.DEAD:
		return
	var wave := WAVE_SPIT_SCENE.instantiate() as EnemyHydroProjectile
	get_parent().add_child(wave)
	wave.damage = 0.0
	var origin := global_position + Vector2(22.0 * float(_facing), -18.0)
	var direction := (target_position - origin).normalized()
	wave.launch(origin, direction)
	ENEMY_VFX.spawn(get_parent(), ELITE_VFX_FRAMES, &"large_splash_hit", target_position, false, Vector2.ONE, 11)
	if is_instance_valid(_target) and _target.global_position.distance_to(target_position) <= WAVE_HIT_RADIUS:
		_target.take_damage(WAVE_DAMAGE)

func _finish_cast() -> void:
	attack_alert.visible = false
	if is_instance_valid(_target):
		_state = State.CHASE
	else:
		_state = State.IDLE
	if _state != State.DEAD:
		_play_body_loop(&"walk" if _state == State.CHASE else &"idle")

func _play_body_loop(animation: StringName) -> void:
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(animation) and sprite.animation != animation:
		sprite.play(animation)

func _face_target() -> void:
	if not is_instance_valid(_target):
		return
	var dir: float = sign(_target.global_position.x - global_position.x)
	if is_zero_approx(dir):
		dir = float(_facing)
	_facing = int(dir)
	sprite.flip_h = _facing == -1

func _on_detection_body_entered(body: Node) -> void:
	if body is CharacterBase:
		_target = body
		if _state != State.CAST:
			_state = State.CHASE

func _on_detection_body_exited(body: Node) -> void:
	if body == _target:
		_target = null
		if _state != State.CAST:
			_state = State.IDLE
			_play_body_loop(&"idle")

func _on_hurtbox_area_entered(_area: Area2D) -> void:
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
	damage_popup.position = Vector2(-12, -56)
	damage_popup.modulate = Color.WHITE

	var spark_tween := create_tween()
	spark_tween.tween_property(hit_spark, "scale", Vector2(1.45, 1.45), 0.08)
	spark_tween.tween_property(hit_spark, "scale", Vector2.ZERO, 0.12)
	spark_tween.tween_callback(func() -> void: hit_spark.visible = false)

	var popup_tween := create_tween()
	popup_tween.tween_property(damage_popup, "position", Vector2(-12, -74), 0.35)
	popup_tween.parallel().tween_property(damage_popup, "modulate", Color(1, 1, 1, 0), 0.35)
	popup_tween.tween_callback(func() -> void: damage_popup.visible = false)

func _update_health_bar() -> void:
	var ratio: float = clampf(current_health / max_health, 0.0, 1.0)
	health_bar.visible = current_health > 0.0
	health_fill.size.x = 38.0 * ratio
	if ratio > 0.5:
		health_fill.color = Color(0.22, 0.8, 1.0)
	elif ratio > 0.25:
		health_fill.color = Color(0.72, 0.45, 1.0)
	else:
		health_fill.color = Color(1.0, 0.22, 0.36)

func die() -> void:
	_life_version += 1
	var death_version := _life_version
	_play_audio_sfx(&"enemy_death", -2.0)
	_state = State.DEAD
	velocity = Vector2.ZERO
	attack_alert.visible = false
	hit_spark.visible = false
	damage_popup.visible = false
	health_bar.visible = false
	collision_layer = 0
	collision_mask = 0
	hurtbox.collision_layer = 0
	detection.collision_mask = 0
	sprite.modulate = Color.WHITE
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(&"death"):
		sprite.play(&"death")
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
	_state = State.IDLE
	_target = null
	_facing = 1
	_attack_cooldown = 0.65
	_cast_windup_remaining = 0.0
	_cast_recovery_remaining = 0.0
	attack_alert.visible = false
	hit_spark.visible = false
	damage_popup.visible = false
	_update_health_bar()
	hurtbox.collision_layer = PhysicsModel.ENEMY_LAYER
	hurtbox.collision_mask = 0
	detection.collision_layer = 0
	detection.collision_mask = PhysicsModel.PLAYER_LAYER
	sprite.flip_h = false
	sprite.modulate = Color.WHITE
	_play_body_loop(&"idle")
