extends SceneTree

const PhysicsModel := preload("res://scripts/core/game_physics.gd")

const WORLD_LAYER := 1
const PLAYER_LAYER := 2
const ENEMY_LAYER := 4

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	Engine.time_scale = 1.0
	await process_frame

	_check_project_settings()
	_check_folder_structure()
	_check_physics_model()
	await _check_kira()
	Engine.time_scale = 1.0
	await _check_grunt()
	await _check_ember_fields()
	await _check_drowned_coast()
	await _check_main_flow()
	await _check_hud()

	if _failures.is_empty():
		print("RESULT: PASS core demo checklist")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		print("RESULT: FAIL %d checklist item(s)" % _failures.size())
		quit(1)

func _check_project_settings() -> void:
	_expect(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/main.tscn", "Main scene is configured")
	_expect(ProjectSettings.get_setting("display/window/size/viewport_width") == 640, "Viewport width is 640")
	_expect(ProjectSettings.get_setting("display/window/size/viewport_height") == 360, "Viewport height is 360")
	_expect(ProjectSettings.get_setting("display/window/size/mode") == 3, "Game launches fullscreen")
	_expect(ProjectSettings.get_setting("display/window/stretch/mode") == "viewport", "Viewport stretch mode is enabled")
	_expect(ProjectSettings.get_setting("display/window/stretch/aspect") == "keep", "Aspect ratio is preserved")
	_expect(is_equal_approx(ProjectSettings.get_setting("physics/2d/default_gravity"), PhysicsModel.GRAVITY_PX_PER_SEC2), "Default gravity matches physics model")

func _check_folder_structure() -> void:
	for path in ["res://assets", "res://scenes", "res://scripts", "res://resources", "res://docs"]:
		_expect(DirAccess.dir_exists_absolute(path), "Folder exists: %s" % path)

func _check_physics_model() -> void:
	_expect(is_equal_approx(PhysicsModel.TILE_SIZE_PX, 32.0), "Physics model uses 32px tiles")
	_expect(is_equal_approx(PhysicsModel.PLAYER_RUN_SPEED_PX_PER_SEC, PhysicsModel.tiles_to_pixels(6.0)), "Player run speed is 6 tiles per second")
	_expect(absf(PhysicsModel.jump_height_px() - PhysicsModel.tiles_to_pixels(3.0)) <= 0.4, "Player jump height is about 3 tiles")
	_expect(PhysicsModel.same_height_airtime_sec() > 0.88 and PhysicsModel.same_height_airtime_sec() < 0.89, "Player same-height airtime is predictable")
	_expect(PhysicsModel.run_jump_distance_px() >= PhysicsModel.tiles_to_pixels(PhysicsModel.SAFE_FLAT_JUMP_GAP_TILES), "Player run jump covers the 5-tile safe gap")
	_expect(is_equal_approx(PhysicsModel.COYOTE_TIME_SEC, 0.10), "Coyote time is fixed at 0.10 seconds")
	_expect(is_equal_approx(PhysicsModel.JUMP_BUFFER_TIME_SEC, 0.10), "Jump buffer is fixed at 0.10 seconds")
	var character_base := CharacterBase.new()
	_expect(is_equal_approx(character_base.move_speed, PhysicsModel.PLAYER_RUN_SPEED_PX_PER_SEC), "Character base run speed matches physics model")
	_expect(is_equal_approx(character_base.jump_velocity, PhysicsModel.PLAYER_JUMP_VELOCITY_PX_PER_SEC), "Character base jump velocity matches physics model")
	_expect(is_equal_approx(character_base.acceleration, PhysicsModel.PLAYER_ACCELERATION_PX_PER_SEC2), "Character base acceleration matches physics model")
	_expect(is_equal_approx(character_base.friction, PhysicsModel.PLAYER_FRICTION_PX_PER_SEC2), "Character base friction matches physics model")
	_expect(is_equal_approx(character_base.coyote_time_sec, PhysicsModel.COYOTE_TIME_SEC), "Character base coyote time matches physics model")
	_expect(is_equal_approx(character_base.jump_buffer_time_sec, PhysicsModel.JUMP_BUFFER_TIME_SEC), "Character base jump buffer matches physics model")
	character_base._coyote_time_remaining = PhysicsModel.COYOTE_TIME_SEC
	character_base._jump_buffer_remaining = PhysicsModel.JUMP_BUFFER_TIME_SEC
	_expect(character_base._consume_buffered_jump(), "Buffered jump consumes during coyote time")
	_expect(is_equal_approx(character_base.velocity.y, PhysicsModel.PLAYER_JUMP_VELOCITY_PX_PER_SEC), "Buffered jump applies shared jump velocity")
	character_base.velocity = Vector2.ZERO
	character_base._coyote_time_remaining = 0.0
	character_base._jump_buffer_remaining = PhysicsModel.JUMP_BUFFER_TIME_SEC
	_expect(not character_base._consume_buffered_jump(), "Buffered jump does not fire without coyote time or floor contact")
	character_base.free()
	_expect(is_equal_approx(Kira.DODGE_SPEED * Kira.DODGE_DURATION_SEC, PhysicsModel.tiles_to_pixels(PhysicsModel.DODGE_DISTANCE_TILES)), "Kira dodge covers 4 tiles")
	_expect(is_equal_approx(Marina.DODGE_SPEED * Marina.DODGE_DURATION_SEC, PhysicsModel.tiles_to_pixels(PhysicsModel.DODGE_DISTANCE_TILES)), "Marina dodge covers 4 tiles")
	_expect(is_equal_approx(Ryne.DODGE_SPEED * Ryne.DODGE_DURATION_SEC, PhysicsModel.tiles_to_pixels(PhysicsModel.DODGE_DISTANCE_TILES)), "Ryne dodge covers 4 tiles")
	_expect(is_equal_approx(Kira.ATTACK_RANGE, PhysicsModel.tiles_to_pixels(PhysicsModel.KIRA_MELEE_RANGE_TILES)), "Kira melee range is 2 tiles")
	_expect(is_equal_approx(Ryne.ATTACK_RANGE, PhysicsModel.tiles_to_pixels(PhysicsModel.RYNE_MELEE_RANGE_TILES)), "Ryne melee range is 1.5 tiles")
	_expect(is_equal_approx(Grunt.ATTACK_RANGE, PhysicsModel.tiles_to_pixels(PhysicsModel.GRUNT_ATTACK_RANGE_TILES)), "Grunt attack range is 2 tiles")
	_expect(is_equal_approx(FireOrb.MAX_RANGE, PhysicsModel.tiles_to_pixels(PhysicsModel.SMALL_PROJECTILE_RANGE_TILES)), "Kira thrown fire orb range is 5 tiles")
	_expect(is_equal_approx(WaterOrb.MAX_RANGE, PhysicsModel.tiles_to_pixels(PhysicsModel.SMALL_PROJECTILE_RANGE_TILES)), "Marina water orb range is 5 tiles")
	_expect(is_equal_approx(FireBomb.MAX_RANGE, PhysicsModel.tiles_to_pixels(PhysicsModel.KIRA_FIRE_BOMB_RANGE_TILES)), "Kira fire bomb range is 13 tiles")
	_expect(is_equal_approx(WaterBurst.MAX_RANGE, PhysicsModel.tiles_to_pixels(PhysicsModel.MARINA_WATER_BURST_RANGE_TILES)), "Marina water burst range is 10 tiles")
	_expect(is_equal_approx(Shockwave.RANGE, PhysicsModel.tiles_to_pixels(PhysicsModel.RYNE_SHOCKWAVE_RANGE_TILES)), "Ryne shockwave range is 3 tiles")

func _check_kira() -> void:
	var root := Node2D.new()
	root.name = "KiraTestRoot"
	get_root().add_child(root)

	var kira := _instantiate("res://scenes/characters/kira.tscn") as Kira
	root.add_child(kira)
	await process_frame

	var sprite := kira.get_node("AnimatedSprite2D") as AnimatedSprite2D
	_expect(sprite.sprite_frames != null, "Kira has SpriteFrames")
	_expect_animations(sprite.sprite_frames, ["idle", "run", "jump", "attack_1", "attack_2", "attack_3", "skill", "dodge", "hurt", "death"], "Kira")
	_expect(kira.collision_layer == PLAYER_LAYER, "Kira body is on player collision layer")
	_expect(kira.collision_mask == WORLD_LAYER, "Kira body only collides physically with world")
	_expect(((kira.get_node("HitboxArea2D") as Area2D).collision_mask & ENEMY_LAYER) != 0, "Kira hitbox detects enemies")
	_expect(Kira.ATTACK_DAMAGE == [10.0, 12.0, 16.0], "Kira combo damage is balanced explicitly")
	_expect(is_equal_approx(Kira.SKILL_DAMAGE, 50.0), "Kira skill damage is balanced explicitly")

	Input.action_press("move_right")
	kira._handle_movement()
	Input.action_release("move_right")
	_expect(kira.velocity.x > 0.0, "Kira responds to move_right")

	kira._start_attack()
	_expect(sprite.animation == &"attack_1", "Kira starts attack combo")
	_expect(not (kira.get_node("HitboxArea2D/HitboxCollisionShape") as CollisionShape2D).disabled, "Kira attack enables hitbox")
	_expect(not (kira.get_node("AttackRangeGuide") as Polygon2D).visible, "Kira attack keeps debug reach guide hidden")
	_expect((kira.get_node("HitboxArea2D") as Area2D).position.x > 0.0, "Kira attack hitbox is placed in front")
	_expect(is_equal_approx(((kira.get_node("HitboxArea2D/HitboxCollisionShape") as CollisionShape2D).shape as RectangleShape2D).size.x, Kira.ATTACK_RANGE), "Kira attack hitbox is exactly 2 tiles")

	kira._on_combo_timer_timeout()
	kira._use_skill()
	await process_frame
	_expect(not (kira.get_node("SkillCooldownTimer") as Timer).is_stopped(), "Kira Fire Bomb starts cooldown")
	var bomb := root.find_child("FireBomb", true, false) as FireBomb
	_expect(bomb != null, "Kira spawns Fire Bomb")
	if bomb:
		_expect(bomb.collision_mask == ENEMY_LAYER, "Fire Bomb detects enemy bodies")
		_expect(FireBomb.MAX_RANGE == Kira.SKILL_RANGE, "Fire Bomb range matches Kira skill guide")
		_expect(FireBomb.DAMAGE == Kira.SKILL_DAMAGE, "Fire Bomb damage matches Kira skill damage")
		_expect(bomb.get_node_or_null("Visuals") != null, "Fire Bomb has a flame projectile visual")
	_expect(not (kira.get_node("SkillAura") as Polygon2D).visible, "Kira skill keeps debug aura hidden")
	_expect(not (kira.get_node("SkillRangeGuide") as Line2D).visible, "Kira skill keeps debug range guide hidden")
	_expect(((kira.get_node("SkillRangeGuide") as Line2D).points[1].x - (kira.get_node("SkillRangeGuide") as Line2D).points[0].x) < Kira.SKILL_RANGE, "Kira skill guide is a short cast cue, not the projectile")
	for index in 45:
		await physics_frame
	_expect(kira.current_state != Kira.State.SKILL, "Kira exits skill state after animation")
	_expect(not (kira.get_node("SkillAura") as Polygon2D).visible, "Kira skill aura clears after cast")
	_expect(not (kira.get_node("SkillRangeGuide") as Line2D).visible, "Kira skill guide clears after cast")

	(kira.get_node("SkillCooldownTimer") as Timer).stop()
	kira._use_skill()
	await process_frame
	kira.take_damage(1.0)
	_expect(not (kira.get_node("SkillAura") as Polygon2D).visible, "Kira skill aura clears when cast is interrupted")
	_expect(not (kira.get_node("SkillRangeGuide") as Line2D).visible, "Kira skill guide clears when cast is interrupted")

	kira._start_dodge()
	_expect(kira.is_invincible, "Kira dodge grants invincibility")
	_expect(absf(kira.velocity.x) >= 400.0, "Kira dodge applies horizontal burst")

	root.queue_free()
	await process_frame

func _check_grunt() -> void:
	var grunt := _instantiate("res://scenes/enemies/grunt.tscn") as Grunt
	get_root().add_child(grunt)
	await process_frame

	var sprite := grunt.get_node("AnimatedSprite2D") as AnimatedSprite2D
	_expect(sprite.sprite_frames != null, "Grunt has SpriteFrames")
	_expect_animations(sprite.sprite_frames, ["default", "walk", "attack", "death"], "Grunt")
	_expect((grunt.get_node("DetectionArea2D/CollisionShape2D") as CollisionShape2D).shape != null, "Grunt has detection area")
	_expect(grunt.get_node_or_null("AttackAlert") != null, "Grunt has attack warning marker")
	_expect(grunt.get_node_or_null("AttackArc") != null, "Grunt has attack hit arc")
	_expect(grunt.get_node_or_null("HitSpark") != null, "Grunt has hit spark feedback")
	_expect(grunt.get_node_or_null("DamagePopup") != null, "Grunt has damage number feedback")
	_expect(grunt.get_node_or_null("HealthBar") != null, "Grunt has a visible health bar")
	_expect(is_equal_approx(grunt.max_health, 50.0), "Grunt max health is consistent")
	_expect(is_equal_approx(grunt.damage, 6.0), "Grunt contact attack damage is consistent")
	_expect(grunt.collision_layer == ENEMY_LAYER, "Grunt body is on enemy collision layer")
	_expect(grunt.collision_mask == WORLD_LAYER, "Grunt body only collides physically with world")
	_expect(((grunt.get_node("DetectionArea2D") as Area2D).collision_mask & PLAYER_LAYER) != 0, "Grunt detection sees player layer")
	_expect(is_equal_approx(grunt.move_speed, PhysicsModel.tiles_to_pixels(3.0)), "Grunt patrol speed is 3 tiles per second")
	_expect(is_equal_approx(Grunt.CHASE_SPEED, PhysicsModel.tiles_to_pixels(4.0)), "Grunt chase speed is 4 tiles per second")
	_expect(is_equal_approx(((grunt.get_node("DetectionArea2D/CollisionShape2D") as CollisionShape2D).shape as CircleShape2D).radius, PhysicsModel.tiles_to_pixels(PhysicsModel.GRUNT_DETECTION_RANGE_TILES)), "Grunt detection radius is 6 tiles")

	var target := CharacterBase.new()
	get_root().add_child(target)
	target.global_position = grunt.global_position + Vector2(50.0, 0.0)
	grunt._on_detection_body_entered(target)
	grunt._physics_process(0.016)
	_expect((grunt.get_node("AttackAlert") as Label).visible, "Grunt attack wind-up is visible")
	_expect(sprite.animation == &"attack", "Grunt plays attack animation")
	target.queue_free()

	var close_target := CharacterBase.new()
	get_root().add_child(close_target)
	close_target.global_position = grunt.global_position + Vector2(8.0, 0.0)
	grunt._on_detection_body_entered(close_target)
	grunt._physics_process(0.016)
	_expect(grunt.velocity.x < 0.0, "Grunt backs away instead of overlapping Kira")
	close_target.queue_free()

	var health_before := grunt.current_health
	grunt.take_damage(10.0, "pyro")
	_expect(grunt.current_health < health_before, "Grunt takes damage")
	_expect(is_equal_approx(grunt.current_health, health_before - grunt.last_damage_taken), "Grunt health math is predictable after damage")
	_expect(is_equal_approx((grunt.get_node("HealthBar/Fill") as ColorRect).size.x, 30.0 * (grunt.current_health / grunt.max_health)), "Grunt health bar reflects current health")
	_expect((grunt.get_node("HitSpark") as Polygon2D).visible, "Grunt hit spark appears on damage")
	_expect((grunt.get_node("DamagePopup") as Label).visible, "Grunt damage number appears on damage")
	_expect((grunt.get_node("DamagePopup") as Label).text == "-10", "Grunt damage number shows actual damage")
	grunt.take_damage(999.0, "pyro")
	_expect(grunt.current_health <= 0.0, "Grunt can reach death state")
	_expect(grunt.collision_layer == 0, "Defeated Grunt is removed from active collision")
	Engine.time_scale = 1.0
	for index in 70:
		await physics_frame
		await process_frame
	_expect(not grunt.visible, "Grunt hides after death animation")
	grunt.reset_for_run()
	_expect(grunt.visible, "Grunt reset makes defeated enemy visible again")
	_expect(is_equal_approx(grunt.current_health, grunt.max_health), "Grunt reset restores health")
	_expect(is_equal_approx((grunt.get_node("HealthBar/Fill") as ColorRect).size.x, 30.0), "Grunt reset restores full health bar")

	grunt.queue_free()
	await process_frame

func _check_ember_fields() -> void:
	var area := _instantiate("res://scenes/areas/ember_fields.tscn")
	get_root().add_child(area)
	await process_frame

	var ground := area.get_node("Ground") as TileMapLayer
	_expect(ground.tile_set != null, "Ember Fields has TileSet")
	_expect(ground.get_used_cells().size() > 100, "Ember Fields has a built TileMapLayer layout")
	_expect(_tileset_has_collision(ground.tile_set), "Ember Fields TileSet has collision")

	_expect(area.get_node_or_null("ParallaxBackground/BgFar/FallbackSprite") != null, "Far background is wired")
	for node_path in [
		"ParallaxBackground/BgMid/Sprite2D",
		"ParallaxBackground/BgNear/Sprite2D",
	]:
		_expect((area.get_node(node_path) as Sprite2D).texture != null, "Background texture wired: %s" % node_path)

	_expect(area.get_node_or_null("StartPoint") != null, "Area has start point")
	_expect(area.get_node_or_null("EndFlag") != null, "Area has end flag")
	_expect(area.get_node("Enemies").get_child_count() >= 3, "Area has at least three Grunts")
	_expect(area.get_node_or_null("Party/Kira") != null, "Area has Kira")
	_expect(((area.get_node("EndFlag") as Area2D).collision_mask & PLAYER_LAYER) != 0, "Goal flag detects Kira on player layer")

	var camera := area.get_node("Party/Camera2D") as Camera2D
	_expect(camera.limit_left == 0 and camera.limit_right >= 3200, "Party camera limits are configured")
	var kira := area.get_node("Party/Kira") as Kira
	var grunt := area.get_node("Enemies/Grunt") as Grunt
	_expect((kira.collision_mask & grunt.collision_layer) == 0, "Kira does not physically collide with Grunt bodies")
	_expect((grunt.collision_mask & kira.collision_layer) == 0, "Grunt does not physically collide with Kira body")
	_check_goal_route_is_jumpable(ground, kira)

	area.queue_free()
	await process_frame

func _check_drowned_coast() -> void:
	var area := _instantiate("res://scenes/areas/drowned_coast.tscn")
	get_root().add_child(area)
	await process_frame

	var ground := area.get_node("Ground") as TileMapLayer
	_expect(ground.tile_set != null, "Drowned Coast has TileSet")
	_expect(ground.get_used_cells().size() > 100, "Drowned Coast has a built TileMapLayer layout")
	_expect(_tileset_has_collision(ground.tile_set), "Drowned Coast TileSet has collision")

	for node_path in [
		"ParallaxBackground/BgFar/FallbackSprite",
		"ParallaxBackground/BgMid/Sprite2D",
		"ParallaxBackground/BgNear/Sprite2D",
	]:
		_expect((area.get_node(node_path) as Sprite2D).texture != null, "Drowned Coast background texture wired: %s" % node_path)

	_expect(area.get_node_or_null("StartPoint") != null, "Drowned Coast has start point")
	_expect(area.get_node_or_null("EndFlag") != null, "Drowned Coast has end flag")
	_expect(area.get_node_or_null("CheckpointStart") != null, "Drowned Coast has start checkpoint")
	_expect(area.get_node_or_null("CheckpointMid") != null, "Drowned Coast has mid checkpoint")
	_expect(area.get_node_or_null("CheckpointPreGoal") != null, "Drowned Coast has pre-goal checkpoint")
	_expect(area.get_node("Enemies").get_child_count() >= 3, "Drowned Coast has at least three Grunts")
	_expect(area.get_node_or_null("Party/Kira") != null, "Drowned Coast has Kira")
	_expect(area.get_node_or_null("Party/Marina") != null, "Drowned Coast has Marina")
	_expect(area.get_node_or_null("Party/Ryne") != null, "Drowned Coast has Ryne")
	_expect(((area.get_node("EndFlag") as Area2D).collision_mask & PLAYER_LAYER) != 0, "Drowned Coast goal flag detects Kira on player layer")

	var camera := area.get_node("Party/Camera2D") as Camera2D
	_expect(camera.limit_left == 0 and camera.limit_right >= 3200, "Drowned Coast party camera limits are configured")
	var kira := area.get_node("Party/Kira") as Kira
	var grunt := area.get_node("Enemies/Grunt") as Grunt
	_expect((kira.collision_mask & grunt.collision_layer) == 0, "Drowned Coast Kira does not physically collide with Grunt bodies")
	_expect((grunt.collision_mask & kira.collision_layer) == 0, "Drowned Coast Grunt does not physically collide with Kira body")
	_check_goal_route_is_jumpable(ground, kira)

	area.queue_free()
	await process_frame

func _check_hud() -> void:
	var main := _instantiate("res://scenes/main.tscn")
	get_root().add_child(main)
	current_scene = main
	await process_frame
	await process_frame
	main.call("_start_game")
	await process_frame

	var hud := main.get_node("HUD") as HUD
	var kira := main.get_node("EmberFields/Party/Kira") as Kira
	var health_bar := hud.get_node("HealthBar") as ProgressBar
	var skill_bar := hud.get_node("SkillBar") as ProgressBar

	kira.take_damage(25.0)
	await process_frame
	_expect(is_equal_approx(health_bar.value, 75.0), "HUD health bar follows Kira health")

	kira._use_skill()
	await process_frame
	hud._process(0.0)
	_expect(skill_bar.value < 100.0, "HUD skill cooldown bar updates")

	main.queue_free()
	current_scene = null
	await process_frame

func _check_main_flow() -> void:
	var main := _instantiate("res://scenes/main.tscn") as Node2D
	get_root().add_child(main)
	current_scene = main
	await process_frame
	await process_frame

	_expect(main.get_node("TitleScreen").visible, "Title screen is visible on launch")
	_expect(not main.get_node("HUD").visible, "HUD is hidden on title screen")
	_expect(main.get_node_or_null("EmberFields") == null, "Ember Fields is not loaded on title screen")
	_expect(main.get_node_or_null("DrownedCoast") == null, "Drowned Coast is not loaded on title screen")

	main.call("_start_game")
	await process_frame
	var area := main.get_node("EmberFields") as AreaBase
	var kira := area.get_player()
	_expect(not main.get_node("TitleScreen").visible, "Start hides title screen")
	_expect(main.get_node("HUD").visible, "Start shows HUD")
	_expect(area != null and area.visible, "Start loads Ember Fields")
	_expect(main.get_node_or_null("DrownedCoast") == null, "Start does not load Drowned Coast")
	_expect(get_root().get_viewport().get_camera_2d() == area.get_node("Party/Camera2D"), "Start makes Ember Fields camera current")
	_expect((main.get_node("GameOverScreen/Panel/ExitButton") as Button).text == "Main Menu", "Game-over menu action is clearly labeled")

	var first_grunt := area.get_node("Enemies/Grunt") as Grunt
	var enemy_spawn := first_grunt.get_spawn_position()
	first_grunt.take_damage(999.0, "pyro")
	_expect(first_grunt.collision_layer == 0, "Defeated Grunt is removed from active play")

	kira.global_position = Vector2(kira.global_position.x, 640.0)
	for index in 20:
		await physics_frame
		await process_frame
	_expect(not main.get_node("GameOverScreen").visible, "Falling uses checkpoint respawn instead of game-over screen")
	_expect(kira.global_position.y < 520.0, "Falling respawns Kira above the fall limit")

	main.call("_restart_game")
	await process_frame
	area = main.get_node("EmberFields") as AreaBase
	kira = area.get_player()
	_expect(not main.get_node("GameOverScreen").visible, "Restart hides game-over screen")
	_expect(kira.global_position.y < 400.0, "Restart returns Kira to playable start")
	first_grunt = area.get_node("Enemies/Grunt") as Grunt
	_expect(first_grunt.visible, "Restart respawns defeated Grunts")
	_expect(is_equal_approx(first_grunt.current_health, first_grunt.max_health), "Restart restores Grunt health")
	_expect(first_grunt.global_position.distance_to(enemy_spawn) < 4.0, "Restart returns Grunt to spawn position")

	var switcher := get_root().get_node_or_null("CharacterSwitcher")
	if switcher and switcher.has_method("set_active"):
		switcher.set_active(2)
		_expect(switcher.active_slot() == 2, "Party switcher can select Ryne before area transition")

	area._on_end_flag_body_entered(kira)
	await process_frame
	await process_frame
	_expect(main.get_node("GameOverScreen").visible, "Ember Fields goal shows area-clear screen")
	_expect((main.get_node("GameOverScreen/Panel/RestartButton") as Button).text == "Continue", "Area-clear button continues to Drowned Coast")
	_expect((main.get_node("GameOverScreen/Panel/GameOverBodyLabel") as Label).text.find("Drowned Coast") >= 0, "Area-clear text points to Drowned Coast")

	main.call("_on_restart_button_pressed")
	await process_frame
	await process_frame
	_expect(not main.get_node("GameOverScreen").visible, "Continue hides area-clear screen")
	_expect(main.get_node_or_null("EmberFields") == null, "Continue unloads Ember Fields")
	var drowned_coast := main.get_node("DrownedCoast") as AreaBase
	_expect(drowned_coast.visible, "Continue loads Drowned Coast")
	_expect(main.get_node("HUD").visible, "Continue shows HUD for Drowned Coast")
	var drowned_player := drowned_coast.get_player()
	_expect(drowned_player != null, "Drowned Coast has an active player after continue")
	_expect(get_root().get_viewport().get_camera_2d() == drowned_coast.get_node("Party/Camera2D"), "Continue makes Drowned Coast camera current")
	if switcher and switcher.has_method("active_slot"):
		_expect(switcher.active_slot() == 2, "Selected party slot carries into Drowned Coast")
	_expect(drowned_player.global_position.y < 400.0, "Drowned Coast player starts in playable space")

	drowned_coast._on_end_flag_body_entered(drowned_player)
	await process_frame
	await process_frame
	_expect(main.get_node("GameOverScreen").visible, "Drowned Coast goal shows final area-clear screen")
	_expect((main.get_node("GameOverScreen/Panel/RestartButton") as Button).text == "Restart", "Final area-clear button restarts run")
	_expect((main.get_node("GameOverScreen/Panel/GameOverBodyLabel") as Label).text.find("Drowned Coast") >= 0, "Final area-clear text names Drowned Coast")

	main.call("_restart_game")
	await process_frame
	await process_frame
	_expect(not main.get_node("GameOverScreen").visible, "Restart hides area-clear screen")
	area = main.get_node("EmberFields") as AreaBase
	_expect(area.visible, "Restart after final clear loads Ember Fields")
	_expect(main.get_node_or_null("DrownedCoast") == null, "Restart after final clear unloads Drowned Coast")
	_expect(area.get_player().global_position.x < 200.0, "Restart after final clear returns player to Ember Fields start")

	main.queue_free()
	current_scene = null
	await process_frame

func _expect_animations(frames: SpriteFrames, names: Array[String], label: String) -> void:
	for animation_name in names:
		_expect(frames.has_animation(animation_name), "%s animation exists: %s" % [label, animation_name])
		if frames.has_animation(animation_name):
			_expect(frames.get_frame_count(animation_name) > 0, "%s animation has frames: %s" % [label, animation_name])

func _tileset_has_collision(tile_set: TileSet) -> bool:
	for source_id in tile_set.get_source_count():
		var source := tile_set.get_source(tile_set.get_source_id(source_id)) as TileSetAtlasSource
		if source == null:
			continue
		for tile_index in source.get_tiles_count():
			var coords := source.get_tile_id(tile_index)
			var tile_data := source.get_tile_data(coords, 0)
			if tile_data and tile_data.get_collision_polygons_count(0) > 0:
				return true
	return false

func _check_goal_route_is_jumpable(tile_layer: TileMapLayer, kira: Kira) -> void:
	var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
	var max_jump_height: float = pow(absf(kira.jump_velocity), 2.0) / (2.0 * gravity)
	var safe_step_height: float = min(max_jump_height * 0.84, PhysicsModel.tiles_to_pixels(PhysicsModel.SAFE_JUMP_RISE_TILES))
	var route: Array[Vector2i] = [
		Vector2i(72, 12),
		Vector2i(76, 10),
		Vector2i(80, 9),
		Vector2i(84, 8),
		Vector2i(88, 7),
		Vector2i(89, 7),
	]
	for coords in route:
		_expect(tile_layer.get_cell_source_id(coords) != -1, "Goal route platform exists at %s" % coords)
	for index in range(1, route.size()):
		var previous: Vector2i = route[index - 1]
		var current: Vector2i = route[index]
		var rise_px: float = float(previous.y - current.y) * PhysicsModel.TILE_SIZE_PX
		var gap_px: float = float(current.x - previous.x) * PhysicsModel.TILE_SIZE_PX
		_expect(rise_px <= safe_step_height, "Goal route rise fits Kira jump physics: %spx" % rise_px)
		_expect(gap_px <= PhysicsModel.tiles_to_pixels(PhysicsModel.SAFE_FLAT_JUMP_GAP_TILES), "Goal route horizontal gap is reachable: %spx" % gap_px)

func _instantiate(path: String) -> Node:
	var packed := load(path) as PackedScene
	_expect(packed != null, "Scene loads: %s" % path)
	return packed.instantiate()

func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_failures.append(message)
		print("FAIL: %s" % message)
