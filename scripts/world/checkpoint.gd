class_name Checkpoint
extends Area2D
## Trigger that registers itself as the active checkpoint the first time Kira enters.

@export var checkpoint_name: String = "checkpoint"
@export var respawn_offset: Vector2 = Vector2.ZERO

var _activated: bool = false

@onready var banner: Polygon2D = %Banner

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collision_layer = 0
	collision_mask = 2

## Activates this checkpoint without requiring a body-entered event.
func force_activate() -> void:
	if _activated:
		return
	_activated = true
	var checkpoint_system := _checkpoint_system()
	if checkpoint_system and checkpoint_system.has_method("activate"):
		checkpoint_system.activate(checkpoint_name, _respawn_position())
	_play_activation_feedback()

func _on_body_entered(body: Node) -> void:
	if _activated:
		return
	if body is CharacterBase:
		_activated = true
		var checkpoint_system := _checkpoint_system()
		if checkpoint_system and checkpoint_system.has_method("activate"):
			checkpoint_system.activate(checkpoint_name, _respawn_position())
		_play_activation_feedback()
		_emit_toast()

func _respawn_position() -> Vector2:
	return global_position + respawn_offset

func _play_activation_feedback() -> void:
	_play_audio_sfx(&"checkpoint", -1.0, 0.0)
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

func _checkpoint_system() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("CheckpointSystem")

func _play_audio_sfx(cue: StringName, volume_offset_db: float = 0.0, pitch_jitter: float = 0.035) -> void:
	var tree := get_tree()
	if tree == null:
		return
	var audio := tree.root.get_node_or_null("AudioManager")
	if audio and audio.has_method("play_sfx"):
		audio.play_sfx(cue, volume_offset_db, pitch_jitter)
