extends SceneTree

const PhysicsModel := preload("res://scripts/core/game_physics.gd")

const WORLD_LAYER := PhysicsModel.WORLD_LAYER
const PLAYER_LAYER := PhysicsModel.PLAYER_LAYER
const ENEMY_LAYER := PhysicsModel.ENEMY_LAYER
const PROJECTILE_LAYER := PhysicsModel.PROJECTILE_LAYER

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
	await _check_projectile_physics()
	await _check_ember_fields()
	await _check_ember_progression_levels()
	await _check_boss_arenas()
	await _check_drowned_coast()
	await _check_storm_peaks()
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
	_expect(PhysicsModel.WORLD_LAYER == 1, "World collision layer is fixed")
	_expect(PhysicsModel.PLAYER_LAYER == 2, "Player collision layer is fixed")
	_expect(PhysicsModel.ENEMY_LAYER == 4, "Enemy collision layer is fixed")
	_expect(PhysicsModel.PROJECTILE_LAYER == 8, "Projectile collision layer is fixed")
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
	kira._handle_movement(0.016)
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
		_expect(bomb.collision_layer == PROJECTILE_LAYER, "Fire Bomb broadcasts as a projectile")
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
	_expect(is_equal_approx(absf(kira.velocity.x), PhysicsModel.DODGE_SPEED_PX_PER_SEC), "Kira dodge applies tile-model horizontal burst")

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

func _check_projectile_physics() -> void:
	var projectile_specs: Array[Dictionary] = [
		{"path": "res://scenes/projectiles/fire_orb.tscn", "label": "Fire Orb"},
		{"path": "res://scenes/projectiles/fire_bomb.tscn", "label": "Fire Bomb"},
		{"path": "res://scenes/projectiles/water_orb.tscn", "label": "Water Orb"},
		{"path": "res://scenes/projectiles/water_burst.tscn", "label": "Water Burst"},
		{"path": "res://scenes/projectiles/shockwave.tscn", "label": "Shockwave"},
	]
	for spec in projectile_specs:
		var projectile := _instantiate(spec["path"]) as Area2D
		get_root().add_child(projectile)
		await process_frame
		_expect(projectile.collision_layer == PROJECTILE_LAYER, "%s broadcasts on projectile layer" % spec["label"])
		_expect(projectile.collision_mask == ENEMY_LAYER, "%s only detects enemies" % spec["label"])
		if projectile is Shockwave:
			projectile.set_facing(-1)
			var shape := (projectile.get_node("CollisionShape2D") as CollisionShape2D).shape as ConvexPolygonShape2D
			_expect(projectile.scale == Vector2.ONE, "Shockwave does not flip by scaling its physics body")
			_expect(shape.points[1].x < 0.0, "Shockwave mirrors collision polygon for left-facing casts")
		projectile.queue_free()
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
	_check_ember_fields_route(area, ground, kira)

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

