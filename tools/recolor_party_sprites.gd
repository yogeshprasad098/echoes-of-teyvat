extends SceneTree
## Generates Marina and Ryne spritesheets by palette-swapping Kira's PNGs.
## Run once via:  godot --headless --path . --script tools/recolor_party_sprites.gd

# Kira's source palette (from generate_pixel_assets.gd).
const KIRA_OUTLINE  := Color(0.05, 0.035, 0.025, 1)
const KIRA_SKIN     := Color(1.0, 0.66, 0.36, 1)
const KIRA_HAIR     := Color(1.0, 0.47, 0.06, 1)
const KIRA_TUNIC    := Color(0.74, 0.05, 0.05, 1)
const KIRA_TUNIC_D  := Color(0.32, 0.02, 0.03, 1)
const KIRA_SCARF    := Color(1.0, 0.18, 0.02, 1)
const KIRA_GOLD     := Color(1.0, 0.78, 0.18, 1)
const KIRA_BOOT     := Color(0.12, 0.07, 0.04, 1)
const KIRA_SWORD    := Color(0.86, 0.9, 0.86, 1)
const KIRA_FIRE     := Color(1.0, 0.26, 0.02, 1)
const KIRA_FIRE_GLW := Color(1.0, 0.68, 0.06, 1)

# Marina — hydro support: cyan hair, blue tunic, white-blue accents.
const MARINA_PALETTE := {
	KIRA_HAIR:     Color(0.42, 0.85, 1.00, 1),  # bright cyan hair
	KIRA_TUNIC:    Color(0.18, 0.42, 0.78, 1),  # deep blue robe
	KIRA_TUNIC_D:  Color(0.08, 0.22, 0.48, 1),  # darker blue trim
	KIRA_SCARF:    Color(0.65, 0.92, 1.00, 1),  # pale water scarf
	KIRA_GOLD:     Color(0.85, 0.95, 1.00, 1),  # silver accents
	KIRA_SWORD:    Color(0.55, 0.85, 1.00, 1),  # water-tinted weapon
	KIRA_FIRE:     Color(0.20, 0.55, 1.00, 1),  # blue projectile core
	KIRA_FIRE_GLW: Color(0.55, 0.92, 1.00, 1),  # cyan glow
}

# Ryne — electro striker: yellow hair, purple gauntlets, electric accents.
const RYNE_PALETTE := {
	KIRA_HAIR:     Color(1.00, 0.92, 0.32, 1),  # bright yellow hair
	KIRA_TUNIC:    Color(0.55, 0.28, 0.78, 1),  # purple gi
	KIRA_TUNIC_D:  Color(0.32, 0.12, 0.48, 1),  # darker purple
	KIRA_SCARF:    Color(1.00, 0.95, 0.42, 1),  # gold sash
	KIRA_GOLD:     Color(1.00, 0.95, 0.42, 1),  # gold accents
	KIRA_SWORD:    Color(0.78, 0.55, 1.00, 1),  # purple gauntlet
	KIRA_FIRE:     Color(0.78, 0.42, 1.00, 1),  # purple electro core
	KIRA_FIRE_GLW: Color(1.00, 0.95, 0.55, 1),  # yellow glow
}

const ANIMS := ["idle", "run", "jump", "attack", "throw", "skill", "dodge", "hurt", "death"]

func _initialize() -> void:
	_ensure_dir("res://assets/characters/marina")
	_ensure_dir("res://assets/characters/ryne")
	for anim in ANIMS:
		_recolor("res://assets/characters/kira/%s.png" % anim,
				 "res://assets/characters/marina/%s.png" % anim,
				 MARINA_PALETTE)
		_recolor("res://assets/characters/kira/%s.png" % anim,
				 "res://assets/characters/ryne/%s.png" % anim,
				 RYNE_PALETTE)
	print("Recolored %d animations × 2 characters." % ANIMS.size())
	quit(0)

func _ensure_dir(path: String) -> void:
	var d := DirAccess.open("res://")
	if d == null:
		return
	if not d.dir_exists(path):
		d.make_dir_recursive(path)

func _recolor(src_path: String, dst_path: String, palette: Dictionary) -> void:
	var img: Image = Image.load_from_file(src_path)
	if img == null:
		push_error("Failed to load: %s" % src_path)
		return
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c: Color = img.get_pixel(x, y)
			if c.a < 0.05:
				continue
			# Match against the palette with small tolerance.
			for src_color in palette:
				if _approx(c, src_color):
					img.set_pixel(x, y, palette[src_color])
					break
	var err: int = img.save_png(dst_path)
	if err != OK:
		push_error("Failed to save %s: %s" % [dst_path, err])

func _approx(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) < 0.01 and absf(a.g - b.g) < 0.01 and absf(a.b - b.b) < 0.01
