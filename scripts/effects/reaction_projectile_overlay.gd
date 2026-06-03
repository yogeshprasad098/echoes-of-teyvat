class_name ReactionProjectileOverlay
extends RefCounted
## Applies map-reaction overlay strips to character-owned projectiles.

const REACTION_NONE := 0
const REACTION_VAPORIZE_FORWARD := 1
const REACTION_VAPORIZE_REVERSE := 2
const REACTION_OVERLOADED := 3
const REACTION_ELECTRO_CHARGED := 4

static func apply_to(sprite: AnimatedSprite2D, tree: SceneTree, character_name: StringName) -> void:
	if sprite == null:
		return
	var animation_name := _animation_for_character(tree, character_name)
	if animation_name == &"" or sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(animation_name):
		hide(sprite)
		return
	sprite.visible = true
	sprite.animation = animation_name
	sprite.frame = 0
	sprite.play()

static func hide(sprite: AnimatedSprite2D) -> void:
	if sprite == null:
		return
	sprite.visible = false
	sprite.stop()

static func _animation_for_character(tree: SceneTree, character_name: StringName) -> StringName:
	if tree == null:
		return &""
	var balance := tree.root.get_node_or_null("CombatBalance")
	if balance == null or not balance.has_method("reaction_visual_id"):
		return &""
	match int(balance.reaction_visual_id(character_name)):
		REACTION_VAPORIZE_FORWARD, REACTION_VAPORIZE_REVERSE:
			return &"reaction_vaporize_steam_trail"
		REACTION_OVERLOADED:
			return &"reaction_overloaded_spark_rim"
		REACTION_ELECTRO_CHARGED:
			return &"reaction_electro_charged_water_arcs"
	return &""
