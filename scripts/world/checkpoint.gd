class_name Checkpoint
extends Area2D
## Trigger that registers itself as the active checkpoint the first time Kira enters.

@export var checkpoint_name: String = "checkpoint"

var _activated: bool = false

@onready var banner: Polygon2D = $Banner

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collision_layer = 0
	collision_mask = 2

func force_activate() -> void:
	if _activated:
		return
	_activated = true
	CheckpointSystem.activate(checkpoint_name, global_position)
	_play_activation_feedback()

func _on_body_entered(body: Node) -> void:
	if _activated:
		return
	if body is CharacterBase:
		_activated = true
		CheckpointSystem.activate(checkpoint_name, global_position)
		_play_activation_feedback()
		_emit_toast()

func _play_activation_feedback() -> void:
	if banner == null:
		return
	var tween: Tween = create_tween()
	banner.modulate = Color(1.0, 1.0, 0.4, 0.2)
	tween.tween_property(banner, "modulate", Color(1.0, 0.7, 0.2, 1.0), 0.25)

func _emit_toast() -> void:
	var tree: SceneTree = get_tree()
	if tree == null or tree.current_scene == null:
		return
	var toast: Node = tree.current_scene.find_child("CheckpointToast", true, false)
	if toast and toast.has_method("show_toast"):
		toast.show_toast("Checkpoint — %s" % checkpoint_name)
