extends SceneTree
## Unit: CharacterSwitcher tracks an active member and emits active_changed on swap.

func _init() -> void:
	var SW = preload("res://scripts/systems/character_switcher.gd")
	var sw: Node = SW.new()
	root.add_child(sw)

	var CB = preload("res://scripts/characters/character_base.gd")
	var a: CharacterBase = CB.new(); a.name = "A"
	var b: CharacterBase = CB.new(); b.name = "B"
	var c: CharacterBase = CB.new(); c.name = "C"
	root.add_child(a); root.add_child(b); root.add_child(c)
	a.global_position = Vector2(100, 50)
	b.global_position = Vector2.ZERO
	c.global_position = Vector2.ZERO

	var emissions: Array = []
	sw.active_changed.connect(func(ch: CharacterBase, slot: int) -> void:
		emissions.append([String(ch.name), slot])
	)

	var party: Array[CharacterBase] = [a, b, c]
	sw.register(party)
	assert(sw.active_slot() == 0, "active_slot should be 0 after register")
	assert(sw.active() == a, "active should be A")
	assert(emissions.size() == 1, "active_changed should fire once on register")
	assert(b.visible == false and b.process_mode == Node.PROCESS_MODE_DISABLED)
	assert(c.visible == false and c.process_mode == Node.PROCESS_MODE_DISABLED)

	sw.set_active(1)
	assert(sw.active() == b, "active should be B")
	assert(b.global_position == Vector2(100, 50), "B should copy A's position on swap")
	assert(a.visible == false and a.process_mode == Node.PROCESS_MODE_DISABLED)
	assert(b.visible == true and b.process_mode == Node.PROCESS_MODE_INHERIT)
	assert(emissions.size() == 2)
	assert(String(emissions[1][0]) == "B" and emissions[1][1] == 1, "expected ['B', 1] got %s" % str(emissions[1]))

	sw.set_active(1)
	assert(emissions.size() == 2, "no-op swap should not fire signal")

	sw.set_active(99)
	assert(sw.active() == b)
	assert(emissions.size() == 2)

	a.queue_free(); b.queue_free(); c.queue_free(); sw.queue_free()
	print("[unit_character_switcher] PASS")
	quit()