func _check_storm_peaks() -> void:
	var area := _instantiate("res://scenes/areas/storm_peaks.tscn")
	get_root().add_child(area)
	await process_frame

	var ground := area.get_node("Ground") as TileMapLayer
	_expect(ground.tile_set != null, "Storm Peaks has TileSet")
	_expect(ground.get_used_cells().size() > 100, "Storm Peaks has a built TileMapLayer layout")
	_expect(_tileset_has_collision(ground.tile_set), "Storm Peaks TileSet has collision")

	for node_path in [
		"ParallaxBackground/BgFar/FallbackSprite",
		"ParallaxBackground/BgMid/Sprite2D",
		"ParallaxBackground/BgNear/Sprite2D",
	]:
		_expect((area.get_node(node_path) as Sprite2D).texture != null, "Storm Peaks background texture wired: %s" % node_path)

	_expect(area is AreaBase, "Storm Peaks remains an AreaBase scene")
	_expect(area.get_node_or_null("StartPoint") != null, "Storm Peaks has start point")
	_expect(area.get_node_or_null("EndFlag") != null, "Storm Peaks has end flag")
	_expect(area.get_node_or_null("CheckpointStart") != null, "Storm Peaks has start checkpoint")
	_expect(area.get_node_or_null("CheckpointMid") != null, "Storm Peaks has mid checkpoint")
	_expect(area.get_node_or_null("CheckpointPreGoal") != null, "Storm Peaks has pre-goal checkpoint")
	_expect(area.get_node("Enemies").get_child_count() >= 4, "Storm Peaks has expected Grunt count")
	_expect(area.get_node_or_null("Party/Kira") != null, "Storm Peaks has Kira")
	_expect(area.get_node_or_null("Party/Marina") != null, "Storm Peaks has Marina")
	_expect(area.get_node_or_null("Party/Ryne") != null, "Storm Peaks has Ryne")
	_expect(((area.get_node("EndFlag") as Area2D).collision_mask & PLAYER_LAYER) != 0, "Storm Peaks goal flag detects Kira on player layer")

	var camera := area.get_node("Party/Camera2D") as Camera2D
	_expect(camera.limit_left == 0 and camera.limit_right >= 5056, "Storm Peaks party camera covers route")
	var kira := area.get_node("Party/Kira") as Kira
	var grunt := area.get_node("Enemies/Grunt") as Grunt
	_expect((kira.collision_mask & grunt.collision_layer) == 0, "Storm Peaks Kira does not physically collide with Grunt bodies")
	_expect((grunt.collision_mask & kira.collision_layer) == 0, "Storm Peaks Grunt does not physically collide with Kira body")
	_check_storm_peaks_route(area, ground, kira)

	area.queue_free()
	await process_frame

func _check_ember_progression_levels() -> void:
	var level_specs: Array[Dictionary] = [
		{
			"path": "res://scenes/areas/ember_fields_level_2.tscn",
			"label": "Ember Fields Level 2",
			"grunts": 4,
			"camera_right": 4992,
			"end": Vector2(4736, 256),
			"mid": Vector2(1792, 208),
			"pre_goal": Vector2(3904, 208),
			"platforms": [
				Vector3i(0, 12, 16),
				Vector3i(21, 11, 13),
				Vector3i(39, 9, 10),
				Vector3i(53, 8, 12),
				Vector3i(69, 10, 14),
				Vector3i(88, 12, 13),
				Vector3i(106, 10, 11),
				Vector3i(122, 8, 11),
				Vector3i(138, 9, 15),
			],
		},
		{
			"path": "res://scenes/areas/ember_fields_level_3.tscn",
			"label": "Ember Fields Level 3",
			"grunts": 5,
			"camera_right": 4992,
			"end": Vector2(4736, 256),
			"mid": Vector2(1792, 208),
			"pre_goal": Vector2(3904, 208),
			"platforms": [
				Vector3i(0, 12, 16),
				Vector3i(21, 11, 13),
				Vector3i(39, 9, 10),
				Vector3i(53, 8, 12),
				Vector3i(69, 10, 14),
				Vector3i(88, 12, 13),
				Vector3i(106, 10, 11),
				Vector3i(122, 8, 11),
				Vector3i(138, 9, 15),
			],
		},
		{
			"path": "res://scenes/areas/ember_fields_level_4.tscn",
			"label": "Ember Fields Level 4",
			"grunts": 6,
			"camera_right": 5568,
			"end": Vector2(5312, 320),
			"mid": Vector2(2624, 304),
			"pre_goal": Vector2(3776, 176),
			"platforms": [
				Vector3i(0, 12, 15),
				Vector3i(20, 12, 11),
				Vector3i(36, 10, 10),
				Vector3i(50, 8, 12),
				Vector3i(67, 9, 10),
				Vector3i(82, 11, 16),
				Vector3i(103, 9, 10),
				Vector3i(118, 7, 12),
				Vector3i(135, 9, 12),
				Vector3i(152, 11, 19),
			],
		},
		{
			"path": "res://scenes/areas/ember_fields_level_5.tscn",
			"label": "Ember Fields Level 5",
			"grunts": 7,
			"camera_right": 6208,
			"end": Vector2(5952, 192),
			"mid": Vector2(1568, 176),
			"pre_goal": Vector2(4800, 208),
			"platforms": [
				Vector3i(0, 12, 14),
				Vector3i(19, 11, 10),
				Vector3i(34, 9, 10),
				Vector3i(49, 7, 12),
				Vector3i(66, 9, 11),
				Vector3i(82, 12, 16),
				Vector3i(103, 10, 10),
				Vector3i(118, 8, 10),
				Vector3i(133, 10, 12),
				Vector3i(150, 8, 12),
				Vector3i(167, 7, 24),
			],
		},
	]
	for spec in level_specs:
		await _check_ember_level_scene(spec)

