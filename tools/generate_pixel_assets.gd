extends SceneTree

const CLEAR := Color(0, 0, 0, 0)
const OUTLINE := Color(0.05, 0.035, 0.025, 1)
const SKIN := Color(1.0, 0.66, 0.36, 1)
const HAIR := Color(1.0, 0.47, 0.06, 1)
const TUNIC := Color(0.74, 0.05, 0.05, 1)
const TUNIC_DARK := Color(0.32, 0.02, 0.03, 1)
const SCARF := Color(1.0, 0.18, 0.02, 1)
const GOLD := Color(1.0, 0.78, 0.18, 1)
const BOOT := Color(0.12, 0.07, 0.04, 1)
const SWORD := Color(0.86, 0.9, 0.86, 1)
const FIRE := Color(1.0, 0.26, 0.02, 1)
const FIRE_GLOW := Color(1.0, 0.68, 0.06, 1)
const GRUNT_DARK := Color(0.04, 0.18, 0.04, 1)
const GRUNT := Color(0.28, 0.68, 0.18, 1)
const GRUNT_LIGHT := Color(0.55, 0.95, 0.25, 1)

func _initialize() -> void:
	_generate_kira()
	_generate_grunt()
	print("Generated clearer pixel-art character and enemy sheets.")
	quit(0)

func _generate_kira() -> void:
	_save_strip("res://assets/characters/kira/idle.png", 32, 48, 4, _draw_kira_idle)
	_save_strip("res://assets/characters/kira/run.png", 32, 48, 6, _draw_kira_run)
	_save_strip("res://assets/characters/kira/jump.png", 32, 48, 3, _draw_kira_jump)
	_save_strip("res://assets/characters/kira/attack.png", 32, 48, 12, _draw_kira_attack)
	_save_strip("res://assets/characters/kira/throw.png", 32, 48, 4, _draw_kira_throw)
	_save_strip("res://assets/characters/kira/skill.png", 32, 48, 4, _draw_kira_skill)
	_save_strip("res://assets/characters/kira/dodge.png", 32, 48, 4, _draw_kira_dodge)
	_save_strip("res://assets/characters/kira/hurt.png", 32, 48, 2, _draw_kira_hurt)
	_save_strip("res://assets/characters/kira/death.png", 32, 48, 5, _draw_kira_death)

func _generate_grunt() -> void:
	_save_strip("res://assets/enemies/grunt/idle.png", 32, 32, 4, _draw_grunt_idle)
	_save_strip("res://assets/enemies/grunt/walk.png", 32, 32, 6, _draw_grunt_walk)
	_save_strip("res://assets/enemies/grunt/attack.png", 32, 32, 4, _draw_grunt_attack)
	_save_strip("res://assets/enemies/grunt/death.png", 32, 32, 5, _draw_grunt_death)

func _save_strip(path: String, frame_w: int, frame_h: int, frame_count: int, drawer: Callable) -> void:
	var image := Image.create(frame_w * frame_count, frame_h, false, Image.FORMAT_RGBA8)
	image.fill(CLEAR)
	for frame in frame_count:
		drawer.call(image, frame * frame_w, frame)
	var error := image.save_png(path)
	if error != OK:
		push_error("Failed to save %s: %s" % [path, error])

func _draw_kira_idle(image: Image, ox: int, frame: int) -> void:
	_draw_kira_base(image, ox, 0, frame % 2, 1, false)

func _draw_kira_run(image: Image, ox: int, frame: int) -> void:
	_draw_kira_base(image, ox, 0, frame % 2, 1, false)
	var leg_shift := -2 if frame % 2 == 0 else 2
	_rect(image, ox + 10 + leg_shift, 36, 5, 6, BOOT)
	_rect(image, ox + 18 - leg_shift, 36, 5, 6, BOOT)

func _draw_kira_jump(image: Image, ox: int, frame: int) -> void:
	_draw_kira_base(image, ox, -2 - frame, 0, 1, false)
	_rect(image, ox + 9, 36, 5, 4, BOOT)
	_rect(image, ox + 19, 34, 5, 4, BOOT)

