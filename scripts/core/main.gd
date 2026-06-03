class_name Main
extends Node2D
## Controls the title screen, active run, and game-over restart flow.

const AREA_SCENES: Array[PackedScene] = [
	preload("res://scenes/areas/ember_fields.tscn"),
	preload("res://scenes/areas/ember_fields_boss_1_arena.tscn"),
	preload("res://scenes/areas/ember_fields_level_2.tscn"),
	preload("res://scenes/areas/ember_fields_boss_2_arena.tscn"),
	preload("res://scenes/areas/ember_fields_level_3.tscn"),
	preload("res://scenes/areas/ember_fields_boss_3_arena.tscn"),
	preload("res://scenes/areas/ember_fields_level_4.tscn"),
	preload("res://scenes/areas/ember_fields_boss_4_arena.tscn"),
	preload("res://scenes/areas/ember_fields_level_5.tscn"),
	preload("res://scenes/areas/ember_fields_boss_5_arena.tscn"),
	preload("res://scenes/areas/drowned_coast.tscn"),
	preload("res://scenes/areas/drowned_coast_boss_1_arena.tscn"),
	preload("res://scenes/areas/drowned_coast_level_2.tscn"),
	preload("res://scenes/areas/drowned_coast_boss_2_arena.tscn"),
	preload("res://scenes/areas/drowned_coast_level_3.tscn"),
	preload("res://scenes/areas/drowned_coast_boss_3_arena.tscn"),
	preload("res://scenes/areas/drowned_coast_level_4.tscn"),
	preload("res://scenes/areas/drowned_coast_boss_4_arena.tscn"),
	preload("res://scenes/areas/drowned_coast_level_5.tscn"),
	preload("res://scenes/areas/drowned_coast_boss_5_arena.tscn"),
	preload("res://scenes/areas/storm_peaks.tscn"),
	preload("res://scenes/areas/storm_peaks_boss_1_arena.tscn"),
	preload("res://scenes/areas/storm_peaks_level_2.tscn"),
	preload("res://scenes/areas/storm_peaks_boss_2_arena.tscn"),
	preload("res://scenes/areas/storm_peaks_level_3.tscn"),
	preload("res://scenes/areas/storm_peaks_boss_3_arena.tscn"),
	preload("res://scenes/areas/storm_peaks_level_4.tscn"),
	preload("res://scenes/areas/storm_peaks_boss_4_arena.tscn"),
	preload("res://scenes/areas/storm_peaks_level_5.tscn"),
	preload("res://scenes/areas/storm_peaks_boss_5_arena.tscn"),
]
const AREA_NODE_NAMES: Array[StringName] = [
	&"EmberFields",
	&"EmberFieldsBoss1Arena",
	&"EmberFieldsLevel2",
	&"EmberFieldsBoss2Arena",
	&"EmberFieldsLevel3",
	&"EmberFieldsBoss3Arena",
	&"EmberFieldsLevel4",
	&"EmberFieldsBoss4Arena",
	&"EmberFieldsLevel5",
	&"EmberFieldsBoss5Arena",
	&"DrownedCoast",
	&"DrownedCoastBoss1Arena",
	&"DrownedCoastLevel2",
	&"DrownedCoastBoss2Arena",
	&"DrownedCoastLevel3",
	&"DrownedCoastBoss3Arena",
	&"DrownedCoastLevel4",
	&"DrownedCoastBoss4Arena",
	&"DrownedCoastLevel5",
	&"DrownedCoastBoss5Arena",
	&"StormPeaks",
	&"StormPeaksBoss1Arena",
	&"StormPeaksLevel2",
	&"StormPeaksBoss2Arena",
	&"StormPeaksLevel3",
	&"StormPeaksBoss3Arena",
	&"StormPeaksLevel4",
	&"StormPeaksBoss4Arena",
	&"StormPeaksLevel5",
	&"StormPeaksBoss5Arena",
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
	"Drowned Coast Level 1",
	"Tide Warden",
	"Drowned Coast Level 2",
	"Reef Serpent",
	"Drowned Coast Level 3",
	"Abyss Caller",
	"Drowned Coast Level 4",
	"Maelstrom Sentinel",
	"Drowned Coast Level 5",
	"Drowned Leviathan",
	"Storm Peaks Level 1",
	"Storm Harbinger",
	"Storm Peaks Level 2",
	"Thunder Ravager",
	"Storm Peaks Level 3",
	"Arc Sentinel",
	"Storm Peaks Level 4",
	"Tempest Colossus",
	"Storm Peaks Level 5",
	"Storm Sovereign",
]
const LIVES_PER_MAP_FLOW: int = 5
const MAP_FLOW_START_INDICES: Array[int] = [0, 10, 20]

