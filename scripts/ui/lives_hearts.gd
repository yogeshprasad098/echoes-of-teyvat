class_name LivesHearts
extends Control

const HEART_SIZE := Vector2(14.0, 13.0)
const HEART_GAP: float = 3.5
const FILLED_COLOR := Color(0.98, 0.08, 0.15, 0.98)
const FILLED_SHADOW := Color(0.22, 0.02, 0.03, 0.62)
const FILLED_HIGHLIGHT := Color(1.0, 0.62, 0.64, 0.88)
const EMPTY_COLOR := Color(0.18, 0.15, 0.15, 0.52)
const EMPTY_INNER := Color(0.08, 0.065, 0.07, 0.5)
const EMPTY_OUTLINE := Color(0.78, 0.66, 0.62, 0.78)
const FILLED_OUTLINE := Color(1.0, 0.43, 0.46, 0.96)

var _remaining: int = 5
var _maximum: int = 5

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(222, 17)

func set_lives(remaining: int, maximum: int) -> void:
	_maximum = maxi(maximum, 0)
	_remaining = clampi(remaining, 0, _maximum)
	queue_redraw()

func remaining_lives() -> int:
	return _remaining

func maximum_lives() -> int:
	return _maximum

func _draw() -> void:
	if _maximum <= 0:
		return
	var total_width := float(_maximum) * HEART_SIZE.x + float(maxi(_maximum - 1, 0)) * HEART_GAP
	var start_x := maxf(size.x - total_width, 0.0)
	var start_y := maxf((size.y - HEART_SIZE.y) * 0.5, 0.0)
	for index in _maximum:
		var origin := Vector2(start_x + float(index) * (HEART_SIZE.x + HEART_GAP), start_y)
		_draw_heart(origin, index < _remaining)

func _draw_heart(origin: Vector2, filled: bool) -> void:
	origin = origin.floor()
	var points := PackedVector2Array([
		origin + Vector2(7.0, 12.0),
		origin + Vector2(1.5, 7.2),
		origin + Vector2(0.5, 4.0),
		origin + Vector2(1.4, 1.7),
		origin + Vector2(3.4, 0.5),
		origin + Vector2(5.8, 1.0),
		origin + Vector2(7.0, 2.5),
		origin + Vector2(8.2, 1.0),
		origin + Vector2(10.6, 0.5),
		origin + Vector2(12.6, 1.7),
		origin + Vector2(13.5, 4.0),
		origin + Vector2(12.5, 7.2),
	])
	if filled:
		var shadow_points := PackedVector2Array()
		for point in points:
			shadow_points.append(point + Vector2(0.8, 1.0))
		draw_colored_polygon(shadow_points, FILLED_SHADOW)
		draw_colored_polygon(points, FILLED_COLOR)
	else:
		draw_colored_polygon(points, EMPTY_COLOR)
		var inner_points := PackedVector2Array()
		for point in points:
			inner_points.append(origin + Vector2(7.0, 6.0) + (point - origin - Vector2(7.0, 6.0)) * 0.68)
		draw_colored_polygon(inner_points, EMPTY_INNER)
		_draw_closed_polyline(inner_points, EMPTY_OUTLINE.darkened(0.18), 0.85)
	_draw_closed_polyline(points, FILLED_OUTLINE if filled else EMPTY_OUTLINE, 1.45)
	if filled:
		draw_line(origin + Vector2(3.2, 2.0), origin + Vector2(5.0, 1.5), FILLED_HIGHLIGHT, 1.0)
		draw_line(origin + Vector2(8.8, 2.0), origin + Vector2(10.4, 1.6), FILLED_HIGHLIGHT.darkened(0.08), 1.0)

func _draw_closed_polyline(points: PackedVector2Array, color: Color, width: float) -> void:
	if points.size() < 2:
		return
	var closed_points := PackedVector2Array(points)
	closed_points.append(points[0])
	draw_polyline(closed_points, color, width, false)
