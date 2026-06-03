extends SceneTree

const SCENE_PATH := "res://scenes/areas/ember_fields_boss_5_arena.tscn"

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame

	var packed := load(SCENE_PATH) as PackedScene
	_expect(packed != null, "Boss 5 arena scene loads")
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
	_expect(root.get_node_or_null("ArenaEnvironment") == null, "Boss 5 arena removes boss-specific environment art")
	_expect(root.get_node_or_null("ParallaxBackground/BgFar/FallbackSprite") != null, "Clean Ember background node exists")
	_expect(root.get_node_or_null("ParallaxBackground/BgMid/Sprite2D") != null, "Clean Ember mid background node exists")
	_expect(root.get_node_or_null("ParallaxBackground/BgNear/Sprite2D") != null, "Clean Ember near background node exists")
	var bg := root.get_node_or_null("ParallaxBackground/BgFar/FallbackSprite") as AnimatedSprite2D
	_expect(bg != null and bg.sprite_frames.resource_path.ends_with("ember_fields_clean_ambient_bg_sprite_frames.tres"), "Boss 5 uses level 1-5 clean animated background")
	var ground := root.get_node_or_null("Ground") as TileMapLayer
	_expect(ground != null and ground.tile_set.resource_path.ends_with("ember_fields_clean_preview_tileset.tres"), "Boss 5 uses level 1-5 clean tileset")
	_expect(root.get_node_or_null("Pillars/LeftTallPillar") != null, "Left tall pillar exists")
	_expect(root.get_node_or_null("Pillars/RightTallPillar") != null, "Right tall pillar exists")
	var left_pillar := root.get_node_or_null("Pillars/LeftTallPillar") as Sprite2D
	var right_pillar := root.get_node_or_null("Pillars/RightTallPillar") as Sprite2D
	if left_pillar != null and right_pillar != null:
		_expect(left_pillar.texture.resource_path.ends_with("ember_boss_pillar_tall.png"), "Left pillar uses tall pillar asset")
		_expect(right_pillar.texture.resource_path.ends_with("ember_boss_pillar_tall.png"), "Right pillar uses tall pillar asset")
		_expect(_sprite_bottom_global_y(left_pillar) == 308.0, "Left pillar sits into floor lip")
		_expect(_sprite_bottom_global_y(right_pillar) == 308.0, "Right pillar sits into floor lip")
		_expect(left_pillar.position.x == 0.0, "Left pillar is placed at arena end")
		_expect(right_pillar.position.x + right_pillar.texture.get_width() == 640.0, "Right pillar is placed at arena end")
	_expect(root.get_node_or_null("ArenaFloorVisual") == null, "Old root ColorRect floor placeholder removed")
	_expect(root.get_node_or_null("LavaGlow") == null, "Old root ColorRect lava placeholder removed")

func _check_collision_contract(root: Node) -> void:
	var ground := root.get_node_or_null("Ground") as TileMapLayer
	var left_wall := root.get_node_or_null("BoundaryWalls/LeftWallShape") as CollisionShape2D
	var right_wall := root.get_node_or_null("BoundaryWalls/RightWallShape") as CollisionShape2D
	_expect(ground != null and ground.get_used_cells().size() == 40, "TileMap floor has one 20-tile two-layer platform")
	if ground != null:
		for x in range(20):
			_expect(ground.get_cell_atlas_coords(Vector2i(x, 9)) == Vector2i(0, 0), "Top layer uses normal tile at x=%d" % x)
			_expect(ground.get_cell_atlas_coords(Vector2i(x, 10)) == Vector2i(1, 0), "Second layer uses orange cracked tile at x=%d" % x)
	_expect(left_wall != null and left_wall.position == Vector2(-16, 180), "Left wall collision position unchanged")
	_expect(right_wall != null and right_wall.position == Vector2(656, 180), "Right wall collision position unchanged")
	if left_wall:
		var wall_shape := left_wall.shape as RectangleShape2D
		_expect(wall_shape != null and wall_shape.size == Vector2(32, 360), "Wall collision rectangle unchanged")

func _check_texture_sizes() -> void:
	var expected := {
		"res://assets/backgrounds/ember_fields/ember_fields_clean_bg_plate.png": Vector2i(1672, 941),
		"res://assets/tilesets/ember_fields/ember_fields_clean_tileset_32.png": Vector2i(128, 128),
		"res://assets/props/ember_fields/boss_arenas/pillars/ember_boss_pillar_tall.png": Vector2i(128, 256),
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

func _sprite_bottom_global_y(sprite: Sprite2D) -> float:
	var texture := sprite.texture
	if texture == null:
		return sprite.global_position.y
	var texture_height := float(texture.get_height())
	var visible_bottom := texture_height
	var image := texture.get_image()
	if image != null:
		var used_rect := image.get_used_rect()
		if used_rect.size.y > 0:
			visible_bottom = float(used_rect.position.y + used_rect.size.y)
	if sprite.centered:
		visible_bottom -= texture_height * 0.5
	return sprite.global_position.y + visible_bottom * sprite.global_scale.y

func _finish() -> void:
	if _failures.is_empty():
		print("RESULT: PASS Boss 5 arena environment check")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	print("RESULT: FAIL %d Boss 5 arena environment item(s)" % _failures.size())
	quit(1)
