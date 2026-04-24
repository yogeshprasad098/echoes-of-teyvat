extends Node
## Autoload. Perturbs the active Camera2D offset to signal hits, explosions, heavy events.
## Null-safe: if no active Camera2D is present, calls are silent no-ops.

var _remaining: float = 0.0
var _magnitude: float = 0.0

# Pulse the camera for `duration` seconds with a given `magnitude` (in pixels).
func pulse(magnitude: float = 4.0, duration: float = 0.15) -> void:
	_magnitude = max(_magnitude, magnitude)
	_remaining = max(_remaining, duration)

func _process(delta: float) -> void:
	if _remaining <= 0.0:
		return
	var cam: Camera2D = _active_camera()
	if cam == null:
		_remaining = 0.0
		_magnitude = 0.0
		return

	_remaining -= delta
	if _remaining <= 0.0:
		cam.offset = Vector2.ZERO
		_magnitude = 0.0
		return

	var falloff: float = _remaining / max(0.001, _remaining + delta)
	cam.offset = Vector2(
		randf_range(-_magnitude, _magnitude) * falloff,
		randf_range(-_magnitude, _magnitude) * falloff,
	)

func _active_camera() -> Camera2D:
	var vp: Viewport = get_viewport()
	if vp == null:
		return null
	return vp.get_camera_2d()
