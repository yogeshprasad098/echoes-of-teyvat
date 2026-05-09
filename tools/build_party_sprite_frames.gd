extends SceneTree
## Builds Kira / Marina / Ryne SpriteFrames .tres files programmatically.
## Run once when sprite sheets change:
##   godot --headless --path . --script tools/build_party_sprite_frames.gd

const FRAME_W: int = 32
const FRAME_H: int = 48

# Per-animation: (frame_count, fps, looping).
const ANIMS: Dictionary = {
	"idle":    [4, 6.0, true],
	"run":     [6, 10.0, true],
	"jump":    [3, 8.0, false],
	"attack":  [12, 16.0, false],
	"throw":   [8, 24.0, false],
	"skill":   [4, 10.0, false],
	"dodge":   [4, 12.0, false],
	"hurt":    [2, 8.0, false],
	"death":   [5, 8.0, false],
}

# attack frames need to be exposed as attack_1/attack_2/attack_3 (3 frames each, kira's combo).
const ATTACK_SUBSETS: Array = [
	{"name": "attack_1", "start": 0, "count": 4, "fps": 14.0, "loop": false},
	{"name": "attack_2", "start": 4, "count": 4, "fps": 14.0, "loop": false},
	{"name": "attack_3", "start": 8, "count": 4, "fps": 14.0, "loop": false},
]

const CHARS: Array[String] = ["kira", "marina", "ryne"]

func _initialize() -> void:
	for c in CHARS:
		_build(c)
	print("Built party SpriteFrames for: %s" % str(CHARS))
	quit(0)

func _build(char_name: String) -> void:
	var sf := SpriteFrames.new()
	# Default animation 'default' is auto-created; remove it.
	if sf.has_animation(&"default"):
		sf.remove_animation(&"default")
	for anim_name in ANIMS:
		var spec = ANIMS[anim_name]
		var count: int = spec[0]
		var fps: float = spec[1]
		var loop: bool = spec[2]
		var png_path := "res://assets/characters/%s/%s.png" % [char_name, anim_name]
		var tex: Texture2D = load(png_path) as Texture2D
		if tex == null:
			push_warning("Missing texture: %s" % png_path)
			continue
		# Special case: 'attack' is split into attack_1/2/3 subsets.
		if anim_name == "attack":
			for subset in ATTACK_SUBSETS:
				_add_anim(sf, subset["name"], tex, subset["start"], subset["count"], subset["fps"], subset["loop"])
		else:
			_add_anim(sf, anim_name, tex, 0, count, fps, loop)

	var save_path := "res://resources/sprite_frames/%s_sprite_frames.tres" % char_name
	var err := ResourceSaver.save(sf, save_path)
	if err != OK:
		push_error("Failed to save %s: %s" % [save_path, err])
	else:
		print("  wrote %s" % save_path)

func _add_anim(sf: SpriteFrames, anim_name: String, tex: Texture2D, start: int, count: int, fps: float, loop: bool) -> void:
	sf.add_animation(anim_name)
	sf.set_animation_speed(anim_name, fps)
	sf.set_animation_loop(anim_name, loop)
	for i in range(count):
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2((start + i) * FRAME_W, 0, FRAME_W, FRAME_H)
		sf.add_frame(anim_name, atlas)
