class_name AreaBase
extends Node2D
## Base for all game areas. Handles area completion signal.

# === Signals ===
signal area_completed

func _ready() -> void:
	var end_flag: Area2D = get_node_or_null("EndFlag")
	if end_flag:
		end_flag.body_entered.connect(_on_end_flag_body_entered)

func _on_end_flag_body_entered(body: Node) -> void:
	if body is CharacterBase:
		area_completed.emit()
