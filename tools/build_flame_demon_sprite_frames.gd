@tool
extends SceneTree
## One-shot tool: generates a SpriteFrames resource for the flame-demon-skinned Grunt.
## Uses two static images (flame_demon.png + flame_demon_evolved.png) with different
## animation speeds/configurations per state to fake "living" motion from static frames.
##
## Animations:
##   walk  - alternates between the two frames at 6 fps for a flicker-walk feel
##   attack - holds the evolved (more menacing) frame, single-frame non-looping
##   death  - flickers back to the base demon before fading (handled by caller modulate)

const BASE_PATH: String = "res://assets/enemies/flame_demon/flame_demon.png"
const EVOLVED_PATH: String = "res://assets/enemies/flame_demon/flame_demon_evolved.png"
const OUTPUT_PATH: String = "res://resources/sprite_frames/grunt_sprite_frames.tres"

func _init() -> void:
	var base_tex: Texture2D = load(BASE_PATH) as Texture2D
	var evolved_tex: Texture2D = load(EVOLVED_PATH) as Texture2D
	if base_tex == null or evolved_tex == null:
		push_error("Failed to load flame demon textures")
		quit(1)
		return

	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation(&"default")

	# walk: alternate frames at 6fps loop
	frames.add_animation(&"walk")
	frames.set_animation_speed(&"walk", 6.0)
	frames.set_animation_loop(&"walk", true)
	frames.add_frame(&"walk", base_tex)
	frames.add_frame(&"walk", evolved_tex)

	# attack: hold the evolved (more menacing) pose
	frames.add_animation(&"attack")
	frames.set_animation_speed(&"attack", 8.0)
	frames.set_animation_loop(&"attack", false)
	frames.add_frame(&"attack", evolved_tex)
	frames.add_frame(&"attack", evolved_tex)

	# death: flicker back to base then implementer fades via modulate
	frames.add_animation(&"death")
	frames.set_animation_speed(&"death", 10.0)
	frames.set_animation_loop(&"death", false)
	frames.add_frame(&"death", evolved_tex)
	frames.add_frame(&"death", base_tex)
	frames.add_frame(&"death", base_tex)

	# default alias for any code expecting it
	frames.add_animation(&"default")
	frames.set_animation_speed(&"default", 6.0)
	frames.set_animation_loop(&"default", true)
	frames.add_frame(&"default", base_tex)
	frames.add_frame(&"default", evolved_tex)

	var err: int = ResourceSaver.save(frames, OUTPUT_PATH)
	if err != OK:
		push_error("Failed to save %s: %d" % [OUTPUT_PATH, err])
		quit(1)
		return

	print("[build_flame_demon_sprite_frames] PASS — saved %s" % OUTPUT_PATH)
	quit()
