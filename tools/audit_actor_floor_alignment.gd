extends SceneTree
## Audits all area scenes so actors share the same visual floor baseline.

const AREA_SCENES: Array[String] = [
	"res://scenes/areas/drowned_coast.tscn",
	"res://scenes/areas/drowned_coast_level_2.tscn",
	"res://scenes/areas/drowned_coast_level_3.tscn",
	"res://scenes/areas/drowned_coast_level_4.tscn",
	"res://scenes/areas/drowned_coast_level_5.tscn",
	"res://scenes/areas/drowned_coast_boss_1_arena.tscn",
	"res://scenes/areas/drowned_coast_boss_2_arena.tscn",
	"res://scenes/areas/drowned_coast_boss_3_arena.tscn",
	"res://scenes/areas/drowned_coast_boss_4_arena.tscn",
	"res://scenes/areas/drowned_coast_boss_5_arena.tscn",
	"res://scenes/areas/ember_fields.tscn",
	"res://scenes/areas/ember_fields_level_2.tscn",
	"res://scenes/areas/ember_fields_level_3.tscn",
	"res://scenes/areas/ember_fields_level_4.tscn",
	"res://scenes/areas/ember_fields_level_5.tscn",
	"res://scenes/areas/ember_fields_boss_1_arena.tscn",
	"res://scenes/areas/ember_fields_boss_2_arena.tscn",
	"res://scenes/areas/ember_fields_boss_3_arena.tscn",
	"res://scenes/areas/ember_fields_boss_4_arena.tscn",
	"res://scenes/areas/ember_fields_boss_5_arena.tscn",
	"res://scenes/areas/storm_peaks.tscn",
	"res://scenes/areas/storm_peaks_level_2.tscn",
	"res://scenes/areas/storm_peaks_level_3.tscn",
	"res://scenes/areas/storm_peaks_level_4.tscn",
	"res://scenes/areas/storm_peaks_level_5.tscn",
	"res://scenes/areas/storm_peaks_boss_1_arena.tscn",
	"res://scenes/areas/storm_peaks_boss_2_arena.tscn",
	"res://scenes/areas/storm_peaks_boss_3_arena.tscn",
	"res://scenes/areas/storm_peaks_boss_4_arena.tscn",
	"res://scenes/areas/storm_peaks_boss_5_arena.tscn",
]

const TOLERANCE_PX := 4.0

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for scene_path in AREA_SCENES:
		await _audit_scene(scene_path)
	if _failures.is_empty():
		print("[actor_floor_alignment] PASS")
	else:
		for failure in _failures:
			push_error(failure)
		print("[actor_floor_alignment] FAIL %d actor baseline issue(s)" % _failures.size())
	quit(1 if not _failures.is_empty() else 0)

func _audit_scene(scene_path: String) -> void:
	var packed := load(scene_path) as PackedScene
	if packed == null:
		_failures.append("%s does not load" % scene_path)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame

	var kira := scene.get_node_or_null("Party/Kira") as CharacterBody2D
	if kira == null:
		scene.queue_free()
		await process_frame
		return
	var reference := _sprite_bottom_offset(kira.get_node_or_null("%AnimatedSprite2D") as AnimatedSprite2D)
	if is_inf(reference):
		_failures.append("%s Party/Kira has no measurable sprite baseline" % scene_path)
		scene.queue_free()
		await process_frame
		return

	for actor in _actors_under(scene.get_node_or_null("Party")):
		_check_actor(scene_path, scene, actor, reference)
	for actor in _actors_under(scene.get_node_or_null("Enemies")):
		if not (scene_path.contains("_boss_") and actor.name == "Boss"):
			_check_actor(scene_path, scene, actor, reference)
	_check_boss_arena_visual_floor(scene_path, scene)
	_check_boss_arena_floor(scene_path, scene, kira)

	scene.queue_free()
	await process_frame

func _actors_under(parent: Node) -> Array[CharacterBody2D]:
	var actors: Array[CharacterBody2D] = []
	if parent == null:
		return actors
	for child in parent.get_children():
		if child is CharacterBody2D:
			actors.append(child)
	return actors

