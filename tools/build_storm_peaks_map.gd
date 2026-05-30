extends SceneTree

const TILE_SIZE := 32
const TILE_SOURCE_ID := 0
const TILE_GROUND := Vector2i(1, 0)
const TILE_PLATFORM := Vector2i(3, 0)
const TILE_ROCK := Vector2i(1, 1)
const TILE_HAZARD := Vector2i(2, 3)

const MAP_DIR := "res://assets/map/storm_peaks"
const TILESET_DIR := "res://assets/tilesets/storm_peaks"
const PLATFORM_DIR := "res://assets/platforms/storm_peaks"
const HAZARD_DIR := "res://assets/hazards/storm_peaks/electric_floor"
const PROP_DIR := "res://assets/props/storm_peaks"
const DATA_DIR := "res://data/maps/storm_peaks"

const TILESET_IMAGE := "res://assets/tilesets/storm_peaks/storm_peaks-tileset-32.png"
const TILESET_RESOURCE := "res://resources/tilesets/storm_peaks_tileset.tres"
const SCENE_PATH := "res://scenes/areas/storm_peaks.tscn"

const BG_SIZE := Vector2i(1536, 864)
const ROUTE_PLATFORMS: Array[Vector3i] = [
	Vector3i(0, 12, 16),
	Vector3i(21, 12, 12),
	Vector3i(38, 10, 10),
	Vector3i(53, 9, 11),
	Vector3i(69, 11, 13),
	Vector3i(87, 10, 12),
	Vector3i(104, 8, 10),
	Vector3i(119, 10, 13),
	Vector3i(137, 9, 19),
]
const HAZARD_GAPS: Array[Vector3i] = [
	Vector3i(16, 14, 5),
	Vector3i(33, 14, 5),
	Vector3i(64, 14, 5),
	Vector3i(99, 14, 5),
	Vector3i(132, 14, 5),
]

func _initialize() -> void:
	var failed := false
	failed = not _ensure_dirs() or failed
	failed = not _write_prompts() or failed
	failed = not _generate_images() or failed
	failed = not _save_tileset() or failed
	failed = not _save_scene() or failed
	failed = not _save_metadata() or failed
	print("Generated Storm Peaks electro map assets and scene.")
	quit(1 if failed else 0)

func _ensure_dirs() -> bool:
	var dir := DirAccess.open("res://")
	if dir == null:
		push_error("Could not open res://")
		return false
	for path in [
		MAP_DIR,
		TILESET_DIR,
		PLATFORM_DIR,
		HAZARD_DIR,
		PROP_DIR,
		DATA_DIR,
		"res://resources/tilesets",
	]:
		var error := dir.make_dir_recursive(path.trim_prefix("res://"))
		if error != OK and error != ERR_ALREADY_EXISTS:
			push_error("Could not create %s: %s" % [path, error])
			return false
	return true

func _write_prompts() -> bool:
	var prompt_map := {
		"storm_peaks-stage-reference.prompt.txt": "Use case: procedural-placeholder\nAsset type: 2D game stage reference mockup for Godot side-scroller map planning\nPrimary request: Storm Peaks electro side-scroller route with storm cliffs, conductive ruins, violet/cyan lightning, readable 32x32 platform logic, start flag, checkpoint shrine, and end gate. Procedural raster art only, no image generation, no SVG, no characters, enemies, UI, labels, arrows, or combat VFX.\n",
		"storm_peaks-sky.prompt.txt": "Use case: procedural-placeholder\nAsset type: parallax sky layer\nPrimary request: Storm Peaks stormy night sky plate with distant clouds, pale moon haze, and subtle violet lightning glow. Procedural raster art only, no image generation, no SVG, scenery only, no gameplay objects or text.\n",
		"storm_peaks-far-bg.prompt.txt": "Use case: procedural-placeholder\nAsset type: far parallax scenery layer\nPrimary request: distant jagged mountain silhouettes and storm clouds for an electro fantasy platformer map. Procedural raster art only, no image generation, no SVG, keep shapes non-walkable and behind gameplay.\n",
		"storm_peaks-mid-bg.prompt.txt": "Use case: procedural-placeholder\nAsset type: mid parallax scenery layer\nPrimary request: conductive ruin silhouettes, broken pylons, cable runs, and cyan storm energy in the middle distance. Procedural raster art only, no image generation, no SVG, no collision-critical objects, characters, enemies, UI, or text.\n",
		"storm_peaks-near-bg.prompt.txt": "Use case: procedural-placeholder\nAsset type: near parallax scenery layer\nPrimary request: close storm rocks, hanging cables, and ruined electro pylons behind the gameplay lane. Procedural raster art only, no image generation, no SVG, keep platform silhouettes distinct from actual tilemap terrain.\n",
		"storm_peaks-foreground-overlay.prompt.txt": "Use case: procedural-placeholder\nAsset type: foreground ambience layer\nPrimary request: sparse rain streaks, charged motes, scanline static, and edge silhouettes for a Storm Peaks electro map overlay. Procedural raster art only, no image generation, no SVG, transparent-ready ambience, no UI or text.\n",
		"storm_peaks-tileset-32.prompt.txt": "Use case: procedural-placeholder\nAsset type: Godot TileMap-ready 2D pixel-art terrain tileset sheet\nPrimary request: 4x4 128x128 atlas of 32x32 storm cliff and conductive ruin tiles: walkable tops, solid rock, cracked variants, one-way platform, electric edge, and decorative charged stone. Procedural raster art only, no image generation, no SVG, no labels or characters.\n",
	}
	for file_name in prompt_map:
		var dir := MAP_DIR
		if file_name == "storm_peaks-tileset-32.prompt.txt":
			dir = TILESET_DIR
		if not _write_text("%s/%s" % [dir, file_name], prompt_map[file_name]):
			return false
	return true

