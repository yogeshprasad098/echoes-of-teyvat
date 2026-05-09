extends SceneTree
## Unit test: ScreenShake autoload perturbs Camera2D offset then restores it.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var cam := Camera2D.new()
	root.add_child(cam)
	cam.make_current()
	await process_frame

	# ScreenShake is normally an autoload; for unit testing we instance its script.
	var shaker_script: Script = load("res://scripts/systems/screen_shake.gd")
	var shaker: Node = Node.new()
	shaker.set_script(shaker_script)
	root.add_child(shaker)

	shaker.pulse(6.0, 0.1)
	await process_frame
	await process_frame
	assert(cam.offset.length() > 0.01, "Expected camera offset to be non-zero after pulse")

	await create_timer(1.0, true, false, true).timeout
	assert(cam.offset.length() < 0.01, "Expected camera offset to restore to ~0 after pulse duration")

	print("[unit_screen_shake] PASS")
	quit()
