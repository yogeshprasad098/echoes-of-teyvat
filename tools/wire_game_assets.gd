extends SceneTree

const KIRA_FRAMES_PATH := "res://resources/sprite_frames/kira_sprite_frames.tres"
const GRUNT_FRAMES_PATH := "res://resources/sprite_frames/grunt_sprite_frames.tres"
const EMBER_TILESET_PATH := "res://resources/tilesets/ember_fields_tileset.tres"

const TILE_SOURCE_ID := 0
const GROUND_TILE := Vector2i(0, 0)
const PLATFORM_TILE := Vector2i(1, 0)
const LAVA_TILE := Vector2i(2, 0)
const ROCK_TILE := Vector2i(3, 0)
const WORLD_LAYER := 1
const PLAYER_LAYER := 2
const ENEMY_LAYER := 4

func _initialize() -> void:
	var failed := false
	failed = not _ensure_dirs() or failed
	failed = not _save_kira_frames() or failed
	failed = not _save_grunt_frames() or failed
	failed = not _save_ember_tileset() or failed
	failed = not _wire_kira_scene() or failed
	failed = not _wire_grunt_scene() or failed
	failed = not _wire_fire_bomb_scene() or failed
	failed = not _wire_ember_fields_scene() or failed
	quit(1 if failed else 0)

func _ensure_dirs() -> bool:
	var dir := DirAccess.open("res://")
	if dir == null:
		push_error("Could not open res://")
		return false
	for path in ["resources/sprite_frames", "resources/tilesets"]:
		var error := dir.make_dir_recursive(path)
		if error != OK and error != ERR_ALREADY_EXISTS:
			push_error("Could not create %s: %s" % [path, error])
			return false
	return true

func _save_kira_frames() -> bool:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	_add_strip_animation(frames, "idle", "res://assets/characters/kira/idle.png", Vector2i(32, 48), 4, 6.0, true)
	_add_strip_animation(frames, "run", "res://assets/characters/kira/run.png", Vector2i(32, 48), 6, 10.0, true)
	_add_strip_animation(frames, "jump", "res://assets/characters/kira/jump.png", Vector2i(32, 48), 3, 8.0, false)
	_add_strip_animation(frames, "attack_1", "res://assets/characters/kira/attack.png", Vector2i(32, 48), 4, 12.0, false, 0)
	_add_strip_animation(frames, "attack_2", "res://assets/characters/kira/attack.png", Vector2i(32, 48), 4, 12.0, false, 4)
	_add_strip_animation(frames, "attack_3", "res://assets/characters/kira/attack.png", Vector2i(32, 48), 4, 12.0, false, 8)
	_add_strip_animation(frames, "skill", "res://assets/characters/kira/skill.png", Vector2i(32, 48), 4, 10.0, false)
	_add_strip_animation(frames, "dodge", "res://assets/characters/kira/dodge.png", Vector2i(32, 48), 4, 12.0, false)
	_add_strip_animation(frames, "hurt", "res://assets/characters/kira/hurt.png", Vector2i(32, 48), 2, 8.0, false)
	_add_strip_animation(frames, "death", "res://assets/characters/kira/death.png", Vector2i(32, 48), 5, 8.0, false)
	return _save_resource(frames, KIRA_FRAMES_PATH)

func _save_grunt_frames() -> bool:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	_add_strip_animation(frames, "idle", "res://assets/enemies/grunt/idle.png", Vector2i(32, 32), 4, 6.0, true)
	_add_strip_animation(frames, "walk", "res://assets/enemies/grunt/walk.png", Vector2i(32, 32), 6, 8.0, true)
	_add_strip_animation(frames, "attack", "res://assets/enemies/grunt/attack.png", Vector2i(32, 32), 4, 10.0, false)
	_add_strip_animation(frames, "death", "res://assets/enemies/grunt/death.png", Vector2i(32, 32), 5, 8.0, false)
	return _save_resource(frames, GRUNT_FRAMES_PATH)

func _add_strip_animation(frames: SpriteFrames, animation_name: StringName, path: String, frame_size: Vector2i, frame_count: int, speed: float, loops: bool, start_frame: int = 0) -> void:
	var source_texture := load(path) as Texture2D
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, speed)
	frames.set_animation_loop(animation_name, loops)
	for index in frame_count:
		var atlas_texture := AtlasTexture.new()
		atlas_texture.atlas = source_texture
		atlas_texture.region = Rect2(Vector2((start_frame + index) * frame_size.x, 0), Vector2(frame_size))
		frames.add_frame(animation_name, atlas_texture)