func _generate_images() -> bool:
	_save_bg("%s/storm_peaks-sky.png" % MAP_DIR, 0)
	_save_bg("%s/storm_peaks-far-bg.png" % MAP_DIR, 1)
	_save_bg("%s/storm_peaks-mid-bg.png" % MAP_DIR, 2)
	_save_bg("%s/storm_peaks-near-bg.png" % MAP_DIR, 3)
	_save_stage_reference("%s/storm_peaks-stage-reference.png" % MAP_DIR)
	_save_foreground_overlay("%s/storm_peaks-foreground-overlay.png" % MAP_DIR)
	_save_parallax_preview("%s/storm_peaks-parallax-preview.png" % MAP_DIR)
	_save_tileset_image(TILESET_IMAGE)
	_save_platform_strip("%s/storm_peaks-platform-strip-1x4.png" % PLATFORM_DIR)
	_save_electric_floor("%s/storm_peaks-electric-floor-6f.png" % HAZARD_DIR)
	_save_start_flag("%s/storm_start_flag.png" % PROP_DIR)
	_save_checkpoint_marker("%s/storm_checkpoint_marker.png" % PROP_DIR)
	_save_end_gate("%s/storm_end_goal_gate.png" % PROP_DIR)
	return true

func _save_bg(path: String, layer: int) -> void:
	var image := Image.create(BG_SIZE.x, BG_SIZE.y, false, Image.FORMAT_RGBA8)
	var top := Color(0.025, 0.025, 0.075, 1)
	var bottom := Color(0.09, 0.075, 0.16, 1)
	if layer >= 2:
		top = Color(0.035, 0.035, 0.095, 1)
		bottom = Color(0.12, 0.10, 0.20, 1)
	_gradient(image, top, bottom)
	_draw_cloud_bands(image, layer)
	_draw_sky_noise(image, 48 + layer * 9, Color(0.45, 0.82, 1.0, 0.28))
	if layer == 0:
		_draw_moon_haze(image, 1180, 120, 86)
		_draw_lightning(image, 1070, 65, Color(0.68, 0.94, 1.0, 0.42), 2)
		_draw_lightning(image, 370, 105, Color(0.55, 0.58, 1.0, 0.28), 1)
	elif layer == 1:
		_draw_mountains(image, Color(0.038, 0.040, 0.083, 1), 610, 34, 0)
		_draw_mountains(image, Color(0.058, 0.052, 0.110, 1), 700, 24, 77)
		_draw_fog_band(image, 420, 540, Color(0.16, 0.18, 0.31, 0.22))
	elif layer == 2:
		_draw_mountains(image, Color(0.075, 0.064, 0.135, 1), 640, 18, 35)
		for x in range(160, 1420, 210):
			var pylon_y := 486 + (x % 4) * 18
			_draw_pylon(image, x, pylon_y, 170, Color(0.105, 0.087, 0.180, 1))
			_draw_rune_cluster(image, x + 8, pylon_y - 126, Color(0.26, 0.88, 1.0, 0.34))
			_draw_lightning(image, x + 28, pylon_y - 92, Color(0.35, 0.85, 1.0, 0.34), 1)
		for x in range(105, 1300, 210):
			_draw_cable(image, Vector2i(x, 404), Vector2i(x + 180, 426), Color(0.055, 0.050, 0.095, 1))
	elif layer == 3:
		_draw_mountains(image, Color(0.102, 0.087, 0.168, 1), 664, 14, 11)
		for x in range(60, 1480, 180):
			_draw_pylon(image, x, 575, 104, Color(0.145, 0.118, 0.225, 1))
			_draw_chain(image, x + 42, 506, 70, Color(0.10, 0.095, 0.17, 1))
		_draw_fog_band(image, 592, 690, Color(0.20, 0.18, 0.32, 0.20))
	_save_png(image, path)

func _save_stage_reference(path: String) -> void:
	var image := Image.create(BG_SIZE.x, BG_SIZE.y, false, Image.FORMAT_RGBA8)
	_gradient(image, Color(0.03, 0.03, 0.08, 1), Color(0.10, 0.08, 0.16, 1))
	_draw_cloud_bands(image, 2)
	_draw_mountains(image, Color(0.05, 0.05, 0.10, 1), 640, 20, 0)
	_draw_mountains(image, Color(0.09, 0.075, 0.15, 1), 705, 16, 48)
	for platform in ROUTE_PLATFORMS:
		var px := platform.x * 10
		var py := platform.y * 32
		var pw := platform.z * 10
		_draw_reference_platform(image, px, py, pw)
	for gap in HAZARD_GAPS:
		_draw_reference_hazard(image, gap.x * 10, gap.y * 32 - 8, gap.z * 10)
	_draw_flag_icon(image, 30, 332, Color(0.55, 0.90, 1, 1))
	_draw_flag_icon(image, 550, 282, Color(0.72, 0.48, 1, 1))
	_draw_gate_icon(image, 1480, 272)
	_draw_lightning(image, 1060, 102, Color(0.58, 0.92, 1.0, 0.42), 2)
	_save_png(image, path)

