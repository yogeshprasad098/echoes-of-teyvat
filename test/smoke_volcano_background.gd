extends SceneTree
## Smoke: instances the volcano background scene and asserts it has its expected children.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var pkg: PackedScene = load("res://scenes/environments/volcano_background.tscn")
	assert(pkg != null, "Failed to load volcano_background.tscn")
	var root: Node3D = pkg.instantiate() as Node3D
	self.root.add_child(root)
	assert(root != null, "Root should be Node3D")
	assert(root.get_node_or_null("Camera3D") != null, "Camera3D missing")
	assert(root.get_node_or_null("SunLight") != null, "SunLight missing")
	assert(root.get_node_or_null("LavaGlow") != null, "LavaGlow missing")
	assert(root.get_node_or_null("VolcanoMesh") != null, "VolcanoMesh missing")
	assert(root.get_node_or_null("EmbersParticles") != null, "EmbersParticles missing")
	root.queue_free()
	await process_frame
	print("[smoke_volcano_background] PASS")
	quit()
