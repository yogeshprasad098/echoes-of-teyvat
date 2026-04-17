class_name HUD
extends CanvasLayer
## Minimal HUD: Kira's health bar and elemental skill cooldown bar.

# === Onready ===
@onready var health_bar: ProgressBar = $HealthBar
@onready var skill_bar: ProgressBar = $SkillBar

# Reference set by main.tscn or ember_fields.tscn after Kira is spawned.
var _kira: Kira = null

func _ready() -> void:
	health_bar.max_value = 100
	skill_bar.max_value = 100

# Call this from the area scene once Kira is in the tree.
func bind_kira(kira: Kira) -> void:
	_kira = kira
	kira.health_changed.connect(_on_health_changed)
	health_bar.value = 100

func _process(_delta: float) -> void:
	if not is_instance_valid(_kira):
		return
	# Update skill cooldown bar each frame.
	var timer: Timer = _kira.get_node_or_null("SkillCooldownTimer")
	if timer:
		var remaining: float = timer.time_left
		var ratio: float = 1.0 - (remaining / 8.0) if not timer.is_stopped() else 1.0
		skill_bar.value = ratio * 100.0

func _on_health_changed(current: float, maximum: float) -> void:
	health_bar.value = (current / maximum) * 100.0
