extends SceneTree

const SCENE_PATHS := [
	"res://scenes/areas/storm_peaks_boss_1_arena.tscn",
	"res://scenes/areas/storm_peaks_boss_2_arena.tscn",
	"res://scenes/areas/storm_peaks_boss_3_arena.tscn",
	"res://scenes/areas/storm_peaks_boss_4_arena.tscn",
	"res://scenes/areas/storm_peaks_boss_5_arena.tscn",
]

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	for path in SCENE_PATHS:
		_check_arena(path)
		await process_frame
	_finish()

func _check_arena(path: String) -> void:
	var packed := load(path) as PackedScene
	_expect(packed != null, "Scene loads: %s" % path)
	if packed == null:
		return
	var arena := packed.instantiate()
	get_root().add_child(arena)
	var label := arena.name
	_expect(arena is BossArenaBase, "%s keeps BossArenaBase behavior" % label)
	_expect(arena.get_node_or_null("ArenaEnvironment") == null, "%s removes old generated ArenaEnvironment" % label)
	_expect(arena.get_node_or_null("ParallaxBackground/BgFar/Sprite2D") != null, "%s has far Storm parallax layer" % label)
	_expect(arena.get_node_or_null("ParallaxBackground/BgMid/Sprite2D") != null, "%s has mid Storm parallax layer" % label)
	_expect(arena.get_node_or_null("ParallaxBackground/BgNear/Sprite2D") != null, "%s has near Storm parallax layer" % label)
	var far_bg := arena.get_node("ParallaxBackground/BgFar/Sprite2D") as Sprite2D
	var mid_bg := arena.get_node("ParallaxBackground/BgMid/Sprite2D") as Sprite2D
	var near_bg := arena.get_node("ParallaxBackground/BgNear/Sprite2D") as Sprite2D
	_expect(far_bg.texture.resource_path.ends_with("bg_far_fallback.png"), "%s uses clean Storm far background" % label)
	_expect(mid_bg.texture.resource_path.ends_with("bg_mid.png"), "%s uses clean Storm mid background" % label)
	_expect(near_bg.texture.resource_path.ends_with("bg_near.png"), "%s uses clean Storm near background" % label)
	_expect(far_bg.scale == Vector2(2, 2), "%s far Storm background fills the boss viewport" % label)
	_expect(mid_bg.scale == Vector2(2, 2), "%s mid Storm background fills the boss viewport" % label)
	_expect(near_bg.scale == Vector2(2, 2), "%s near Storm background fills the boss viewport" % label)
	var ground := arena.get_node_or_null("Ground") as TileMapLayer
	_expect(ground != null, "%s uses TileMapLayer floor" % label)
	if ground != null:
		_expect(ground.tile_set.resource_path.ends_with("storm_peaks_clean_preview_tileset.tres"), "%s uses clean Storm Peaks floor tileset" % label)
		_expect(ground.get_used_cells().size() == 40, "%s has a 20-tile two-layer boss floor" % label)
		for x in range(20):
			_expect(ground.get_cell_atlas_coords(Vector2i(x, 9)) == Vector2i(0, 0), "%s top floor tile uses normal Storm tile at x=%d" % [label, x])
			_expect(ground.get_cell_atlas_coords(Vector2i(x, 10)) == Vector2i(1, 0), "%s second floor tile uses cracked Storm tile at x=%d" % [label, x])
	var left_pillar := arena.get_node_or_null("Pillars/LeftTallPillar") as Sprite2D
	var right_pillar := arena.get_node_or_null("Pillars/RightTallPillar") as Sprite2D
	_expect(left_pillar != null and right_pillar != null, "%s has two tall pillars" % label)
	if left_pillar != null and right_pillar != null:
		_expect(left_pillar.texture.resource_path.ends_with("storm_boss_pillar_tall.png"), "%s left pillar uses Storm tall pillar" % label)
		_expect(right_pillar.texture.resource_path.ends_with("storm_boss_pillar_tall.png"), "%s right pillar uses Storm tall pillar" % label)
		_expect(left_pillar.position == Vector2(0, 52), "%s left pillar matches boss template edge placement" % label)
		_expect(right_pillar.position == Vector2(512, 52), "%s right pillar matches boss template edge placement" % label)
	_expect(arena.get_node_or_null("BoundaryWalls/LeftWallShape") != null, "%s keeps left boundary collision" % label)
	_expect(arena.get_node_or_null("BoundaryWalls/RightWallShape") != null, "%s keeps right boundary collision" % label)
	_expect(arena.get_node_or_null("Enemies/Boss") != null, "%s keeps boss node" % label)
	_expect(arena.get_node_or_null("Party") != null, "%s keeps party node" % label)
	arena.queue_free()

func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("RESULT: PASS Storm Peaks boss arena layout check")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	print("RESULT: FAIL %d Storm Peaks boss arena layout item(s)" % _failures.size())
	quit(1)
