class_name DialoguePopup
extends CanvasLayer
## Compact quote popup used for area, switch, skill, and boss polish beats.

@onready var panel: PanelContainer = %Panel
@onready var speaker_label: Label = %SpeakerLabel
@onready var quote_label: RichTextLabel = %QuoteLabel

var _tween: Tween = null

func _ready() -> void:
	panel.modulate.a = 0.0

func show_line(speaker: String, line: String, duration: float = 2.4) -> void:
	if line.strip_edges() == "":
		return
	speaker_label.text = speaker
	quote_label.text = line
	if _tween:
		_tween.kill()
	panel.modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(panel, "modulate:a", 1.0, 0.18)
	_tween.tween_interval(duration)
	_tween.tween_property(panel, "modulate:a", 0.0, 0.28)
