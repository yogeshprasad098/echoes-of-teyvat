extends SceneTree
## Unit test: HitStop freezes time scale; a longer freeze extends; a shorter freeze does not shorten.
## Probes the internal _active_until_ms directly to avoid scaled-time await pitfalls.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var script: Script = load("res://scripts/systems/hit_stop.gd")
	var stopper: Node = Node.new()
	stopper.set_script(script)
	stopper.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(stopper)

	# Baseline: freeze sets time_scale = 0 and seeds _active_until_ms.
	Engine.time_scale = 1.0
	stopper.freeze(0.10)
	assert(Engine.time_scale == 0.0, "Expected time_scale 0 after freeze")
	var after_first: int = stopper._active_until_ms
	assert(after_first > 0, "Expected _active_until_ms seeded")

	# Longer freeze extends the window.
	stopper.freeze(0.20)
	var after_longer: int = stopper._active_until_ms
	assert(after_longer > after_first, "Expected longer freeze to extend _active_until_ms")

	# Shorter freeze while active must NOT shorten the window.
	stopper.freeze(0.01)
	assert(stopper._active_until_ms == after_longer, "Expected shorter freeze to be ignored (window unchanged)")

	# Restore manually so we don't leave a global frozen state for the next test.
	Engine.time_scale = 1.0
	stopper._active_until_ms = 0

	print("[unit_hit_stop] PASS")
	quit()
