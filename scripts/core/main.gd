class_name Main
extends Node2D
## Controls the title screen, active run, and game-over restart flow.

# === Onready ===
@onready var area: AreaBase = $EmberFields
@onready var hud: HUD = $HUD
@onready var title_screen: CanvasLayer = $TitleScreen
@onready var game_over_screen: CanvasLayer = $GameOverScreen
@onready var start_button: Button = $TitleScreen/Panel/StartButton
@onready var quit_button: Button = $TitleScreen/Panel/QuitButton
@onready var restart_button: Button = $GameOverScreen/Panel/RestartButton
@onready var exit_button: Button = $GameOverScreen/Panel/ExitButton

var _run_id: int = 0

func _ready() -> void:
	title_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	game_over_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	start_button.pressed.connect(_start_game)
	quit_button.pressed.connect(_quit_game)
	restart_button.pressed.connect(_restart_game)
	exit_button.pressed.connect(_show_title_screen)
	area.player_failed.connect(_show_game_over)
	area.area_completed.connect(_show_victory)
	_show_title_screen()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and title_screen.visible:
		_start_game()
	elif event.is_action_pressed("ui_accept") and game_over_screen.visible:
		_restart_game()
	elif event.is_action_pressed("ui_cancel"):
		_show_title_screen()

func _start_game() -> void:
	_run_id += 1
	title_screen.visible = false
	game_over_screen.visible = false
	area.visible = true
	hud.visible = true
	area.process_mode = Node.PROCESS_MODE_INHERIT
	hud.process_mode = Node.PROCESS_MODE_INHERIT
	area.reset_area()
	hud.bind_kira(area.get_player())

func _restart_game() -> void:
	_start_game()

func _show_title_screen() -> void:
	title_screen.visible = true
	game_over_screen.visible = false
	area.visible = false
	hud.visible = false
	area.process_mode = Node.PROCESS_MODE_DISABLED
	hud.process_mode = Node.PROCESS_MODE_DISABLED

func _show_game_over() -> void:
	call_deferred("_handle_death", _run_id)

func _handle_death(run_id: int) -> void:
	if run_id != _run_id:
		return
	var fade: ColorRect = get_node_or_null("DeathFade/Black")
	if fade == null:
		area.respawn_player()
		return
	var fade_in: Tween = create_tween()
	fade_in.tween_property(fade, "color:a", 1.0, 0.2)
	fade_in.tween_callback(func() -> void:
		area.respawn_player()
	)
	fade_in.tween_interval(0.05)
	fade_in.tween_property(fade, "color:a", 0.0, 0.25)

func _show_victory() -> void:
	call_deferred("_apply_victory", _run_id)

func _apply_victory(run_id: int) -> void:
	if run_id != _run_id:
		return
	area.process_mode = Node.PROCESS_MODE_DISABLED
	hud.process_mode = Node.PROCESS_MODE_DISABLED
	hud.visible = false
	$GameOverScreen/Panel/TitleLabel.text = "Area Clear"
	$GameOverScreen/Panel/BodyLabel.text = "You reached the Ember Fields goal."
	game_over_screen.visible = true

func _quit_game() -> void:
	get_tree().quit()
