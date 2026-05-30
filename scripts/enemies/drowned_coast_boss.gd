class_name DrownedCoastBoss
extends BossBase

const ENEMY_VFX := preload("res://scripts/effects/enemy_vfx_effect.gd")
const BOSS_VFX_FRAMES := preload("res://resources/sprite_frames/drowned_coast_boss_enemy_vfx_sprite_frames.tres")
const BOSS_WATER_BULLET_SCENE := preload("res://scenes/projectiles/drowned_coast_boss_water_bullet.tscn")
const BOSS_BUBBLE_ORB_SCENE := preload("res://scenes/projectiles/drowned_coast_boss_bubble_orb.tscn")
const BOSS_WAVE_SPIT_SCENE := preload("res://scenes/projectiles/drowned_coast_boss_wave_spit.tscn")

@export_range(1, 5) var drowned_boss_level: int = 1

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
	var warning := _create_warning(_target.global_position + Vector2(0, 8), Vector2(128, 52), Pattern.WATER_WAVE)
	_spawn_vfx(&"enemy_cast_charge", global_position + Vector2(0, -42), Vector2.ONE, 12)
	await get_tree().create_timer(maxf(0.24, attack_windup_sec * 0.55)).timeout
	if _is_dead or not is_instance_valid(_target):
		_is_casting = false
		return

	match drowned_boss_level:
		1:
			_attack_tide_mauler()
		2:
			_attack_bubble_caster()
		3:
			_attack_reef_serpent_duelist()
		4:
			await _attack_abyssal_shellguard()
		_:
			await _attack_leviathan_oracle()

	await get_tree().create_timer(0.2).timeout
	if is_instance_valid(warning):
		warning.queue_free()
		if _active_warning == warning:
			_active_warning = null
	_is_casting = false

func _attack_tide_mauler() -> void:
	_fire_projectile(BOSS_WATER_BULLET_SCENE, 11.0, 248.0, _target.global_position + Vector2(0, -18))
	_spawn_vfx(&"wet_puddle", _target.global_position + Vector2(0, 10), Vector2(0.82, 0.82), 7)

func _attack_bubble_caster() -> void:
	_fire_projectile(BOSS_BUBBLE_ORB_SCENE, 13.0, 178.0, _target.global_position + Vector2(0, -16))
	if _attack_index % 2 == 0:
		_fire_projectile(BOSS_WATER_BULLET_SCENE, 8.0, 230.0, _target.global_position + Vector2(0, -20), Vector2(-18, -30))

func _attack_reef_serpent_duelist() -> void:
	var target_position := _target.global_position + Vector2(0, -6)
	_spawn_vfx(&"area_warning", target_position + Vector2(0, 12), Vector2.ONE, 6)
	_fire_projectile(BOSS_WAVE_SPIT_SCENE, 15.0, 224.0, target_position)
	if _attack_index % 2 == 0:
		_fire_projectile(BOSS_WATER_BULLET_SCENE, 9.0, 260.0, target_position + Vector2(0, -22), Vector2(-18, -42))

func _attack_abyssal_shellguard() -> void:
	var target_position := _target.global_position + Vector2(0, 8)
	_spawn_vfx(&"area_warning", target_position, Vector2(1.1, 0.9), 6)
	await get_tree().create_timer(0.18).timeout
	if _is_dead or not is_instance_valid(_target):
		return
	_spawn_vfx(&"splash_hit", target_position, Vector2.ONE, 11)
	_spawn_vfx(&"wet_puddle", target_position + Vector2(0, 10), Vector2.ONE, 7)
	if _target.global_position.distance_to(target_position) <= 72.0:
		_target.take_damage(16.0)
	_fire_projectile(BOSS_BUBBLE_ORB_SCENE, 10.0, 158.0, _target.global_position + Vector2(0, -18))

func _attack_leviathan_oracle() -> void:
	var branch := _attack_index % 3
	if branch == 0:
		_fire_spread_bullets()
	elif branch == 1:
		_attack_bubble_caster()
	else:
		_attack_reef_serpent_duelist()
		await get_tree().create_timer(0.16).timeout
		if not _is_dead and is_instance_valid(_target):
			_fire_projectile(BOSS_BUBBLE_ORB_SCENE, 12.0, 182.0, _target.global_position + Vector2(0, -20), Vector2(30, -44))

func _fire_spread_bullets() -> void:
	var origin := global_position + Vector2(28.0 * _facing_to_target(), -32.0)
	var aim := (_target.global_position + Vector2(0, -18) - origin).normalized()
	var angles: Array[float] = [-0.18, 0.0, 0.18]
	for angle: float in angles:
		var projectile := BOSS_WATER_BULLET_SCENE.instantiate() as EnemyHydroProjectile
		get_parent().add_child(projectile)
		projectile.damage = 10.0
		projectile.speed = 268.0
		projectile.launch(origin, aim.rotated(angle))

func _fire_projectile(
	scene: PackedScene,
	projectile_damage: float,
	projectile_speed: float,
	target_position: Vector2,
	origin_offset: Vector2 = Vector2(28, -30)
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
	match drowned_boss_level:
		1:
			attack_interval_sec = minf(attack_interval_sec, 2.45)
		2:
			attack_interval_sec = minf(attack_interval_sec, 2.25)
		3:
			attack_interval_sec = minf(attack_interval_sec, 2.1)
		4:
			attack_interval_sec = minf(attack_interval_sec, 1.95)
		_:
			attack_interval_sec = minf(attack_interval_sec, 1.75)
	if _attack_timer:
		_attack_timer.wait_time = attack_interval_sec
		_attack_timer.start(attack_interval_sec)

func _apply_pattern_tint() -> void:
	if sprite:
		sprite.modulate = Color.WHITE