func _save_foreground_overlay(path: String) -> void:
	var image := Image.create(BG_SIZE.x, BG_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for i in range(0, 140):
		var x := (i * 53) % BG_SIZE.x
		var y := (i * 97) % BG_SIZE.y
		_draw_line(image, Vector2i(x, y), Vector2i(x - 6, y + 20 + (i % 4) * 7), Color(0.45, 0.86, 1.0, 0.20), 1)
	for i in range(0, 42):
		var sx := (i * 113) % BG_SIZE.x
		var sy := 678 + (i % 5) * 22
		_rect(image, sx, sy, 24 + (i % 3) * 10, 2, Color(0.42, 0.24, 0.65, 0.28))
		_rect(image, sx + 4, sy - 5, 3, 3, Color(0.58, 0.94, 1.0, 0.32))
	_save_png(image, path)

func _save_parallax_preview(path: String) -> void:
	var image := Image.create(BG_SIZE.x, BG_SIZE.y, false, Image.FORMAT_RGBA8)
	_gradient(image, Color(0.03, 0.03, 0.08, 1), Color(0.11, 0.09, 0.18, 1))
	_draw_cloud_bands(image, 1)
	_draw_mountains(image, Color(0.05, 0.05, 0.10, 1), 620, 22, 0)
	_draw_mountains(image, Color(0.08, 0.07, 0.13, 1), 660, 16, 55)
	for platform in ROUTE_PLATFORMS:
		_draw_reference_platform(image, int(platform.x * TILE_SIZE / 3), platform.y * TILE_SIZE, int(platform.z * TILE_SIZE / 3))
	_save_png(image, path)

func _save_tileset_image(path: String) -> void:
	var image := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for y in 4:
		for x in 4:
			_draw_tile(image, Vector2i(x, y))
	_save_png(image, path)

func _draw_tile(image: Image, coords: Vector2i) -> void:
	var ox := coords.x * TILE_SIZE
	var oy := coords.y * TILE_SIZE
	var dark := Color(0.08, 0.065, 0.13, 1)
	var mid := Color(0.18, 0.16, 0.27, 1)
	var top := Color(0.50, 0.54, 0.66, 1)
	var glow := Color(0.32, 0.88, 1.0, 1)
	_rect(image, ox, oy, 32, 32, dark)
	if coords.y == 0:
		_rect(image, ox, oy, 32, 4, Color(0.72, 0.75, 0.86, 1))
		_rect(image, ox, oy + 4, 32, 5, top)
		_rect(image, ox, oy + 9, 32, 23, mid)
		_rect(image, ox + 2, oy + 9, 28, 2, Color(0.28, 0.84, 1.0, 0.35))
		_draw_cracks(image, ox, oy, coords.x + coords.y * 7, Color(0.08, 0.07, 0.13, 1), glow)
	elif coords == TILE_HAZARD:
		image.fill_rect(Rect2i(ox, oy, 32, 32), Color(0, 0, 0, 0))
		_rect(image, ox, oy + 25, 32, 4, Color(0.08, 0.07, 0.13, 0.85))
		for x in range(0, 32, 6):
			_draw_line(image, Vector2i(ox + x, oy + 22), Vector2i(ox + x + 5, oy + 8), glow, 2)
			_rect(image, ox + x + 1, oy + 20, 4, 4, Color(0.86, 0.74, 1.0, 0.72))
	else:
		_rect(image, ox, oy, 32, 32, Color(0.13, 0.11, 0.21, 1))
		_rect(image, ox, oy, 32, 5, Color(0.32, 0.34, 0.45, 1))
		_rect(image, ox, oy + 5, 32, 3, Color(0.20, 0.18, 0.31, 1))
		_draw_cracks(image, ox, oy, coords.x * 13 + coords.y, Color(0.06, 0.05, 0.10, 1), glow)
	for i in range(0, 8):
		var px := ox + 3 + ((i * 9 + coords.x * 5) % 26)
		var py := oy + 8 + ((i * 7 + coords.y * 3) % 20)
		_rect(image, px, py, 2, 2, Color(0.07, 0.06, 0.12, 1))
	if coords.x == 2 or coords.y == 3:
		_draw_line(image, Vector2i(ox + 6, oy + 10), Vector2i(ox + 25, oy + 22), glow, 1)
		_rect(image, ox + 14, oy + 16, 4, 4, Color(0.72, 0.48, 1.0, 1))

func _save_platform_strip(path: String) -> void:
	var image := Image.create(256, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for x in range(0, 256, 8):
		_rect(image, x, 0, 8, 5, Color(0.72, 0.76, 0.88, 1))
		_rect(image, x, 5, 8, 7, Color(0.43, 0.46, 0.58, 1))
		_rect(image, x, 12, 8, 17, Color(0.13, 0.11, 0.22, 1))
	for x in range(0, 256, 32):
		_draw_line(image, Vector2i(x + 4, 25), Vector2i(x + 28, 10), Color(0.28, 0.84, 1, 0.95), 1)
		_rect(image, x + 12, 6, 8, 2, Color(0.68, 0.94, 1.0, 0.40))
	_draw_line(image, Vector2i(0, 3), Vector2i(255, 3), Color(0.92, 0.96, 1.0, 0.55), 1)
	_save_png(image, path)

func _save_electric_floor(path: String) -> void:
	var image := Image.create(192, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for frame in 6:
		var ox := frame * 32
		_rect(image, ox, 24, 32, 5, Color(0.10, 0.08, 0.18, 0.90))
		_rect(image, ox, 27, 32, 2, Color(0.32, 0.20, 0.52, 0.75))
		for x in range(2, 32, 7):
			var y := 18 - ((x + frame * 3) % 7)
			_draw_line(image, Vector2i(ox + x, 26), Vector2i(ox + x + 5, y), Color(0.32, 0.92, 1, 1), 2)
			_rect(image, ox + x + 2, y, 3, 3, Color(0.82, 0.72, 1, 1))
		_circle(image, Vector2i(ox + 16, 16), 12 + frame % 2, Color(0.28, 0.78, 1.0, 0.10))
	_save_png(image, path)

func _save_start_flag(path: String) -> void:
	var image := Image.create(64, 96, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_draw_flag_icon(image, 28, 88, Color(0.42, 0.86, 1, 1))
	_save_png(image, path)

func _save_checkpoint_marker(path: String) -> void:
	var image := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_circle(image, Vector2i(48, 48), 34, Color(0.20, 0.70, 1.0, 0.12))
	_poly(image, [Vector2i(22, 78), Vector2i(36, 22), Vector2i(60, 22), Vector2i(74, 78)], Color(0.13, 0.11, 0.23, 1))
	_poly(image, [Vector2i(31, 72), Vector2i(42, 30), Vector2i(54, 30), Vector2i(65, 72)], Color(0.21, 0.17, 0.33, 1))
	_rect(image, 44, 18, 8, 60, Color(0.42, 0.86, 1, 0.92))
	_draw_line(image, Vector2i(16, 76), Vector2i(80, 76), Color(0.55, 0.42, 0.82, 1), 5)
	_draw_lightning(image, 48, 24, Color(0.82, 0.72, 1, 1), 2)
	_save_png(image, path)

func _save_end_gate(path: String) -> void:
	var image := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_circle(image, Vector2i(64, 68), 42, Color(0.26, 0.78, 1.0, 0.12))
	_draw_gate_icon(image, 64, 112)
	_save_png(image, path)

func _save_tileset() -> bool:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1)
	tile_set.set_physics_layer_collision_mask(0, 1)
	var source := TileSetAtlasSource.new()
	source.texture = load(TILESET_IMAGE)
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tile_set.add_source(source, TILE_SOURCE_ID)
	for y in 4:
		for x in 4:
			var coords := Vector2i(x, y)
			source.create_tile(coords)
			if coords != TILE_HAZARD and coords != Vector2i(3, 3):
				_add_collision(source, coords)
	return _save_resource(tile_set, TILESET_RESOURCE)

func _add_collision(source: TileSetAtlasSource, coords: Vector2i) -> void:
	var tile_data := source.get_tile_data(coords, 0)
	tile_data.add_collision_polygon(0)
	tile_data.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(0, 0),
		Vector2(32, 0),
		Vector2(32, 32),
		Vector2(0, 32),
	]))

