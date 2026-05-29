class_name Main
extends Node2D
## Controls the title screen, active run, and game-over restart flow.

const AREA_SCENES: Array[PackedScene] = [
	preload("res://scenes/areas/ember_fields.tscn"),
	preload("res://scenes/areas/boss_1_arena.tscn"),
	preload("res://scenes/areas/ember_fields_level_2.tscn"),
	preload("res://scenes/areas/boss_2_arena.tscn"),
	preload("res://scenes/areas/ember_fields_level_3.tscn"),
	preload("res://scenes/areas/boss_3_arena.tscn"),
	preload("res://scenes/areas/ember_fields_level_4.tscn"),
	preload("res://scenes/areas/boss_4_arena.tscn"),
	preload("res://scenes/areas/ember_fields_level_5.tscn"),
	preload("res://scenes/areas/boss_5_arena.tscn"),
	preload("res://scenes/areas/drowned_coast.tscn"),
	preload("res://scenes/areas/storm_peaks.tscn"),
]
const AREA_NODE_NAMES: Array[StringName] = [
	&"EmberFields",
	&"Boss1Arena",
	&"EmberFieldsLevel2",
	&"Boss2Arena",
	&"EmberFieldsLevel3",
	&"Boss3Arena",
	&"EmberFieldsLevel4",
	&"Boss4Arena",
	&"EmberFieldsLevel5",
	&"Boss5Arena",
	&"DrownedCoast",
	&"StormPeaks",
]
const AREA_DISPLAY_NAMES: Array[String] = [
	"Ember Fields Level 1",
	"Flame Warden",
	"Ember Fields Level 2",
	"Tide Serpent",
	"Ember Fields Level 3",
	"Sparking Sentinel",
	"Ember Fields Level 4",
	"Ash Colossus",
	"Ember Fields Level 5",
	"Ember Tyrant",
	"Drowned Coast",
	"Storm Peaks",
]

var _run_id: int = 0
var _current_area_index: int = 0
var _pending_next_area_index: int = -1
var area: AreaBase = null

# === Onready ===
@onready var hud: HUD = %HUD
@onready var title_screen: CanvasLayer = %TitleScreen
@onready var game_over_screen: CanvasLayer = %GameOverScreen
@onready var start_button: Button = %StartButton
@onready var quit_button: Button = %QuitButton
@onready var restart_button: Button = %RestartButton
@onready var exit_button: Button = %ExitButton
@onready var death_fade: ColorRect = %Black
@onready var game_over_title: Label = %GameOverTitleLabel
@onready var game_over_body: Label = %GameOverBodyLabel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	title_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	game_over_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	start_button.pressed.connect(_start_game)
	quit_button.pressed.connect(_quit_game)
	restart_button.pressed.connect(_on_restart_button_pressed)
	exit_button.pressed.connect(_show_title_screen)
	_show_title_screen()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE:
			_show_title_screen()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
			if title_screen.visible:
				_start_game()
				get_viewport().set_input_as_handled()
			elif game_over_screen.visible:
				_on_restart_button_pressed()
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if title_screen.visible:
			if _button_contains_global_point(start_button, event.position):
				_start_game()
				get_viewport().set_input_as_handled()
			elif _button_contains_global_point(quit_button, event.position):
				_quit_game()
				get_viewport().set_input_as_handled()
		elif game_over_screen.visible:
			if _button_contains_global_point(restart_button, event.position):
				_on_restart_button_pressed()
				get_viewport().set_input_as_handled()
			elif _button_contains_global_point(exit_button, event.position):
				_show_title_screen()
				get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and title_screen.visible:
		_start_game()
	elif event.is_action_pressed("ui_accept") and game_over_screen.visible:
		_on_restart_button_pressed()
	elif event.is_action_pressed("ui_cancel"):
		_show_title_screen()

func _start_game() -> void:
	_run_id += 1
	_pending_next_area_index = -1
	_current_area_index = 0
	title_screen.visible = false
	game_over_screen.visible = false
	hud.visible = true
	hud.process_mode = Node.PROCESS_MODE_INHERIT
	restart_button.text = "Restart"
	_activate_area(_current_area_index, 0)

