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
var _player: Kira = null
var _run_failed: bool = false

func _ready() -> void:
	_player = get_node_or_null("Kira") as Kira
	var start_point := get_node_or_null("StartPoint") as Marker2D
	if start_point:
		_start_position = start_point.position
	elif _player:
		_start_position = _player.position
	var end_flag: Area2D = get_node_or_null("EndFlag")
	if end_flag:
		end_flag.body_entered.connect(_on_end_flag_body_entered)
	_configure_player_camera()

func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		return
	if not _run_failed and _player.current_health <= 0.0:
		_run_failed = true
		player_failed.emit()
	if not _run_failed and _player.global_position.y > fall_limit_y:
		_run_failed = true
		player_failed.emit()

func _on_end_flag_body_entered(body: Node) -> void:
	if body is CharacterBase:
		area_completed.emit()

func reset_area() -> void:
	_run_failed = false
	_reset_enemies()
	_player = get_node_or_null("Kira") as Kira
	if _player == null:
		return
	_player.reset_for_run(_start_position)
	_configure_player_camera()

func get_player() -> Kira:
	if not is_instance_valid(_player):
		_player = get_node_or_null("Kira") as Kira
	return _player

func _configure_player_camera() -> void:
	var player := get_player()
	if player == null:
		return

	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return

	camera.limit_left = camera_limit_left
	camera.limit_top = camera_limit_top
	camera.limit_right = camera_limit_right
	camera.limit_bottom = camera_limit_bottom

func _reset_enemies() -> void:
	var enemies := get_node_or_null("Enemies")
	if enemies == null:
		return
	for child in enemies.get_children():
		if child is EnemyBase:
			child.reset_for_run()