func _save_scene() -> bool:
	var root := Node2D.new()
	root.name = "StormPeaks"
	root.set_script(load("res://scripts/areas/area_base.gd"))
	root.set("camera_limit_right", 5056)
	root.set("fall_limit_y", 560.0)
	_add_parallax(root)
	_add_ground(root)
	_add_markers(root)
	_add_enemies(root)
	_add_party(root)
	return _pack_scene(root, SCENE_PATH)

func _add_parallax(root: Node) -> void:
	var parallax := ParallaxBackground.new()
	parallax.name = "ParallaxBackground"
	root.add_child(parallax)
	_owned(parallax, root)
	_add_parallax_layer(parallax, root, "BgFar", "FallbackSprite", "res://assets/map/storm_peaks/storm_peaks-far-bg.png", Vector2(0.2, 0.2), null)
	_add_parallax_layer(parallax, root, "BgMid", "Sprite2D", "res://assets/map/storm_peaks/storm_peaks-mid-bg.png", Vector2(0.5, 0.5), _storm_material())
	_add_parallax_layer(parallax, root, "BgNear", "Sprite2D", "res://assets/map/storm_peaks/storm_peaks-near-bg.png", Vector2(0.8, 0.8), null)
	var particles := GPUParticles2D.new()
	particles.name = "StormMotesParticles"
	particles.position = Vector2(320, 360)
	particles.amount = 28
	particles.lifetime = 3.6
	particles.preprocess = 1.0
	var proc := ParticleProcessMaterial.new()
	proc.particle_flag_disable_z = true
	proc.direction = Vector3(0, -1, 0)
	proc.spread = 75.0
	proc.initial_velocity_min = 18.0
	proc.initial_velocity_max = 44.0
	proc.gravity = Vector3(0, -32, 0)
	proc.scale_min = 0.6
	proc.scale_max = 2.4
	proc.color = Color(0.45, 0.85, 1.0, 0.58)
	particles.process_material = proc
	parallax.get_node("BgNear").add_child(particles)
	_owned(particles, root)

func _storm_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = "shader_type canvas_item;\nrender_mode blend_mix;\nuniform float distortion_strength : hint_range(0.0, 0.05) = 0.006;\nuniform float scroll_speed : hint_range(0.0, 2.0) = 0.55;\nvoid fragment() {\n\tvec2 sample_uv = UV;\n\tfloat dx = sin(sample_uv.y * 22.0 + TIME * scroll_speed) * distortion_strength;\n\tfloat dy = cos(sample_uv.x * 15.0 + TIME * scroll_speed * 0.7) * distortion_strength * 0.4;\n\tCOLOR = texture(TEXTURE, sample_uv + vec2(dx, dy));\n}"
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("distortion_strength", 0.006)
	material.set_shader_parameter("scroll_speed", 0.55)
	return material

func _add_parallax_layer(parent: Node, owner: Node, layer_name: String, sprite_name: String, texture_path: String, motion: Vector2, material: Material) -> void:
	var layer := ParallaxLayer.new()
	layer.name = layer_name
	layer.motion_scale = motion
	layer.motion_mirroring = Vector2(640, 360)
	parent.add_child(layer)
	_owned(layer, owner)
	var sprite := Sprite2D.new()
	sprite.name = sprite_name
	sprite.unique_name_in_owner = sprite_name == "FallbackSprite"
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	sprite.scale = Vector2(2, 2)
	sprite.texture = load(texture_path)
	sprite.centered = false
	sprite.material = material
	layer.add_child(sprite)
	_owned(sprite, owner)

func _add_ground(root: Node) -> void:
	var ground := TileMapLayer.new()
	ground.name = "Ground"
	ground.tile_set = load(TILESET_RESOURCE)
	root.add_child(ground)
	_owned(ground, root)
	for segment in ROUTE_PLATFORMS:
		_add_solid_segment(ground, segment.x, segment.y, segment.z)
	for hazard in HAZARD_GAPS:
		for x in range(hazard.x, hazard.x + hazard.z):
			ground.set_cell(Vector2i(x, hazard.y), TILE_SOURCE_ID, TILE_HAZARD, 0)
	for y in range(7, 15):
		ground.set_cell(Vector2i(-1, y), TILE_SOURCE_ID, TILE_ROCK, 0)
		ground.set_cell(Vector2i(-2, y), TILE_SOURCE_ID, TILE_ROCK, 0)
	for coords in [Vector2i(58, 8), Vector2i(59, 8), Vector2i(110, 7), Vector2i(111, 7)]:
		ground.set_cell(coords, TILE_SOURCE_ID, TILE_PLATFORM, 0)