func _check_ember_level_scene(spec: Dictionary) -> void:
	var area := _instantiate(spec["path"])
	get_root().add_child(area)
	await process_frame

	var label: String = spec["label"]
	var ground := area.get_node("Ground") as TileMapLayer
	_expect(ground.tile_set != null, "%s has TileSet" % label)
	_expect(_tileset_has_collision(ground.tile_set), "%s TileSet has collision" % label)
	_expect(ground.get_used_cells().size() > 100, "%s has built terrain" % label)
	_expect(area is AreaBase, "%s remains an AreaBase scene" % label)
	_expect(area.get_node_or_null("StartPoint") != null, "%s has start point" % label)
	_expect(area.get_node_or_null("EndFlag") != null, "%s has end flag" % label)
	_expect(area.get_node_or_null("CheckpointStart") != null, "%s has start checkpoint" % label)
	_expect(area.get_node_or_null("CheckpointMid") != null, "%s has mid checkpoint" % label)
	_expect(area.get_node_or_null("CheckpointPreGoal") != null, "%s has pre-goal checkpoint" % label)
	_expect(area.get_node_or_null("Party/Kira") != null, "%s has Kira" % label)
	_expect(area.get_node("Enemies").get_child_count() >= int(spec["grunts"]), "%s has expected Grunt count" % label)
	_expect((area.get_node("Party/Camera2D") as Camera2D).limit_right >= int(spec["camera_right"]), "%s camera covers route" % label)
	_expect((area.get_node("EndFlag") as Node2D).position == spec["end"], "%s flag sits on final platform" % label)
	_expect((area.get_node("CheckpointMid") as Node2D).position == spec["mid"], "%s mid checkpoint is placed before combat" % label)
	_expect((area.get_node("CheckpointPreGoal") as Node2D).position == spec["pre_goal"], "%s pre-goal checkpoint is placed before final route" % label)

	var platforms: Array = spec["platforms"]
	var jump_pairs: Array[Vector2i] = []
	for platform in platforms:
		var segment := platform as Vector3i
		_expect(ground.get_cell_source_id(Vector2i(segment.x, segment.y)) != -1, "%s platform starts at %s" % [label, Vector2i(segment.x, segment.y)])
		_expect(ground.get_cell_source_id(Vector2i(segment.x + segment.z - 1, segment.y)) != -1, "%s platform ends at %s" % [label, Vector2i(segment.x + segment.z - 1, segment.y)])
	for index in range(1, platforms.size()):
		var previous := platforms[index - 1] as Vector3i
		var current := platforms[index] as Vector3i
		jump_pairs.append(Vector2i(previous.x + previous.z - 1, previous.y))
		jump_pairs.append(Vector2i(current.x, current.y))
	_check_jump_pairs_are_reachable(jump_pairs, area.get_node("Party/Kira") as Kira, label)
	if spec.has("obstacles"):
		for obstacle in spec["obstacles"]:
			var coords := obstacle as Vector2i
			_expect(ground.get_cell_source_id(coords) != -1, "%s has obstacle tile at %s" % [label, coords])

	area.queue_free()
	await process_frame

