class_name PartyCamera
extends Camera2D
## Follows the active party member's global position each frame.
## Lives on the Party node so swapping doesn't reparent the camera.

@export var follow_offset: Vector2 = Vector2(0, -16)

func _process(_delta: float) -> void:
	var tree := get_tree()
	if tree == null:
		return
	var switcher := tree.root.get_node_or_null("CharacterSwitcher")
	if switcher == null or not switcher.has_method("active"):
		return
	var active = switcher.active()
	if active == null:
		return
	global_position = active.global_position + follow_offset
