class_name ReactionPopupSpawner
extends Node
## Singleton-style helper. Creates a floating label at a world position
## that reads the reaction name + final damage. Phase ε replaces the
## visuals; the public API is fixed.

const POPUP_SCENE: PackedScene = preload("res://scenes/ui/reaction_popup.tscn")
const RISE_DISTANCE: float = 28.0
const LIFE_SECONDS: float = 0.7

static func spawn(world_position: Vector2, reaction: int, final_damage: float) -> void:
	var name_text: String = ElementalReactions.display_name(reaction)
	if name_text == "":
		return
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return
	var label: Label = POPUP_SCENE.instantiate() as Label
	label.text = "%s  -%d" % [name_text, int(round(final_damage))]
	label.global_position = world_position + Vector2(-32.0, -48.0)
	tree.current_scene.add_child(label)
	var tween: Tween = label.create_tween()
	tween.parallel().tween_property(label, "global_position:y", label.global_position.y - RISE_DISTANCE, LIFE_SECONDS)
	tween.parallel().tween_property(label, "modulate:a", 0.0, LIFE_SECONDS)
	tween.tween_callback(label.queue_free)
