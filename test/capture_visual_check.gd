extends SceneTree

const OUTPUT_DIR := "res://test/artifacts/visual_check"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_prepare_output_dir()
	get_root().size = Vector2i(640, 360)

	var main_scene := load("res://scenes/main.tscn") as PackedScene
	var main := main_scene.instantiate() as Node2D
	get_root().add_child(main)
	current_scene = main
	await _settle()
	await _capture("00_title_screen")

	main.call("_start_game")
	await _settle()

	var area := main.get_node("EmberFields") as Node2D
	var kira := area.get_node("Party/Kira") as Kira
	var hud := main.get_node("HUD") as HUD
	var camera := area.get_node("Party/Camera2D") as Camera2D

	await _capture("01_start")

	kira.global_position = Vector2(692, 256)
	camera.reset_smoothing()
	_force_grunt_attack(area, "Enemies/Grunt", kira)
	await _settle()
	await _capture("02_first_platform_grunt")
	for index in 16:
		await physics_frame
		await process_frame
	await _capture("02b_grunt_attack_hit")

	kira.global_position = Vector2(1536, 224)
	camera.reset_smoothing()
	await _settle()
	await _capture("03_mid_level_grunt")

	kira.global_position = Vector2(2240, 288)
	camera.reset_smoothing()
	await _settle()
	await _capture("04_late_level_grunt")

	kira.global_position = Vector2(2592, 288)
	camera.reset_smoothing()
	await _settle()
	await _capture("05_goal_climb")

	kira.global_position = Vector2(3170, 192)
	camera.reset_smoothing()
	await _settle()
	await _capture("06_end_flag")

	main.queue_free()
	await process_frame
	main = main_scene.instantiate() as Node2D
	get_root().add_child(main)
	current_scene = main
	await _settle()
	main.call("_start_game")
	await _settle()
	area = main.get_node("EmberFields") as Node2D
	kira = area.get_node("Party/Kira") as Kira
	hud = main.get_node("HUD") as HUD
	camera = area.get_node("Party/Camera2D") as Camera2D
	await _stage_attack_capture(area, kira, camera)
	await _capture("07_attack")

	await _stage_skill_capture(main_scene)
	main = current_scene as Node2D
	area = main.get_node("EmberFields") as Node2D
	kira = area.get_node("Party/Kira") as Kira
	camera = area.get_node("Party/Camera2D") as Camera2D
	await _capture("08_skill_fire_bomb")

	kira.take_damage(35.0)
	await _settle()
	hud._process(0.0)
	await _capture("09_hud_damaged_cooldown")

	main.call("_restart_game")
	await _settle()
	area = main.get_node("EmberFields") as Node2D
	kira = area.get_node("Party/Kira") as Kira
	camera = area.get_node("Party/Camera2D") as Camera2D
	kira.global_position = Vector2(kira.global_position.x, 640.0)
	camera.reset_smoothing()
	for index in 30:
		await physics_frame
		await process_frame
	main.get_node("HUD").visible = false
	main.get_node("GameOverScreen/Panel/TitleLabel").text = "Kira Fell"
	main.get_node("GameOverScreen/Panel/BodyLabel").text = "Return to the Ember Fields."
	main.get_node("GameOverScreen").visible = true
	(main.get_node("GameOverScreen") as CanvasLayer).layer = 10
	await process_frame
	await _capture("10_game_over")

	Engine.time_scale = 1.0
	print("Visual captures saved to %s" % ProjectSettings.globalize_path(OUTPUT_DIR))
	quit(0)

func _prepare_output_dir() -> void:
	var dir := DirAccess.open("res://")
	if dir == null:
		push_error("Could not open project root")
		quit(1)
		return
	dir.make_dir_recursive("test/artifacts/visual_check")

func _settle() -> void:
	for index in 8:
		await physics_frame
		await process_frame

func _force_grunt_attack(area: Node, grunt_path: NodePath, kira: Kira) -> void:
	var grunt := area.get_node_or_null(grunt_path) as Grunt
	if grunt == null:
		return
	grunt._on_detection_body_entered(kira)
	grunt._physics_process(0.016)

func _stage_attack_capture(area: Node, kira: Kira, camera: Camera2D) -> void:
	var grunt := area.get_node("Enemies/Grunt") as Grunt
	grunt.reset_for_run()
	grunt.global_position = Vector2(720, 256)
	grunt.set_physics_process(false)
	kira.global_position = Vector2(675, 256)
	kira.velocity = Vector2.ZERO
	kira.facing_direction = 1
	kira.sprite.flip_h = false
	camera.reset_smoothing()

	await process_frame
	kira._start_attack()
	await physics_frame
	await process_frame
	kira._damage_enemy(grunt)
	await process_frame

func _stage_skill_capture(main_scene: PackedScene) -> void:
	if is_instance_valid(current_scene):
		var previous_scene := current_scene
		get_root().remove_child(previous_scene)
		previous_scene.queue_free()
		await process_frame
	var main := main_scene.instantiate() as Node2D
	get_root().add_child(main)
	current_scene = main
	await _settle()
	main.call("_start_game")
	await _settle()

	var area := main.get_node("EmberFields") as Node2D
	var kira := area.get_node("Party/Kira") as Kira
	var camera := area.get_node("Party/Camera2D") as Camera2D
	area.get_node("Enemies").visible = false
	kira.global_position = Vector2(180, 336)
	kira.velocity = Vector2.ZERO
	kira.facing_direction = 1
	kira.sprite.flip_h = false
	(kira.get_node("SkillCooldownTimer") as Timer).stop()
	camera.reset_smoothing()
	camera.make_current()
	await process_frame
	kira._use_skill()
	await physics_frame
	await process_frame

func _capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		print("Skipped %s: no viewport image in headless renderer" % name)
		return
	RenderingServer.force_draw(false)
	var texture := get_root().get_texture()
	if texture == null:
		print("Skipped %s: no viewport texture in this renderer" % name)
		return
	var image := texture.get_image()
	if image == null or image.is_empty():
		print("Skipped %s: no viewport image in this renderer" % name)
		return
	var path := "%s/%s.png" % [OUTPUT_DIR, name]
	var error := image.save_png(path)
	if error != OK:
		push_error("Failed to save %s: %s" % [path, error])
	else:
		print("Saved %s" % ProjectSettings.globalize_path(path))