var _run_id: int = 0
var _current_area_index: int = 0
var _pending_next_area_index: int = -1
var _pending_restart_area_index: int = -1
var _lives_remaining: int = LIVES_PER_MAP_FLOW
var area: AreaBase = null

# === Onready ===
@onready var hud: HUD = %HUD
@onready var party_indicator: PartyIndicator = $PartyIndicator
@onready var title_screen: CanvasLayer = %TitleScreen
@onready var game_over_screen: CanvasLayer = %GameOverScreen
@onready var pause_screen: CanvasLayer = %PauseScreen
@onready var start_button: Button = %StartButton
@onready var quit_button: Button = %QuitButton
@onready var restart_button: Button = %RestartButton
@onready var exit_button: Button = %ExitButton
@onready var resume_button: Button = %ResumeButton
@onready var start_over_button: Button = %StartOverButton
@onready var pause_quit_button: Button = %PauseQuitButton
@onready var death_fade: ColorRect = %Black
@onready var respawn_notice = %RespawnNotice
@onready var game_over_title: Label = %GameOverTitleLabel
@onready var game_over_body: Label = %GameOverBodyLabel
@onready var dialogue_popup: DialoguePopup = $DialoguePopup

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	title_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	game_over_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	start_button.pressed.connect(_start_game)
	quit_button.pressed.connect(_quit_game)
	restart_button.pressed.connect(_on_restart_button_pressed)
	exit_button.pressed.connect(_show_title_screen)
	resume_button.pressed.connect(_resume_game)
	start_over_button.pressed.connect(_start_over_from_pause)
	pause_quit_button.pressed.connect(_quit_game)
	var api_client := _genshin_api_client()
	if api_client and api_client.has_signal("dialogue_line_ready"):
		api_client.dialogue_line_ready.connect(_on_dialogue_line_ready)
	var switcher := _character_switcher()
	if switcher and switcher.has_signal("active_changed"):
		switcher.active_changed.connect(_on_active_party_changed)
	_show_title_screen()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE:
			if pause_screen.visible:
				_resume_game()
			elif title_screen.visible:
				pass
			elif game_over_screen.visible:
				_show_title_screen()
			elif is_instance_valid(area):
				_show_pause_screen()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
			if title_screen.visible:
				_start_game()
				get_viewport().set_input_as_handled()
			elif pause_screen.visible:
				_resume_game()
				get_viewport().set_input_as_handled()
			elif game_over_screen.visible:
				_on_restart_button_pressed()
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if pause_screen.visible:
			if _button_contains_global_point(resume_button, event.position):
				_resume_game()
				get_viewport().set_input_as_handled()
			elif _button_contains_global_point(start_over_button, event.position):
				_start_over_from_pause()
				get_viewport().set_input_as_handled()
			elif _button_contains_global_point(pause_quit_button, event.position):
				_quit_game()
				get_viewport().set_input_as_handled()
		elif title_screen.visible:
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
	elif event.is_action_pressed("ui_accept") and pause_screen.visible:
		_resume_game()
	elif event.is_action_pressed("ui_accept") and game_over_screen.visible:
		_on_restart_button_pressed()
	elif event.is_action_pressed("ui_cancel"):
		if pause_screen.visible:
			_resume_game()
		elif title_screen.visible:
			return
		elif game_over_screen.visible:
			_show_title_screen()
		elif is_instance_valid(area):
			_show_pause_screen()

func _start_game() -> void:
	_run_id += 1
	_pending_next_area_index = -1
	_pending_restart_area_index = -1
	_current_area_index = 0
	_reset_lives_for_area(_current_area_index)
	_play_audio_sfx(&"ui_start", -2.0, 0.0)
	pause_screen.visible = false
	title_screen.visible = false
	game_over_screen.visible = false
	respawn_notice.hide_notice()
	hud.visible = true
	party_indicator.visible = true
	hud.process_mode = Node.PROCESS_MODE_INHERIT
	restart_button.text = "Restart"
	_activate_area(_current_area_index, 0)

func _restart_game() -> void:
	_start_game()

