@tool
extends SceneTree
## One-shot tool: generates a SpriteFrames resource for the Fire Bomb animation.
## Loads 30 numbered frames (img_0.png ... img_29.png) from assets/projectiles/fireball
## and saves a single-animation SpriteFrames .tres with numeric ordering.

const FRAME_DIR: String = "res://assets/projectiles/fireball/"
const FRAME_COUNT: int = 30
const OUTPUT_PATH: String = "res://resources/sprite_frames/fireball_sprite_frames.tres"
const ANIM_NAME: StringName = &"fly"
const ANIM_FPS: float = 24.0

func _init() -> void:
	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(ANIM_NAME)
	frames.set_animation_speed(ANIM_NAME, ANIM_FPS)
	frames.set_animation_loop(ANIM_NAME, true)

	for i in range(FRAME_COUNT):
		var path := "%simg_%d.png" % [FRAME_DIR, i]
		var tex: Texture2D = load(path) as Texture2D
		if tex == null:
			push_error("Missing frame: %s" % path)
			quit(1)
			return
		frames.add_frame(ANIM_NAME, tex)

	var err: int = ResourceSaver.save(frames, OUTPUT_PATH)
	if err != OK:
		push_error("Failed to save %s: %d" % [OUTPUT_PATH, err])
		quit(1)
		return

	print("[build_fireball_sprite_frames] PASS — saved %s with %d frames" % [OUTPUT_PATH, FRAME_COUNT])
	quit()
