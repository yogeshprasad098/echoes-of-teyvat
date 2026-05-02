class_name ReactionBurstSpawner
extends Node2D
## Spawned per reaction. Activates the matching preset's GPUParticles2D
## once and queue_frees on finish.
##
## ElementalReactions accessed indirectly so this script compiles in
## headless test contexts.

const SCENE: PackedScene = preload("res://scenes/effects/reaction_burst.tscn")

# Reaction enum mirror — kept in sync with ElementalReactions.Reaction.
# Used so this script can be loaded without the autoload identifier.
const _REACTION_NONE := 0
const _REACTION_VAPORIZE_FORWARD := 1
const _REACTION_VAPORIZE_REVERSE := 2
const _REACTION_OVERLOADED := 3
const _REACTION_ELECTRO_CHARGED := 4

static func play_at(world_position: Vector2, reaction: int) -> void:
	if reaction == _REACTION_NONE:
		return
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return
	var instance: Node2D = SCENE.instantiate() as Node2D
	instance.global_position = world_position
	tree.current_scene.add_child(instance)
	instance._fire(reaction)

func _fire(reaction: int) -> void:
	var preset_name: String = ""
	match reaction:
		_REACTION_VAPORIZE_FORWARD, _REACTION_VAPORIZE_REVERSE:
			preset_name = "Steam"
		_REACTION_OVERLOADED:
			preset_name = "Overload"
		_REACTION_ELECTRO_CHARGED:
			preset_name = "ElectroCharge"
	if preset_name == "":
		queue_free()
		return
	var p: GPUParticles2D = get_node_or_null(preset_name)
	if p == null:
		queue_free()
		return
	p.emitting = true
	p.finished.connect(queue_free)