func _add_solid_segment(ground: TileMapLayer, start_x: int, y: int, width: int) -> void:
	for x in range(start_x, start_x + width):
		ground.set_cell(Vector2i(x, y), TILE_SOURCE_ID, TILE_GROUND, 0)
		for fill_y in range(y + 1, 15):
			ground.set_cell(Vector2i(x, fill_y), TILE_SOURCE_ID, TILE_ROCK, 0)

func _add_markers(root: Node) -> void:
	var start := Marker2D.new()
	start.name = "StartPoint"
	start.unique_name_in_owner = true
	start.position = Vector2(96, 336)
	root.add_child(start)
	_owned(start, root)
	_add_prop_sprite(root, "StartFlagVisual", "res://assets/props/storm_peaks/storm_start_flag.png", Vector2(96, 336), Vector2(-32, -96), 8)
	var end_flag := Area2D.new()
	end_flag.name = "EndFlag"
	end_flag.unique_name_in_owner = true
	end_flag.position = Vector2(4800, 288)
	end_flag.collision_layer = 0
	end_flag.collision_mask = 2
	root.add_child(end_flag)
	_owned(end_flag, root)
	var shape_node := CollisionShape2D.new()
	shape_node.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(32, 64)
	shape_node.shape = shape
	end_flag.add_child(shape_node)
	_owned(shape_node, root)
	var gate := Sprite2D.new()
	gate.name = "Sprite2D"
	gate.texture = load("res://assets/props/storm_peaks/storm_end_goal_gate.png")
	gate.position = Vector2(0, -64)
	gate.z_index = 10
	end_flag.add_child(gate)
	_owned(gate, root)
	_add_goal_label(end_flag, root)
	_add_checkpoint(root, "CheckpointStart", "start", Vector2(96, 336), true)
	_add_checkpoint(root, "CheckpointMid", "mid", Vector2(1760, 288), false, Vector2(96, -48))
	_add_checkpoint(root, "CheckpointPreGoal", "pre_goal", Vector2(3840, 320), false, Vector2(0, -48))

func _add_goal_label(parent: Node, owner: Node) -> void:
	var label := Label.new()
	label.name = "GoalLabel"
	label.offset_left = -14.0
	label.offset_top = 50.0
	label.offset_right = 34.0
	label.offset_bottom = 73.0
	label.text = "GOAL"
	label.add_theme_color_override("font_color", Color(0.68, 0.96, 1, 1))
	parent.add_child(label)
	_owned(label, owner)

func _add_checkpoint(root: Node, node_name: String, checkpoint_name: String, position: Vector2, unique: bool, respawn_offset: Vector2 = Vector2.ZERO) -> void:
	var packed := load("res://scenes/world/checkpoint.tscn") as PackedScene
	var checkpoint := packed.instantiate() as Area2D
	checkpoint.name = node_name
	checkpoint.unique_name_in_owner = unique
	checkpoint.position = position
	checkpoint.set("checkpoint_name", checkpoint_name)
	checkpoint.set("respawn_offset", respawn_offset)
	var banner := checkpoint.get_node_or_null("Banner") as Polygon2D
	if banner:
		banner.color = Color(0.18, 0.14, 0.32, 0.92)
	var pennant := checkpoint.get_node_or_null("Banner/Pennant") as Polygon2D
	if pennant:
		pennant.color = Color(0.45, 0.88, 1.0, 0.95)
	var sprite := Sprite2D.new()
	sprite.name = "StormMarkerVisual"
	sprite.texture = load("res://assets/props/storm_peaks/storm_checkpoint_marker.png")
	sprite.position = Vector2(0, -48)
	sprite.z_index = 7
	checkpoint.add_child(sprite)
	root.add_child(checkpoint)
	_owned(checkpoint, root)
	_owned(sprite, root)

func _add_prop_sprite(root: Node, node_name: String, texture_path: String, position: Vector2, offset: Vector2, z: int) -> void:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = load(texture_path)
	sprite.position = position + offset
	sprite.centered = false
	sprite.z_index = z
	root.add_child(sprite)
	_owned(sprite, root)

func _add_enemies(root: Node) -> void:
	var enemies := Node2D.new()
	enemies.name = "Enemies"
	enemies.unique_name_in_owner = true
	root.add_child(enemies)
	_owned(enemies, root)
	var packed := load("res://scenes/enemies/grunt.tscn") as PackedScene
	var positions := [Vector2(800, 336), Vector2(2112, 240), Vector2(4384, 240), Vector2(4576, 240)]
	for i in positions.size():
		var grunt := packed.instantiate()
		grunt.name = "Grunt" if i == 0 else "Grunt%d" % (i + 1)
		grunt.position = positions[i]
		enemies.add_child(grunt)
		_owned(grunt, root)

func _add_party(root: Node) -> void:
	var party := Node2D.new()
	party.name = "Party"
	party.unique_name_in_owner = true
	party.position = Vector2(96, 336)
	party.set_script(load("res://scripts/world/party.gd"))
	root.add_child(party)
	_owned(party, root)
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.unique_name_in_owner = true
	camera.limit_left = 0
	camera.limit_top = -256
	camera.limit_right = 5056
	camera.limit_bottom = 480
	camera.position_smoothing_enabled = true
	camera.set_script(load("res://scripts/world/party_camera.gd"))
	party.add_child(camera)
	_owned(camera, root)
	for spec in [
		["Kira", "res://scenes/characters/kira.tscn", true],
		["Marina", "res://scenes/characters/marina.tscn", false],
		["Ryne", "res://scenes/characters/ryne.tscn", false],
	]:
		var packed := load(spec[1]) as PackedScene
		var member := packed.instantiate()
		member.name = spec[0]
		member.unique_name_in_owner = bool(spec[2])
		party.add_child(member)
		_owned(member, root)

