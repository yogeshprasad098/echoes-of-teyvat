extends SceneTree

const GamePhysics := preload("res://scripts/core/game_physics.gd")

const PREVIEW_SCENE := "res://scenes/areas/ember_fields_asset_preview.tscn"
const OBJECTS_JSON := "res://data/maps/ember_fields/ember_fields_01-objects.json"
const COLLISION_JSON := "res://data/maps/ember_fields/ember_fields_01-collision.json"
const SCENE_HOOKS_JSON := "res://data/maps/ember_fields/ember_fields_01-scene-hooks.json"

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame

	var scene := load(PREVIEW_SCENE) as PackedScene
	_expect(scene != null, "Preview scene loads")
	if scene == null:
		_finish()
		return

	var root := scene.instantiate()
	get_root().add_child(root)
	await process_frame

	_check_preview_nodes(root)
	_check_json_and_assets()
	_check_route_physics()

	root.queue_free()
	await process_frame
	_finish()

func _check_preview_nodes(root: Node) -> void:
	var required_nodes := [
		"ParallaxPreview/Sky",
		"ParallaxPreview/FarBackground",
		"ParallaxPreview/MidBackground",
		"ParallaxPreview/NearBackground",
		"ParallaxPreview/ForegroundOverlay",
		"AssetScaleBoard/Tileset32",
		"AssetScaleBoard/PlatformStrip1x4",
		"AssetScaleBoard/LavaSurface6f",
		"RoutePreview/CollisionDebug/RouteLine",
		"RoutePreview/StartFlagVisual",
		"RoutePreview/CheckpointMidVisual",
		"RoutePreview/CheckpointPreGoalVisual",
		"RoutePreview/EndGoalGateVisual",
		"RoutePreview/PlatformBridgeIntroVisual",
		"RoutePreview/PlatformUpperCheckpointVisual",
		"RoutePreview/LavaGapMidVisual",
		"RoutePreview/LavaGapFinalVisual",
		"RoutePreview/SmallFlameMidVisual",
		"RoutePreview/SmokeVentFinalVisual"
	]
	for node_path in required_nodes:
		_expect(root.get_node_or_null(node_path) != null, "Preview node exists: %s" % node_path)

	var root_canvas := root as CanvasItem
	_expect(root_canvas != null and root_canvas.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Preview root forces nearest texture filtering")

func _check_json_and_assets() -> void:
	var objects := _read_json_dict(OBJECTS_JSON)
	var collision := _read_json_dict(COLLISION_JSON)
	var scene_hooks := _read_json_dict(SCENE_HOOKS_JSON)
	_expect(not objects.is_empty(), "Objects JSON parses")
	_expect(not collision.is_empty(), "Collision JSON parses")
	_expect(not scene_hooks.is_empty(), "Scene hooks JSON parses")
	if objects.is_empty():
		return

	var expected_sizes := {
		"tileset": Vector2i(128, 128),
		"platform_strip": Vector2i(256, 32),
		"lava_surface": Vector2i(192, 32),
		"small_flame": Vector2i(192, 48),
		"smoke_vent": Vector2i(256, 96),
		"ember_ambience": Vector2i(128, 128),
		"start_flag": Vector2i(64, 96),
		"checkpoint_marker": Vector2i(96, 96),
		"end_goal_gate": Vector2i(128, 128),
	}

	var assets := objects.get("assets", {}) as Dictionary
	for asset_key in expected_sizes.keys():
		var path := str(assets.get(asset_key, ""))
		_expect(path.begins_with("res://"), "Asset ref is project local: %s" % asset_key)
		var texture := load(path) as Texture2D
		_expect(texture != null, "Asset texture loads: %s" % asset_key)
		if texture != null:
			var size := Vector2i(texture.get_width(), texture.get_height())
			_expect(size == expected_sizes[asset_key], "Asset texture size matches metadata: %s" % asset_key)

	var object_list := objects.get("objects", []) as Array
	_expect(object_list.size() >= 10, "Objects JSON contains map asset placements")

func _check_route_physics() -> void:
	var collision := _read_json_dict(COLLISION_JSON)
	if collision.is_empty():
		return

	var route_validation := collision.get("route_validation", {}) as Dictionary
	var jump_pairs := route_validation.get("jump_pairs", []) as Array
	var max_gap := 0.0
	var max_rise := -INF
	for pair in jump_pairs:
		var jump_pair := pair as Dictionary
		max_gap = maxf(max_gap, float(jump_pair.get("horizontal_gap_tiles", 0.0)))
		max_rise = maxf(max_rise, float(jump_pair.get("vertical_rise_tiles", 0.0)))

	_expect(max_gap <= GamePhysics.SAFE_FLAT_JUMP_GAP_TILES, "Route max gap is within shared physics")
	_expect(max_rise <= GamePhysics.SAFE_JUMP_RISE_TILES, "Route max rise is within shared physics")
	_expect(bool(route_validation.get("passes_game_physics_limits", false)), "Collision metadata marks route physics-valid")

	var points := route_validation.get("intended_main_route_tile_points", []) as Array
	var highest_y := INF
	var highest_id := ""
	for point_value in points:
		var point := point_value as Dictionary
		var tile := point.get("tile", {}) as Dictionary
		var tile_y := float(tile.get("y", INF))
		if tile_y < highest_y:
			highest_y = tile_y
			highest_id = str(point.get("id", ""))
	_expect(highest_id == "highest_intended_platform" and is_equal_approx(highest_y, 9.0), "Highest intended platform is tile y=9")

func _read_json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		_failures.append("Missing JSON file: %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_failures.append("Cannot open JSON file: %s" % path)
		return {}

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_failures.append("JSON is not a dictionary: %s" % path)
		return {}
	return parsed as Dictionary

func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_failures.append(message)

func _finish() -> void:
	if _failures.is_empty():
		print("RESULT: PASS Ember Fields asset preview check")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		print("RESULT: FAIL %d Ember Fields asset preview item(s)" % _failures.size())
		quit(1)
