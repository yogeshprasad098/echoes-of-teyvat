extends SceneTree
## Sim: simulate pressing switch_2 in the live ember_fields scene and verify
## CharacterSwitcher's active becomes Marina.

func _init() -> void:
	# Mount the autoloads (custom SceneTree doesn't get project.godot autoloads).
	_add_autoload("HitStop", "res://scripts/systems/hit_stop.gd")
	_add_autoload("ScreenShake", "res://scripts/systems/screen_shake.gd")
	_add_autoload("ElementalReactions", "res://scripts/systems/elemental_reactions.gd")
	_add_autoload("CheckpointSystem", "res://scripts/systems/checkpoint_system.gd")
	_add_autoload("CharacterSwitcher", "res://scripts/systems/character_switcher.gd")

	# Build the minimal Party + chars (avoid loading ember_fields which pulls every
	# autoload-dependent script).
	var Party = preload("res://scripts/world/party.gd")
	var CB = preload("res://scripts/characters/character_base.gd")
	var party_node: Node2D = Party.new()
	party_node.global_position = Vector2(96, 336)
	root.add_child(party_node)

	var a: CharacterBase = CB.new(); a.name = "Kira"
	var b: CharacterBase = CB.new(); b.name = "Marina"
	var c: CharacterBase = CB.new(); c.name = "Ryne"
	party_node.add_child(a)
	party_node.add_child(b)
	party_node.add_child(c)

	await process_frame
	await process_frame

	var switcher: Node = root.get_node_or_null("CharacterSwitcher")
	assert(switcher, "CharacterSwitcher not in tree")
	assert(switcher.active() == a, "expected Kira as initial active")

	# Direct API call works?
	switcher.set_active(1)
	assert(switcher.active() == b, "set_active(1) failed — direct API broken")
	print("[direct] set_active(1) -> Marina  ✓")

	# Now simulate a switch_3 input event going through the autoload's _unhandled_input.
	var ev := InputEventAction.new()
	ev.action = "switch_3"
	ev.pressed = true
	root.propagate_call("_unhandled_input", [ev])

	await process_frame

	if switcher.active() == c:
		print("[input] switch_3 input -> Ryne  ✓")
	else:
		print("[input] switch_3 input FAILED — active is %s (expected Ryne)" % str(switcher.active().name if switcher.active() else "null"))

	print("[sim_switch_input] done")
	quit()

func _add_autoload(node_name: String, script_path: String) -> void:
	var n: Node = Node.new()
	n.name = node_name
	n.set_script(load(script_path))
	root.add_child(n)
