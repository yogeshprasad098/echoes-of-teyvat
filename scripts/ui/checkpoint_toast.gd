class_name CheckpointToast
extends CanvasLayer
## Brief top-center fade-in/out label, used by Checkpoint to notify the player.

@onready var label: Label = $Label

func _ready() -> void:
	label.modulate.a = 0.0

func show_toast(text: String, duration: float = 1.4) -> void:
	label.text = text
	var tween: Tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.18)
	tween.tween_interval(duration)
	tween.tween_property(label, "modulate:a", 0.0, 0.35)