func _show_title_screen() -> void:
	_run_id += 1
	_pending_next_area_index = -1
	_pending_restart_area_index = -1
	_stop_music()
	pause_screen.visible = false
	title_screen.visible = true
	game_over_screen.visible = false
	respawn_notice.hide_notice()
	hud.visible = false
	party_indicator.visible = false
	hud.process_mode = Node.PROCESS_MODE_DISABLED
	restart_button.text = "Restart"
	_clear_area()

func _on_restart_button_pressed() -> void:
	if _pending_next_area_index >= 0:
		_continue_to_next_area()
	elif _pending_restart_area_index >= 0:
		_restart_map_flow()
	else:
		_restart_game()

func _show_game_over(area_index: int) -> void:
	if area_index != _current_area_index:
		return
	call_deferred("_handle_death", _run_id, area_index)

func _handle_death(run_id: int, area_index: int) -> void:
	if run_id != _run_id or area_index != _current_area_index:
		return
	if not is_instance_valid(area):
		return
	_lives_remaining = maxi(_lives_remaining - 1, 0)
	_update_lives_hud()
	if _lives_remaining <= 0:
		_show_flow_failed(area_index)
		return
	respawn_notice.show_respawn(_lives_remaining, LIVES_PER_MAP_FLOW, _stage_status_label(area_index), area is BossArenaBase)
	if death_fade == null:
		area.respawn_player()
		return
	var fade_in: Tween = create_tween()
	fade_in.tween_property(death_fade, "color:a", 1.0, 0.2)
	fade_in.tween_callback(func() -> void:
		if run_id == _run_id and area_index == _current_area_index and is_instance_valid(area):
			area.respawn_player()
	)
	fade_in.tween_interval(0.05)
	fade_in.tween_property(death_fade, "color:a", 0.0, 0.25)

func _show_flow_failed(area_index: int) -> void:
	if not is_instance_valid(area):
		return
	var restart_index := _map_flow_start_index_for_area(area_index)
	_pending_next_area_index = -1
	_pending_restart_area_index = restart_index
	pause_screen.visible = false
	respawn_notice.hide_notice()
	area.process_mode = Node.PROCESS_MODE_DISABLED
	hud.process_mode = Node.PROCESS_MODE_DISABLED
	hud.visible = false
	party_indicator.visible = false
	game_over_title.text = "Run Failed"
	restart_button.text = "Start Over"
	game_over_body.text = "No lives left. Start over from %s." % AREA_DISPLAY_NAMES[restart_index]
	game_over_screen.visible = true

func _show_victory(area_index: int) -> void:
	if area_index != _current_area_index:
		return
	call_deferred("_apply_victory", _run_id, area_index)

func _apply_victory(run_id: int, area_index: int) -> void:
	if run_id != _run_id or area_index != _current_area_index:
		return
	pause_screen.visible = false
	respawn_notice.hide_notice()
	_request_dialogue(&"boss_defeat" if area is BossArenaBase else &"area_clear")
	_play_audio_sfx(&"boss_defeat" if area is BossArenaBase else &"area_clear", 0.0, 0.0)
	area.process_mode = Node.PROCESS_MODE_DISABLED
	hud.process_mode = Node.PROCESS_MODE_DISABLED
	hud.visible = false
	party_indicator.visible = false
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
	var previous_flow_start := _map_flow_start_index_for_area(_current_area_index)
	_current_area_index = _pending_next_area_index
	_pending_next_area_index = -1
	_pending_restart_area_index = -1
	if _map_flow_start_index_for_area(_current_area_index) != previous_flow_start:
		_reset_lives_for_area(_current_area_index)
	pause_screen.visible = false
	title_screen.visible = false
	game_over_screen.visible = false
	respawn_notice.hide_notice()
	hud.visible = true
	party_indicator.visible = true
	hud.process_mode = Node.PROCESS_MODE_INHERIT
	restart_button.text = "Restart"
	_activate_area(_current_area_index, preferred_slot)

func _restart_map_flow() -> void:
	if _pending_restart_area_index < 0 or _pending_restart_area_index >= AREA_SCENES.size():
		return
	_run_id += 1
	var preferred_slot := _active_party_slot()
	_current_area_index = _pending_restart_area_index
	_pending_restart_area_index = -1
	_pending_next_area_index = -1
	_reset_lives_for_area(_current_area_index)
	pause_screen.visible = false
	title_screen.visible = false
	game_over_screen.visible = false
	respawn_notice.hide_notice()
	hud.visible = true
	party_indicator.visible = true
	hud.process_mode = Node.PROCESS_MODE_INHERIT
	restart_button.text = "Restart"
	_activate_area(_current_area_index, preferred_slot)

