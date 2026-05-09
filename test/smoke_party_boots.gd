extends SceneTree
## Smoke: verify Party.gd registers a 3-member array with CharacterSwitcher
## and that only slot 0 is visible after register.
##
## We build the party tree programmatically so we don't pull in every
## autoload-dependent script (enemy_base, checkpoint, etc.) — those compile
## fine under normal game boot but the custom SceneTree context here lacks
## the global autoload identifiers.

func _init() -> void:
	# Manually mount the autoloads CharacterSwitcher + Party need.
	_add_autoload("HitStop", "res://scripts/systems/hit_stop.gd")
	_add_autoload("CharacterSwitcher", "res://scripts/systems/character_switcher.gd")

	# Build a minimal Party + 3 character stand-ins.
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

	# Re-trigger _ready by yielding a frame.
	await process_frame
	await process_frame

	assert(a.visible == true, "Kira (slot 0) should be visible")
	assert(b.visible == false, "Marina should be hidden")
	assert(c.visible == false, "Ryne should be hidden")

	var switcher: Node = root.get_node_or_null("CharacterSwitcher")
	assert(switcher != null)
	assert(switcher.active() == a)
	assert(switcher.active_slot() == 0)

	print("[smoke_party_boots] PASS")
	quit()

func _add_autoload(node_name: String, script_path: String) -> void:
	var n: Node = Node.new()
	n.name = node_name
	n.set_script(load(script_path))
	root.add_child(n)