func _save_metadata() -> bool:
	var assets := {
		"tileset": TILESET_IMAGE,
		"platform_strip": "res://assets/platforms/storm_peaks/storm_peaks-platform-strip-1x4.png",
		"electric_floor": "res://assets/hazards/storm_peaks/electric_floor/storm_peaks-electric-floor-6f.png",
		"start_flag": "res://assets/props/storm_peaks/storm_start_flag.png",
		"checkpoint_marker": "res://assets/props/storm_peaks/storm_checkpoint_marker.png",
		"end_goal_gate": "res://assets/props/storm_peaks/storm_end_goal_gate.png",
	}
	var objects := {
		"schema_version": 1,
		"map_id": "storm_peaks_01",
		"tile_size_px": TILE_SIZE,
		"coordinate_space": "world_pixels",
		"source_scene": SCENE_PATH,
		"asset_scope": "map_assets_only",
		"assets": assets,
		"objects": [
			_object("start_flag_01", "start_marker", "start_flag", Vector2(96, 336), "none"),
			_object("checkpoint_mid_01", "checkpoint", "checkpoint_marker", Vector2(1760, 288), "trigger"),
			_object("checkpoint_pre_goal_01", "checkpoint", "checkpoint_marker", Vector2(3840, 320), "trigger"),
			_object("end_goal_gate_01", "stage_exit", "end_goal_gate", Vector2(4800, 288), "trigger"),
		],
	}
	var collision := {
		"schema_version": 1,
		"map_id": "storm_peaks_01",
		"tile_size_px": TILE_SIZE,
		"collision_source_of_truth": "metadata_and_godot_tileset_not_pixels",
		"route_validation": {
			"intended_main_route_tile_points": _route_points(),
			"jump_pairs": _jump_pair_metadata(),
			"max_horizontal_gap_tiles": 5,
			"max_vertical_rise_tiles": 2,
			"passes_game_physics_limits": true,
		},
		"solid_ground_segments": _segment_metadata(),
		"hazards": _hazard_metadata(),
	}
	var hooks := {
		"schema_version": 1,
		"map_id": "storm_peaks_01",
		"tile_size_px": TILE_SIZE,
		"source_scene": SCENE_PATH,
		"player_spawn": {"id": "player_spawn_start", "position_px": _vec_dict(Vector2(96, 336)), "source_node": "StartPoint", "metadata_only": true},
		"camera_bounds": {"left": 0, "top": -256, "right": 5056, "bottom": 480, "source": "AreaBase camera limits in storm_peaks.tscn"},
		"checkpoints": [
			{"id": "checkpoint_start", "position_px": _vec_dict(Vector2(96, 336)), "source_node": "CheckpointStart"},
			{"id": "checkpoint_mid", "position_px": _vec_dict(Vector2(1760, 288)), "respawn_position_px": _vec_dict(Vector2(1856, 240)), "source_node": "CheckpointMid"},
			{"id": "checkpoint_pre_goal", "position_px": _vec_dict(Vector2(3840, 320)), "respawn_position_px": _vec_dict(Vector2(3840, 272)), "source_node": "CheckpointPreGoal"},
		],
		"exits": [
			{"id": "final_clear", "type": "area_completed", "position_px": _vec_dict(Vector2(4800, 288)), "source_node": "EndFlag", "trigger_shape_px": {"w": 64, "h": 96}, "target": {"handoff": "final_area_clear"}},
		],
		"enemy_spawn_markers": [
			{"id": "enemy_spawn_grunt_01", "enemy_type": "grunt", "position_px": _vec_dict(Vector2(800, 336)), "source_node": "Enemies/Grunt"},
			{"id": "enemy_spawn_grunt_02", "enemy_type": "grunt", "position_px": _vec_dict(Vector2(2112, 240)), "source_node": "Enemies/Grunt2"},
			{"id": "enemy_spawn_grunt_03", "enemy_type": "grunt", "position_px": _vec_dict(Vector2(4384, 240)), "source_node": "Enemies/Grunt3"},
		],
		"route_summary": {"theme": "Electro storm cliffs with conductive ruins and electric hazard gaps.", "physics_valid": true},
	}
	return _write_json("%s/storm_peaks_01-objects.json" % DATA_DIR, objects) \
		and _write_json("%s/storm_peaks_01-collision.json" % DATA_DIR, collision) \
		and _write_json("%s/storm_peaks_01-scene-hooks.json" % DATA_DIR, hooks)

func _object(id: String, type: String, asset: String, position: Vector2, collision_role: String) -> Dictionary:
	return {"id": id, "type": type, "asset": asset, "position_px": _vec_dict(position), "anchor": "bottom_center", "render_layer": "interactive_markers", "collision_role": collision_role}

func _route_points() -> Array:
	var points := []
	for i in ROUTE_PLATFORMS.size():
		var segment := ROUTE_PLATFORMS[i]
		points.append({"id": "route_%02d" % i, "tile": {"x": segment.x, "y": segment.y}})
	return points

func _jump_pair_metadata() -> Array:
	var pairs := []
	for i in range(1, ROUTE_PLATFORMS.size()):
		var previous := ROUTE_PLATFORMS[i - 1]
		var current := ROUTE_PLATFORMS[i]
		pairs.append({
			"from_tile": {"x": previous.x + previous.z - 1, "y": previous.y},
			"to_tile": {"x": current.x, "y": current.y},
			"horizontal_gap_tiles": current.x - (previous.x + previous.z),
			"vertical_rise_tiles": previous.y - current.y,
		})
	return pairs

func _segment_metadata() -> Array:
	var segments := []
	for i in ROUTE_PLATFORMS.size():
		var segment := ROUTE_PLATFORMS[i]
		segments.append({"id": "storm_solid_%02d" % i, "tile_rect": {"x": segment.x, "y": segment.y, "w": segment.z, "h": 15 - segment.y}, "collision": "solid"})
	return segments