func _save_ember_tileset() -> bool:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(32, 32)
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1)
	tile_set.set_physics_layer_collision_mask(0, 1)

	var source := TileSetAtlasSource.new()
	source.texture = load("res://assets/tilesets/ember_fields/ember_tileset.png")
	source.texture_region_size = Vector2i(32, 32)
	tile_set.add_source(source, TILE_SOURCE_ID)

	for y in 4:
		for x in 4:
			var coords := Vector2i(x, y)
			source.create_tile(coords)
			if coords != LAVA_TILE:
				_add_solid_collision(source, coords)

	return _save_resource(tile_set, EMBER_TILESET_PATH)

func _add_solid_collision(source: TileSetAtlasSource, coords: Vector2i) -> void:
	var tile_data := source.get_tile_data(coords, 0)
	tile_data.add_collision_polygon(0)
	tile_data.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(0, 0),
		Vector2(32, 0),
		Vector2(32, 32),
		Vector2(0, 32),
	]))

func _wire_kira_scene() -> bool:
	var root := _instantiate_scene("res://scenes/characters/kira.tscn")
	if root == null:
		return false
	root.set_script(load("res://scripts/characters/kira.gd"))
	root.collision_layer = PLAYER_LAYER
	root.collision_mask = WORLD_LAYER
	var sprite := root.get_node("AnimatedSprite2D") as AnimatedSprite2D
	sprite.sprite_frames = load(KIRA_FRAMES_PATH)
	sprite.animation = &"idle"
	sprite.centered = true
	sprite.scale = Vector2(1.25, 1.25)
	sprite.position = Vector2(0, -6)
	var hitbox := root.get_node("HitboxArea2D") as Area2D
	hitbox.collision_layer = 0
	hitbox.collision_mask = ENEMY_LAYER
	var hitbox_shape := root.get_node("HitboxArea2D/CollisionShape2D") as CollisionShape2D
	var attack_shape := RectangleShape2D.new()
	attack_shape.size = Vector2(58, 34)
	hitbox_shape.position = Vector2.ZERO
	hitbox_shape.shape = attack_shape
	_configure_attack_range_guide(root)
	_configure_skill_range_guide(root)
	return _save_scene(root, "res://scenes/characters/kira.tscn")

func _wire_grunt_scene() -> bool:
	var root := _instantiate_scene("res://scenes/enemies/grunt.tscn")
	if root == null:
		return false
	root.set_script(load("res://scripts/enemies/grunt.gd"))
	root.collision_layer = ENEMY_LAYER
	root.collision_mask = WORLD_LAYER
	root.max_health = 50.0
	root.damage = 6.0
	var sprite := root.get_node("AnimatedSprite2D") as AnimatedSprite2D
	sprite.sprite_frames = load(GRUNT_FRAMES_PATH)
	sprite.animation = &"walk"
	sprite.centered = true
	sprite.scale = Vector2(1.2, 1.2)
	sprite.position = Vector2(0, -4)
	var hurtbox := root.get_node("Hurtbox") as Area2D
	hurtbox.collision_layer = ENEMY_LAYER
	hurtbox.collision_mask = 0
	var detection := root.get_node("DetectionArea2D") as Area2D
	detection.collision_layer = 0
	detection.collision_mask = PLAYER_LAYER
	_configure_grunt_feedback(root)
	_configure_grunt_health_bar(root)
	return _save_scene(root, "res://scenes/enemies/grunt.tscn")

func _configure_attack_range_guide(root: Node) -> void:
	var guide := root.get_node_or_null("AttackRangeGuide") as Polygon2D
	if guide == null:
		guide = Polygon2D.new()
		guide.name = "AttackRangeGuide"
		root.add_child(guide)
		guide.owner = root
	guide.visible = false
	guide.z_index = 4
	guide.position = Vector2(12, -2)
	guide.color = Color(1.0, 0.78, 0.18, 0.22)
	guide.polygon = PackedVector2Array([
		Vector2(0, -18),
		Vector2(58, -18),
		Vector2(58, 18),
		Vector2(0, 18),
	])

