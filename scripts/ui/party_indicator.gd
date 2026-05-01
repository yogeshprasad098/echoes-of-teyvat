class_name PartyIndicator
extends CanvasLayer
## Three-slot indicator. Highlights the active slot.

const SLOT_COLORS: Array = [
	Color(1.0, 0.42, 0.18, 1.0),
	Color(0.32, 0.78, 1.0, 1.0),
	Color(0.72, 0.55, 1.0, 1.0),
]

@onready var slots: Array[ColorRect] = [
	$Slot1, $Slot2, $Slot3,
] as Array[ColorRect]
@onready var outlines: Array[ColorRect] = [
	$Slot1Outline, $Slot2Outline, $Slot3Outline,
] as Array[ColorRect]

func _ready() -> void:
	for i in range(slots.size()):
		slots[i].color = SLOT_COLORS[i]
		outlines[i].visible = false
	var switcher := _character_switcher()
	if switcher and not switcher.active_changed.is_connected(_on_active_changed):
		switcher.active_changed.connect(_on_active_changed)

func _on_active_changed(_active: CharacterBase, slot: int) -> void:
	for i in range(outlines.size()):
		outlines[i].visible = (i == slot)

func _character_switcher() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("CharacterSwitcher")
