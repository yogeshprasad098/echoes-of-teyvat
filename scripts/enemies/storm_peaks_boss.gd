class_name StormPeaksBoss
extends BossBase

const ENEMY_VFX := preload("res://scripts/effects/enemy_vfx_effect.gd")
const BOSS_VFX_FRAMES := preload("res://resources/sprite_frames/storm_peaks_boss_enemy_vfx_sprite_frames.tres")
const SPARK_BOLT_SCENE := preload("res://scenes/projectiles/storm_peaks_boss_spark_bolt.tscn")
const ELECTRIC_ORB_SCENE := preload("res://scenes/projectiles/storm_peaks_boss_electric_orb.tscn")
const LIGHTNING_LINE_SCENE := preload("res://scenes/projectiles/storm_peaks_boss_lightning_line.tscn")

@export_range(1, 5) var storm_boss_level: int = 1

var _attack_index: int = 0
var _is_casting: bool = false

func _ready() -> void:
	super._ready()
	_apply_level_pressure()

func _start_attack() -> void:
	if _is_dead or _is_casting:
		return
	_find_target()
	if not is_instance_valid(_target):
		return

	_is_casting = true
	_attack_index += 1
	_play_audio_sfx(&"boss_attack", -2.5)
	var target_position := _target.global_position + Vector2(0, -10)
	var warning := _create_warning(target_position + Vector2(0, 12), Vector2(128, 58), Pattern.LIGHTNING_BOLT)
	_spawn_vfx(&"enemy_cast_charge", global_position + Vector2(0, -44), Vector2.ONE, 12)
	await get_tree().create_timer(maxf(0.22, attack_windup_sec * 0.55)).timeout
	if _is_dead or not is_instance_valid(_target):
		_is_casting = false
		return

	match storm_boss_level:
		1:
			_attack_spark_striker()
		2:
			_attack_static_channeler()
		3:
			_attack_thunder_duelist()
		4:
			await _attack_pylon_breaker()
		_:
			await _attack_tempest_ascendant()

	await get_tree().create_timer(0.18).timeout
	if is_instance_valid(warning):
		warning.queue_free()
		if _active_warning == warning:
			_active_warning = null
	_is_casting = false

func _attack_spark_striker() -> void:
	_fire_projectile(SPARK_BOLT_SCENE, 10.0, 292.0, _target.global_position + Vector2(0, -18))
	_spawn_vfx(&"static_pop", _target.global_position + Vector2(0, -8), Vector2(0.75, 0.75), 11)

func _attack_static_channeler() -> void:
	_fire_projectile(ELECTRIC_ORB_SCENE, 13.0, 172.0, _target.global_position + Vector2(0, -18))
	if _attack_index % 2 == 0:
		_fire_projectile(SPARK_BOLT_SCENE, 8.0, 268.0, _target.global_position + Vector2(-22, -24), Vector2(-24, -42))

func _attack_thunder_duelist() -> void:
	var target_position := _target.global_position + Vector2(0, -10)
	_spawn_vfx(&"area_warning", target_position + Vector2(0, 18), Vector2.ONE, 6)
	_fire_projectile(LIGHTNING_LINE_SCENE, 15.0, 330.0, target_position)
	if _attack_index % 2 == 0:
		_fire_projectile(SPARK_BOLT_SCENE, 9.0, 288.0, target_position + Vector2(26, -26), Vector2(26, -42))

func _attack_pylon_breaker() -> void:
	var target_position := _target.global_position + Vector2(0, 6)
	_spawn_vfx(&"area_warning", target_position, Vector2(1.08, 0.92), 6)
	await get_tree().create_timer(0.16).timeout
	if _is_dead or not is_instance_valid(_target):
		return
	_spawn_vfx(&"electric_burst", target_position, Vector2.ONE, 11)
	if _target.global_position.distance_to(target_position) <= 78.0:
		_target.take_damage(17.0)
	_fire_projectile(ELECTRIC_ORB_SCENE, 11.0, 164.0, _target.global_position + Vector2(0, -18))

func _attack_tempest_ascendant() -> void:
	var branch := _attack_index % 3
	if branch == 0:
		_fire_spread_bolts()
	elif branch == 1:
		_attack_static_channeler()
	else:
		_attack_thunder_duelist()
		await get_tree().create_timer(0.14).timeout
		if not _is_dead and is_instance_valid(_target):
			_fire_projectile(ELECTRIC_ORB_SCENE, 12.0, 188.0, _target.global_position + Vector2(0, -24), Vector2(32, -46))

func _fire_spread_bolts() -> void:
	var origin := global_position + Vector2(30.0 * _facing_to_target(), -36.0)
	var aim := (_target.global_position + Vector2(0, -20) - origin).normalized()
	for angle: float in [-0.22, 0.0, 0.22]:
		var projectile := SPARK_BOLT_SCENE.instantiate() as EnemyHydroProjectile
		get_parent().add_child(projectile)
		projectile.damage = 9.0
		projectile.speed = 304.0
		projectile.launch(origin, aim.rotated(angle))

func _fire_projectile(
	scene: PackedScene,
	projectile_damage: float,
	projectile_speed: float,
	target_position: Vector2,
	origin_offset: Vector2 = Vector2(30, -36)
) -> void:
	var projectile := scene.instantiate() as EnemyHydroProjectile
	get_parent().add_child(projectile)
	projectile.damage = projectile_damage
	projectile.speed = projectile_speed
	var origin := global_position + Vector2(origin_offset.x * _facing_to_target(), origin_offset.y)
	projectile.launch(origin, target_position - origin)

func _spawn_vfx(animation: StringName, world_position: Vector2, scale_value: Vector2, z: int) -> void:
	ENEMY_VFX.spawn(get_parent(), BOSS_VFX_FRAMES, animation, world_position, false, scale_value, z)

func _facing_to_target() -> float:
	if not is_instance_valid(_target):
		return 1.0
	var direction := signf(_target.global_position.x - global_position.x)
	return direction if not is_zero_approx(direction) else 1.0

func _apply_level_pressure() -> void:
	match storm_boss_level:
		1:
			attack_interval_sec = minf(attack_interval_sec, 2.35)
		2:
			attack_interval_sec = minf(attack_interval_sec, 2.15)
		3:
			attack_interval_sec = minf(attack_interval_sec, 1.98)
		4:
			attack_interval_sec = minf(attack_interval_sec, 1.84)
		_:
			attack_interval_sec = minf(attack_interval_sec, 1.62)
	if _attack_timer:
		_attack_timer.wait_time = attack_interval_sec
		_attack_timer.start(attack_interval_sec)

func _apply_pattern_tint() -> void:
	if sprite:
		sprite.modulate = Color.WHITE
