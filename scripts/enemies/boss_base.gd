class_name BossBase
extends EnemyBase
## Shared base for one-screen boss arenas.

enum Pattern { FLAME_BURST, WATER_WAVE, LIGHTNING_BOLT, ASH_STOMP, EMBER_TYRANT }

const PLAYER_LAYER := 2
const ATTACK_COLORS: Array[Color] = [
	Color(1.0, 0.22, 0.06, 0.68),
	Color(0.15, 0.72, 1.0, 0.62),
	Color(0.85, 0.95, 1.0, 0.72),
	Color(0.62, 0.38, 0.18, 0.64),
	Color(1.0, 0.42, 0.08, 0.70),
]

@export var boss_display_name: String = "Boss"
@export var boss_pattern: Pattern = Pattern.FLAME_BURST
@export var attack_interval_sec: float = 2.4
@export var attack_windup_sec: float = 0.75
@export var attack_active_sec: float = 0.22
@export var arena_left_x: float = 32.0
@export var arena_right_x: float = 608.0
@export var preferred_range_px: float = 160.0
@export var movement_dead_zone_px: float = 24.0

var _target: CharacterBase = null
var _attack_timer: Timer = null
var _active_warning: Node2D = null
var _is_dead: bool = false

@onready var sprite: AnimatedSprite2D = get_node_or_null("%AnimatedSprite2D") as AnimatedSprite2D
@onready var hit_spark: Polygon2D = get_node_or_null("%HitSpark") as Polygon2D
@onready var damage_popup: Label = get_node_or_null("%DamagePopup") as Label
@onready var health_bar: Node2D = get_node_or_null("%HealthBar") as Node2D
@onready var health_fill: ColorRect = get_node_or_null("%Fill") as ColorRect

func _ready() -> void:
	super._ready()
	_attack_timer = Timer.new()
	_attack_timer.one_shot = false
	_attack_timer.wait_time = attack_interval_sec
	_attack_timer.timeout.connect(_start_attack)
	add_child(_attack_timer)
	_attack_timer.start()
	_update_health_bar()
	if sprite:
		sprite.play(&"walk")
		_apply_pattern_tint()
	if hit_spark:
		hit_spark.visible = false
	if damage_popup:
		damage_popup.visible = false

func _physics_process(delta: float) -> void:
	if _is_dead:
		return
	velocity.y += gravity * delta
	_find_target()
	_update_movement(delta)
	move_and_slide()
	if is_instance_valid(_target) and sprite:
		sprite.flip_h = _target.global_position.x < global_position.x

func take_damage(amount: float, element: String = "") -> void:
	if _is_dead:
		return
	super.take_damage(amount, element)
	_update_health_bar()
	_show_damage_feedback(last_damage_taken)

func die() -> void:
	if _is_dead:
		return
	_is_dead = true
	_play_audio_sfx(&"boss_defeat", -1.0, 0.0)
	if _attack_timer:
		_attack_timer.stop()
	if _active_warning:
		_active_warning.queue_free()
	collision_layer = 0
	collision_mask = 0
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	died.emit()

func reset_for_run() -> void:
	_is_dead = false
	if _active_warning:
		_active_warning.queue_free()
		_active_warning = null
	super.reset_for_run()
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	_update_health_bar()
	if sprite:
		sprite.play(&"walk")
		_apply_pattern_tint()
	if _attack_timer:
		_attack_timer.start(attack_interval_sec)

func _start_attack() -> void:
	if _is_dead:
		return
	_find_target()
	if not is_instance_valid(_target):
		return
	_play_audio_sfx(&"boss_attack", -1.5)
	var pattern := boss_pattern
	if boss_pattern == Pattern.EMBER_TYRANT:
		pattern = Pattern.FLAME_BURST if randi() % 2 == 0 else Pattern.ASH_STOMP
	match pattern:
		Pattern.FLAME_BURST:
			_cast_zone(Vector2(_target.global_position.x, 320.0), Vector2(96, 48), Pattern.FLAME_BURST)
		Pattern.WATER_WAVE:
			var start_x := arena_left_x if _target.global_position.x > global_position.x else arena_right_x
			_cast_sweep(Vector2(start_x, 320.0), Vector2(96, 42), Pattern.WATER_WAVE)
		Pattern.LIGHTNING_BOLT:
			_cast_zone(Vector2(_target.global_position.x, 248.0), Vector2(40, 192), Pattern.LIGHTNING_BOLT)
		Pattern.ASH_STOMP:
			_cast_zone(Vector2(global_position.x, 320.0), Vector2(160, 54), Pattern.ASH_STOMP)

