class_name PartyIndicator
extends CanvasLayer
## Compact three-slot character switch HUD. Highlights the active slot.

const SLOT_COLORS: Array[Color] = [
	Color(1.0, 0.35, 0.18, 1.0),
	Color(0.36, 0.74, 1.0, 1.0),
	Color(0.7, 0.52, 1.0, 1.0),
]
const KEY_COLOR := Color(1.0, 0.92, 0.66, 1.0)
const INACTIVE_BORDER := Color(0.78, 0.62, 0.38, 0.45)

@onready var slots: Array[PanelContainer] = [
	%Slot1, %Slot2, %Slot3,
] as Array[PanelContainer]
@onready var keys: Array[Label] = [
	%Slot1Key, %Slot2Key, %Slot3Key,
] as Array[Label]
@onready var names: Array[Label] = [
	%Slot1Name, %Slot2Name, %Slot3Name,
] as Array[Label]
@onready var lives_hearts: LivesHearts = %LivesHearts

func _ready() -> void:
	_apply_active_slot(-1)
	var switcher := _character_switcher()
	if switcher and not switcher.active_changed.is_connected(_on_active_changed):
		switcher.active_changed.connect(_on_active_changed)
		if switcher.has_method("active_slot"):
			_apply_active_slot(switcher.active_slot())

func _on_active_changed(_active: CharacterBase, slot: int) -> void:
	_apply_active_slot(slot)

func set_lives(remaining: int, maximum: int) -> void:
	if lives_hearts:
		lives_hearts.set_lives(remaining, maximum)

func _apply_active_slot(active_slot: int) -> void:
	for i in range(slots.size()):
		var active := i == active_slot
		var style := StyleBoxFlat.new()
		style.bg_color = SLOT_COLORS[i].darkened(0.78)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = INACTIVE_BORDER
		style.corner_radius_top_left = 5
		style.corner_radius_top_right = 5
		style.corner_radius_bottom_right = 5
		style.corner_radius_bottom_left = 5
		style.content_margin_left = 7.0
		style.content_margin_top = 6.0
		style.content_margin_right = 7.0
		style.content_margin_bottom = 6.0
		if active:
			style.bg_color = SLOT_COLORS[i].darkened(0.5)
			style.border_color = SLOT_COLORS[i].lightened(0.12)
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2
		slots[i].add_theme_stylebox_override("panel", style)
		keys[i].add_theme_color_override("font_color", KEY_COLOR if active else KEY_COLOR.darkened(0.25))
		names[i].add_theme_color_override("font_color", SLOT_COLORS[i].lightened(0.18) if active else SLOT_COLORS[i].lightened(0.04))

func _character_switcher() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("CharacterSwitcher")