func _hazard_metadata() -> Array:
	var hazards := []
	for i in HAZARD_GAPS.size():
		var gap := HAZARD_GAPS[i]
		hazards.append({"id": "electric_gap_%02d" % i, "tile_rect": {"x": gap.x, "y": gap.y, "w": gap.z, "h": 1}, "type": "damage_area"})
	return hazards

func _vec_dict(value: Vector2) -> Dictionary:
	return {"x": int(value.x), "y": int(value.y)}

func _gradient(image: Image, top: Color, bottom: Color) -> void:
	for y in image.get_height():
		var t := float(y) / float(maxi(image.get_height() - 1, 1))
		var color := top.lerp(bottom, t)
		for x in image.get_width():
			image.set_pixel(x, y, color)

func _draw_cloud_bands(image: Image, layer: int) -> void:
	for band in range(0, 5):
		var y := 72 + band * 78 + layer * 14
		var color := Color(0.16, 0.16, 0.29, 0.10 + band * 0.014)
		for i in range(0, 9):
			var x := (i * 181 + band * 73 + layer * 51) % image.get_width()
			var width := 150 + (i % 4) * 52
			var height := 18 + (i % 3) * 7
			_blend_rect(image, x - width / 2, y + (i % 4) * 13, width, height, color)
			_blend_rect(image, x - width / 3, y + 10 + (i % 5) * 9, int(width * 0.7), height, color)

func _draw_sky_noise(image: Image, count: int, color: Color) -> void:
	for i in range(0, count):
		var x := (i * 173 + 41) % image.get_width()
		var y := 38 + ((i * 47 + 19) % 230)
		_blend_rect(image, x, y, 2 + i % 2, 2 + int(i / 3) % 2, color)

func _draw_moon_haze(image: Image, x: int, y: int, radius: int) -> void:
	for r in range(radius, 12, -12):
		_blend_circle(image, Vector2i(x, y), r, Color(0.42, 0.48, 0.72, 0.018))
	_blend_circle(image, Vector2i(x, y), 18, Color(0.56, 0.62, 0.86, 0.16))

func _draw_fog_band(image: Image, y0: int, y1: int, color: Color) -> void:
	for y in range(y0, y1):
		var t := sin(float(y - y0) * 0.045) * 0.5 + 0.5
		for x in range(0, image.get_width(), 4):
			if ((x + y * 3) % 29) < 17:
				_blend_rect(image, x, y, 4, 1, Color(color.r, color.g, color.b, color.a * (0.45 + t * 0.55)))

func _draw_mountains(image: Image, color: Color, base_y: int, step: int, seed: int) -> void:
	var points: Array[Vector2i] = [Vector2i(0, image.get_height()), Vector2i(0, base_y)]
	for x in range(0, image.get_width() + 80, 80):
		var peak := base_y - 70 - ((x + seed * 37) % 170)
		points.append(Vector2i(x + 40, peak))
		points.append(Vector2i(x + 80, base_y + ((x + seed) % step)))
	points.append(Vector2i(image.get_width(), image.get_height()))
	_poly(image, points, color)

func _draw_pylon(image: Image, x: int, y: int, h: int, color: Color) -> void:
	_rect(image, x, y - h, 14, h, color)
	_rect(image, x - 28, y - h + 20, 70, 10, color)
	_draw_line(image, Vector2i(x - 20, y - h + 28), Vector2i(x + 42, y - 8), color, 4)
	_rect(image, x + 3, y - h + 8, 8, 8, Color(0.28, 0.82, 1.0, 0.55))
	_rect(image, x + 5, y - h + 22, 4, h - 34, Color(0.22, 0.58, 0.86, 0.18))

func _draw_cable(image: Image, a: Vector2i, b: Vector2i, color: Color) -> void:
	var mid := Vector2i((a.x + b.x) / 2, maxi(a.y, b.y) + 22)
	_draw_line(image, a, mid, color, 3)
	_draw_line(image, mid, b, color, 3)
	_draw_line(image, a + Vector2i(0, 4), mid + Vector2i(0, 4), Color(0.18, 0.52, 0.72, 0.22), 1)
	_draw_line(image, mid + Vector2i(0, 4), b + Vector2i(0, 4), Color(0.18, 0.52, 0.72, 0.22), 1)

func _draw_chain(image: Image, x: int, y: int, length: int, color: Color) -> void:
	for i in range(0, length, 10):
		_rect(image, x - 2, y + i, 5, 7, color)
		_rect(image, x - 5, y + i + 3, 11, 2, Color(0.22, 0.20, 0.31, 1))

func _draw_rune_cluster(image: Image, x: int, y: int, color: Color) -> void:
	_rect(image, x - 8, y, 16, 3, color)
	_rect(image, x - 2, y - 7, 4, 18, color)
	_draw_line(image, Vector2i(x - 9, y + 10), Vector2i(x + 9, y - 10), color, 1)

func _draw_reference_platform(image: Image, px: int, py: int, pw: int) -> void:
	_rect(image, px, py - 2, pw, 5, Color(0.78, 0.82, 0.94, 1))
	_rect(image, px, py + 3, pw, 9, Color(0.42, 0.45, 0.56, 1))
	_rect(image, px, py + 12, pw, 48, Color(0.12, 0.10, 0.20, 1))
	for x in range(px + 8, px + pw, 28):
		_draw_line(image, Vector2i(x, py + 52), Vector2i(x + 22, py + 14), Color(0.27, 0.84, 1.0, 0.62), 1)

func _draw_reference_hazard(image: Image, x: int, y: int, w: int) -> void:
	_rect(image, x, y + 6, w, 4, Color(0.13, 0.09, 0.22, 1))
	for i in range(0, w, 12):
		_draw_line(image, Vector2i(x + i, y + 8), Vector2i(x + i + 8, y - 8), Color(0.25, 0.95, 1.0, 1), 2)
		_circle(image, Vector2i(x + i + 5, y), 5, Color(0.55, 0.62, 1.0, 0.28))

