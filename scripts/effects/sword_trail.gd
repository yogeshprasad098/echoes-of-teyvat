class_name SwordTrail
extends Line2D
## Procedural crescent slash trail. Pre-shaped points form a sword arc;
## the node scales + fades in on start() and fades out on stop().
## Idiomatic for 2D action RPGs when the hitbox doesn't physically move
## enough to produce a naturally-sampled Line2D trail.

var SLASH_POINTS: PackedVector2Array = PackedVector2Array([
	Vector2(-14, -24),
	Vector2( -2, -22),
	Vector2( 12, -16),
	Vector2( 24,  -6),
	Vector2( 30,   4),
	Vector2( 24,  14),
	Vector2( 12,  22),
	Vector2( -2,  24),
	Vector2(-14,  22),
])

var _tween: Tween = null

func _ready() -> void:
	top_level = true  # positions live in global space
	clear_points()
	modulate.a = 0.0
	z_index = 6
	default_color = Color(1.0, 0.92, 0.55, 1.0)
	width = 7.0
	width_curve = _build_taper()
	gradient = _build_gradient()

# Play the slash arc at `global_pos`, facing `facing_dir` (1 right, -1 left).
func play_slash(global_pos: Vector2, facing_dir: int, scale_mul: float = 1.0, duration: float = 0.14) -> void:
	clear_points()
	for p in SLASH_POINTS:
		add_point(Vector2(p.x * facing_dir * scale_mul, p.y * scale_mul) + global_pos)

	if _tween != null and _tween.is_valid():
		_tween.kill()
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, duration)
	_tween.tween_callback(clear_points)

func _build_taper() -> Curve:
	var c: Curve = Curve.new()
	c.add_point(Vector2(0.0, 0.08))
	c.add_point(Vector2(0.55, 1.0))
	c.add_point(Vector2(1.0, 0.12))
	return c

func _build_gradient() -> Gradient:
	var g: Gradient = Gradient.new()
	g.set_color(0, Color(1.0, 0.45, 0.10, 0.0))
	g.add_point(0.4, Color(1.0, 0.62, 0.12, 0.9))
	g.set_color(1, Color(1.0, 0.95, 0.55, 1.0))
	return g
