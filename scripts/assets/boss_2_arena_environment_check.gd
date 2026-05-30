extends SceneTree

const SCENE_PATH := "res://scenes/areas/ember_fields_boss_2_arena.tscn"

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame

	var packed := load(SCENE_PATH) as PackedScene
	_expect(packed != null, "Boss 2 arena scene loads")
	if packed == null:
		_finish()
		return

	var root := packed.instantiate()
	get_root().add_child(root)
	await process_frame

	_check_behavior_nodes(root)
	_check_environment_nodes(root)
	_check_collision_contract(root)
	_check_texture_sizes()

	root.queue_free()
	await process_frame
	_finish()

func _check_behavior_nodes(root: Node) -> void:
	_expect(root is BossArenaBase, "Root keeps BossArenaBase behavior")
	_expect(root.get_node_or_null("Party") != null, "Party node preserved")
	_expect(root.get_node_or_null("Party/Camera2D") != null, "Camera node preserved")
	_expect(root.get_node_or_null("Enemies/Boss") != null, "Boss node preserved")
	_expect(root.get_node_or_null("StartPoint") != null, "StartPoint preserved")
	_expect(root.get_node_or_null("CheckpointStart") != null, "CheckpointStart preserved")
	_expect((root as BossArenaBase).boss_node_path == NodePath("Enemies/Boss"), "Boss path still points to Enemies/Boss")

func _check_environment_nodes(root: Node) -> void:
	var required := [
		"ArenaEnvironment/Backdrop",
		"ArenaEnvironment/LavaDepth",
		"ArenaEnvironment/BossGatePortal",
		"ArenaEnvironment/LeftBoundaryWallVisual",
		"ArenaEnvironment/RightBoundaryWallVisual",
		"ArenaEnvironment/LeftSigilBanner",
		"ArenaEnvironment/RightSigilBanner",
		"ArenaEnvironment/ArenaFloorVisual",
		"ArenaEnvironment/ForegroundEdge",
	]
	for path in required:
		_expect(root.get_node_or_null(path) != null, "Environment node exists: %s" % path)
	_expect(root.get_node_or_null("ArenaFloorVisual") == null, "Old root ColorRect floor placeholder removed")
	_expect(root.get_node_or_null("LavaGlow") == null, "Old root ColorRect lava placeholder removed")

	var lava_depth := root.get_node_or_null("ArenaEnvironment/LavaDepth") as Sprite2D
	var floor_visual := root.get_node_or_null("ArenaEnvironment/ArenaFloorVisual") as Sprite2D
	var foreground_edge := root.get_node_or_null("ArenaEnvironment/ForegroundEdge") as Sprite2D
	_expect(lava_depth != null and lava_depth.position == Vector2(0, 300), "Lava/steam depth placed behind lower floor")
	_expect(floor_visual != null and floor_visual.position == Vector2(0, 296), "Floor art aligns with combat baseline")
	_expect(foreground_edge != null and foreground_edge.position == Vector2(0, 312), "Foreground edge sits in front of floor lip")

func _check_collision_contract(root: Node) -> void:
	var floor := root.get_node_or_null("Ground/FloorShape") as CollisionShape2D
	var left_wall := root.get_node_or_null("Ground/LeftWallShape") as CollisionShape2D
	var right_wall := root.get_node_or_null("Ground/RightWallShape") as CollisionShape2D
	_expect(floor != null and floor.position == Vector2(320, 360), "Floor collision position unchanged")
	_expect(left_wall != null and left_wall.position == Vector2(-16, 180), "Left wall collision position unchanged")
	_expect(right_wall != null and right_wall.position == Vector2(656, 180), "Right wall collision position unchanged")
	if floor:
		var floor_shape := floor.shape as RectangleShape2D
		_expect(floor_shape != null and floor_shape.size == Vector2(640, 32), "Floor collision rectangle unchanged")
	if left_wall:
		var wall_shape := left_wall.shape as RectangleShape2D
		_expect(wall_shape != null and wall_shape.size == Vector2(32, 360), "Wall collision rectangle unchanged")

func _check_texture_sizes() -> void:
	var expected := {
		"res://assets/map/ember_fields/boss_arenas/boss_2/boss_2_arena_backdrop.png": Vector2i(640, 360),
		"res://assets/map/ember_fields/boss_arenas/boss_2/boss_2_lava_steam_depth_layer.png": Vector2i(640, 96),
		"res://assets/platforms/ember_fields/boss_arenas/boss_2/boss_2_arena_floor_strip.png": Vector2i(640, 64),
		"res://assets/platforms/ember_fields/boss_arenas/boss_2/boss_2_boundary_wall_left.png": Vector2i(64, 360),
		"res://assets/platforms/ember_fields/boss_arenas/boss_2/boss_2_boundary_wall_right.png": Vector2i(64, 360),
		"res://assets/platforms/ember_fields/boss_arenas/boss_2/boss_2_foreground_edge.png": Vector2i(640, 48),
		"res://assets/props/ember_fields/boss_arenas/boss_2/boss_2_hydro_charred_sigil_banner.png": Vector2i(96, 160),
		"res://assets/props/ember_fields/boss_arenas/boss_2/boss_2_tide_gate_portal.png": Vector2i(160, 192),
	}
	for path in expected.keys():
		var texture := load(path) as Texture2D
		_expect(texture != null, "Texture loads: %s" % path)
		if texture:
			_expect(Vector2i(texture.get_width(), texture.get_height()) == expected[path], "Texture size matches: %s" % path)

func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("RESULT: PASS Boss 2 arena environment check")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	print("RESULT: FAIL %d Boss 2 arena environment item(s)" % _failures.size())
	quit(1)