func _cast_zone(center: Vector2, size: Vector2, pattern: Pattern) -> void:
	var warning := _create_warning(center, size, pattern)
	await get_tree().create_timer(attack_windup_sec).timeout
	if _is_dead or not is_instance_valid(warning):
		return
	_apply_warning_hit(warning, size)
	await get_tree().create_timer(attack_active_sec).timeout
	if is_instance_valid(warning):
		warning.queue_free()

func _cast_sweep(start: Vector2, size: Vector2, pattern: Pattern) -> void:
	var warning := _create_warning(start, size, pattern)
	await get_tree().create_timer(attack_windup_sec).timeout
	if _is_dead or not is_instance_valid(warning):
		return
	var tween := create_tween()
	tween.tween_property(warning, "global_position:x", arena_right_x if start.x <= arena_left_x else arena_left_x, 0.75)
	for index in 8:
		await get_tree().create_timer(0.1).timeout
		if _is_dead or not is_instance_valid(warning):
			return
		_apply_warning_hit(warning, size)
	if is_instance_valid(warning):
		warning.queue_free()

func _create_warning(center: Vector2, size: Vector2, pattern: Pattern) -> Node2D:
	if _active_warning:
		_active_warning.queue_free()
	var warning := Node2D.new()
	warning.name = "BossAttackTelegraph"
	warning.global_position = center
	warning.z_index = 3
	var warning_color := _warning_vfx_color(pattern)
	match pattern:
		Pattern.WATER_WAVE:
			_add_wave_warning_vfx(warning, size, warning_color)
		Pattern.LIGHTNING_BOLT:
			_add_bolt_warning_vfx(warning, size, warning_color)
		_:
			_add_burst_warning_vfx(warning, size, warning_color)
	_add_warning_particles(warning, size, warning_color)
	add_sibling(warning)
	_animate_warning_vfx(warning)
	_active_warning = warning
	return warning

func _warning_vfx_color(pattern: Pattern) -> Color:
	var color := ATTACK_COLORS[int(pattern)]
	return Color(color.r, color.g, color.b, 0.78)

