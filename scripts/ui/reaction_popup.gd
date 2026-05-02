class_name ReactionPopupSpawner
extends Node
## Singleton-style helper. Creates a floating label at a world position
## that reads the reaction name + final damage. Tinted by reaction.

const POPUP_SCENE: PackedScene = preload("res://scenes/ui/reaction_popup.tscn")
const RISE_DISTANCE: float = 28.0
const LIFE_SECONDS: float = 0.7

# Mirror of ElementalReactions.Reaction so this script compiles without the autoload.
const _REACTION_VAPORIZE_FORWARD := 1
const _REACTION_VAPORIZE_REVERSE := 2
const _REACTION_OVERLOADED := 3
const _REACTION_ELECTRO_CHARGED := 4

const COLORS := {
	_REACTION_VAPORIZE_FORWARD:  Color(1.0, 0.85, 0.45),
	_REACTION_VAPORIZE_REVERSE:  Color(1.0, 0.85, 0.45),
	_REACTION_OVERLOADED:        Color(1.0, 0.45, 0.18),
	_REACTION_ELECTRO_CHARGED:   Color(0.78, 0.65, 1.0),
}

const NAMES := {
	_REACTION_VAPORIZE_FORWARD:  "VAPORIZE 2.0×",
	_REACTION_VAPORIZE_REVERSE:  "VAPORIZE 1.5×",
	_REACTION_OVERLOADED:        "OVERLOADED",
	_REACTION_ELECTRO_CHARGED:   "ELECTRO-CHARGED",
}

static func spawn(world_position: Vector2, reaction: int, final_damage: float) -> void:
	var name_text: String = NAMES.get(reaction, "")
	if name_text == "":
		return
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return
	var label: Label = POPUP_SCENE.instantiate() as Label
	label.text = "%s  -%d" % [name_text, int(round(final_damage))]
	label.global_position = world_position + Vector2(-32.0, -48.0)
	label.modulate = COLORS.get(reaction, Color.WHITE)
	tree.current_scene.add_child(label)
	var tween: Tween = label.create_tween()
	tween.parallel().tween_property(label, "global_position:y", label.global_position.y - RISE_DISTANCE, LIFE_SECONDS)
	tween.parallel().tween_property(label, "modulate:a", 0.0, LIFE_SECONDS)
	tween.tween_callback(label.queue_free)