func _check_actor(scene_path: String, scene: Node, actor: CharacterBody2D, reference: float) -> void:
	var sprite := actor.get_node_or_null("%AnimatedSprite2D") as AnimatedSprite2D
	var offset := _sprite_bottom_offset(sprite)
	if is_inf(offset):
		_failures.append("%s %s has no measurable sprite baseline" % [scene_path, scene.get_path_to(actor)])
		return
	var delta := offset - reference
	if absf(delta) > TOLERANCE_PX:
		_failures.append(
			"%s %s visual baseline differs by %.2fpx (actor %.2f, Kira %.2f)"
			% [scene_path, scene.get_path_to(actor), delta, offset, reference]
		)

func _check_boss_arena_floor(scene_path: String, scene: Node, kira: CharacterBody2D) -> void:
	if not scene_path.contains("_boss_"):
		return
	var boss := scene.get_node_or_null("Enemies/Boss") as CharacterBody2D
	if boss == null:
		return
	var player := kira
	if scene.has_method("get_player"):
		var active_player := scene.call("get_player") as CharacterBody2D
		if active_player != null:
			player = active_player
	var kira_floor := _sprite_floor_y(player.get_node_or_null("%AnimatedSprite2D") as AnimatedSprite2D)
	var boss_floor := _sprite_floor_y(boss.get_node_or_null("%AnimatedSprite2D") as AnimatedSprite2D)
	if is_inf(kira_floor) or is_inf(boss_floor):
		return
	var delta := boss_floor - kira_floor
	if absf(delta) > TOLERANCE_PX:
		_failures.append(
			"%s boss global foot line differs by %.2fpx (boss %.2f, player %.2f)"
			% [scene_path, delta, boss_floor, kira_floor]
		)

func _check_boss_arena_visual_floor(scene_path: String, scene: Node) -> void:
	if not scene_path.contains("_boss_"):
		return
	if scene.get_node_or_null("ArenaEnvironment/ForegroundEdge") != null:
		_failures.append("%s has duplicate foreground floor lip" % scene_path)
	var ground := scene.get_node_or_null("Ground")
	if scene.get_node_or_null("ArenaEnvironment/ArenaFloorVisual") == null and not (ground is TileMapLayer):
		_failures.append("%s is missing boss arena floor art" % scene_path)

func _sprite_floor_y(sprite: AnimatedSprite2D) -> float:
	var visible_bottom := _visible_bottom_y_for_sprite(sprite)
	if visible_bottom < 0:
		return INF
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
	var texture_size := texture.get_size()
	var local_bottom := visible_bottom - texture_size.y * 0.5 if sprite.centered else visible_bottom
	return sprite.global_position.y + local_bottom * absf(sprite.global_scale.y)

func _sprite_bottom_offset(sprite: AnimatedSprite2D) -> float:
	if sprite == null or sprite.sprite_frames == null:
		return INF
	var animation := sprite.animation
	if not sprite.sprite_frames.has_animation(animation):
		return INF
	var texture := sprite.sprite_frames.get_frame_texture(animation, 0)
	if texture == null:
		return INF
	var visible_bottom := _visible_bottom_y_for_sprite(sprite)
	if visible_bottom < 0:
		return INF
	var texture_size := texture.get_size()
	var local_bottom := visible_bottom - texture_size.y * 0.5 if sprite.centered else visible_bottom
	return sprite.position.y + local_bottom * absf(sprite.scale.y)

func _visible_bottom_y_for_sprite(sprite: AnimatedSprite2D) -> float:
	if sprite == null or sprite.sprite_frames == null:
		return -1.0
	if not sprite.sprite_frames.has_animation(sprite.animation):
		return -1.0
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
	if texture == null:
		return -1.0
	return _visible_bottom_y(texture)

func _visible_bottom_y(texture: Texture2D) -> float:
	var image := texture.get_image()
	if image == null:
		return -1.0
	var bottom := -1
	for y in image.get_height():
		var scan_y := image.get_height() - 1 - y
		for x in image.get_width():
			if image.get_pixel(x, scan_y).a > 0.05:
				bottom = scan_y
				break
		if bottom >= 0:
			break
	return float(bottom)
