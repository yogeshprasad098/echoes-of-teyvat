class_name HitSparks
extends GPUParticles2D
## One-shot warm-orange spark burst on hit. Self-frees when emission ends.
## Use HitSparks.burst_at(pos) instead of manual instantiation.

const SCENE: PackedScene = preload("res://scenes/effects/hit_sparks.tscn")

static func burst_at(pos: Vector2, parent: Node = null) -> void:
	var inst: HitSparks = SCENE.instantiate() as HitSparks
	inst.global_position = pos
	var target: Node = parent
	if target == null:
		var tree: SceneTree = Engine.get_main_loop() as SceneTree
		if tree and tree.current_scene:
			target = tree.current_scene
	if target == null:
		inst.queue_free()
		return
	target.add_child(inst)
	inst.emitting = true

func _ready() -> void:
	finished.connect(queue_free)