func _check_boss_arenas() -> void:
	var boss_specs: Array[Dictionary] = [
		{"path": "res://scenes/areas/boss_1_arena.tscn", "node": "FlameWardenArena", "name": "Flame Warden", "health": 180.0, "pattern": BossBase.Pattern.FLAME_BURST, "runtime_environment": true},
		{"path": "res://scenes/areas/boss_2_arena.tscn", "node": "TideSerpentArena", "name": "Tide Serpent", "health": 240.0, "pattern": BossBase.Pattern.WATER_WAVE, "runtime_environment": true},
		{"path": "res://scenes/areas/boss_3_arena.tscn", "node": "SparkingSentinelArena", "name": "Sparking Sentinel", "health": 320.0, "pattern": BossBase.Pattern.LIGHTNING_BOLT, "runtime_environment": true},
		{"path": "res://scenes/areas/boss_4_arena.tscn", "node": "AshColossusArena", "name": "Ash Colossus", "health": 420.0, "pattern": BossBase.Pattern.ASH_STOMP, "runtime_environment": true},
		{"path": "res://scenes/areas/boss_5_arena.tscn", "node": "EmberTyrantArena", "name": "Ember Tyrant", "health": 560.0, "pattern": BossBase.Pattern.EMBER_TYRANT, "runtime_environment": true},
	]
	for spec in boss_specs:
		await _check_boss_arena_scene(spec)

