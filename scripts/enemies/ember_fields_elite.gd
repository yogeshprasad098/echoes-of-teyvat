class_name EmberFieldsElite
extends EnemyBase
## Ember Fields elite caster. Stays grounded, telegraphs lava attacks, then
## releases map-native projectiles/VFX that do not use player elemental reactions.

enum State { IDLE, CHASE, CAST, DEAD }
enum AttackKind { LAVA_SPIT, FLAME_WAVE, AREA_WARNING }

const ENEMY_VFX := preload("res://scripts/effects/enemy_vfx_effect.gd")
const ELITE_VFX_FRAMES := preload("res://resources/sprite_frames/ember_fields_elite_enemy_vfx_sprite_frames.tres")
const LAVA_SPIT_SCENE := preload("res://scenes/projectiles/ember_elite_lava_spit.tscn")
const FLAME_WAVE_SCENE := preload("res://scenes/projectiles/ember_elite_flame_wave.tscn")

const MAX_ATTACK_RANGE: float = PhysicsModel.TILE_SIZE_PX * 8.0
const VERTICAL_TOLERANCE: float = PhysicsModel.TILE_SIZE_PX * 2.0
const ATTACK_COOLDOWN: float = 1.5
const CAST_WINDUP: float = 0.58
const CAST_RECOVERY: float = 0.34
const DEATH_CLEANUP_DELAY: float = 0.9
const AREA_DAMAGE: float = 16.0
const AREA_RADIUS: float = PhysicsModel.TILE_SIZE_PX * 2.0
const AREA_WARNING_DELAY: float = 0.42

var _state: State = State.IDLE
var _target: CharacterBase = null
var _facing: int = 1
var _attack_cooldown: float = 0.45
var _cast_windup_remaining: float = 0.0
var _cast_recovery_remaining: float = 0.0
var _current_attack: AttackKind = AttackKind.LAVA_SPIT
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
	max_health = maxf(max_health, 120.0)
	current_health = max_health
	damage = maxf(damage, 14.0)
	detection.body_entered.connect(_on_detection_body_entered)
	detection.body_exited.connect(_on_detection_body_exited)
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	attack_alert.visible = false
	hit_spark.visible = false
	damage_popup.visible = false
	_update_health_bar()
	_play_grounded_idle()

func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		if _death_cleanup_deadline_ms > 0 and Time.get_ticks_msec() >= _death_cleanup_deadline_ms:
			_finish_death_cleanup(_life_version)
		return

	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	velocity.y += gravity * delta
	match _state:
		State.IDLE:
			_process_grounded_idle()
		State.CHASE:
			_process_grounded_idle()
		State.CAST:
			_process_cast(delta)
	move_and_slide()

func _process_grounded_idle() -> void:
	velocity.x = 0.0
	if not is_instance_valid(_target):
		_state = State.IDLE
		_play_grounded_idle()
		return
	_face_target()
	var delta_to_target := _target.global_position - global_position
	var horizontal_distance := absf(delta_to_target.x)
	var vertical_distance := absf(delta_to_target.y)
	if horizontal_distance <= MAX_ATTACK_RANGE and vertical_distance <= VERTICAL_TOLERANCE and _attack_cooldown <= 0.0:
		_start_cast()
		return
	_state = State.CHASE
	_play_grounded_idle()

func _play_grounded_idle() -> void:
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(&"idle") and sprite.animation != &"idle":
		sprite.play(&"idle")

func _start_cast() -> void:
	_state = State.CAST
	velocity = Vector2.ZERO
	_cast_windup_remaining = CAST_WINDUP
	_cast_recovery_remaining = CAST_RECOVERY
	_attack_index += 1
	if _attack_index % 4 == 0:
		_current_attack = AttackKind.AREA_WARNING
	elif _attack_index % 2 == 0:
		_current_attack = AttackKind.FLAME_WAVE
	else:
		_current_attack = AttackKind.LAVA_SPIT
	_face_target()
	attack_alert.visible = true
	attack_alert.modulate = Color(1.0, 0.48, 0.1, 1.0)
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(&"cast"):
		sprite.play(&"cast")
	ENEMY_VFX.spawn(get_parent(), ELITE_VFX_FRAMES, &"elite_cast_charge", global_position + Vector2(0, -34), false, Vector2.ONE, 10)
	var alert_tween := create_tween().set_loops(3)
	alert_tween.tween_property(attack_alert, "modulate:a", 0.2, 0.08)
	alert_tween.tween_property(attack_alert, "modulate:a", 1.0, 0.08)

