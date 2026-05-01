class_name Party
extends Node2D
## Holds the player party (Kira, Marina, Ryne) under one transform.
## Registers with CharacterSwitcher on _ready so 1/2/3 input works.
##
## CharacterSwitcher is accessed indirectly so this script also compiles
## under custom SceneTree test runs that lack project.godot's autoloads.

func _ready() -> void:
	var members: Array[CharacterBase] = []
	for child in get_children():
		if child is CharacterBase:
			members.append(child)
	if members.is_empty():
		return
	members[0].global_position = global_position
	var switcher: Node = get_tree().root.get_node_or_null("CharacterSwitcher")
	if switcher and switcher.has_method("register"):
		switcher.register(members)
