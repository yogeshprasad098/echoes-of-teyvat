class_name HUD
extends CanvasLayer
## Compact HUD: active character health, elemental skill cooldown, and status text.

const ELEMENTS := {
	&"Kira": {"name": "PYRO", "color": Color(0.95, 0.3, 0.12, 0.92)},
	&"Marina": {"name": "HYDRO", "color": Color(0.24, 0.68, 1.0, 0.92)},
	&"Ryne": {"name": "ELECTRO", "color": Color(0.6, 0.42, 1.0, 0.92)},
}

# Reference to the currently bound active character (any CharacterBase).
var _active: CharacterBase = null

# === Onready ===
@onready var health_bar: ProgressBar = %HealthBar
@onready var skill_bar: ProgressBar = %SkillBar
@onready var character_label: Label = %CharacterLabel
@onready var element_label: Label = %ElementLabel
@onready var health_value_label: Label = %HealthValueLabel
@onready var skill_value_label: Label = %SkillValueLabel
@onready var status_title_label: Label = %StatusTitleLabel
@onready var status_value_label: Label = %StatusValueLabel

func _ready() -> void:
	health_bar.max_value = 100
	skill_bar.max_value = 100
	var switcher := _character_switcher()
	if switcher and not switcher.active_changed.is_connected(_on_active_changed):
		switcher.active_changed.connect(_on_active_changed)
	call_deferred("_bind_initial_active")

## Backwards-compatible wrapper for existing Main callers.
func bind_kira(player: CharacterBase) -> void:
	bind_active(player)

## Binds HUD health and cooldown display to [param player].
func bind_active(player: CharacterBase) -> void:
	if _active == player:
		_refresh_all()
		return
	if _active and _active.health_changed.is_connected(_on_health_changed):
		_active.health_changed.disconnect(_on_health_changed)
	_active = player
	if player == null:
		_set_empty()
		return
	if not player.health_changed.is_connected(_on_health_changed):
		player.health_changed.connect(_on_health_changed)
	_refresh_all()

func _process(_delta: float) -> void:
	if not is_instance_valid(_active):
		return
	_update_skill_display()

func _on_health_changed(current: float, maximum: float) -> void:
	_update_health_display(current, maximum)

func _on_active_changed(active: CharacterBase, _slot: int) -> void:
	bind_active(active)

func _bind_initial_active() -> void:
	# Initial bind: prefer CharacterSwitcher's active member, else fall back to scene search.
	var switcher := _character_switcher()
	if switcher and switcher.has_method("active") and switcher.active():
		bind_active(switcher.active())
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	var kira := scene.find_child("Kira", true, false) as CharacterBase
	if kira:
		bind_active(kira)

func _refresh_all() -> void:
	if not is_instance_valid(_active):
		_set_empty()
		return
	character_label.text = _active.name
	var element: Dictionary = ELEMENTS.get(StringName(_active.name), {"name": "PARTY", "color": Color(0.8, 0.65, 0.42, 0.92)})
	element_label.text = str(element["name"])
	var badge := element_label.get_parent() as PanelContainer
	if badge:
		var style := badge.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		style.bg_color = element["color"] as Color
		badge.add_theme_stylebox_override("panel", style)
	_update_health_display(_active.current_health, _active.max_health)
	_update_skill_display()

func _update_health_display(current: float, maximum: float) -> void:
	var safe_max: float = maxf(maximum, 1.0)
	var safe_current: float = clampf(current, 0.0, safe_max)
	health_bar.value = (safe_current / safe_max) * 100.0
	health_value_label.text = "%d/%d" % [roundi(safe_current), roundi(safe_max)]

func _update_skill_display() -> void:
	var timer: Timer = _active.get_node_or_null("%SkillCooldownTimer")
	if timer == null or timer.is_stopped():
		skill_bar.value = 100.0
		skill_value_label.text = "Ready"
		return
	var wait_time: float = maxf(timer.wait_time, 0.001)
	var ratio: float = clampf(1.0 - (timer.time_left / wait_time), 0.0, 1.0)
	var percent := roundi(ratio * 100.0)
	skill_bar.value = percent
	skill_value_label.text = "%d%%" % percent

func set_stage_status(stage_name: String, is_boss: bool) -> void:
	status_title_label.text = "BOSS" if is_boss else "AREA"
	status_value_label.text = stage_name

func _set_empty() -> void:
	character_label.text = "Party"
	element_label.text = "WAIT"
	health_bar.value = 0.0
	skill_bar.value = 0.0
	health_value_label.text = "0/0"
	skill_value_label.text = "--"
	status_title_label.text = "AREA"
	status_value_label.text = "--"

func _character_switcher() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("CharacterSwitcher")
