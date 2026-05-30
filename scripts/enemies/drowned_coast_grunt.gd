class_name DrownedCoastGrunt
extends Grunt

const DROWNED_VFX_FRAMES := preload("res://resources/sprite_frames/drowned_coast_tide_grunt_vfx_sprite_frames.tres")
const ENEMY_VFX := preload("res://scripts/effects/enemy_vfx_effect.gd")

func _ready() -> void:
	super._ready()
	var water_claw := Gradient.new()
	water_claw.set_color(0, Color(0.02, 0.18, 0.24, 0.0))
	water_claw.add_point(0.42, Color(0.18, 0.78, 1.0, 0.95))
	water_claw.set_color(1, Color(0.7, 1.0, 0.92, 1.0))
	attack_arc.gradient = water_claw
	attack_arc.default_color = Color(0.25, 0.9, 1.0, 1.0)

func _apply_attack_hit() -> void:
	attack_alert.visible = false
	sprite.modulate = Color.WHITE
	_play_audio_sfx(&"boss_attack", -7.0)

	var strike_origin: Vector2 = global_position + Vector2(22.0 * _patrol_direction, -10.0)
	ENEMY_VFX.spawn(
		get_parent(),
		DROWNED_VFX_FRAMES,
		&"water_bullet",
		strike_origin,
		_patrol_direction == -1,
		Vector2.ONE,
		9
	)

	if _attack_has_hit:
		return

	_attack_has_hit = true
	_contact_cooldown = CONTACT_COOLDOWN
	var target_delta: Vector2 = _target.global_position - global_position if is_instance_valid(_target) else Vector2(INF, INF)
	var connected: bool = absf(target_delta.x) <= ATTACK_RANGE and absf(target_delta.y) < SEPARATION_Y_RANGE
	if connected:
		_target.take_damage(damage)
		_add_screen_shake(0.32)
		_freeze_hit_stop(0.06)
		ENEMY_VFX.spawn(
			get_parent(),
			DROWNED_VFX_FRAMES,
			&"splash_hit",
			_target.global_position + Vector2(0, -12),
			false,
			Vector2.ONE,
			10
		)
		ENEMY_VFX.spawn(
			get_parent(),
			DROWNED_VFX_FRAMES,
			&"wet_puddle",
			_target.global_position + Vector2(0, 8),
			false,
			Vector2.ONE,
			6
		)
	else:
		ENEMY_VFX.spawn(
			get_parent(),
			DROWNED_VFX_FRAMES,
			&"bubble_pop",
			strike_origin,
			false,
			Vector2.ONE,
			10
		)
