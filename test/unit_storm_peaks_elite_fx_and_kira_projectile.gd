extends SceneTree

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	_check_kira_skill_height()
	await _check_elite_cast_vfx_cleanup()
	await _check_looping_enemy_vfx_self_cleans()

	if _failures.is_empty():
		print("RESULT: PASS storm peaks elite fx and Kira projectile")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		print("RESULT: FAIL %d storm peaks elite fx item(s)" % _failures.size())
		quit(1)

func _check_kira_skill_height() -> void:
	_expect(is_equal_approx(Kira.SKILL_PROJECTILE_SPAWN_OFFSET.y, -24.0), "Kira skill projectile spawns lower for Storm Peaks elite hurtboxes")

func _check_elite_cast_vfx_cleanup() -> void:
	var root := Node2D.new()
	root.name = "StormEliteFxTestRoot"
	get_root().add_child(root)

	var elite := load("res://scenes/enemies/elite_storm_caster.tscn").instantiate() as EliteEnemy
	root.add_child(elite)
	var target := CharacterBase.new()
	root.add_child(target)
	target.global_position = elite.global_position + Vector2(96.0, 0.0)
	await process_frame

	elite._target = target
	elite._start_cast()
	await process_frame
	_expect(_count_vfx(root, &"enemy_cast_charge") == 1, "Storm elite starts one cast charge VFX")

	elite._release_attack()
	await process_frame
	_expect(_count_vfx(root, &"enemy_cast_charge") == 0, "Storm elite clears cast charge VFX when attack releases")

	elite._current_attack = EliteEnemy.AttackKind.LINE
	elite._release_lightning_line()
	await process_frame
	_expect(_count_vfx(root, &"lightning_line_warning") == 1, "Storm elite starts one lightning warning VFX")
	elite._strike_lightning_line(elite.global_position + Vector2(48.0, -12.0), false)
	await process_frame
	_expect(_count_vfx(root, &"lightning_line_warning") == 0, "Storm elite clears lightning warning VFX when strike lands")
	_expect(_count_vfx(root, &"lightning_line_segment") == 1, "Storm elite spawns the actual lightning strike segment")

	root.queue_free()
	await process_frame

func _check_looping_enemy_vfx_self_cleans() -> void:
	var root := Node2D.new()
	root.name = "EnemyVfxLoopCleanupTestRoot"
	get_root().add_child(root)

	EnemyVfxEffect.spawn(root, load("res://resources/sprite_frames/storm_peak_elite_enemy_vfx_sprite_frames.tres"), &"enemy_cast_charge", Vector2.ZERO)
	await create_timer(0.55).timeout
	_expect(_count_vfx(root, &"enemy_cast_charge") == 0, "Looping enemy one-shot VFX self-cleans after one cycle")

	root.queue_free()
	await process_frame

func _count_vfx(root: Node, animation: StringName) -> int:
	var count := 0
	for node in _collect_nodes(root):
		var sprite := node as AnimatedSprite2D
		if sprite != null and sprite.animation == animation and is_instance_valid(sprite):
			count += 1
	return count

func _collect_nodes(root: Node) -> Array[Node]:
	var nodes: Array[Node] = [root]
	for child in root.get_children():
		nodes.append_array(_collect_nodes(child))
	return nodes

func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_failures.append(message)