func _check_boss_arena_scene(spec: Dictionary) -> void:
	var arena := _instantiate(spec["path"]) as BossArenaBase
	get_root().add_child(arena)
	await process_frame

	var label: String = spec["name"]
	_expect(arena != null, "%s arena uses BossArenaBase" % label)
	_expect(arena.name == spec["node"], "%s arena root name is stable" % label)
	_expect(arena.get_node_or_null("Ground") != null, "%s arena has locked floor" % label)
	_expect(arena.get_node_or_null("StartPoint") != null, "%s arena has start point" % label)
	_expect(arena.get_node_or_null("CheckpointStart") != null, "%s arena has start checkpoint" % label)
	_expect(arena.get_node_or_null("Party/Kira") != null, "%s arena has Kira" % label)
	_expect(arena.get_node_or_null("Party/Marina") != null, "%s arena has Marina" % label)
	_expect(arena.get_node_or_null("Party/Ryne") != null, "%s arena has Ryne" % label)
	if bool(spec.get("runtime_environment", false)):
		_expect(arena.get_node_or_null("ArenaEnvironment/Backdrop") != null, "%s arena uses generated backdrop" % label)
		_expect(arena.get_node_or_null("ArenaEnvironment/LavaDepth") != null, "%s arena uses generated lava depth" % label)
		_expect(arena.get_node_or_null("ArenaEnvironment/ArenaFloorVisual") != null, "%s arena uses generated floor art" % label)
		_expect(arena.get_node_or_null("ArenaEnvironment/LeftBoundaryWallVisual") != null, "%s arena uses generated left wall art" % label)
		_expect(arena.get_node_or_null("ArenaEnvironment/RightBoundaryWallVisual") != null, "%s arena uses generated right wall art" % label)
		_expect(arena.get_node_or_null("ArenaFloorVisual") == null, "%s arena replaced root floor placeholder" % label)
		_expect(arena.get_node_or_null("LavaGlow") == null, "%s arena replaced root lava placeholder" % label)
		var floor_art := arena.get_node("ArenaEnvironment/ArenaFloorVisual") as CanvasItem
		var lava_glow := arena.get_node("ArenaEnvironment/LavaDepth") as CanvasItem
		_expect(floor_art.z_index < 0, "%s arena floor art stays behind combat" % label)
		_expect(lava_glow.z_index < 0, "%s arena glow stays behind combat" % label)
	else:
		_expect(arena.get_node_or_null("ParallaxBackground/BgFar/FallbackSprite") != null, "%s arena uses Ember far background" % label)
		_expect(arena.get_node_or_null("ParallaxBackground/BgMid/Sprite2D") != null, "%s arena uses Ember mid background" % label)
		_expect(arena.get_node_or_null("ParallaxBackground/BgNear/Sprite2D") != null, "%s arena uses Ember near background" % label)
		_expect(arena.get_node_or_null("ArenaFloorVisual") != null, "%s arena has visible Ember floor art" % label)
		var floor_art := arena.get_node("ArenaFloorVisual") as CanvasItem
		var lava_glow := arena.get_node("LavaGlow") as CanvasItem
		_expect(floor_art.z_index < 0, "%s arena floor art stays behind combat" % label)
		_expect(lava_glow.z_index < 0, "%s arena glow stays behind combat" % label)
	_expect(arena.camera_limit_left == 0 and arena.camera_limit_right == 640, "%s arena locks horizontal camera" % label)
	_expect(arena.camera_limit_top == 0 and arena.camera_limit_bottom == 360, "%s arena locks vertical camera" % label)
	var camera := arena.get_node("Party/Camera2D") as Camera2D
	_expect(camera.limit_left == 0 and camera.limit_right == 640 and camera.limit_bottom == 360, "%s camera bounds are one screen" % label)

	var boss := arena.get_node("Enemies/Boss") as BossBase
	_expect(boss != null, "%s arena has one boss" % label)
	_expect(is_equal_approx(boss.max_health, float(spec["health"])), "%s boss health scales correctly" % label)
	_expect(boss.boss_display_name == spec["name"], "%s boss display name is set" % label)
	_expect(boss.boss_pattern == spec["pattern"], "%s boss pattern is unique" % label)
	(arena.get_node("Party/Kira") as CharacterBase).global_position = Vector2(112, 296)
	for index in 20:
		boss._physics_process(0.016)
	_expect(boss.velocity.x < 0.0, "%s boss advances toward the player" % label)
	boss._start_attack()
	await process_frame
	_expect(boss.get("_active_warning") != null, "%s boss starts a telegraphed attack" % label)
	var warning := boss.get("_active_warning") as Node2D
	if warning:
		_expect(warning.name == "BossAttackTelegraph", "%s boss telegraph uses a named VFX node" % label)
		_expect(warning.find_children("*", "Line2D", false, false).size() > 0, "%s boss telegraph uses animated line VFX" % label)
		_expect(warning.find_children("*", "GPUParticles2D", false, false).size() > 0, "%s boss telegraph uses particle VFX" % label)
		_expect(warning.find_children("*", "ColorRect", false, false).is_empty(), "%s boss telegraph avoids solid highlight rectangles" % label)

	var completed := [false]
	arena.area_completed.connect(func() -> void: completed[0] = true)
	boss.take_damage(9999.0, "pyro")
	await process_frame
	_expect(completed[0], "%s arena completes when boss dies" % label)

	arena.queue_free()
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
	_expect((main.get_node("TitleScreen/Backdrop") as Control).mouse_filter == Control.MOUSE_FILTER_IGNORE, "Title backdrop does not block start clicks")
	_expect((main.get_node("TitleScreen/Panel") as Control).mouse_filter == Control.MOUSE_FILTER_PASS, "Title panel passes clicks to menu buttons")
	_expect((main.get_node("TitleScreen/Panel/TitleLabel") as Control).mouse_filter == Control.MOUSE_FILTER_IGNORE, "Title label does not block menu clicks")
	_expect((main.get_node("GameOverScreen/Backdrop") as Control).mouse_filter == Control.MOUSE_FILTER_IGNORE, "Clear backdrop does not block continue clicks")
	_expect((main.get_node("GameOverScreen/Panel") as Control).mouse_filter == Control.MOUSE_FILTER_PASS, "Clear panel passes clicks to menu buttons")

	var start_button := main.get_node("TitleScreen/Panel/StartButton") as Button
	var start_click := InputEventMouseButton.new()
	start_click.button_index = MOUSE_BUTTON_LEFT
	start_click.position = start_button.global_position + start_button.size * 0.5
	start_click.pressed = true
	main._input(start_click)
	await process_frame
	var area := main.get_node("EmberFields") as AreaBase
	var kira := area.get_player()
	_expect(not main.get_node("TitleScreen").visible, "Start hides title screen")
	_expect(main.get_node("HUD").visible, "Start shows HUD")
	_expect(area != null and area.visible, "Start loads Ember Fields")
	_expect(main.get_node_or_null("DrownedCoast") == null, "Start does not load Drowned Coast")
	_expect(get_root().get_viewport().get_camera_2d() == area.get_node("Party/Camera2D"), "Start makes Ember Fields camera current")
	_expect((main.get_node("GameOverScreen/Panel/ExitButton") as Button).text == "Main Menu", "Game-over menu action is clearly labeled")

	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	main._input(escape)
	await process_frame
	_expect(main.get_node("TitleScreen").visible, "Escape returns to title screen")
	_expect(main.get_node_or_null("EmberFields") == null, "Escape unloads active area")
	start_click = InputEventMouseButton.new()
	start_click.button_index = MOUSE_BUTTON_LEFT
	start_click.position = start_button.global_position + start_button.size * 0.5
	start_click.pressed = true
	main._input(start_click)
	await process_frame
	area = main.get_node("EmberFields") as AreaBase
	kira = area.get_player()

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

	var stage_nodes: Array[String] = [
		"EmberFields",
		"Boss1Arena",
		"EmberFieldsLevel2",
		"Boss2Arena",
		"EmberFieldsLevel3",
		"Boss3Arena",
		"EmberFieldsLevel4",
		"Boss4Arena",
		"EmberFieldsLevel5",
		"Boss5Arena",
		"DrownedCoast",
		"StormPeaks",
	]
	var next_stage_names: Array[String] = [
		"Flame Warden",
		"Ember Fields Level 2",
		"Tide Serpent",
		"Ember Fields Level 3",
		"Sparking Sentinel",
		"Ember Fields Level 4",
		"Ash Colossus",
		"Ember Fields Level 5",
		"Ember Tyrant",
		"Drowned Coast",
		"Storm Peaks",
	]
	for index in range(0, stage_nodes.size() - 1):
		var active_area := main.get_node(stage_nodes[index]) as AreaBase
		await _complete_stage(active_area)
		_expect(main.get_node("GameOverScreen").visible, "%s clear shows continue screen" % stage_nodes[index])
		_expect((main.get_node("GameOverScreen/Panel/RestartButton") as Button).text == "Continue", "%s clear button continues run" % stage_nodes[index])
		_expect((main.get_node("GameOverScreen/Panel/GameOverBodyLabel") as Label).text.find(next_stage_names[index]) >= 0, "%s clear text points to %s" % [stage_nodes[index], next_stage_names[index]])

		main.call("_on_restart_button_pressed")
		await process_frame
		await process_frame
		_expect(not main.get_node("GameOverScreen").visible, "Continue hides clear screen for %s" % next_stage_names[index])
		_expect(main.get_node_or_null(stage_nodes[index]) == null, "Continue unloads %s" % stage_nodes[index])
		var next_area := main.get_node(stage_nodes[index + 1]) as AreaBase
		_expect(next_area != null and next_area.visible, "Continue loads %s" % stage_nodes[index + 1])
		_expect(main.get_node("HUD").visible, "Continue shows HUD for %s" % stage_nodes[index + 1])
		_expect(next_area.get_player() != null, "%s has an active player after continue" % stage_nodes[index + 1])
		_expect(get_root().get_viewport().get_camera_2d() == next_area.get_node("Party/Camera2D"), "%s camera is current" % stage_nodes[index + 1])
		if switcher and switcher.has_method("active_slot"):
			_expect(switcher.active_slot() == 2, "Selected party slot carries into %s" % stage_nodes[index + 1])

	var storm_peaks := main.get_node("StormPeaks") as AreaBase
	await _complete_stage(storm_peaks)
	_expect(main.get_node("GameOverScreen").visible, "Storm Peaks goal shows final area-clear screen")
	_expect((main.get_node("GameOverScreen/Panel/RestartButton") as Button).text == "Restart", "Final area-clear button restarts run")
	_expect((main.get_node("GameOverScreen/Panel/GameOverBodyLabel") as Label).text.find("Storm Peaks") >= 0, "Final area-clear text names Storm Peaks")

	main.call("_restart_game")
	await process_frame
	await process_frame
	_expect(not main.get_node("GameOverScreen").visible, "Restart hides area-clear screen")
	area = main.get_node("EmberFields") as AreaBase
	_expect(area.visible, "Restart after final clear loads Ember Fields")
	_expect(main.get_node_or_null("DrownedCoast") == null, "Restart after final clear unloads Drowned Coast")
	_expect(main.get_node_or_null("StormPeaks") == null, "Restart after final clear unloads Storm Peaks")
	_expect(area.get_player().global_position.x < 200.0, "Restart after final clear returns player to Ember Fields start")

	main.queue_free()
	current_scene = null
	await process_frame