func _process_cast(delta: float) -> void:
	velocity.x = 0.0
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
	_play_audio_sfx(&"boss_attack", -3.0)
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(&"attack"):
		sprite.play(&"attack")
	match _current_attack:
		AttackKind.FLAME_WAVE:
			_release_flame_wave()
		AttackKind.AREA_WARNING:
			_release_area_warning()
		_:
			_release_lava_spit()
	_attack_cooldown = ATTACK_COOLDOWN

func _release_lava_spit() -> void:
	var projectile := LAVA_SPIT_SCENE.instantiate() as EnemyHydroProjectile
	get_parent().add_child(projectile)
	var origin := global_position + Vector2(24.0 * float(_facing), -24.0)
	var direction := (_target.global_position + Vector2(0, -12) - origin).normalized()
	projectile.launch(origin, direction)

func _release_flame_wave() -> void:
	var projectile := FLAME_WAVE_SCENE.instantiate() as EnemyHydroProjectile
	get_parent().add_child(projectile)
	var origin := global_position + Vector2(34.0 * float(_facing), -10.0)
	var direction := Vector2(float(_facing), 0.0)
	projectile.launch(origin, direction)

func _release_area_warning() -> void:
	var target_position := _target.global_position + Vector2(0, -8)
	ENEMY_VFX.spawn(get_parent(), ELITE_VFX_FRAMES, &"volcanic_area_warning", target_position, false, Vector2.ONE, 8)
	var timer := get_tree().create_timer(AREA_WARNING_DELAY)
	timer.timeout.connect(_strike_area_warning.bind(target_position), CONNECT_ONE_SHOT)

func _strike_area_warning(target_position: Vector2) -> void:
	if _state == State.DEAD:
		return
	ENEMY_VFX.spawn(get_parent(), ELITE_VFX_FRAMES, &"large_lava_splash", target_position, false, Vector2.ONE, 11)
	if is_instance_valid(_target) and _target.global_position.distance_to(target_position) <= AREA_RADIUS:
		_target.take_damage(AREA_DAMAGE)

func _finish_cast() -> void:
	attack_alert.visible = false
	if is_instance_valid(_target):
		_state = State.CHASE
	else:
		_state = State.IDLE
	if _state != State.DEAD:
		_play_grounded_idle()

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
	damage_popup.position = Vector2(-12, -64)
	damage_popup.modulate = Color.WHITE

	var spark_tween := create_tween()
	spark_tween.tween_property(hit_spark, "scale", Vector2(1.45, 1.45), 0.08)
	spark_tween.tween_property(hit_spark, "scale", Vector2.ZERO, 0.12)
	spark_tween.tween_callback(func() -> void: hit_spark.visible = false)

	var popup_tween := create_tween()
	popup_tween.tween_property(damage_popup, "position", Vector2(-12, -82), 0.35)
	popup_tween.parallel().tween_property(damage_popup, "modulate", Color(1, 1, 1, 0), 0.35)
	popup_tween.tween_callback(func() -> void: damage_popup.visible = false)

func _update_health_bar() -> void:
	var ratio: float = clampf(current_health / max_health, 0.0, 1.0)
	health_bar.visible = current_health > 0.0
	health_fill.size.x = 46.0 * ratio
	if ratio > 0.5:
		health_fill.color = Color(1.0, 0.46, 0.12)
	elif ratio > 0.25:
		health_fill.color = Color(1.0, 0.78, 0.12)
	else:
		health_fill.color = Color(1.0, 0.16, 0.08)

func die() -> void:
	_life_version += 1
	var death_version := _life_version
	_play_audio_sfx(&"enemy_death", -1.5)
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
	_attack_cooldown = 0.45
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
	_play_grounded_idle()