func _activate_area(area_index: int, preferred_slot: int = 0) -> void:
	_clear_area()
	_update_combat_balance(area_index)
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
	hud.set_stage_status(_stage_status_label(area_index), area is BossArenaBase)
	_update_lives_hud()
	_play_music(_music_for_area_index(area_index))
	_request_dialogue(StringName("area_%s" % AREA_NODE_NAMES[area_index]))

func _update_combat_balance(area_index: int) -> void:
	var balance := _combat_balance()
	if balance and balance.has_method("set_current_map"):
		balance.set_current_map(AREA_NODE_NAMES[area_index])

func _clear_area() -> void:
	if is_instance_valid(area):
		remove_child(area)
		area.queue_free()
		area = null

func _show_pause_screen() -> void:
	if not is_instance_valid(area):
		return
	pause_screen.visible = true
	area.process_mode = Node.PROCESS_MODE_DISABLED
	hud.process_mode = Node.PROCESS_MODE_DISABLED
	resume_button.grab_focus()

func _resume_game() -> void:
	pause_screen.visible = false
	if is_instance_valid(area):
		area.process_mode = Node.PROCESS_MODE_INHERIT
	if hud.visible:
		hud.process_mode = Node.PROCESS_MODE_INHERIT

func _start_over_from_pause() -> void:
	pause_screen.visible = false
	_restart_game()

func _active_party_slot() -> int:
	var switcher := get_tree().root.get_node_or_null("CharacterSwitcher")
	if switcher and switcher.has_method("active_slot"):
		return maxi(switcher.active_slot(), 0)
	return 0

func _reset_lives_for_area(_area_index: int) -> void:
	_lives_remaining = LIVES_PER_MAP_FLOW
	_update_lives_hud()

func _map_flow_start_index_for_area(area_index: int) -> int:
	var flow_start := MAP_FLOW_START_INDICES[0]
	for start_index in MAP_FLOW_START_INDICES:
		if area_index >= start_index:
			flow_start = start_index
	return flow_start

func _stage_status_label(area_index: int) -> String:
	var display_name := AREA_DISPLAY_NAMES[area_index]
	return display_name.replace(" Level ", " ")

func _update_lives_hud() -> void:
	if party_indicator and party_indicator.has_method("set_lives"):
		party_indicator.set_lives(_lives_remaining, LIVES_PER_MAP_FLOW)

func _button_contains_global_point(button: Button, point: Vector2) -> bool:
	var rect := Rect2(button.global_position, button.size)
	return button.visible and not button.disabled and rect.has_point(point)

func _quit_game() -> void:
	get_tree().quit()

func _on_active_party_changed(active: CharacterBase, _slot: int) -> void:
	if not is_instance_valid(active):
		return
	_request_dialogue(StringName("switch_%s" % active.name), active.name)

func _on_dialogue_line_ready(speaker: String, text: String) -> void:
	if dialogue_popup and dialogue_popup.has_method("show_line"):
		dialogue_popup.show_line(speaker, text)

func _request_dialogue(event_name: StringName, speaker_hint: String = "") -> void:
	var api_client := _genshin_api_client()
	if api_client and api_client.has_method("request_dialogue_line"):
		api_client.request_dialogue_line(event_name, speaker_hint)
	elif dialogue_popup:
		dialogue_popup.show_line("Party" if speaker_hint == "" else speaker_hint, "Keep moving.")

func _genshin_api_client() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("GenshinAPIClient")

func _character_switcher() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("CharacterSwitcher")

func _combat_balance() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("CombatBalance")

func _music_for_area_index(area_index: int) -> StringName:
	var area_name := AREA_NODE_NAMES[area_index]
	if String(area_name).begins_with("StormPeaks"):
		return &"storm_peaks"
	if String(area_name).contains("Boss"):
		return &"boss"
	return &"ember_fields"

func _audio_manager() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("AudioManager")

func _play_audio_sfx(cue: StringName, volume_offset_db: float = 0.0, pitch_jitter: float = 0.035) -> void:
	var audio := _audio_manager()
	if audio and audio.has_method("play_sfx"):
		audio.play_sfx(cue, volume_offset_db, pitch_jitter)

func _play_music(cue: StringName) -> void:
	var audio := _audio_manager()
	if audio and audio.has_method("play_music"):
		audio.play_music(cue)

func _stop_music() -> void:
	var audio := _audio_manager()
	if audio and audio.has_method("stop_music"):
		audio.stop_music()
