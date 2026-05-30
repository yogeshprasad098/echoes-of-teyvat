class_name StormPeakGrunt
extends Grunt

const STORM_VFX_FRAMES := preload("res://resources/sprite_frames/storm_peak_normal_enemy_vfx_sprite_frames.tres")
const ENEMY_VFX := preload("res://scripts/effects/enemy_vfx_effect.gd")

func _ready() -> void:
	super._ready()
	var claw := Gradient.new()
	claw.set_color(0, Color(0.08, 0.18, 0.32, 0.0))
	claw.add_point(0.42, Color(0.18, 0.78, 1.0, 0.95))
	claw.set_color(1, Color(0.72, 0.45, 1.0, 1.0))
	attack_arc.gradient = claw
	attack_arc.default_color = Color(0.35, 0.9, 1.0, 1.0)

func _apply_attack_hit() -> void:
	attack_alert.visible = false
	sprite.modulate = Color.WHITE
	_play_audio_sfx(&"boss_attack", -7.0)

	var claw_origin: Vector2 = global_position + Vector2(24.0 * _patrol_direction, -12.0)
	ENEMY_VFX.spawn(
		get_parent(),
		STORM_VFX_FRAMES,
		&"shock_claw_arc",
		claw_origin,
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
		_add_screen_shake(0.4)
		_freeze_hit_stop(0.08)
		ENEMY_VFX.spawn(
			get_parent(),
			STORM_VFX_FRAMES,
			&"shock_hit",
			_target.global_position + Vector2(0, -12),
			false,
			Vector2.ONE,
			10
		)
	else:
		ENEMY_VFX.spawn(
			get_parent(),
			STORM_VFX_FRAMES,
			&"static_pop",
			claw_origin,
			false,
			Vector2.ONE,
			10
		)