func _complete_stage(active_area: AreaBase) -> void:
	if active_area is BossArenaBase:
		var boss := active_area.get_node("Enemies/Boss") as BossBase
		boss.take_damage(9999.0, "pyro")
	else:
		active_area._on_end_flag_body_entered(active_area.get_player())
	await process_frame
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
		var empty_gap_tiles := maxi(current.x - previous.x - 1, 0)
		var gap_px: float = float(empty_gap_tiles) * PhysicsModel.TILE_SIZE_PX
		_expect(rise_px <= safe_step_height, "Goal route rise fits Kira jump physics: %spx" % rise_px)
		_expect(gap_px <= PhysicsModel.tiles_to_pixels(PhysicsModel.SAFE_FLAT_JUMP_GAP_TILES), "Goal route horizontal gap is reachable: %spx" % gap_px)

func _check_ember_fields_route(area: Node, tile_layer: TileMapLayer, kira: Kira) -> void:
	var required_cells: Array[Vector2i] = [
		Vector2i(3, 12),
		Vector2i(20, 12),
		Vector2i(32, 12),
		Vector2i(37, 11),
		Vector2i(48, 11),
		Vector2i(53, 12),
		Vector2i(65, 12),
		Vector2i(70, 10),
		Vector2i(79, 10),
		Vector2i(84, 9),
		Vector2i(93, 9),
		Vector2i(99, 11),
		Vector2i(116, 11),
	]
	for coords in required_cells:
		_expect(tile_layer.get_cell_source_id(coords) != -1, "Ember Fields route platform exists at %s" % coords)

	var jumps: Array[Vector2i] = [
		Vector2i(15, 12), Vector2i(20, 12),
		Vector2i(32, 12), Vector2i(37, 11),
		Vector2i(48, 11), Vector2i(53, 12),
		Vector2i(65, 12), Vector2i(70, 10),
		Vector2i(79, 10), Vector2i(84, 9),
		Vector2i(93, 9), Vector2i(99, 11),
	]
	_check_jump_pairs_are_reachable(jumps, kira, "Ember Fields")

	_expect((area.get_node("CheckpointMid") as Node2D).position == Vector2(1696, 352), "Ember Fields mid checkpoint starts the combat pocket")
	_expect((area.get_node("CheckpointPreGoal") as Node2D).position == Vector2(2688, 256), "Ember Fields pre-goal checkpoint starts final platforming")
	_expect((area.get_node("EndFlag") as Node2D).position == Vector2(3712, 320), "Ember Fields flag sits on the final platform")
	_expect((area.get_node("Party/Camera2D") as Camera2D).limit_right >= 3904, "Ember Fields camera covers redesigned route")
	_expect((area.get_node("Enemies/Grunt") as Grunt).position == Vector2(800, 352), "First Grunt is placed after the start runway")
	_expect((area.get_node("Enemies/Grunt2") as Grunt).position == Vector2(1888, 352), "Second Grunt is placed in the mid combat pocket")
	_expect((area.get_node("Enemies/Grunt3") as Grunt).position == Vector2(3456, 320), "Third Grunt is placed after the final landing")

	var detection_px := PhysicsModel.tiles_to_pixels(PhysicsModel.GRUNT_DETECTION_RANGE_TILES)
	_expect(absf((area.get_node("Enemies/Grunt2") as Grunt).position.x - (area.get_node("CheckpointMid") as Node2D).position.x) >= detection_px, "Mid Grunt has readable approach from checkpoint")
	_expect(absf((area.get_node("Enemies/Grunt3") as Grunt).position.x - PhysicsModel.tiles_to_pixels(99.0)) >= detection_px, "Final Grunt is not inside the landing zone")

