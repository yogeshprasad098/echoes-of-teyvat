class_name RespawnNotice
extends CanvasLayer
## Center-screen transition notice shown while the player is being respawned.

const DISPLAY_TIME_SEC := 0.72

var _tween: Tween = null

@onready var panel: PanelContainer = %Panel
@onready var title_label: Label = %TitleLabel
@onready var stage_label: Label = %StageLabel
@onready var body_label: Label = %BodyLabel
@onready var lives_bar: ProgressBar = %LivesBar

func _ready() -> void:
	visible = false
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.96, 0.96)

func show_respawn(remaining: int, maximum: int, stage_name: String, is_boss: bool) -> void:
	if _tween:
		_tween.kill()
	_tween = null

	var safe_maximum := maxi(maximum, 1)
	var safe_remaining := clampi(remaining, 0, safe_maximum)
	title_label.text = "Respawning"
	stage_label.text = "%s  %s" % ["BOSS" if is_boss else "AREA", stage_name]
	body_label.text = "Life lost. %d/%d lives remaining." % [safe_remaining, safe_maximum]
	lives_bar.max_value = safe_maximum
	lives_bar.value = safe_remaining

	visible = true
	panel.pivot_offset = panel.size * 0.5
	panel.modulate = Color(1, 1, 1, 0)
	panel.scale = Vector2(0.96, 0.96)

	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(panel, "modulate:a", 1.0, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(DISPLAY_TIME_SEC)
	_tween.tween_property(panel, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tween.tween_callback(func() -> void:
		visible = false
		_tween = null
	)

func hide_notice() -> void:
	if _tween:
		_tween.kill()
		_tween = null
	visible = false
	panel.modulate.a = 0.0
