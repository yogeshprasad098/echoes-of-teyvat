class_name VolcanoBackground
extends Node3D
## Idle animation loop for the 3D volcano scene — slow rotation + periodic eruption flash.

@export var rotation_speed_deg_per_sec: float = 1.6
@export var eruption_interval_min: float = 18.0
@export var eruption_interval_max: float = 25.0
@export var eruption_flash_duration: float = 0.35

@onready var sun_light: DirectionalLight3D = $SunLight
@onready var lava_glow: OmniLight3D = $LavaGlow
@onready var volcano_mesh: Node3D = $VolcanoMesh

var _eruption_timer: Timer = null

func _ready() -> void:
	_eruption_timer = Timer.new()
	_eruption_timer.one_shot = true
	add_child(_eruption_timer)
	_eruption_timer.timeout.connect(_on_eruption)
	_schedule_next_eruption()

func _process(delta: float) -> void:
	if volcano_mesh:
		volcano_mesh.rotate_y(deg_to_rad(rotation_speed_deg_per_sec) * delta)

func _schedule_next_eruption() -> void:
	var wait: float = randf_range(eruption_interval_min, eruption_interval_max)
	_eruption_timer.start(wait)

func _on_eruption() -> void:
	if lava_glow == null:
		_schedule_next_eruption()
		return
	var base_energy: float = lava_glow.light_energy
	var tween: Tween = create_tween()
	tween.tween_property(lava_glow, "light_energy", base_energy * 3.2, 0.1)
	tween.tween_property(lava_glow, "light_energy", base_energy, eruption_flash_duration)
	tween.tween_callback(_schedule_next_eruption)
