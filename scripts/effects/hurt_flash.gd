class_name HurtFlash
extends Node
## Briefly modulates a CanvasItem to white to signal that it took a hit.

const FLASH_COLOR: Color = Color(1.0, 1.0, 1.0, 1.0)
const FLASH_DURATION: float = 0.08

static func play(target: CanvasItem) -> void:
	if target == null:
		return
	var original: Color = target.modulate
	target.modulate = FLASH_COLOR
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		target.modulate = original
		return
	var tween: Tween = tree.create_tween()
	tween.tween_property(target, "modulate", original, FLASH_DURATION)
