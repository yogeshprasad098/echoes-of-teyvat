extends Node
## Autoload. Trauma-based camera shake.
##
## Follows the kidscancode / Vlambeer "Art of Screenshake" trauma model:
##   trauma is a scalar in [0, 1]. It decays over time. Actual shake
##   displacement is `max_offset * trauma^trauma_power`, so small trauma
##   produces almost no shake and high trauma produces a strong pulse
##   with a quadratic falloff — this feels much better than a linear
##   random shake, which reads as "noisy" rather than "impactful".
##
## Tuned for a 640x360 pixel viewport; max_offset is therefore small.
## Null-safe: if no active Camera2D is present, calls are silent no-ops.

@export var trauma_power: float = 2.0
@export var decay: float = 0.9  # per second
@export var max_offset: Vector2 = Vector2(6.0, 4.0)
@export var max_roll: float = 0.04  # radians

var _trauma: float = 0.0

# Idiomatic API — add trauma with a floating-point weight in [0, 1].
func add_trauma(amount: float) -> void:
	_trauma = min(1.0, _trauma + amount)

# Backward-compat shim so existing callers (pulse(magnitude, duration))
# keep working while we migrate. Maps rough magnitude to a trauma weight.
func pulse(magnitude: float = 4.0, _duration: float = 0.15) -> void:
	add_trauma(clampf(magnitude / 10.0, 0.05, 1.0))

func _process(delta: float) -> void:
	var cam: Camera2D = _active_camera()
	if cam == null:
		_trauma = 0.0
		return

	if _trauma <= 0.0:
		cam.offset = Vector2.ZERO
		cam.rotation = 0.0
		return

	_trauma = max(0.0, _trauma - decay * delta)
	var shake: float = pow(_trauma, trauma_power)
	cam.offset = Vector2(
		randf_range(-1.0, 1.0) * max_offset.x * shake,
		randf_range(-1.0, 1.0) * max_offset.y * shake,
	)
	cam.rotation = randf_range(-1.0, 1.0) * max_roll * shake

func _active_camera() -> Camera2D:
	var vp: Viewport = get_viewport()
	if vp == null:
		return null
	return vp.get_camera_2d()
