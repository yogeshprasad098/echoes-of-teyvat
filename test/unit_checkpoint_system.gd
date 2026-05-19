extends SceneTree
## Unit test: CheckpointSystem tracks active checkpoint and falls back to default_spawn.

func _init() -> void:
	_run()
	quit()

func _run() -> void:
	var script: Script = load("res://scripts/systems/checkpoint_system.gd")
	var cps: Node = Node.new()
	cps.set_script(script)
	root.add_child(cps)

	cps.reset_for_new_area(Vector2(10, 20))
	assert(cps.get_spawn_point() == Vector2(10, 20), "default_spawn should be returned when no checkpoint active")

	cps.activate("mid", Vector2(100, 200))
	assert(cps.get_spawn_point() == Vector2(100, 200), "active checkpoint should override default_spawn")

	cps.activate("pre_goal", Vector2(300, 400))
	assert(cps.get_spawn_point() == Vector2(300, 400), "latest activation should win")

	cps.reset_for_new_area(Vector2(0, 0))
	assert(cps.get_spawn_point() == Vector2(0, 0), "reset_for_new_area should clear active checkpoint")

	print("[unit_checkpoint_system] PASS")
