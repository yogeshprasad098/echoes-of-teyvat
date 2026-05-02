class_name SlashTrail
extends Line2D
## Motion trail that samples a source Node2D's position each frame, fades out on stop.

const MAX_POINTS: int = 12
const SAMPLE_INTERVAL: float = 0.015

var _recording: bool = false
var _time_since_sample: float = 0.0
var _source: Node2D = null

func _ready() -> void:
	clear_points()
	default_color = Color(1.0, 0.82, 0.32, 0.95)
	width = 6.0
	width_curve = _build_taper()
	gradient = _build_gradient()

func _process(delta: float) -> void:
	if not _recording or _source == null:
		return
	_time_since_sample += delta
	if _time_since_sample < SAMPLE_INTERVAL:
		return
	_time_since_sample = 0.0
	add_point(_source.global_position - global_position)
	if get_point_count() > MAX_POINTS:
		remove_point(0)

func start(source: Node2D) -> void:
	_source = source
	_recording = true
	clear_points()

func stop() -> void:
	_recording = false
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.18)
	tween.tween_callback(func() -> void:
		clear_points()
		modulate.a = 1.0
	)

func _build_taper() -> Curve:
	var c: Curve = Curve.new()
	c.add_point(Vector2(0.0, 0.05))
	c.add_point(Vector2(1.0, 1.0))
	return c

func _build_gradient() -> Gradient:
	var g: Gradient = Gradient.new()
	g.set_color(0, Color(1.0, 0.42, 0.08, 0.0))
	g.set_color(1, Color(1.0, 0.92, 0.48, 0.95))
	return g