func _configure_skill_range_guide(root: Node) -> void:
	var guide := root.get_node_or_null("SkillRangeGuide") as Line2D
	if guide == null:
		guide = Line2D.new()
		guide.name = "SkillRangeGuide"
		root.add_child(guide)
		guide.owner = root
	guide.visible = false
	guide.z_index = 4
	guide.points = PackedVector2Array([Vector2(18, -16), Vector2(88, -16)])
	guide.width = 5.0
	guide.default_color = Color(1.0, 0.42, 0.04, 0.45)

func _configure_grunt_feedback(root: Node) -> void:
	var hit_spark := root.get_node_or_null("HitSpark") as Polygon2D
	if hit_spark == null:
		hit_spark = Polygon2D.new()
		hit_spark.name = "HitSpark"
		root.add_child(hit_spark)
		hit_spark.owner = root
	hit_spark.visible = false
	hit_spark.z_index = 9
	hit_spark.color = Color(1.0, 0.92, 0.12, 0.95)
	hit_spark.polygon = PackedVector2Array([
		Vector2(0, -13),
		Vector2(5, -3),
		Vector2(15, -1),
		Vector2(6, 5),
		Vector2(8, 15),
		Vector2(0, 8),
		Vector2(-8, 15),
		Vector2(-6, 5),
		Vector2(-15, -1),
		Vector2(-5, -3),
	])

	var damage_popup := root.get_node_or_null("DamagePopup") as Label
	if damage_popup == null:
		damage_popup = Label.new()
		damage_popup.name = "DamagePopup"
		root.add_child(damage_popup)
		damage_popup.owner = root
	damage_popup.visible = false
	damage_popup.z_index = 10
	damage_popup.offset_left = -11.0
	damage_popup.offset_top = -43.0
	damage_popup.offset_right = 11.0
	damage_popup.offset_bottom = -27.0
	damage_popup.text = "-10"
	damage_popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	damage_popup.add_theme_font_size_override("font_size", 10)
	damage_popup.add_theme_color_override("font_color", Color(1.0, 0.95, 0.28))
	damage_popup.add_theme_color_override("font_shadow_color", Color(0.16, 0.02, 0.0))
	damage_popup.add_theme_constant_override("shadow_offset_x", 1)
	damage_popup.add_theme_constant_override("shadow_offset_y", 1)

func _configure_grunt_health_bar(root: Node) -> void:
	var health_bar := root.get_node_or_null("HealthBar") as Node2D
	if health_bar == null:
		health_bar = Node2D.new()
		health_bar.name = "HealthBar"
		root.add_child(health_bar)
		health_bar.owner = root
	health_bar.z_index = 8
	health_bar.position = Vector2(-16, -30)

	var back := health_bar.get_node_or_null("Back") as ColorRect
	if back == null:
		back = ColorRect.new()
		back.name = "Back"
		health_bar.add_child(back)
		back.owner = root
	back.offset_left = 0.0
	back.offset_top = 0.0
	back.offset_right = 32.0
	back.offset_bottom = 4.0
	back.color = Color(0.07, 0.015, 0.015, 0.9)

	var fill := health_bar.get_node_or_null("Fill") as ColorRect
	if fill == null:
		fill = ColorRect.new()
		fill.name = "Fill"
		health_bar.add_child(fill)
		fill.owner = root
	fill.offset_left = 1.0
	fill.offset_top = 1.0
	fill.offset_right = 31.0
	fill.offset_bottom = 3.0
	fill.color = Color(0.38, 0.95, 0.2)