func _add_burst_warning_vfx(warning: Node2D, size: Vector2, color: Color) -> void:
	for scale_factor in [0.48, 0.72, 0.98]:
		var ring := _make_ellipse_line(size * scale_factor, color, 3.0)
		ring.modulate.a = 0.75
		warning.add_child(ring)
	var flare := Polygon2D.new()
	var points := PackedVector2Array()
	var half := size * 0.5
	for index in 12:
		var angle := TAU * float(index) / 12.0
		var radius := half * (0.45 if index % 2 == 0 else 0.18)
		points.append(Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	flare.polygon = points
	flare.color = Color(color.r, color.g, color.b, 0.16)
	warning.add_child(flare)

func _add_wave_warning_vfx(warning: Node2D, size: Vector2, color: Color) -> void:
	var half := size * 0.5
	var wave_rows: Array[float] = [-0.22, 0.0, 0.22]
	for row: float in wave_rows:
		var line := Line2D.new()
		line.width = 4.0
		line.default_color = color
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		for index in 9:
			var ratio: float = float(index) / 8.0
			var x: float = lerpf(-half.x, half.x, ratio)
			var y: float = size.y * row + sin(ratio * TAU * 2.0) * 7.0
			line.add_point(Vector2(x, y))
		warning.add_child(line)

func _add_bolt_warning_vfx(warning: Node2D, size: Vector2, color: Color) -> void:
	var half := size * 0.5
	var bolt := Line2D.new()
	bolt.width = 5.0
	bolt.default_color = color
	bolt.joint_mode = Line2D.LINE_JOINT_SHARP
	bolt.begin_cap_mode = Line2D.LINE_CAP_ROUND
	bolt.end_cap_mode = Line2D.LINE_CAP_ROUND
	var offsets: Array[float] = [-0.15, 0.18, -0.08, 0.22, -0.2, 0.1]
	for index in 7:
		var ratio: float = float(index) / 6.0
		var y: float = lerpf(-half.y, half.y, ratio)
		var x: float = size.x * offsets[index % offsets.size()]
		bolt.add_point(Vector2(x, y))
	warning.add_child(bolt)
	var branch_sides: Array[float] = [-1.0, 1.0]
	for side: float in branch_sides:
		var branch := Line2D.new()
		branch.width = 2.5
		branch.default_color = Color(color.r, color.g, color.b, 0.55)
		branch.add_point(Vector2(0.0, -half.y * 0.2))
		branch.add_point(Vector2(side * half.x * 0.6, half.y * 0.05))
		warning.add_child(branch)

func _add_warning_particles(warning: Node2D, size: Vector2, color: Color) -> void:
	var particles := GPUParticles2D.new()
	particles.name = "WarningSparks"
	particles.amount = 18
	particles.lifetime = 0.45
	particles.one_shot = false
	particles.explosiveness = 0.45
	particles.local_coords = true
	var particle_material := ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	particle_material.emission_box_extents = Vector3(size.x * 0.5, size.y * 0.5, 0.0)
	particle_material.gravity = Vector3.ZERO
	particle_material.initial_velocity_min = 8.0
	particle_material.initial_velocity_max = 28.0
	particle_material.scale_min = 1.4
	particle_material.scale_max = 2.8
	particle_material.color = Color(color.r, color.g, color.b, 0.62)
	particles.process_material = particle_material
	particles.emitting = true
	warning.add_child(particles)

func _animate_warning_vfx(warning: Node2D) -> void:
	warning.scale = Vector2(0.92, 0.92)
	var tween := create_tween()
	tween.bind_node(warning)
	tween.set_loops()
	tween.set_parallel(true)
	tween.tween_property(warning, "scale", Vector2(1.06, 1.06), 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(warning, "modulate:a", 0.56, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.chain()
	tween.set_parallel(true)
	tween.tween_property(warning, "scale", Vector2(0.94, 0.94), 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(warning, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _make_ellipse_line(size: Vector2, color: Color, width: float) -> Line2D:
	var line := Line2D.new()
	line.width = width
	line.default_color = color
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.closed = true
	var half := size * 0.5
	for index in 28:
		var angle := TAU * float(index) / 28.0
		line.add_point(Vector2(cos(angle) * half.x, sin(angle) * half.y))
	return line

func _apply_warning_hit(warning: Node2D, size: Vector2) -> void:
	_find_target()
	if not is_instance_valid(_target):
		return
	var half := size * 0.5
	var delta_to_target := _target.global_position - warning.global_position
	if absf(delta_to_target.x) <= half.x and absf(delta_to_target.y) <= half.y:
		_target.take_damage(damage)

func _find_target() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var switcher := tree.root.get_node_or_null("CharacterSwitcher")
	if switcher and switcher.has_method("active"):
		var active_node: Object = switcher.call("active")
		if is_instance_valid(active_node) and active_node is CharacterBase:
			var active := active_node as CharacterBase
			if active.is_inside_tree() and _shares_area_with(active):
				_target = active
				return
	var current := get_parent()
	while current != null:
		var party := current.get_node_or_null("Party")
		if party:
			var kira := party.get_node_or_null("Kira") as CharacterBase
			if kira:
				_target = kira
				return
		current = current.get_parent()

func _shares_area_with(candidate: Node) -> bool:
	var current := get_parent()
	while current != null:
		if current == candidate or current.is_ancestor_of(candidate):
			return true
		current = current.get_parent()
	return false

func _update_movement(delta: float) -> void:
	if not is_instance_valid(_target):
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 4.0 * delta)
		return
	var distance_x := _target.global_position.x - global_position.x
	var desired_velocity := 0.0
	if absf(distance_x) > preferred_range_px + movement_dead_zone_px:
		desired_velocity = signf(distance_x) * move_speed
	elif absf(distance_x) < preferred_range_px - movement_dead_zone_px:
		desired_velocity = -signf(distance_x) * move_speed * 0.6
	velocity.x = move_toward(velocity.x, desired_velocity, move_speed * 5.0 * delta)
	if global_position.x <= arena_left_x and velocity.x < 0.0:
		velocity.x = 0.0
	elif global_position.x >= arena_right_x and velocity.x > 0.0:
		velocity.x = 0.0

func _apply_pattern_tint() -> void:
	var color := ATTACK_COLORS[int(boss_pattern)]
	sprite.modulate = Color(color.r, color.g, color.b, 1.0)

func _show_damage_feedback(amount: float) -> void:
	if hit_spark:
		hit_spark.visible = true
		hit_spark.scale = Vector2.ONE
		var spark_tween := create_tween()
		spark_tween.tween_property(hit_spark, "scale", Vector2(1.6, 1.6), 0.08)
		spark_tween.tween_property(hit_spark, "scale", Vector2.ZERO, 0.12)
		spark_tween.tween_callback(func() -> void: hit_spark.visible = false)
	if damage_popup:
		damage_popup.visible = true
		damage_popup.text = "-%d" % int(amount)
		damage_popup.modulate = Color.WHITE
		var popup_tween := create_tween()
		popup_tween.tween_property(damage_popup, "position", Vector2(-18, -84), 0.35)
		popup_tween.parallel().tween_property(damage_popup, "modulate", Color(1, 1, 1, 0), 0.35)
		popup_tween.tween_callback(func() -> void:
			damage_popup.visible = false
			damage_popup.position = Vector2(-18, -64)
		)

func _update_health_bar() -> void:
	if health_bar:
		health_bar.visible = current_health > 0.0
	if health_fill:
		var ratio := clampf(current_health / max_health, 0.0, 1.0)
		health_fill.size.x = 96.0 * ratio