func _draw_cracks(image: Image, ox: int, oy: int, seed: int, dark: Color, glow: Color) -> void:
	for i in range(0, 3):
		var sx := ox + 5 + ((seed * 11 + i * 9) % 22)
		var sy := oy + 10 + ((seed * 7 + i * 5) % 16)
		var ex := clampi(sx + 5 - ((seed + i) % 11), ox + 1, ox + 30)
		var ey := clampi(sy + 7 + ((seed + i * 3) % 8), oy + 2, oy + 30)
		_draw_line(image, Vector2i(sx, sy), Vector2i(ex, ey), dark, 1)
		if i == 0:
			_draw_line(image, Vector2i(sx, sy), Vector2i(ex, ey), Color(glow.r, glow.g, glow.b, 0.42), 1)

func _draw_flag_icon(image: Image, x: int, y: int, color: Color) -> void:
	_rect(image, x, y - 74, 6, 74, Color(0.14, 0.12, 0.22, 1))
	_rect(image, x + 2, y - 70, 4, 66, Color(0.34, 0.72, 0.95, 1))
	_poly(image, [Vector2i(x + 6, y - 70), Vector2i(x + 42, y - 58), Vector2i(x + 6, y - 42)], color)

func _draw_gate_icon(image: Image, x: int, y: int) -> void:
	_rect(image, x - 36, y - 82, 14, 82, Color(0.14, 0.12, 0.24, 1))
	_rect(image, x + 22, y - 82, 14, 82, Color(0.14, 0.12, 0.24, 1))
	_rect(image, x - 38, y - 88, 76, 14, Color(0.20, 0.16, 0.32, 1))
	_rect(image, x - 20, y - 64, 40, 56, Color(0.14, 0.40, 0.62, 0.75))
	_draw_lightning(image, x, y - 72, Color(0.78, 0.92, 1.0, 1), 3)

func _draw_lightning(image: Image, x: int, y: int, color: Color, width: int) -> void:
	var points := [
		Vector2i(x, y),
		Vector2i(x - 16, y + 34),
		Vector2i(x + 2, y + 34),
		Vector2i(x - 14, y + 78),
		Vector2i(x + 22, y + 24),
		Vector2i(x + 4, y + 26),
	]
	for i in range(1, points.size()):
		_draw_line(image, points[i - 1], points[i], color, width)

func _draw_line(image: Image, a: Vector2i, b: Vector2i, color: Color, width: int) -> void:
	var dx: int = absi(b.x - a.x)
	var sx: int = 1 if a.x < b.x else -1
	var dy: int = -absi(b.y - a.y)
	var sy: int = 1 if a.y < b.y else -1
	var err: int = dx + dy
	var x: int = a.x
	var y: int = a.y
	while true:
		_rect(image, x - width / 2, y - width / 2, width, width, color)
		if x == b.x and y == b.y:
			break
		var e2: int = 2 * err
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy

func _poly(image: Image, points: Array[Vector2i], color: Color) -> void:
	var min_y := image.get_height()
	var max_y := 0
	for p in points:
		min_y = mini(min_y, p.y)
		max_y = maxi(max_y, p.y)
	for y in range(maxi(min_y, 0), mini(max_y + 1, image.get_height())):
		var intersections: Array[float] = []
		for i in points.size():
			var a := points[i]
			var b := points[(i + 1) % points.size()]
			if (a.y <= y and b.y > y) or (b.y <= y and a.y > y):
				var t := float(y - a.y) / float(b.y - a.y)
				intersections.append(lerpf(float(a.x), float(b.x), t))
		intersections.sort()
		for i in range(0, intersections.size(), 2):
			if i + 1 >= intersections.size():
				break
			_rect(image, int(intersections[i]), y, int(intersections[i + 1] - intersections[i]) + 1, 1, color)

func _rect(image: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	image.fill_rect(Rect2i(x, y, w, h).intersection(Rect2i(Vector2i.ZERO, image.get_size())), color)

func _circle(image: Image, center: Vector2i, radius: int, color: Color) -> void:
	var r2 := radius * radius
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			var dx := x - center.x
			var dy := y - center.y
			if dx * dx + dy * dy <= r2:
				_rect(image, x, y, 1, 1, color)

func _blend_rect(image: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	var rect := Rect2i(x, y, w, h).intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	for py in range(rect.position.y, rect.position.y + rect.size.y):
		for px in range(rect.position.x, rect.position.x + rect.size.x):
			var base := image.get_pixel(px, py)
			image.set_pixel(px, py, base.lerp(Color(color.r, color.g, color.b, 1.0), color.a))

func _blend_circle(image: Image, center: Vector2i, radius: int, color: Color) -> void:
	var r2 := radius * radius
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
				continue
			var dx := x - center.x
			var dy := y - center.y
			if dx * dx + dy * dy <= r2:
				var base := image.get_pixel(x, y)
				image.set_pixel(x, y, base.lerp(Color(color.r, color.g, color.b, 1.0), color.a))

func _save_png(image: Image, path: String) -> void:
	var error := image.save_png(path)
	if error != OK:
		push_error("Could not save %s: %s" % [path, error])
	else:
		print("Saved %s" % path)

func _save_resource(resource: Resource, path: String) -> bool:
	var error := ResourceSaver.save(resource, path)
	if error != OK:
		push_error("Could not save %s: %s" % [path, error])
		return false
	print("Saved %s" % path)
	return true

func _pack_scene(root: Node, path: String) -> bool:
	var packed := PackedScene.new()
	var pack_error := packed.pack(root)
	if pack_error != OK:
		push_error("Could not pack %s: %s" % [path, pack_error])
		root.free()
		return false
	var ok := _save_resource(packed, path)
	root.free()
	return ok

func _write_text(path: String, content: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write %s: %s" % [path, FileAccess.get_open_error()])
		return false
	file.store_string(content)
	return true

func _write_json(path: String, value: Variant) -> bool:
	return _write_text(path, JSON.stringify(value, "\t") + "\n")

func _owned(node: Node, owner: Node) -> void:
	node.owner = owner
