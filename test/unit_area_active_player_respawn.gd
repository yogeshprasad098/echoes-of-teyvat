extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_add_autoload("HitStop", "res://scripts/systems/hit_stop.gd")
	_add_autoload("CharacterSwitcher", "res://scripts/systems/character_switcher.gd")
	_add_autoload("CheckpointSystem", "res://scripts/systems/checkpoint_system.gd")

	var Area = preload("res://scripts/areas/area_base.gd")
	var PartyScript = preload("res://scripts/world/party.gd")
	var Character = preload("res://scripts/characters/character_base.gd")

	var area: AreaBase = Area.new()
	area.name = "TestArea"
	area.fall_limit_y = 200.0

	var start := Marker2D.new()
	start.name = "StartPoint"
	start.unique_name_in_owner = true
	start.position = Vector2(40, 60)
	area.add_child(start)

	var party: Party = PartyScript.new()
	party.name = "Party"
	party.unique_name_in_owner = true
	party.global_position = start.position
	area.add_child(party)

	var kira: CharacterBase = Character.new()
	kira.name = "Kira"
	kira.unique_name_in_owner = true
	var marina: CharacterBase = Character.new()
	marina.name = "Marina"
	marina.unique_name_in_owner = true
	var ryne: CharacterBase = Character.new()
	ryne.name = "Ryne"
	ryne.unique_name_in_owner = true
	party.add_child(kira)
	party.add_child(marina)
	party.add_child(ryne)

	root.add_child(area)
	await process_frame
	area._start_position = start.position
	var checkpoint_system := root.get_node("CheckpointSystem")
	checkpoint_system.reset_for_new_area(start.position)

	var switcher := root.get_node("CharacterSwitcher")
	switcher.set_active(1)
	assert(switcher.active() == marina, "Marina should be active after switching")
	assert(area.get_player() == marina, "Area should track Marina as the active player")

	kira.global_position = Vector2(40, 60)
	marina.global_position = Vector2(40, 240)
	area._process(0.016)
	assert(area._run_failed, "Falling with Marina should mark the run failed")

	area.respawn_player()
	assert(area.get_player() == marina, "Respawn should still target the active Marina")
	assert(marina.global_position == start.position, "Marina should respawn at the area spawn point")
	assert(marina.visible and switcher.active() == marina, "Respawn should keep Marina active and visible")
	assert(not kira.visible, "Respawn should not reactivate inactive Kira")

	switcher.set_active(2)
	await process_frame
	assert(area.get_player() == ryne, "Area should refresh to Ryne after switching")

	area.queue_free()
	await process_frame
	print("[unit_area_active_player_respawn] PASS")
	quit()

func _add_autoload(node_name: String, script_path: String) -> void:
	var node := Node.new()
	node.name = node_name
	node.set_script(load(script_path))
	root.add_child(node)