func _check_storm_peaks_route(area: Node, tile_layer: TileMapLayer, kira: Kira) -> void:
	var platforms: Array[Vector3i] = [
		Vector3i(0, 12, 16),
		Vector3i(21, 12, 12),
		Vector3i(38, 10, 10),
		Vector3i(53, 9, 11),
		Vector3i(69, 11, 13),
		Vector3i(87, 10, 12),
		Vector3i(104, 8, 10),
		Vector3i(119, 10, 13),
		Vector3i(137, 9, 19),
	]
	var jumps: Array[Vector2i] = []
	for platform in platforms:
		_expect(tile_layer.get_cell_source_id(Vector2i(platform.x, platform.y)) != -1, "Storm Peaks platform starts at %s" % Vector2i(platform.x, platform.y))
		_expect(tile_layer.get_cell_source_id(Vector2i(platform.x + platform.z - 1, platform.y)) != -1, "Storm Peaks platform ends at %s" % Vector2i(platform.x + platform.z - 1, platform.y))
	for index in range(1, platforms.size()):
		var previous := platforms[index - 1]
		var current := platforms[index]
		jumps.append(Vector2i(previous.x + previous.z - 1, previous.y))
		jumps.append(Vector2i(current.x, current.y))
	_check_jump_pairs_are_reachable(jumps, kira, "Storm Peaks")

	_expect((area.get_node("CheckpointMid") as Node2D).position == Vector2(1760, 288), "Storm Peaks mid checkpoint starts the charged climb")
	_expect((area.get_node("CheckpointPreGoal") as Node2D).position == Vector2(3840, 320), "Storm Peaks pre-goal checkpoint starts final electro route")
	_expect((area.get_node("EndFlag") as Node2D).position == Vector2(4800, 288), "Storm Peaks flag sits on the final platform")
	_expect((area.get_node("Party/Camera2D") as Camera2D).limit_right >= 5056, "Storm Peaks camera covers full route")
	_expect((area.get_node("Enemies/Grunt") as Grunt).position == Vector2(800, 352), "Storm Peaks first Grunt is placed after the start runway")
	_expect((area.get_node("Enemies/Grunt2") as Grunt).position == Vector2(2112, 256), "Storm Peaks second Grunt guards the charged climb")
	_expect((area.get_node("Enemies/Grunt3") as Grunt).position == Vector2(4384, 288), "Storm Peaks third Grunt is placed before the final gate")

func _check_jump_pairs_are_reachable(jumps: Array[Vector2i], kira: Kira, label: String) -> void:
	var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
	var max_jump_height: float = pow(absf(kira.jump_velocity), 2.0) / (2.0 * gravity)
	var safe_step_height: float = min(max_jump_height * 0.84, PhysicsModel.tiles_to_pixels(PhysicsModel.SAFE_JUMP_RISE_TILES))
	for index in range(0, jumps.size(), 2):
		var previous: Vector2i = jumps[index]
		var current: Vector2i = jumps[index + 1]
		var rise_px: float = float(previous.y - current.y) * PhysicsModel.TILE_SIZE_PX
		var empty_gap_tiles := maxi(current.x - previous.x - 1, 0)
		var gap_px: float = float(empty_gap_tiles) * PhysicsModel.TILE_SIZE_PX
		_expect(rise_px <= safe_step_height, "%s jump rise fits physics: %spx" % [label, rise_px])
		_expect(gap_px <= PhysicsModel.tiles_to_pixels(PhysicsModel.SAFE_FLAT_JUMP_GAP_TILES), "%s jump gap is reachable: %spx" % [label, gap_px])

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