func _draw_kira_attack(image: Image, ox: int, frame: int) -> void:
	var combo_frame := frame % 4
	_draw_kira_base(image, ox, 0, combo_frame % 2, 1, false)
	if combo_frame == 0:
		_rect(image, ox + 20, 20, 5, 3, SKIN)
		_rect(image, ox + 23, 18, 9, 3, SWORD)
		_rect(image, ox + 30, 17, 2, 5, Color.WHITE)
	elif combo_frame == 1:
		_diag(image, ox + 21, 13, ox + 31, 25, SWORD, 2)
		_poly(image, [Vector2i(21, 12), Vector2i(31, 18), Vector2i(29, 26), Vector2i(22, 23)], ox, Color(1, 0.76, 0.12, 0.95))
	elif combo_frame == 2:
		_rect(image, ox + 20, 24, 12, 3, SWORD)
		_poly(image, [Vector2i(21, 17), Vector2i(31, 23), Vector2i(31, 28), Vector2i(21, 32)], ox, Color(1, 0.42, 0.05, 0.85))
	else:
		_diag(image, ox + 20, 30, ox + 31, 14, SWORD, 2)
		_poly(image, [Vector2i(19, 33), Vector2i(31, 15), Vector2i(31, 27), Vector2i(23, 34)], ox, Color(1, 0.88, 0.18, 0.75))

func _draw_kira_skill(image: Image, ox: int, frame: int) -> void:
	# Big skill cast — both arms raised forward as a fireball builds and releases.
	_draw_kira_base(image, ox, 0, 0, 1, true)
	# Wipe the default right-arm pixels so we can redraw it raised.
	_rect(image, ox + 23, 23, 4, 10, Color(0, 0, 0, 0))
	_rect(image, ox + 25, 30, 3, 3, Color(0, 0, 0, 0))
	# Both arms raised and forward — silhouette grows by frame.
	var arm_y := 18 + frame
	_rect(image, ox + 22, arm_y, 4, 8 + frame, OUTLINE)        # outer outline
	_rect(image, ox + 23, arm_y + 1, 2, 6 + frame, SKIN)       # arm
	_rect(image, ox + 7, arm_y + 1, 4, 7, OUTLINE)             # left arm raised too
	_rect(image, ox + 8, arm_y + 2, 2, 5, SKIN)
	# Fireball forming at hands — grows each frame.
	var fb_size := 6 + frame * 3
	var fb_x := ox + 27
	var fb_y := arm_y - 2
	_rect(image, fb_x - 1, fb_y - 1, fb_size + 2, fb_size + 2, OUTLINE)
	_rect(image, fb_x, fb_y, fb_size, fb_size, FIRE_GLOW)
	_rect(image, fb_x + 1, fb_y + 1, fb_size - 2, fb_size - 2, FIRE)
	# Glow ring around character on later frames.
	if frame >= 2:
		var ring := 14 + frame * 3
		_outline_ring(image, ox + 16 - ring / 2, 22 - ring / 2, ring, ring, Color(1, 0.42, 0.08, 0.4))

func _draw_kira_throw(image: Image, ox: int, frame: int) -> void:
	# Quick 4-frame throw: wind-up → arm forward → release with spark → recover.
	_draw_kira_base(image, ox, 0, 0, 1, false)
	# Clear default right-arm to redraw.
	_rect(image, ox + 23, 23, 4, 10, Color(0, 0, 0, 0))
	_rect(image, ox + 25, 30, 3, 3, Color(0, 0, 0, 0))
	match frame:
		0:
			# Wind-up: arm pulled back behind the body.
			_rect(image, ox + 4, 24, 4, 6, OUTLINE)
			_rect(image, ox + 5, 25, 2, 4, SKIN)
			# Spark forming at the cocked hand.
			_rect(image, ox + 3, 26, 3, 3, FIRE_GLOW)
			_rect(image, ox + 4, 27, 1, 1, FIRE)
		1:
			# Mid-swing: arm sweeping forward, body slight forward lean.
			_rect(image, ox + 14, 22, 6, 4, OUTLINE)
			_rect(image, ox + 15, 23, 4, 2, SKIN)
			# Spark trail at hand.
			_rect(image, ox + 19, 22, 3, 3, FIRE_GLOW)
			_rect(image, ox + 20, 23, 2, 2, FIRE)
		2:
			# Release: arm extended forward, hand open, fireball leaves.
			_rect(image, ox + 23, 22, 7, 3, OUTLINE)
			_rect(image, ox + 24, 23, 5, 1, SKIN)
			# The released orb at fingertips.
			_rect(image, ox + 28, 21, 5, 5, OUTLINE)
			_rect(image, ox + 29, 22, 3, 3, FIRE_GLOW)
			_rect(image, ox + 30, 23, 1, 1, FIRE)
			# Trailing fire-streak behind the arm.
			_rect(image, ox + 19, 23, 4, 2, Color(1, 0.42, 0.08, 0.55))
		_:
			# Recover: arm dropping back, slight glow lingering at the hand.
			_rect(image, ox + 22, 25, 4, 6, OUTLINE)
			_rect(image, ox + 23, 26, 2, 4, SKIN)
			_rect(image, ox + 25, 28, 2, 2, Color(1, 0.55, 0.12, 0.4))