func _restart_game() -> void:
	_start_game()

func _show_title_screen() -> void:
	_run_id += 1
	_pending_next_area_index = -1
	title_screen.visible = true
	game_over_screen.visible = false
	hud.visible = false
	hud.process_mode = Node.PROCESS_MODE_DISABLED
	restart_button.text = "Restart"
	_clear_area()

func _on_restart_button_pressed() -> void:
	if _pending_next_area_index >= 0:
		_continue_to_next_area()
	else:
		_restart_game()

func _show_game_over(area_index: int) -> void:
	if area_index != _current_area_index:
		return
	call_deferred("_handle_death", _run_id, area_index)

func _handle_death(run_id: int, area_index: int) -> void:
	if run_id != _run_id or area_index != _current_area_index:
		return
	if death_fade == null:
		area.respawn_player()
		return
	var fade_in: Tween = create_tween()
	fade_in.tween_property(death_fade, "color:a", 1.0, 0.2)
	fade_in.tween_callback(func() -> void:
		area.respawn_player()
	)
	fade_in.tween_interval(0.05)
	fade_in.tween_property(death_fade, "color:a", 0.0, 0.25)

func _show_victory(area_index: int) -> void:
	if area_index != _current_area_index:
		return
	call_deferred("_apply_victory", _run_id, area_index)

func _apply_victory(run_id: int, area_index: int) -> void:
	if run_id != _run_id or area_index != _current_area_index:
		return
	area.process_mode = Node.PROCESS_MODE_DISABLED
	hud.process_mode = Node.PROCESS_MODE_DISABLED
	hud.visible = false
	game_over_title.text = "Area Clear"
	if area_index + 1 < AREA_SCENES.size():
		_pending_next_area_index = area_index + 1
		restart_button.text = "Continue"
		game_over_body.text = "%s cleared. Continue to %s." % [AREA_DISPLAY_NAMES[area_index], AREA_DISPLAY_NAMES[area_index + 1]]
	else:
		_pending_next_area_index = -1
		restart_button.text = "Restart"
		game_over_body.text = "You cleared the %s." % AREA_DISPLAY_NAMES[area_index]
	game_over_screen.visible = true

func _continue_to_next_area() -> void:
	if _pending_next_area_index < 0 or _pending_next_area_index >= AREA_SCENES.size():
		return
	_run_id += 1
	var preferred_slot := _active_party_slot()
	_current_area_index = _pending_next_area_index
	_pending_next_area_index = -1
	title_screen.visible = false
	game_over_screen.visible = false
	hud.visible = true
	hud.process_mode = Node.PROCESS_MODE_INHERIT
	restart_button.text = "Restart"
	_activate_area(_current_area_index, preferred_slot)

func _activate_area(area_index: int, preferred_slot: int = 0) -> void:
	_clear_area()
	area = AREA_SCENES[area_index].instantiate() as AreaBase
	area.name = AREA_NODE_NAMES[area_index]
	add_child(area)
	move_child(area, 0)
	area.player_failed.connect(_show_game_over.bind(area_index))
	area.area_completed.connect(_show_victory.bind(area_index))
	if area.has_method("register_party"):
		area.register_party(preferred_slot)
	area.reset_area()
	hud.bind_kira(area.get_player())

func _clear_area() -> void:
	if is_instance_valid(area):
		remove_child(area)
		area.queue_free()
		area = null

func _active_party_slot() -> int:
	var switcher := get_tree().root.get_node_or_null("CharacterSwitcher")
	if switcher and switcher.has_method("active_slot"):
		return maxi(switcher.active_slot(), 0)
	return 0

func _button_contains_global_point(button: Button, point: Vector2) -> bool:
	var rect := Rect2(button.global_position, button.size)
	return button.visible and not button.disabled and rect.has_point(point)

func _quit_game() -> void:
	get_tree().quit()
