class_name AreaBase
extends Node2D
## Base for all game areas. Handles area completion signal.

# === Signals ===
signal area_completed
signal player_failed

# === Exports ===
@export var camera_limit_left: int = 0
@export var camera_limit_top: int = -256
@export var camera_limit_right: int = 3520
@export var camera_limit_bottom: int = 480
@export var fall_limit_y: float = 520.0

# === Private Variables ===
var _start_position: Vector2 = Vector2.ZERO
var _player: CharacterBase = null
var _run_failed: bool = false
var _respawning: bool = false

func _ready() -> void:
	_player = _find_player()
	var start_point := get_node_or_null("StartPoint") as Marker2D
	if start_point:
		_start_position = start_point.position
	elif _player:
		_start_position = _player.position
	var end_flag: Area2D = get_node_or_null("EndFlag")
	if end_flag:
		end_flag.body_entered.connect(_on_end_flag_body_entered)
	var checkpoint_system := _checkpoint_system()
	if checkpoint_system and checkpoint_system.has_method("reset_for_new_area"):
		checkpoint_system.reset_for_new_area(_start_position)
	var start_cp: Node = get_node_or_null("CheckpointStart")
	if start_cp and start_cp.has_method("force_activate"):
		start_cp.force_activate()
	_configure_player_camera()
	call_deferred("_check_subviewport_fallback")

func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		return
	if _respawning:
		return
	if not _run_failed and _player.current_health <= 0.0:
		_run_failed = true
		player_failed.emit()
	if not _run_failed and _player.global_position.y > fall_limit_y:
		_run_failed = true
		player_failed.emit()

# Respawn the active player at the last activated checkpoint (or default_spawn).
# Keeps the run alive — does NOT show a game-over overlay.
func respawn_player() -> void:
	_respawning = true
	_run_failed = false
	var checkpoint_system := _checkpoint_system()
	var spawn_point: Vector2 = _start_position
	if checkpoint_system and checkpoint_system.has_method("get_spawn_point"):
		spawn_point = checkpoint_system.get_spawn_point()
	var player: CharacterBase = get_player()
	if player != null:
		player.reset_for_run(spawn_point)
	_reset_enemies()
	_respawning = false

func _on_end_flag_body_entered(body: Node) -> void:
	if body is CharacterBase:
		area_completed.emit()

func reset_area() -> void:
	_run_failed = false
	_reset_enemies()
	_player = _find_player()
	if _player == null:
		return
	_player.reset_for_run(_start_position)
	_configure_player_camera()

func get_player() -> CharacterBase:
	if not is_instance_valid(_player):
		_player = _find_player()
	return _player

func _configure_player_camera() -> void:
	var camera := get_node_or_null("Party/Camera2D") as Camera2D
	if camera == null:
		return

	camera.limit_left = camera_limit_left
	camera.limit_top = camera_limit_top
	camera.limit_right = camera_limit_right
	camera.limit_bottom = camera_limit_bottom

func _find_player() -> CharacterBase:
	var switcher := _character_switcher()
	if switcher and switcher.has_method("active"):
		var active := switcher.active() as CharacterBase
		if active:
			return active
	var party := get_node_or_null("Party")
	if party:
		var kira := party.get_node_or_null("Kira") as CharacterBase
		if kira:
			return kira
	return get_node_or_null("Kira") as CharacterBase

func _character_switcher() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("CharacterSwitcher")

func _checkpoint_system() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("CheckpointSystem")

func _reset_enemies() -> void:
	var enemies := get_node_or_null("Enemies")
	if enemies == null:
		return
	for child in enemies.get_children():
		if child is EnemyBase:
			child.reset_for_run()

# Verifies the BgFar SubViewport has a valid texture; falls back to the PNG sprite if not.
func _check_subviewport_fallback() -> void:
	var sub_container: Node = get_node_or_null("ParallaxBackground/BgFar/SubViewportContainer")
	var fallback: Node = get_node_or_null("ParallaxBackground/BgFar/FallbackSprite")
	if sub_container == null or fallback == null:
		return
	var sub_viewport: SubViewport = sub_container.get_node_or_null("SubViewport")
	if sub_viewport == null:
		_activate_fallback(sub_container, fallback)
		return
	await get_tree().process_frame
	await get_tree().process_frame
	var tex: ViewportTexture = sub_viewport.get_texture()
	if tex == null:
		_activate_fallback(sub_container, fallback)
		return
	if DisplayServer.get_name() == "headless":
		_activate_fallback(sub_container, fallback)
		return
	var img: Image = tex.get_image()
	if img == null or img.is_empty():
		_activate_fallback(sub_container, fallback)

func _activate_fallback(sub_container: Node, fallback: Node) -> void:
	push_warning("SubViewport volcano bg failed — falling back to static PNG.")
	sub_container.visible = false
	fallback.visible = true