func _outline_ring(image: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for xx in range(x, x + w):
		_rect(image, xx, y, 1, 1, color)
		_rect(image, xx, y + h - 1, 1, 1, color)
	for yy in range(y, y + h):
		_rect(image, x, yy, 1, 1, color)
		_rect(image, x + w - 1, yy, 1, 1, color)

func _draw_kira_dodge(image: Image, ox: int, frame: int) -> void:
	for i in range(0, frame + 1):
		_draw_kira_base(image, ox - i * 2, 1, 0, maxf(0.25, 0.8 - i * 0.2), false)

func _draw_kira_hurt(image: Image, ox: int, frame: int) -> void:
	_draw_kira_base(image, ox, 0, frame, 1, false)
	_rect(image, ox + 7, 17, 18, 18, Color(1, 0.08, 0.04, 0.3))

func _draw_kira_death(image: Image, ox: int, frame: int) -> void:
	if frame < 2:
		_draw_kira_base(image, ox, frame * 2, 0, 1, false)
	else:
		_rect(image, ox + 8, 34, 18, 4, OUTLINE)
		_rect(image, ox + 10, 31, 14, 5, TUNIC_DARK)
		_rect(image, ox + 21, 29, 6, 3, HAIR)

func _draw_kira_base(image: Image, ox: int, oy: int, bob: int, alpha: float, powered: bool) -> void:
	var skin := Color(SKIN, alpha)
	var hair := Color(HAIR, alpha)
	var tunic := Color(TUNIC, alpha)
	var dark := Color(TUNIC_DARK, alpha)
	var outline := Color(OUTLINE, alpha)
	var scarf := Color(SCARF, alpha)
	var gold := Color(GOLD, alpha)
	var boot := Color(BOOT, alpha)
	if powered:
		_rect(image, ox + 5, 10 + oy, 23, 28, Color(1, 0.25, 0.02, 0.22))

	# Cape and scarf give Kira a readable heroic silhouette.
	_rect(image, ox + 5, 20 + oy, 9, 18, outline)
	_rect(image, ox + 6, 21 + oy, 7, 16, dark)
	_rect(image, ox + 3, 34 + oy, 10, 4, dark)
	_rect(image, ox + 13, 20 + oy, 12, 4, outline)
	_rect(image, ox + 14, 21 + oy, 10, 2, scarf)
	_rect(image, ox + 23, 22 + oy, 5, 3, scarf)

	# Head, hair, and face.
	_rect(image, ox + 10, 7 + bob + oy, 13, 13, outline)
	_rect(image, ox + 11, 9 + bob + oy, 11, 10, skin)
	_rect(image, ox + 8, 5 + bob + oy, 16, 6, hair)
	_rect(image, ox + 7, 10 + bob + oy, 5, 8, hair)
	_rect(image, ox + 21, 8 + bob + oy, 4, 9, hair)
	_rect(image, ox + 12, 11 + bob + oy, 4, 2, hair)
	_rect(image, ox + 13, 14 + bob + oy, 2, 2, outline)
	_rect(image, ox + 19, 14 + bob + oy, 2, 2, outline)
	_rect(image, ox + 15, 18 + bob + oy, 5, 1, outline)

	# Jacket, belt, gloves, and boots.
	_rect(image, ox + 8, 20 + oy, 17, 17, outline)
	_rect(image, ox + 10, 21 + oy, 13, 15, tunic)
	_rect(image, ox + 12, 21 + oy, 3, 15, dark)
	_rect(image, ox + 11, 25 + oy, 12, 3, gold)
	_rect(image, ox + 8, 22 + oy, 5, 9, dark)
	_rect(image, ox + 23, 23 + oy, 4, 9, skin)
	_rect(image, ox + 25, 30 + oy, 3, 3, outline)
	_rect(image, ox + 10, 36 + oy, 5, 6, boot)
	_rect(image, ox + 18, 36 + oy, 5, 6, boot)
	_rect(image, ox + 6, 42 + oy, 9, 3, outline)
	_rect(image, ox + 18, 42 + oy, 9, 3, outline)

func _draw_grunt_idle(image: Image, ox: int, frame: int) -> void:
	_draw_grunt_base(image, ox, frame % 2, 0, false)

func _draw_grunt_walk(image: Image, ox: int, frame: int) -> void:
	_draw_grunt_base(image, ox, frame % 2, frame % 2, false)

func _draw_grunt_attack(image: Image, ox: int, frame: int) -> void:
	_draw_grunt_base(image, ox, 0, frame % 2, true)
	if frame >= 1:
		_rect(image, ox + 20, 17, 7, 3, GRUNT_DARK)
		_rect(image, ox + 26, 16, 4, 2, Color(0.85, 0.95, 0.55, 1))
		_poly(image, [Vector2i(22, 12), Vector2i(31, 18), Vector2i(31, 26), Vector2i(22, 27)], ox, Color(1, 0.12, 0.04, 0.85))

func _draw_grunt_death(image: Image, ox: int, frame: int) -> void:
	if frame < 3:
		_draw_grunt_base(image, ox, frame, 0, false)
	else:
		_rect(image, ox + 7, 24, 18, 4, GRUNT_DARK)
		_rect(image, ox + 10, 21, 12, 4, GRUNT)

func _draw_grunt_base(image: Image, ox: int, bob: int, step: int, angry: bool) -> void:
	_rect(image, ox + 6, 13 + bob, 20, 14, OUTLINE)
	_rect(image, ox + 8, 13 + bob, 16, 13, GRUNT)
	_rect(image, ox + 10, 9 + bob, 13, 8, OUTLINE)
	_rect(image, ox + 11, 10 + bob, 11, 7, GRUNT_LIGHT)
	_rect(image, ox + 6, 8 + bob, 5, 5, GRUNT_DARK)
	_rect(image, ox + 22, 8 + bob, 5, 5, GRUNT_DARK)
	_rect(image, ox + 7, 6 + bob, 3, 3, Color(0.8, 0.92, 0.55, 1))
	_rect(image, ox + 24, 6 + bob, 3, 3, Color(0.8, 0.92, 0.55, 1))
	_rect(image, ox + 12, 13 + bob, 3, 2, Color.RED if angry else OUTLINE)
	_rect(image, ox + 18, 13 + bob, 3, 2, Color.RED if angry else OUTLINE)
	_rect(image, ox + 13, 19 + bob, 8, 2, OUTLINE)
	_rect(image, ox + 9, 22 + bob, 14, 3, GRUNT_DARK)
	_rect(image, ox + 6, 18 + bob, 4, 7, GRUNT_DARK)
	_rect(image, ox + 23, 18 + bob, 4, 7, GRUNT_DARK)
	_rect(image, ox + 7 + step, 27, 7, 3, GRUNT_DARK)
	_rect(image, ox + 19 - step, 27, 7, 3, GRUNT_DARK)

func _rect(image: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for yy in range(maxi(0, y), mini(image.get_height(), y + h)):
		for xx in range(maxi(0, x), mini(image.get_width(), x + w)):
			image.set_pixel(xx, yy, color)

func _diag(image: Image, x0: int, y0: int, x1: int, y1: int, color: Color, width: int) -> void:
	var dx: int = absi(x1 - x0)
	var sx: int = 1 if x0 < x1 else -1
	var dy: int = -absi(y1 - y0)
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx + dy
	var x: int = x0
	var y: int = y0
	while true:
		_rect(image, x, y, width, width, color)
		if x == x1 and y == y1:
			break
		var e2: int = 2 * err
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy

func _poly(image: Image, points: Array[Vector2i], ox: int, color: Color) -> void:
	var min_y := 999
	var max_y := -999
	for point in points:
		min_y = mini(min_y, point.y)
		max_y = maxi(max_y, point.y)
	for y in range(min_y, max_y + 1):
		var nodes: Array[int] = []
		var j := points.size() - 1
		for i in points.size():
			var pi := points[i]
			var pj := points[j]
			if (pi.y < y and pj.y >= y) or (pj.y < y and pi.y >= y):
				nodes.append(int(pi.x + float(y - pi.y) / float(pj.y - pi.y) * float(pj.x - pi.x)))
			j = i
		nodes.sort()
		for i in range(0, nodes.size(), 2):
			if i + 1 >= nodes.size():
				break
			_rect(image, ox + nodes[i], y, nodes[i + 1] - nodes[i] + 1, 1, color)