func _wire_fire_bomb_scene() -> bool:
	var root := _instantiate_scene("res://scenes/projectiles/fire_bomb.tscn")
	if root == null:
		return false
	root.collision_layer = 0
	root.collision_mask = ENEMY_LAYER
	var sprite := root.get_node("Sprite2D") as Sprite2D
	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = load("res://assets/characters/kira/skill.png")
	atlas_texture.region = Rect2(Vector2(96, 0), Vector2(32, 48))
	sprite.texture = atlas_texture
	sprite.scale = Vector2(0.8, 0.8)
	sprite.modulate = Color(1.0, 0.42, 0.05)
	sprite.z_index = 6
	sprite.visible = false

	var visuals := root.get_node_or_null("Visuals") as Node2D
	if visuals == null:
		visuals = Node2D.new()
		visuals.name = "Visuals"
		root.add_child(visuals)
		visuals.owner = root
	visuals.z_index = 8

	_configure_polygon(visuals, root, "Trail", Color(1.0, 0.18, 0.02, 0.42), PackedVector2Array([
		Vector2(-34, -9),
		Vector2(-9, -4),
		Vector2(-6, 4),
		Vector2(-34, 10),
		Vector2(-24, 0),
	]))
	_configure_polygon(visuals, root, "OuterFlame", Color(1.0, 0.22, 0.02, 0.86), PackedVector2Array([
		Vector2(-14, -14),
		Vector2(5, -18),
		Vector2(19, -7),
		Vector2(18, 9),
		Vector2(3, 19),
		Vector2(-15, 13),
		Vector2(-22, -2),
	]))
	_configure_polygon(visuals, root, "InnerFlame", Color(1.0, 0.82, 0.22, 0.95), PackedVector2Array([
		Vector2(-7, -8),
		Vector2(5, -10),
		Vector2(12, -3),
		Vector2(10, 7),
		Vector2(0, 11),
		Vector2(-10, 5),
		Vector2(-12, -3),
	]))
	_configure_polygon(visuals, root, "Core", Color(1.0, 0.98, 0.62, 1.0), PackedVector2Array([
		Vector2(-2, -5),
		Vector2(5, -5),
		Vector2(9, 0),
		Vector2(5, 6),
		Vector2(-3, 5),
		Vector2(-6, 0),
	]))

	var glow := root.get_node_or_null("FireGlow") as Polygon2D
	if glow == null:
		glow = Polygon2D.new()
		glow.name = "FireGlow"
		root.add_child(glow)
		glow.owner = root
	glow.z_index = 5
	glow.color = Color(1.0, 0.2, 0.02, 0.7)
	glow.polygon = PackedVector2Array([
		Vector2(0, -18),
		Vector2(18, 0),
		Vector2(0, 18),
		Vector2(-18, 0),
	])
	return _save_scene(root, "res://scenes/projectiles/fire_bomb.tscn")

func _configure_polygon(parent: Node, owner: Node, node_name: String, color: Color, polygon: PackedVector2Array) -> void:
	var shape := parent.get_node_or_null(node_name) as Polygon2D
	if shape == null:
		shape = Polygon2D.new()
		shape.name = node_name
		parent.add_child(shape)
		shape.owner = owner
	shape.color = color
	shape.polygon = polygon

func _wire_ember_fields_scene() -> bool:
	var root := _instantiate_scene("res://scenes/areas/ember_fields.tscn")
	if root == null:
		return false
	root.set_script(load("res://scripts/areas/area_base.gd"))
	_assign_parallax(root)
	_build_tilemap(root)
	_place_area_nodes(root)
	_decorate_end_flag(root)
	return _save_scene(root, "res://scenes/areas/ember_fields.tscn")

func _assign_parallax(root: Node) -> void:
	var layers := {
		"ParallaxBackground/BgFar/Sprite2D": "res://assets/backgrounds/ember_fields/bg_far.png",
		"ParallaxBackground/BgMid/Sprite2D": "res://assets/backgrounds/ember_fields/bg_mid.png",
		"ParallaxBackground/BgNear/Sprite2D": "res://assets/backgrounds/ember_fields/bg_near.png",
	}
	for node_path in layers:
		var sprite := root.get_node(node_path) as Sprite2D
		sprite.texture = load(layers[node_path])
		sprite.centered = false
		sprite.scale = Vector2(2, 2)
		sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

	for layer_name in ["BgFar", "BgMid", "BgNear"]:
		var layer := root.get_node("ParallaxBackground/%s" % layer_name) as ParallaxLayer
		layer.motion_mirroring = Vector2(640, 360)

