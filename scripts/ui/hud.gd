class_name HUD
extends CanvasLayer
## Minimal HUD: active character's health bar and elemental skill cooldown bar.

# === Onready ===
@onready var health_bar: ProgressBar = $HealthBar
@onready var skill_bar: ProgressBar = $SkillBar

# Reference to the currently bound active character (any CharacterBase).
var _active: CharacterBase = null

func _ready() -> void:
	health_bar.max_value = 100
	skill_bar.max_value = 100
	if CharacterSwitcher:
		CharacterSwitcher.active_changed.connect(_on_active_changed)
	call_deferred("_bind_active_kira")

# Backward-compatible: external callers still pass a CharacterBase.
func bind_kira(player: CharacterBase) -> void:
	if _active == player:
		return
	if _active and _active.health_changed.is_connected(_on_health_changed):
		_active.health_changed.disconnect(_on_health_changed)
	_active = player
	if player == null:
		return
	if not player.health_changed.is_connected(_on_health_changed):
		player.health_changed.connect(_on_health_changed)
	health_bar.value = (player.current_health / player.max_health) * 100.0 if player.max_health > 0 else 100.0

func _process(_delta: float) -> void:
	if not is_instance_valid(_active):
		return
	var timer: Timer = _active.get_node_or_null("SkillCooldownTimer")
	if timer:
		var remaining: float = timer.time_left
		var ratio: float = 1.0 - (remaining / 8.0) if not timer.is_stopped() else 1.0
		skill_bar.value = ratio * 100.0

func _on_health_changed(current: float, maximum: float) -> void:
	health_bar.value = (current / maximum) * 100.0

func _on_active_changed(active: CharacterBase, _slot: int) -> void:
	bind_kira(active)

func _bind_active_kira() -> void:
	# Initial bind: prefer CharacterSwitcher's active member, else fall back to scene search.
	if CharacterSwitcher and CharacterSwitcher.active():
		bind_kira(CharacterSwitcher.active())
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	var kira := scene.find_child("Kira", true, false) as Kira
	if kira:
		bind_kira(kira)