func _build_tilemap(root: Node) -> void:
	var tile_map := root.get_node("TileMap") as TileMap
	tile_map.tile_set = load(EMBER_TILESET_PATH)
	tile_map.clear()

	for x in 110:
		_set_tile(tile_map, x, 12, GROUND_TILE)
		_set_tile(tile_map, x, 13, ROCK_TILE)
		_set_tile(tile_map, x, 14, ROCK_TILE)

	for y in range(7, 15):
		_set_tile(tile_map, -1, y, ROCK_TILE)
		_set_tile(tile_map, -2, y, ROCK_TILE)

	for gap_x in range(18, 20):
		_clear_column(tile_map, gap_x)
		_set_tile(tile_map, gap_x, 14, LAVA_TILE)
	for gap_x in range(35, 37):
		_clear_column(tile_map, gap_x)
		_set_tile(tile_map, gap_x, 14, LAVA_TILE)

	_add_platform(tile_map, 22, 28, 9)
	_add_platform(tile_map, 43, 53, 8)
	_add_platform(tile_map, 63, 76, 10)
	_add_final_goal_staircase(tile_map)
	_add_platform(tile_map, 89, 103, 7)

	for x in range(55, 60):
		_set_tile(tile_map, x, 11, GROUND_TILE)

func _add_final_goal_staircase(tile_map: TileMap) -> void:
	# Each rise is one 32px tile, comfortably under Kira's current jump height.
	_add_platform(tile_map, 76, 82, 10)
	_add_platform(tile_map, 80, 86, 9)
	_add_platform(tile_map, 84, 90, 8)
	_add_platform(tile_map, 88, 92, 7)

func _add_platform(tile_map: TileMap, start_x: int, end_x: int, y: int) -> void:
	for x in range(start_x, end_x + 1):
		_set_tile(tile_map, x, y, PLATFORM_TILE)

func _clear_column(tile_map: TileMap, x: int) -> void:
	for y in range(8, 15):
		tile_map.erase_cell(0, Vector2i(x, y))

func _set_tile(tile_map: TileMap, x: int, y: int, atlas_coords: Vector2i) -> void:
	tile_map.set_cell(0, Vector2i(x, y), TILE_SOURCE_ID, atlas_coords, 0)

func _place_area_nodes(root: Node) -> void:
	root.get_node("StartPoint").position = Vector2(96, 336)
	root.get_node("Kira").position = Vector2(96, 336)
	root.get_node("EndFlag").position = Vector2(3248, 192)
	root.get_node("Enemies/Grunt").position = Vector2(720, 256)
	root.get_node("Enemies/Grunt2").position = Vector2(1536, 224)
	root.get_node("Enemies/Grunt3").position = Vector2(2240, 288)

func _decorate_end_flag(root: Node) -> void:
	var end_flag := root.get_node("EndFlag") as Area2D
	end_flag.collision_layer = 0
	end_flag.collision_mask = PLAYER_LAYER

	var pole := end_flag.get_node_or_null("FlagPole") as Line2D
	if pole == null:
		pole = Line2D.new()
		pole.name = "FlagPole"
		end_flag.add_child(pole)
		pole.owner = root
	pole.points = PackedVector2Array([Vector2(0, 48), Vector2(0, -64)])
	pole.width = 5.0
	pole.default_color = Color(1.0, 0.84, 0.28)

	var pennant := end_flag.get_node_or_null("FlagPennant") as Polygon2D
	if pennant == null:
		pennant = Polygon2D.new()
		pennant.name = "FlagPennant"
		end_flag.add_child(pennant)
		pennant.owner = root
	pennant.polygon = PackedVector2Array([Vector2(0, -64), Vector2(72, -48), Vector2(0, -28)])
	pennant.color = Color(1.0, 0.16, 0.06)

	var goal_label := end_flag.get_node_or_null("GoalLabel") as Label
	if goal_label == null:
		goal_label = Label.new()
		goal_label.name = "GoalLabel"
		end_flag.add_child(goal_label)
		goal_label.owner = root
	goal_label.position = Vector2(-12, 50)
	goal_label.text = "GOAL"
	goal_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.42))

func _instantiate_scene(path: String) -> Node:
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("Could not load scene: %s" % path)
		return null
	return packed.instantiate()

func _save_scene(root: Node, path: String) -> bool:
	var packed := PackedScene.new()
	var pack_error := packed.pack(root)
	if pack_error != OK:
		push_error("Could not pack %s: %s" % [path, pack_error])
		root.free()
		return false
	var saved := _save_resource(packed, path)
	root.free()
	return saved

func _save_resource(resource: Resource, path: String) -> bool:
	var error := ResourceSaver.save(resource, path)
	if error != OK:
		push_error("Could not save %s: %s" % [path, error])
		return false
	print("Saved %s" % path)
	return true
