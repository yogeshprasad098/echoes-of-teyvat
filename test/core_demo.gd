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
	await _check_storm_peak_grunt()
	await _check_projectile_physics()
	await _check_ember_fields()
	await _check_ember_progression_levels()
	await _check_boss_arenas()
	await _check_drowned_coast()
	await _check_drowned_coast_progression_levels()
	await _check_storm_peaks()
	await _check_storm_peaks_progression_levels()
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

func _check_storm_peak_grunt() -> void:
	var grunt := _instantiate("res://scenes/enemies/storm_peak_grunt.tscn") as StormPeakGrunt
	get_root().add_child(grunt)
	await process_frame

	var sprite := grunt.get_node("AnimatedSprite2D") as AnimatedSprite2D
	var target := CharacterBase.new()
	get_root().add_child(target)
	target.global_position = grunt.global_position + Vector2(50.0, 0.0)
	grunt._on_detection_body_entered(target)
	grunt._physics_process(0.016)
	_expect((grunt.get_node("AttackAlert") as Label).visible, "Storm Peaks Grunt attack wind-up is visible")
	_expect(sprite.animation == &"attack", "Storm Peaks Grunt plays attack animation")
	_expect(sprite.modulate == Color.WHITE, "Storm Peaks Grunt attack wind-up keeps neutral sprite color")
	_expect((grunt.get_node("AttackAlert") as Label).modulate == Color(0.45, 0.95, 1.0, 1.0), "Storm Peaks Grunt uses electro attack alert color")
	grunt.take_damage(10.0)
	_expect((grunt.get_node("HealthBar/Fill") as ColorRect).color == Color(0.22, 0.8, 1.0), "Storm Peaks Grunt health bar stays electro cyan above half health")
	target.queue_free()
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

	var enemy_projectile_specs: Array[Dictionary] = [
		{"path": "res://scenes/projectiles/ember_elite_lava_spit.tscn", "label": "Ember elite Lava Spit", "animation": &"lava_spit"},
		{"path": "res://scenes/projectiles/ember_elite_flame_wave.tscn", "label": "Ember elite Flame Wave", "animation": &"flame_wave"},
	]
	for spec in enemy_projectile_specs:
		var projectile := _instantiate(spec["path"]) as EnemyHydroProjectile
		get_root().add_child(projectile)
		await process_frame
		_expect(projectile.collision_layer == PROJECTILE_LAYER, "%s broadcasts on projectile layer" % spec["label"])
		_expect(projectile.collision_mask == (PLAYER_LAYER | WORLD_LAYER), "%s detects player and world only" % spec["label"])
		_expect(projectile.sprite.sprite_frames.has_animation(spec["animation"]), "%s has generated animation frames" % spec["label"])
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
	_expect(area.get_node_or_null("DecorProps") == null, "Ember Fields decorative props are removed")
	_expect(area.get_node_or_null("LavaGaps") == null, "Ember Fields sketch route has no lava gap sprites")

	_expect(area.get_node_or_null("StartPoint") != null, "Area has start point")
	_expect(area.get_node_or_null("EndFlag") != null, "Area has end flag")
	_expect(area.get_node("Enemies").get_child_count() >= 3, "Area has at least three Grunts")
	_expect(_count_enemy_scene(area, "res://scenes/enemies/ember_fields_grunt.tscn") == 3, "Ember Fields Level 1 uses Ember Fields Grunts")
	_expect(_count_enemy_scene(area, "res://scenes/enemies/ember_fields_magma_guard_elite.tscn") == 1, "Ember Fields Level 1 has one Magma Guard elite")
	_expect(_enemies_have_floor_below(area), "Ember Fields enemies have reachable floor below spawn")
	_expect(area.get_node_or_null("Party/Kira") != null, "Area has Kira")
	_expect(((area.get_node("EndFlag") as Area2D).collision_mask & PLAYER_LAYER) != 0, "Goal flag detects Kira on player layer")

	var camera := area.get_node("Party/Camera2D") as Camera2D
	_expect(camera.limit_left == 0 and camera.limit_right >= 2816, "Party camera limits are configured")
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

	_expect((area.get_node("ParallaxBackground/BgFar/FallbackSprite") as AnimatedSprite2D).sprite_frames.resource_path.ends_with("drowned_coast_clean_ambient_bg_sprite_frames.tres"), "Drowned Coast uses the clean animated background")

	_expect(area.get_node_or_null("StartPoint") != null, "Drowned Coast has start point")
	_expect(area.get_node_or_null("EndFlag") != null, "Drowned Coast has end flag")
	_expect(area.get_node_or_null("CheckpointStart") == null, "Drowned Coast route omits the old start checkpoint")
	_expect(area.get_node_or_null("CheckpointMid") != null, "Drowned Coast has mid checkpoint")
	_expect(area.get_node_or_null("CheckpointPreGoal") != null, "Drowned Coast has pre-goal checkpoint")
	_expect(area.get_node("Enemies").get_child_count() >= 3, "Drowned Coast has at least three Grunts")
	_expect(_count_enemy_scene(area, "res://scenes/enemies/drowned_coast_grunt.tscn") == 3, "Drowned Coast Level 1 uses Drowned Coast Grunts")
	_expect(_count_enemy_scene(area, "res://scenes/enemies/drowned_coast_reef_tidecaller.tscn") == 1, "Drowned Coast Level 1 has one reef tidecaller elite")
	_expect(area.get_node_or_null("Party/Kira") != null, "Drowned Coast has Kira")
	_expect(area.get_node_or_null("Party/Marina") != null, "Drowned Coast has Marina")
	_expect(area.get_node_or_null("Party/Ryne") != null, "Drowned Coast has Ryne")
	_expect(((area.get_node("EndFlag") as Area2D).collision_mask & PLAYER_LAYER) != 0, "Drowned Coast goal flag detects Kira on player layer")
	_expect(ground.tile_set.resource_path.ends_with("drowned_coast_clean_preview_tileset.tres"), "Drowned Coast uses the clean Drowned Coast tileset")
	_expect((area.get_node("StartPoint/StartFlagVisual") as Sprite2D).texture.resource_path.ends_with("drowned_coast_start_goal_flag.png"), "Drowned Coast uses the clean route flag at start")
	_expect((area.get_node("EndFlag/Sprite2D") as Sprite2D).texture.resource_path.ends_with("drowned_coast_start_goal_flag.png"), "Drowned Coast uses the clean route flag at goal")

	var camera := area.get_node("Party/Camera2D") as Camera2D
	_expect(camera.limit_left == 0 and camera.limit_right >= 2816, "Drowned Coast party camera limits are configured")
	var kira := area.get_node("Party/Kira") as Kira
	var grunt := area.get_node("Enemies/Grunt") as Grunt
	_expect((kira.collision_mask & grunt.collision_layer) == 0, "Drowned Coast Kira does not physically collide with Grunt bodies")
	_expect((grunt.collision_mask & kira.collision_layer) == 0, "Drowned Coast Grunt does not physically collide with Kira body")
	var platforms: Array[Vector3i] = [
		Vector3i(3, 12, 14),
		Vector3i(22, 10, 12),
		Vector3i(39, 8, 12),
		Vector3i(56, 12, 12),
		Vector3i(73, 12, 14),
	]
	var jumps: Array[Vector2i] = []
	for index in range(platforms.size()):
		var platform := platforms[index]
		var start := Vector2i(platform.x, platform.y)
		var end := Vector2i(platform.x + platform.z - 1, platform.y)
		_expect(ground.get_cell_source_id(start) != -1, "Drowned Coast sketch platform starts at %s" % start)
		_expect(ground.get_cell_source_id(end) != -1, "Drowned Coast sketch platform ends at %s" % end)
		_expect(ground.get_cell_atlas_coords(start + Vector2i(0, 1)) == Vector2i(1, 0), "Drowned Coast sketch platform has cracked second layer at %s" % (start + Vector2i(0, 1)))
		_expect(ground.get_cell_source_id(start + Vector2i(0, 2)) == -1, "Drowned Coast sketch platform uses only two tile layers at %s" % start)
		if index > 0:
			var previous := platforms[index - 1]
			jumps.append(Vector2i(previous.x + previous.z - 1, previous.y))
			jumps.append(start)
	_check_jump_pairs_are_reachable(jumps, kira, "Drowned Coast")
	_expect((area.get_node("CheckpointMid") as Node2D).position == Vector2(1424, 208), "Drowned Coast mid checkpoint is floor-aligned on the elite platform")
	_expect((area.get_node("CheckpointPreGoal") as Node2D).position == Vector2(2384, 336), "Drowned Coast pre-goal checkpoint is floor-aligned on the final platform")
	_expect((area.get_node("EndFlag") as Node2D).position == Vector2(2608, 352), "Drowned Coast flag sits on the final platform")
	_expect((area.get_node("Enemies/DrownedCoastElite") as Node2D).position.is_equal_approx(Vector2(1440, 208)), "Drowned Coast elite is on the high center platform")

	area.queue_free()
	await process_frame

func _check_drowned_coast_progression_levels() -> void:
	var level_specs: Array[Dictionary] = [
		{
			"path": "res://scenes/areas/drowned_coast_level_2.tscn",
			"node": "DrownedCoastLevel2",
			"label": "Drowned Coast Level 2",
			"grunts": 3,
			"elites": 2,
			"camera_right": 3264,
			"end": Vector2(2976, 352),
			"mid": Vector2(1280, 208),
			"pre_goal": Vector2(2336, 336),
			"platforms": [
				Vector3i(3, 12, 12),
				Vector3i(20, 10, 12),
				Vector3i(37, 8, 12),
				Vector3i(53, 6, 12),
				Vector3i(70, 12, 12),
				Vector3i(86, 12, 12),
			],
		},
		{
			"path": "res://scenes/areas/drowned_coast_level_3.tscn",
			"node": "DrownedCoastLevel3",
			"label": "Drowned Coast Level 3",
			"grunts": 3,
			"elites": 3,
			"camera_right": 4224,
			"end": Vector2(3936, 352),
			"mid": Vector2(1280, 208),
			"pre_goal": Vector2(3296, 336),
			"platforms": [
				Vector3i(3, 12, 12),
				Vector3i(20, 10, 12),
				Vector3i(36, 8, 12),
				Vector3i(52, 6, 12),
				Vector3i(68, 9, 12),
				Vector3i(84, 7, 12),
				Vector3i(100, 12, 12),
				Vector3i(116, 12, 12),
			],
		},
		{
			"path": "res://scenes/areas/drowned_coast_level_4.tscn",
			"node": "DrownedCoastLevel4",
			"label": "Drowned Coast Level 4",
			"grunts": 3,
			"elites": 4,
			"camera_right": 4800,
			"end": Vector2(4288, 352),
			"mid": Vector2(1728, 336),
			"pre_goal": Vector2(3456, 368),
			"platforms": [
				Vector3i(3, 12, 12),
				Vector3i(19, 10, 12),
				Vector3i(35, 8, 12),
				Vector3i(51, 12, 12),
				Vector3i(67, 10, 12),
				Vector3i(83, 13, 12),
				Vector3i(99, 13, 12),
				Vector3i(115, 11, 12),
				Vector3i(131, 12, 12),
			],
		},
		{
			"path": "res://scenes/areas/drowned_coast_level_5.tscn",
			"node": "DrownedCoastLevel5",
			"label": "Drowned Coast Level 5",
			"grunts": 5,
			"elites": 5,
			"camera_right": 5760,
			"end": Vector2(5408, 352),
			"mid": Vector2(2112, 368),
			"pre_goal": Vector2(4704, 272),
			"platforms": [
				Vector3i(3, 12, 12),
				Vector3i(19, 10, 12),
				Vector3i(34, 10, 12),
				Vector3i(50, 13, 12),
				Vector3i(65, 13, 12),
				Vector3i(81, 11, 12),
				Vector3i(97, 9, 12),
				Vector3i(113, 9, 12),
				Vector3i(129, 7, 12),
				Vector3i(145, 10, 12),
				Vector3i(161, 12, 12),
			],
		},
	]
	for spec in level_specs:
		var area := _instantiate(spec["path"]) as AreaBase
		get_root().add_child(area)
		await process_frame

		var label: String = spec["label"]
		var ground := area.get_node("Ground") as TileMapLayer
		_expect(area.name == spec["node"], "%s root name is stable" % label)
		_expect(ground.tile_set != null, "%s has TileSet" % label)
		_expect(ground.get_used_cells().size() > 100, "%s has a built TileMapLayer layout" % label)
		_expect(_tileset_has_collision(ground.tile_set), "%s TileSet has collision" % label)
		_expect(ground.tile_set.resource_path.ends_with("drowned_coast_clean_preview_tileset.tres"), "%s uses the clean Drowned Coast tileset" % label)
		_expect((area.get_node("ParallaxBackground/BgFar/FallbackSprite") as AnimatedSprite2D).sprite_frames.resource_path.ends_with("drowned_coast_clean_ambient_bg_sprite_frames.tres"), "%s uses the clean animated background" % label)
		_expect((area.get_node("StartPoint/StartFlagVisual") as Sprite2D).texture.resource_path.ends_with("drowned_coast_start_goal_flag.png"), "%s uses the clean route flag at start" % label)
		_expect((area.get_node("EndFlag/Sprite2D") as Sprite2D).texture.resource_path.ends_with("drowned_coast_start_goal_flag.png"), "%s uses the clean route flag at goal" % label)
		_expect(area.get_node_or_null("CheckpointStart") == null, "%s route omits the old start checkpoint" % label)
		_expect((area.get_node("EndFlag") as Area2D).position.is_equal_approx(spec["end"]), "%s has tuned goal position" % label)
		_expect((area.get_node("CheckpointMid") as Node2D).position.is_equal_approx(spec["mid"]), "%s has tuned mid checkpoint" % label)
		_expect((area.get_node("CheckpointPreGoal") as Node2D).position.is_equal_approx(spec["pre_goal"]), "%s has tuned pre-goal checkpoint" % label)
		_expect(_count_enemy_scene(area, "res://scenes/enemies/drowned_coast_grunt.tscn") == int(spec["grunts"]), "%s has expected Drowned Coast Grunt count" % label)
		_expect(_count_enemy_scene(area, "res://scenes/enemies/drowned_coast_reef_tidecaller.tscn") == int(spec["elites"]), "%s has expected reef tidecaller count" % label)
		_expect(area.get_node_or_null("Party/Kira") != null, "%s has Kira" % label)
		_expect(area.get_node_or_null("Party/Marina") != null, "%s has Marina" % label)
		_expect(area.get_node_or_null("Party/Ryne") != null, "%s has Ryne" % label)
		_expect((area.get_node("Party/Camera2D") as Camera2D).limit_right >= int(spec["camera_right"]), "%s camera covers route" % label)
		_expect(_enemies_have_floor_below(area), "%s enemies have reachable floor below spawn" % label)
		var jump_pairs: Array[Vector2i] = []
		var spec_platforms: Array = spec["platforms"]
		for index in range(spec_platforms.size()):
			var segment := spec_platforms[index] as Vector3i
			_expect(ground.get_cell_source_id(Vector2i(segment.x, segment.y)) != -1, "%s platform starts at %s" % [label, Vector2i(segment.x, segment.y)])
			_expect(ground.get_cell_atlas_coords(Vector2i(segment.x, segment.y + 1)) == Vector2i(1, 0), "%s second layer uses cracked Drowned tile at %s" % [label, Vector2i(segment.x, segment.y + 1)])
			_expect(ground.get_cell_source_id(Vector2i(segment.x, segment.y + 2)) == -1, "%s platform uses only two tile layers at %s" % [label, Vector2i(segment.x, segment.y)])
			if index > 0:
				var previous := spec_platforms[index - 1] as Vector3i
				jump_pairs.append(Vector2i(previous.x + previous.z - 1, previous.y))
				jump_pairs.append(Vector2i(segment.x, segment.y))
		_check_jump_pairs_are_reachable(jump_pairs, area.get_node("Party/Kira") as Kira, label)

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
	_expect(ground.tile_set.resource_path.ends_with("storm_peaks_clean_preview_tileset.tres"), "Storm Peaks uses the clean procedural tileset")

	for node_path in [
		"ParallaxBackground/BgFar/FallbackSprite",
		"ParallaxBackground/BgMid/Sprite2D",
		"ParallaxBackground/BgNear/Sprite2D",
	]:
		_expect((area.get_node(node_path) as Sprite2D).texture != null, "Storm Peaks background texture wired: %s" % node_path)

	_expect(area is AreaBase, "Storm Peaks remains an AreaBase scene")
	_expect(area.get_node_or_null("StartPoint") != null, "Storm Peaks has start point")
	_expect(area.get_node_or_null("EndFlag") != null, "Storm Peaks has end flag")
	_expect(area.get_node_or_null("CheckpointStart") == null, "Storm Peaks route omits the old start checkpoint")
	_expect(area.get_node_or_null("CheckpointMid") != null, "Storm Peaks has mid checkpoint")
	_expect(area.get_node_or_null("CheckpointPreGoal") != null, "Storm Peaks has pre-goal checkpoint")
	_expect(_count_enemy_scene(area, "res://scenes/enemies/storm_peak_grunt.tscn") == 3, "Storm Peaks Level 1 uses Storm Peaks Grunts")
	_expect(_count_enemy_scene(area, "res://scenes/enemies/elite_storm_caster.tscn") == 1, "Storm Peaks Level 1 has one elite caster")
	_expect(area.get_node_or_null("Party/Kira") != null, "Storm Peaks has Kira")
	_expect(area.get_node_or_null("Party/Marina") != null, "Storm Peaks has Marina")
	_expect(area.get_node_or_null("Party/Ryne") != null, "Storm Peaks has Ryne")
	_expect(((area.get_node("EndFlag") as Area2D).collision_mask & PLAYER_LAYER) != 0, "Storm Peaks goal flag detects Kira on player layer")
	_expect((area.get_node("StartPoint/StartFlagVisual") as Sprite2D).texture.resource_path.ends_with("storm_peaks_start_flag.png"), "Storm Peaks uses the Storm Peaks flag at start")
	_expect((area.get_node("EndFlag/Sprite2D") as Sprite2D).texture.resource_path.ends_with("storm_peaks_start_flag.png"), "Storm Peaks uses the Storm Peaks flag at goal")

	var camera := area.get_node("Party/Camera2D") as Camera2D
	_expect(camera.limit_left == 0 and camera.limit_right >= 2816, "Storm Peaks party camera covers route")
	var kira := area.get_node("Party/Kira") as Kira
	var grunt := area.get_node("Enemies/Grunt") as Grunt
	_expect((kira.collision_mask & grunt.collision_layer) == 0, "Storm Peaks Kira does not physically collide with Grunt bodies")
	_expect((grunt.collision_mask & kira.collision_layer) == 0, "Storm Peaks Grunt does not physically collide with Kira body")
	_check_storm_peaks_route(area, ground, kira)

	area.queue_free()
	await process_frame

func _check_storm_peaks_progression_levels() -> void:
	var level_specs: Array[Dictionary] = [
		{
			"path": "res://scenes/areas/storm_peaks_level_2.tscn",
			"node": "StormPeaksLevel2",
			"label": "Storm Peaks Level 2",
			"grunts": 3,
			"elites": 2,
			"camera_right": 3264,
			"end": Vector2(2976, 352),
			"mid": Vector2(1280, 208),
			"pre_goal": Vector2(2336, 336),
			"platforms": [
				Vector3i(3, 12, 12),
				Vector3i(20, 10, 12),
				Vector3i(37, 8, 12),
				Vector3i(53, 6, 12),
				Vector3i(70, 12, 12),
				Vector3i(86, 12, 12),
			],
		},
		{
			"path": "res://scenes/areas/storm_peaks_level_3.tscn",
			"node": "StormPeaksLevel3",
			"label": "Storm Peaks Level 3",
			"grunts": 3,
			"elites": 3,
			"camera_right": 4224,
			"end": Vector2(3936, 352),
			"mid": Vector2(1280, 208),
			"pre_goal": Vector2(3296, 336),
			"platforms": [
				Vector3i(3, 12, 12),
				Vector3i(20, 10, 12),
				Vector3i(36, 8, 12),
				Vector3i(52, 6, 12),
				Vector3i(68, 9, 12),
				Vector3i(84, 7, 12),
				Vector3i(100, 12, 12),
				Vector3i(116, 12, 12),
			],
		},
		{
			"path": "res://scenes/areas/storm_peaks_level_4.tscn",
			"node": "StormPeaksLevel4",
			"label": "Storm Peaks Level 4",
			"grunts": 3,
			"elites": 4,
			"camera_right": 4800,
			"end": Vector2(4288, 352),
			"mid": Vector2(1728, 336),
			"pre_goal": Vector2(3456, 368),
			"platforms": [
				Vector3i(3, 12, 12),
				Vector3i(19, 10, 12),
				Vector3i(35, 8, 12),
				Vector3i(51, 12, 12),
				Vector3i(67, 10, 12),
				Vector3i(83, 13, 12),
				Vector3i(99, 13, 12),
				Vector3i(115, 11, 12),
				Vector3i(131, 12, 12),
			],
		},
		{
			"path": "res://scenes/areas/storm_peaks_level_5.tscn",
			"node": "StormPeaksLevel5",
			"label": "Storm Peaks Level 5",
			"grunts": 5,
			"elites": 5,
			"camera_right": 5760,
			"end": Vector2(5408, 352),
			"mid": Vector2(2112, 368),
			"pre_goal": Vector2(4704, 272),
			"platforms": [
				Vector3i(3, 12, 12),
				Vector3i(19, 10, 12),
				Vector3i(34, 10, 12),
				Vector3i(50, 13, 12),
				Vector3i(65, 13, 12),
				Vector3i(81, 11, 12),
				Vector3i(97, 9, 12),
				Vector3i(113, 9, 12),
				Vector3i(129, 7, 12),
				Vector3i(145, 10, 12),
				Vector3i(161, 12, 12),
			],
		},
	]
	for spec in level_specs:
		await _check_storm_peaks_level_scene(spec)

func _check_storm_peaks_level_scene(spec: Dictionary) -> void:
	var area := _instantiate(spec["path"]) as AreaBase
	get_root().add_child(area)
	await process_frame

	var label: String = spec["label"]
	var ground := area.get_node("Ground") as TileMapLayer
	_expect(area.name == spec["node"], "%s root name is stable" % label)
	_expect(ground.tile_set != null, "%s has TileSet" % label)
	_expect(ground.get_used_cells().size() > 100, "%s has a built TileMapLayer layout" % label)
	_expect(_tileset_has_collision(ground.tile_set), "%s TileSet has collision" % label)
	_expect(ground.tile_set.resource_path.ends_with("storm_peaks_clean_preview_tileset.tres"), "%s uses the clean Storm Peaks tileset" % label)
	_expect(area.get_node_or_null("CheckpointStart") == null, "%s route omits the old start checkpoint" % label)
	_expect((area.get_node("EndFlag") as Area2D).position.is_equal_approx(spec["end"]), "%s has matching goal position" % label)
	_expect((area.get_node("CheckpointMid") as Node2D).position.is_equal_approx(spec["mid"]), "%s has matching mid checkpoint" % label)
	_expect((area.get_node("CheckpointPreGoal") as Node2D).position.is_equal_approx(spec["pre_goal"]), "%s has matching pre-goal checkpoint" % label)
	_expect(_count_enemy_scene(area, "res://scenes/enemies/storm_peak_grunt.tscn") == int(spec["grunts"]), "%s uses Storm Peaks Grunts" % label)
	_expect(_count_enemy_scene(area, "res://scenes/enemies/elite_storm_caster.tscn") == int(spec["elites"]), "%s has expected elite caster count" % label)
	_expect(area.get_node_or_null("Party/Ryne") != null, "%s has Ryne for electro progression" % label)
	_expect((area.get_node("Party/Camera2D") as Camera2D).limit_right >= int(spec["camera_right"]), "%s camera covers matching route" % label)
	_expect(_enemies_have_floor_below(area), "%s enemies have reachable floor below spawn" % label)
	_expect((area.get_node("StartPoint/StartFlagVisual") as Sprite2D).texture.resource_path.ends_with("storm_peaks_start_flag.png"), "%s uses the Storm Peaks flag at start" % label)
	_expect((area.get_node("EndFlag/Sprite2D") as Sprite2D).texture.resource_path.ends_with("storm_peaks_start_flag.png"), "%s uses the Storm Peaks flag at goal" % label)
	var jump_pairs: Array[Vector2i] = []
	var platforms: Array = spec["platforms"]
	for index in range(platforms.size()):
		var segment := platforms[index] as Vector3i
		_expect(ground.get_cell_source_id(Vector2i(segment.x, segment.y)) != -1, "%s platform starts at %s" % [label, Vector2i(segment.x, segment.y)])
		_expect(ground.get_cell_source_id(Vector2i(segment.x + segment.z - 1, segment.y)) != -1, "%s platform ends at %s" % [label, Vector2i(segment.x + segment.z - 1, segment.y)])
		_expect(ground.get_cell_atlas_coords(Vector2i(segment.x, segment.y)) == Vector2i(0, 0), "%s first layer uses normal Storm tile at %s" % [label, Vector2i(segment.x, segment.y)])
		_expect(ground.get_cell_atlas_coords(Vector2i(segment.x, segment.y + 1)) == Vector2i(1, 0), "%s second layer uses cracked Storm tile at %s" % [label, Vector2i(segment.x, segment.y + 1)])
		_expect(ground.get_cell_source_id(Vector2i(segment.x, segment.y + 2)) == -1, "%s platform uses only two tile layers at %s" % [label, Vector2i(segment.x, segment.y)])
		if index > 0:
			var previous := platforms[index - 1] as Vector3i
			jump_pairs.append(Vector2i(previous.x + previous.z - 1, previous.y))
			jump_pairs.append(Vector2i(segment.x, segment.y))
	_check_jump_pairs_are_reachable(jump_pairs, area.get_node("Party/Kira") as Kira, label)

	area.queue_free()
	await process_frame

func _check_ember_progression_levels() -> void:
	var level_specs: Array[Dictionary] = [
		{
			"path": "res://scenes/areas/ember_fields_level_2.tscn",
			"label": "Ember Fields Level 2",
			"grunts": 3,
			"elites": 2,
			"camera_right": 3264,
			"end": Vector2(2976, 352),
			"mid": Vector2(1280, 208),
			"pre_goal": Vector2(2336, 336),
			"start_checkpoint": false,
			"clean_assets": true,
			"two_layers_only": true,
			"second_layer_tile": Vector2i(1, 0),
			"platforms": [
				Vector3i(3, 12, 12),
				Vector3i(20, 10, 12),
				Vector3i(37, 8, 12),
				Vector3i(53, 6, 12),
				Vector3i(70, 12, 12),
				Vector3i(86, 12, 12),
			],
		},
		{
			"path": "res://scenes/areas/ember_fields_level_3.tscn",
			"label": "Ember Fields Level 3",
			"grunts": 3,
			"elites": 3,
			"camera_right": 4224,
			"end": Vector2(3936, 352),
			"mid": Vector2(1280, 208),
			"pre_goal": Vector2(3296, 336),
			"start_checkpoint": false,
			"clean_assets": true,
			"two_layers_only": true,
			"second_layer_tile": Vector2i(1, 0),
			"platforms": [
				Vector3i(3, 12, 12),
				Vector3i(20, 10, 12),
				Vector3i(36, 8, 12),
				Vector3i(52, 6, 12),
				Vector3i(68, 9, 12),
				Vector3i(84, 7, 12),
				Vector3i(100, 12, 12),
				Vector3i(116, 12, 12),
			],
		},
		{
			"path": "res://scenes/areas/ember_fields_level_4.tscn",
			"label": "Ember Fields Level 4",
			"grunts": 3,
			"elites": 4,
			"camera_right": 4800,
			"end": Vector2(4288, 352),
			"mid": Vector2(1728, 336),
			"pre_goal": Vector2(3456, 368),
			"start_checkpoint": false,
			"clean_assets": true,
			"two_layers_only": true,
			"second_layer_tile": Vector2i(1, 0),
			"platforms": [
				Vector3i(3, 12, 12),
				Vector3i(19, 10, 12),
				Vector3i(35, 8, 12),
				Vector3i(51, 12, 12),
				Vector3i(67, 10, 12),
				Vector3i(83, 13, 12),
				Vector3i(99, 13, 12),
				Vector3i(115, 11, 12),
				Vector3i(131, 12, 12),
			],
		},
		{
			"path": "res://scenes/areas/ember_fields_level_5.tscn",
			"label": "Ember Fields Level 5",
			"grunts": 5,
			"elites": 5,
			"camera_right": 5760,
			"end": Vector2(5408, 352),
			"mid": Vector2(2112, 368),
			"pre_goal": Vector2(4704, 272),
			"start_checkpoint": false,
			"clean_assets": true,
			"two_layers_only": true,
			"second_layer_tile": Vector2i(1, 0),
			"platforms": [
				Vector3i(3, 12, 12),
				Vector3i(19, 10, 12),
				Vector3i(34, 10, 12),
				Vector3i(50, 13, 12),
				Vector3i(65, 13, 12),
				Vector3i(81, 11, 12),
				Vector3i(97, 9, 12),
				Vector3i(113, 9, 12),
				Vector3i(129, 7, 12),
				Vector3i(145, 10, 12),
				Vector3i(161, 12, 12),
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
	var expects_start_checkpoint := bool(spec.get("start_checkpoint", true))
	_expect((area.get_node_or_null("CheckpointStart") != null) == expects_start_checkpoint, "%s start checkpoint presence matches route design" % label)
	_expect(area.get_node_or_null("CheckpointMid") != null, "%s has mid checkpoint" % label)
	_expect(area.get_node_or_null("CheckpointPreGoal") != null, "%s has pre-goal checkpoint" % label)
	_expect(area.get_node_or_null("Party/Kira") != null, "%s has Kira" % label)
	_expect(_count_enemy_scene(area, "res://scenes/enemies/ember_fields_grunt.tscn") == int(spec["grunts"]), "%s has expected Ember Grunt count" % label)
	_expect(_count_enemy_scene(area, "res://scenes/enemies/ember_fields_magma_guard_elite.tscn") == int(spec["elites"]), "%s has expected Magma Guard elite count" % label)
	_expect(_enemies_have_floor_below(area), "%s enemies have reachable floor below spawn" % label)
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
		if bool(spec.get("two_layers_only", false)):
			_expect(ground.get_cell_source_id(Vector2i(segment.x, segment.y + 1)) != -1, "%s platform has orange cracked second layer at %s" % [label, Vector2i(segment.x, segment.y + 1)])
			_expect(ground.get_cell_source_id(Vector2i(segment.x + segment.z - 1, segment.y + 1)) != -1, "%s platform has orange cracked second layer at %s" % [label, Vector2i(segment.x + segment.z - 1, segment.y + 1)])
			_expect(ground.get_cell_source_id(Vector2i(segment.x, segment.y + 2)) == -1, "%s platform uses only two tile layers at %s" % [label, Vector2i(segment.x, segment.y)])
			if spec.has("second_layer_tile"):
				var second_layer_tile := spec["second_layer_tile"] as Vector2i
				_expect(ground.get_cell_atlas_coords(Vector2i(segment.x, segment.y + 1)) == second_layer_tile, "%s second layer uses orange cracked tile at %s" % [label, Vector2i(segment.x, segment.y + 1)])
				_expect(ground.get_cell_atlas_coords(Vector2i(segment.x + segment.z - 1, segment.y + 1)) == second_layer_tile, "%s second layer uses orange cracked tile at %s" % [label, Vector2i(segment.x + segment.z - 1, segment.y + 1)])
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
	if bool(spec.get("clean_assets", false)):
		_expect(ground.tile_set.resource_path.ends_with("ember_fields_clean_preview_tileset.tres"), "%s uses the clean Ember Fields tileset" % label)
		_expect((area.get_node("ParallaxBackground/BgFar/FallbackSprite") as AnimatedSprite2D).sprite_frames.resource_path.ends_with("ember_fields_clean_ambient_bg_sprite_frames.tres"), "%s uses the clean animated background" % label)
		_expect((area.get_node("StartPoint/StartFlagVisual") as Sprite2D).texture.resource_path.ends_with("ember_start_flag.png"), "%s uses the clean route flag at start" % label)
		_expect((area.get_node("EndFlag/Sprite2D") as Sprite2D).texture.resource_path.ends_with("ember_start_flag.png"), "%s uses the clean route flag at goal" % label)

	area.queue_free()
	await process_frame

func _check_boss_arenas() -> void:
	var boss_specs: Array[Dictionary] = [
		{"path": "res://scenes/areas/ember_fields_boss_1_arena.tscn", "node": "EmberFieldsBoss1Arena", "name": "Flame Warden", "health": 180.0, "pattern": BossBase.Pattern.FLAME_BURST, "clean_ember_arena": true},
		{"path": "res://scenes/areas/ember_fields_boss_2_arena.tscn", "node": "EmberFieldsBoss2Arena", "name": "Tide Serpent", "health": 240.0, "pattern": BossBase.Pattern.WATER_WAVE, "clean_ember_arena": true},
		{"path": "res://scenes/areas/ember_fields_boss_3_arena.tscn", "node": "EmberFieldsBoss3Arena", "name": "Sparking Sentinel", "health": 320.0, "pattern": BossBase.Pattern.LIGHTNING_BOLT, "clean_ember_arena": true},
		{"path": "res://scenes/areas/ember_fields_boss_4_arena.tscn", "node": "EmberFieldsBoss4Arena", "name": "Ash Colossus", "health": 420.0, "pattern": BossBase.Pattern.ASH_STOMP, "clean_ember_arena": true},
		{"path": "res://scenes/areas/ember_fields_boss_5_arena.tscn", "node": "EmberFieldsBoss5Arena", "name": "Ember Tyrant", "health": 560.0, "pattern": BossBase.Pattern.EMBER_TYRANT, "clean_ember_arena": true},
		{"path": "res://scenes/areas/drowned_coast_boss_1_arena.tscn", "node": "DrownedCoastBoss1Arena", "name": "Tide Warden", "health": 220.0, "pattern": BossBase.Pattern.WATER_WAVE, "clean_drowned_arena": true},
		{"path": "res://scenes/areas/drowned_coast_boss_2_arena.tscn", "node": "DrownedCoastBoss2Arena", "name": "Reef Serpent", "health": 280.0, "pattern": BossBase.Pattern.WATER_WAVE, "clean_drowned_arena": true},
		{"path": "res://scenes/areas/drowned_coast_boss_3_arena.tscn", "node": "DrownedCoastBoss3Arena", "name": "Abyss Caller", "health": 340.0, "pattern": BossBase.Pattern.WATER_WAVE, "clean_drowned_arena": true},
		{"path": "res://scenes/areas/drowned_coast_boss_4_arena.tscn", "node": "DrownedCoastBoss4Arena", "name": "Maelstrom Sentinel", "health": 430.0, "pattern": BossBase.Pattern.WATER_WAVE, "clean_drowned_arena": true},
		{"path": "res://scenes/areas/drowned_coast_boss_5_arena.tscn", "node": "DrownedCoastBoss5Arena", "name": "Drowned Leviathan", "health": 560.0, "pattern": BossBase.Pattern.WATER_WAVE, "clean_drowned_arena": true},
		{"path": "res://scenes/areas/storm_peaks_boss_1_arena.tscn", "node": "StormPeaksBoss1Arena", "name": "Storm Harbinger", "health": 260.0, "pattern": BossBase.Pattern.LIGHTNING_BOLT, "clean_storm_arena": true},
		{"path": "res://scenes/areas/storm_peaks_boss_2_arena.tscn", "node": "StormPeaksBoss2Arena", "name": "Thunder Ravager", "health": 320.0, "pattern": BossBase.Pattern.LIGHTNING_BOLT, "clean_storm_arena": true},
		{"path": "res://scenes/areas/storm_peaks_boss_3_arena.tscn", "node": "StormPeaksBoss3Arena", "name": "Arc Sentinel", "health": 380.0, "pattern": BossBase.Pattern.LIGHTNING_BOLT, "clean_storm_arena": true},
		{"path": "res://scenes/areas/storm_peaks_boss_4_arena.tscn", "node": "StormPeaksBoss4Arena", "name": "Tempest Colossus", "health": 460.0, "pattern": BossBase.Pattern.ASH_STOMP, "clean_storm_arena": true},
		{"path": "res://scenes/areas/storm_peaks_boss_5_arena.tscn", "node": "StormPeaksBoss5Arena", "name": "Storm Sovereign", "health": 600.0, "pattern": BossBase.Pattern.EMBER_TYRANT, "clean_storm_arena": true},
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
	if bool(spec.get("clean_ember_arena", false)):
		_check_clean_ember_boss_arena(arena, label)
	elif bool(spec.get("clean_drowned_arena", false)):
		_check_clean_drowned_boss_arena(arena, label)
	elif bool(spec.get("clean_storm_arena", false)):
		_check_clean_storm_boss_arena(arena, label)
	elif bool(spec.get("runtime_environment", false)):
		_expect(arena.get_node_or_null("ArenaEnvironment/Backdrop") != null, "%s arena uses generated backdrop" % label)
		_expect(arena.get_node_or_null("ArenaEnvironment/LavaDepth") != null, "%s arena uses generated lava depth" % label)
		_expect(arena.get_node_or_null("ArenaEnvironment/ArenaFloorVisual") != null, "%s arena uses generated floor art" % label)
		_expect(arena.get_node_or_null("ArenaEnvironment/LeftBoundaryWallVisual") != null, "%s arena uses generated left wall art" % label)
		_expect(arena.get_node_or_null("ArenaEnvironment/RightBoundaryWallVisual") != null, "%s arena uses generated right wall art" % label)
		_expect(arena.get_node_or_null("ArenaEnvironment/ForegroundEdge") == null, "%s arena does not duplicate the floor foreground lip" % label)
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
	var boss_sprite := boss.get_node("%AnimatedSprite2D") as AnimatedSprite2D
	var player_sprite := arena.get_player().get_node("%AnimatedSprite2D") as AnimatedSprite2D
	_expect(absf(_sprite_floor_y(boss_sprite) - _sprite_floor_y(player_sprite)) <= 4.0, "%s boss global foot line matches active player" % label)
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

func _check_clean_ember_boss_arena(arena: BossArenaBase, label: String) -> void:
	_expect(arena.get_node_or_null("ArenaEnvironment") == null, "%s arena removes boss-specific environment art" % label)
	_expect(arena.get_node_or_null("ParallaxBackground/BgFar/FallbackSprite") != null, "%s arena uses Ember far background" % label)
	_expect(arena.get_node_or_null("ParallaxBackground/BgMid/Sprite2D") != null, "%s arena keeps Ember mid background node" % label)
	_expect(arena.get_node_or_null("ParallaxBackground/BgNear/Sprite2D") != null, "%s arena keeps Ember near background node" % label)
	var bg := arena.get_node("ParallaxBackground/BgFar/FallbackSprite") as AnimatedSprite2D
	_expect(bg.sprite_frames.resource_path.ends_with("ember_fields_clean_ambient_bg_sprite_frames.tres"), "%s arena uses the clean animated Ember background" % label)
	var ground := arena.get_node("Ground") as TileMapLayer
	_expect(ground.tile_set.resource_path.ends_with("ember_fields_clean_preview_tileset.tres"), "%s arena uses the clean Ember Fields tileset" % label)
	_expect(ground.get_used_cells().size() == 40, "%s arena uses one 20-tile two-layer floor" % label)
	for x in range(20):
		_expect(ground.get_cell_atlas_coords(Vector2i(x, 9)) == Vector2i(0, 0), "%s top floor layer uses normal tile at x=%d" % [label, x])
		_expect(ground.get_cell_atlas_coords(Vector2i(x, 10)) == Vector2i(1, 0), "%s second floor layer uses orange cracked tile at x=%d" % [label, x])
	_expect(arena.get_node_or_null("BoundaryWalls/LeftWallShape") != null, "%s arena keeps left physics wall" % label)
	_expect(arena.get_node_or_null("BoundaryWalls/RightWallShape") != null, "%s arena keeps right physics wall" % label)
	var left_pillar := arena.get_node_or_null("Pillars/LeftTallPillar") as Sprite2D
	var right_pillar := arena.get_node_or_null("Pillars/RightTallPillar") as Sprite2D
	_expect(left_pillar != null and right_pillar != null, "%s arena uses two tall pillar props" % label)
	if left_pillar != null and right_pillar != null:
		_expect(left_pillar.texture.resource_path.ends_with("ember_boss_pillar_tall.png"), "%s left pillar uses tall pillar asset" % label)
		_expect(right_pillar.texture.resource_path.ends_with("ember_boss_pillar_tall.png"), "%s right pillar uses tall pillar asset" % label)
		_expect(_sprite_bottom_global_y(left_pillar) == 308.0, "%s left pillar sits into the floor lip" % label)
		_expect(_sprite_bottom_global_y(right_pillar) == 308.0, "%s right pillar sits into the floor lip" % label)
		_expect(left_pillar.position.x == 0.0, "%s left pillar is placed at the arena end" % label)
		_expect(right_pillar.position.x + right_pillar.texture.get_width() == 640.0, "%s right pillar is placed at the arena end" % label)

func _check_clean_drowned_boss_arena(arena: BossArenaBase, label: String) -> void:
	_expect(arena.get_node_or_null("ArenaEnvironment") == null, "%s arena removes boss-specific environment art" % label)
	_expect(arena.get_node_or_null("ParallaxBackground/BgFar/FallbackSprite") != null, "%s arena uses Drowned far background" % label)
	_expect(arena.get_node_or_null("ParallaxBackground/BgMid/Sprite2D") != null, "%s arena keeps Drowned mid background node" % label)
	_expect(arena.get_node_or_null("ParallaxBackground/BgNear/Sprite2D") != null, "%s arena keeps Drowned near background node" % label)
	var bg := arena.get_node("ParallaxBackground/BgFar/FallbackSprite") as AnimatedSprite2D
	_expect(bg.sprite_frames.resource_path.ends_with("drowned_coast_clean_ambient_bg_sprite_frames.tres"), "%s arena uses the clean animated Drowned Coast background" % label)
	var ground := arena.get_node("Ground") as TileMapLayer
	_expect(ground.tile_set.resource_path.ends_with("drowned_coast_clean_preview_tileset.tres"), "%s arena uses the clean Drowned Coast tileset" % label)
	_expect(ground.get_used_cells().size() == 40, "%s arena uses one 20-tile two-layer floor" % label)
	for x in range(20):
		_expect(ground.get_cell_atlas_coords(Vector2i(x, 9)) == Vector2i(0, 0), "%s top floor layer uses normal Drowned tile at x=%d" % [label, x])
		_expect(ground.get_cell_atlas_coords(Vector2i(x, 10)) == Vector2i(1, 0), "%s second floor layer uses cracked Drowned tile at x=%d" % [label, x])
	_expect(arena.get_node_or_null("BoundaryWalls/LeftWallShape") != null, "%s arena keeps left physics wall" % label)
	_expect(arena.get_node_or_null("BoundaryWalls/RightWallShape") != null, "%s arena keeps right physics wall" % label)
	var left_pillar := arena.get_node_or_null("Pillars/LeftTallPillar") as Sprite2D
	var right_pillar := arena.get_node_or_null("Pillars/RightTallPillar") as Sprite2D
	_expect(left_pillar != null and right_pillar != null, "%s arena uses two tall pillar props" % label)
	if left_pillar != null and right_pillar != null:
		_expect(left_pillar.texture.resource_path.ends_with("drowned_boss_pillar_tall.png"), "%s left pillar uses Drowned tall pillar asset" % label)
		_expect(right_pillar.texture.resource_path.ends_with("drowned_boss_pillar_tall.png"), "%s right pillar uses Drowned tall pillar asset" % label)
		_expect(absf(_sprite_bottom_global_y(left_pillar) - 309.0) <= 1.0, "%s left pillar sits into the floor lip" % label)
		_expect(absf(_sprite_bottom_global_y(right_pillar) - 309.0) <= 1.0, "%s right pillar sits into the floor lip" % label)
		_expect(left_pillar.position.x == 0.0, "%s left pillar is placed at the arena end" % label)
		_expect(right_pillar.position.x + right_pillar.texture.get_width() == 640.0, "%s right pillar is placed at the arena end" % label)

func _check_clean_storm_boss_arena(arena: BossArenaBase, label: String) -> void:
	_expect(arena.get_node_or_null("ArenaEnvironment") == null, "%s arena removes boss-specific environment art" % label)
	_expect(arena.get_node_or_null("ParallaxBackground/BgFar/Sprite2D") != null, "%s arena uses Storm far background" % label)
	_expect(arena.get_node_or_null("ParallaxBackground/BgMid/Sprite2D") != null, "%s arena uses Storm mid background" % label)
	_expect(arena.get_node_or_null("ParallaxBackground/BgNear/Sprite2D") != null, "%s arena uses Storm near background" % label)
	var far_bg := arena.get_node("ParallaxBackground/BgFar/Sprite2D") as Sprite2D
	var mid_bg := arena.get_node("ParallaxBackground/BgMid/Sprite2D") as Sprite2D
	var near_bg := arena.get_node("ParallaxBackground/BgNear/Sprite2D") as Sprite2D
	_expect(far_bg.texture.resource_path.ends_with("bg_far_fallback.png"), "%s far layer uses the clean Storm Peaks background" % label)
	_expect(mid_bg.texture.resource_path.ends_with("bg_mid.png"), "%s mid layer uses the clean Storm Peaks background" % label)
	_expect(near_bg.texture.resource_path.ends_with("bg_near.png"), "%s near layer uses the clean Storm Peaks background" % label)
	_expect(far_bg.scale == Vector2(2, 2), "%s far Storm background fills the boss viewport" % label)
	_expect(mid_bg.scale == Vector2(2, 2), "%s mid Storm background fills the boss viewport" % label)
	_expect(near_bg.scale == Vector2(2, 2), "%s near Storm background fills the boss viewport" % label)
	var ground := arena.get_node("Ground") as TileMapLayer
	_expect(ground.tile_set.resource_path.ends_with("storm_peaks_clean_preview_tileset.tres"), "%s arena uses the clean Storm Peaks tileset floor" % label)
	_expect(ground.get_used_cells().size() == 40, "%s arena uses one 20-tile two-layer floor" % label)
	for x in range(20):
		_expect(ground.get_cell_atlas_coords(Vector2i(x, 9)) == Vector2i(0, 0), "%s top floor layer uses normal tile at x=%d" % [label, x])
		_expect(ground.get_cell_atlas_coords(Vector2i(x, 10)) == Vector2i(1, 0), "%s second floor layer uses cracked Storm tile at x=%d" % [label, x])
	_expect(arena.get_node_or_null("BoundaryWalls/LeftWallShape") != null, "%s arena keeps left physics wall" % label)
	_expect(arena.get_node_or_null("BoundaryWalls/RightWallShape") != null, "%s arena keeps right physics wall" % label)
	var left_pillar := arena.get_node_or_null("Pillars/LeftTallPillar") as Sprite2D
	var right_pillar := arena.get_node_or_null("Pillars/RightTallPillar") as Sprite2D
	_expect(left_pillar != null and right_pillar != null, "%s arena uses two tall pillar props" % label)
	if left_pillar != null and right_pillar != null:
		_expect(left_pillar.texture.resource_path.ends_with("storm_boss_pillar_tall.png"), "%s left pillar uses Storm tall pillar asset" % label)
		_expect(right_pillar.texture.resource_path.ends_with("storm_boss_pillar_tall.png"), "%s right pillar uses Storm tall pillar asset" % label)
		_expect(_sprite_bottom_global_y(left_pillar) == 308.0, "%s left pillar sits into the floor lip" % label)
		_expect(_sprite_bottom_global_y(right_pillar) == 308.0, "%s right pillar sits into the floor lip" % label)
		_expect(left_pillar.position.x == 0.0, "%s left pillar is placed at the arena end" % label)
		_expect(right_pillar.position.x + right_pillar.texture.get_width() == 640.0, "%s right pillar is placed at the arena end" % label)

func _sprite_bottom_offset(sprite: AnimatedSprite2D) -> float:
	if sprite == null or sprite.sprite_frames == null:
		return INF
	var animation := sprite.animation
	if not sprite.sprite_frames.has_animation(animation):
		return INF
	var texture := sprite.sprite_frames.get_frame_texture(animation, 0)
	if texture == null:
		return INF
	var visible_bottom := _visible_bottom_y_for_sprite(sprite)
	if visible_bottom < 0:
		return INF
	var texture_size := texture.get_size()
	var local_bottom := visible_bottom - texture_size.y * 0.5 if sprite.centered else visible_bottom
	return sprite.position.y + local_bottom * absf(sprite.scale.y)

func _sprite_floor_y(sprite: AnimatedSprite2D) -> float:
	var visible_bottom := _visible_bottom_y_for_sprite(sprite)
	if visible_bottom < 0:
		return INF
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
	var texture_size := texture.get_size()
	var local_bottom := visible_bottom - texture_size.y * 0.5 if sprite.centered else visible_bottom
	return sprite.global_position.y + local_bottom * absf(sprite.global_scale.y)

func _visible_bottom_y_for_sprite(sprite: AnimatedSprite2D) -> float:
	if sprite == null or sprite.sprite_frames == null:
		return -1.0
	if not sprite.sprite_frames.has_animation(sprite.animation):
		return -1.0
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
	if texture == null:
		return -1.0
	return _visible_bottom_y(texture)

func _visible_bottom_y(texture: Texture2D) -> float:
	var image := texture.get_image()
	if image == null:
		return -1.0
	var bottom := -1
	for y in image.get_height():
		var scan_y := image.get_height() - 1 - y
		for x in image.get_width():
			if image.get_pixel(x, scan_y).a > 0.05:
				bottom = scan_y
				break
		if bottom >= 0:
			break
	return float(bottom)

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
	var health_bar := hud.get_node("%HealthBar") as ProgressBar
	var skill_bar := hud.get_node("%SkillBar") as ProgressBar
	var health_value_label := hud.get_node("%HealthValueLabel") as Label
	var skill_value_label := hud.get_node("%SkillValueLabel") as Label
	var character_label := hud.get_node("%CharacterLabel") as Label
	var status_title_label := hud.get_node("%StatusTitleLabel") as Label
	var status_value_label := hud.get_node("%StatusValueLabel") as Label

	kira.take_damage(25.0)
	await process_frame
	_expect(is_equal_approx(health_bar.value, 75.0), "HUD health bar follows Kira health")
	_expect(health_value_label.text == "75/100", "HUD health value shows current and max HP")

	kira._use_skill()
	await process_frame
	hud._process(0.0)
	_expect(skill_bar.value < 100.0, "HUD skill cooldown bar updates")
	_expect(skill_value_label.text.ends_with("%"), "HUD skill value shows cooldown percent")
	_expect(status_title_label.text == "AREA", "HUD status title shows active area type")
	_expect(status_value_label.text == "Ember Fields 1", "HUD status value shows active map level")

	var switcher := get_root().get_node_or_null("CharacterSwitcher")
	if switcher and switcher.has_method("set_active"):
		switcher.set_active(1)
		await process_frame
		var marina := main.get_node("EmberFields/Party/Marina") as Marina
		marina.take_damage(10.0)
		await process_frame
		_expect(character_label.text == "Marina", "HUD character label follows active switch")
		_expect(health_value_label.text == "90/100", "HUD health value follows switched character")

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
	_expect(not main.get_node("PartyIndicator").visible, "Party switch HUD is hidden on title screen")
	_expect(main.get_node_or_null("RespawnNotice") != null, "Main scene has respawn notice UI")
	_expect(not main.get_node("RespawnNotice").visible, "Respawn notice is hidden on title screen")
	_expect(main.get_node_or_null("DialoguePopup") != null, "Main scene has dialogue popup UI")
	var api_client := get_root().get_node_or_null("GenshinAPIClient")
	_expect(api_client != null and api_client.has_method("request_dialogue_line"), "Genshin API client exposes quote popup dialogue requests")
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
	_expect(main.get_node("PartyIndicator").visible, "Start shows party switch HUD")
	_expect(area != null and area.visible, "Start loads Ember Fields")
	_expect((main.get_node("PartyIndicator").get_node("%LivesHearts") as LivesHearts).remaining_lives() == 5, "Map flow starts with five heart lives")
	_expect(main.get_node("HUD").get_node_or_null("%LivesValueLabel") == null, "Lives are not shown as level text in the HUD")
	_expect((main.get_node("HUD").get_node("%StatusTitleLabel") as Label).text == "AREA", "HUD status identifies normal map levels")
	_expect((main.get_node("HUD").get_node("%StatusValueLabel") as Label).text == "Ember Fields 1", "HUD status starts on Ember Fields level 1")
	_expect((main.get_node("DialoguePopup").get_node("%QuoteLabel") as RichTextLabel).text.find("embers") >= 0, "Area entry shows a dialogue quote popup")
	_expect(main.get_node_or_null("DrownedCoast") == null, "Start does not load Drowned Coast")
	_expect(get_root().get_viewport().get_camera_2d() == area.get_node("Party/Camera2D"), "Start makes Ember Fields camera current")
	_expect((main.get_node("GameOverScreen/Panel/ExitButton") as Button).text == "Main Menu", "Game-over menu action is clearly labeled")

	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	main._input(escape)
	await process_frame
	_expect(main.get_node("PauseScreen").visible, "Escape opens pause screen during gameplay")
	_expect(main.get_node_or_null("EmberFields") != null, "Pause keeps active area loaded")
	_expect((main.get_node("PauseScreen/Panel/Margins/Rows/ResumeButton") as Button).text == "Resume", "Pause menu has Resume")
	_expect((main.get_node("PauseScreen/Panel/Margins/Rows/StartOverButton") as Button).text == "Start Over", "Pause menu has Start Over")
	_expect((main.get_node("PauseScreen/Panel/Margins/Rows/PauseQuitButton") as Button).text == "Quit", "Pause menu has Quit")

	var resume_button := main.get_node("PauseScreen/Panel/Margins/Rows/ResumeButton") as Button
	var pause_click := InputEventMouseButton.new()
	pause_click.button_index = MOUSE_BUTTON_LEFT
	pause_click.position = resume_button.global_position + resume_button.size * 0.5
	pause_click.pressed = true
	main._input(pause_click)
	await process_frame
	_expect(not main.get_node("PauseScreen").visible, "Resume hides pause screen")
	_expect(area.process_mode == Node.PROCESS_MODE_INHERIT, "Resume restores active area processing")

	main._input(escape)
	await process_frame
	var start_over_button := main.get_node("PauseScreen/Panel/Margins/Rows/StartOverButton") as Button
	pause_click = InputEventMouseButton.new()
	pause_click.button_index = MOUSE_BUTTON_LEFT
	pause_click.position = start_over_button.global_position + start_over_button.size * 0.5
	pause_click.pressed = true
	main._input(pause_click)
	await process_frame
	area = main.get_node("EmberFields") as AreaBase
	kira = area.get_player()
	_expect(not main.get_node("PauseScreen").visible, "Start Over hides pause screen")
	_expect(main.get_node("HUD").visible, "Start Over keeps HUD visible")
	_expect(main.get_node("PartyIndicator").visible, "Start Over keeps party switch HUD visible")

	var first_grunt := area.get_node("Enemies/Grunt") as Grunt
	var enemy_spawn := first_grunt.get_spawn_position()
	first_grunt.take_damage(999.0, "pyro")
	_expect(first_grunt.collision_layer == 0, "Defeated Grunt is removed from active play")

	kira.global_position = Vector2(kira.global_position.x, 640.0)
	await _wait_for_failure_resolution()
	_expect(not main.get_node("GameOverScreen").visible, "Falling uses checkpoint respawn instead of game-over screen")
	_expect(kira.global_position.y < 520.0, "Falling respawns Kira above the fall limit")
	_expect((main.get_node("PartyIndicator").get_node("%LivesHearts") as LivesHearts).remaining_lives() == 4, "Falling empties one heart life")
	_expect(main.get_node("RespawnNotice").visible, "Falling shows respawn notice while returning to checkpoint")
	_expect((main.get_node("RespawnNotice").get_node("%TitleLabel") as Label).text == "Respawning", "Respawn notice has clear title")
	_expect((main.get_node("RespawnNotice").get_node("%BodyLabel") as Label).text.find("4/5") >= 0, "Respawn notice shows remaining lives")

	for expected_lives in [3, 2, 1]:
		kira = area.get_player()
		kira.global_position = Vector2(kira.global_position.x, 640.0)
		await _wait_for_failure_resolution()
		_expect(not main.get_node("GameOverScreen").visible, "Checkpoint respawn continues while lives remain")
		_expect((main.get_node("PartyIndicator").get_node("%LivesHearts") as LivesHearts).remaining_lives() == expected_lives, "Map-flow heart lives count down to %d" % expected_lives)

	kira = area.get_player()
	kira.global_position = Vector2(kira.global_position.x, 640.0)
	await _wait_for_failure_resolution()
	_expect(main.get_node("GameOverScreen").visible, "Fifth failure shows run-failed screen")
	_expect((main.get_node("GameOverScreen/Panel/GameOverTitleLabel") as Label).text == "Run Failed", "Run-failed screen has clear title")
	_expect((main.get_node("GameOverScreen/Panel/RestartButton") as Button).text == "Start Over", "Life exhaustion restarts the map flow")
	_expect((main.get_node("GameOverScreen/Panel/GameOverBodyLabel") as Label).text.find("Ember Fields Level 1") >= 0, "Life exhaustion points to current map-flow start")

	main.call("_on_restart_button_pressed")
	await process_frame
	await process_frame
	area = main.get_node("EmberFields") as AreaBase
	kira = area.get_player()
	_expect(area != null and area.visible, "Map-flow start over reloads Ember Fields")
	_expect((main.get_node("PartyIndicator").get_node("%LivesHearts") as LivesHearts).remaining_lives() == 5, "Map-flow start over refills five heart lives")

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
		_expect((main.get_node("DialoguePopup").get_node("%SpeakerLabel") as Label).text == "Ryne", "Party switch shows the active character quote")

	await _complete_stage(area)
	main.call("_on_restart_button_pressed")
	await process_frame
	await process_frame
	var boss_area := main.get_node("EmberFieldsBoss1Arena") as BossArenaBase
	var boss := boss_area.get_node("Enemies/Boss") as BossBase
	_expect((main.get_node("HUD").get_node("%StatusTitleLabel") as Label).text == "BOSS", "HUD status identifies boss arenas")
	_expect((main.get_node("HUD").get_node("%StatusValueLabel") as Label).text == "Flame Warden", "HUD status shows current boss name")
	boss.take_damage(40.0, "pyro")
	var boss_player := boss_area.get_player()
	boss_player.take_damage(9999.0)
	await _wait_for_failure_resolution()
	_expect(not main.get_node("GameOverScreen").visible, "Lost boss fight respawns instead of ending immediately")
	_expect(main.get_node_or_null("EmberFieldsBoss1Arena") == boss_area, "Lost boss fight keeps the same boss arena loaded")
	_expect(is_equal_approx(boss_area.get_player().current_health, boss_area.get_player().max_health), "Lost boss fight restores player health")
	_expect(is_equal_approx(boss.current_health, boss.max_health), "Lost boss fight resets boss health for another attempt")
	_expect((main.get_node("PartyIndicator").get_node("%LivesHearts") as LivesHearts).remaining_lives() == 4, "Lost boss fight empties one heart life")
	_expect((main.get_node("RespawnNotice").get_node("%StageLabel") as Label).text.find("BOSS") >= 0, "Boss loss respawn notice identifies boss retry")

	main.call("_restart_game")
	await process_frame
	await process_frame
	area = main.get_node("EmberFields") as AreaBase
	if switcher and switcher.has_method("set_active"):
		switcher.set_active(2)

	var stage_nodes: Array[String] = [
		"EmberFields",
		"EmberFieldsBoss1Arena",
		"EmberFieldsLevel2",
		"EmberFieldsBoss2Arena",
		"EmberFieldsLevel3",
		"EmberFieldsBoss3Arena",
		"EmberFieldsLevel4",
		"EmberFieldsBoss4Arena",
		"EmberFieldsLevel5",
		"EmberFieldsBoss5Arena",
		"DrownedCoast",
		"DrownedCoastBoss1Arena",
		"DrownedCoastLevel2",
		"DrownedCoastBoss2Arena",
		"DrownedCoastLevel3",
		"DrownedCoastBoss3Arena",
		"DrownedCoastLevel4",
		"DrownedCoastBoss4Arena",
		"DrownedCoastLevel5",
		"DrownedCoastBoss5Arena",
		"StormPeaks",
		"StormPeaksBoss1Arena",
		"StormPeaksLevel2",
		"StormPeaksBoss2Arena",
		"StormPeaksLevel3",
		"StormPeaksBoss3Arena",
		"StormPeaksLevel4",
		"StormPeaksBoss4Arena",
		"StormPeaksLevel5",
		"StormPeaksBoss5Arena",
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
		"Drowned Coast Level 1",
		"Tide Warden",
		"Drowned Coast Level 2",
		"Reef Serpent",
		"Drowned Coast Level 3",
		"Abyss Caller",
		"Drowned Coast Level 4",
		"Maelstrom Sentinel",
		"Drowned Coast Level 5",
		"Drowned Leviathan",
		"Storm Peaks Level 1",
		"Storm Harbinger",
		"Storm Peaks Level 2",
		"Thunder Ravager",
		"Storm Peaks Level 3",
		"Arc Sentinel",
		"Storm Peaks Level 4",
		"Tempest Colossus",
		"Storm Peaks Level 5",
		"Storm Sovereign",
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

	var storm_peaks := main.get_node("StormPeaksBoss5Arena") as AreaBase
	await _complete_stage(storm_peaks)
	_expect(main.get_node("GameOverScreen").visible, "Storm Sovereign clear shows final area-clear screen")
	_expect((main.get_node("GameOverScreen/Panel/RestartButton") as Button).text == "Restart", "Final area-clear button restarts run")
	_expect((main.get_node("GameOverScreen/Panel/GameOverBodyLabel") as Label).text.find("Storm Sovereign") >= 0, "Final area-clear text names Storm Sovereign")

	main.call("_restart_game")
	await process_frame
	await process_frame
	_expect(not main.get_node("GameOverScreen").visible, "Restart hides area-clear screen")
	area = main.get_node("EmberFields") as AreaBase
	_expect(area.visible, "Restart after final clear loads Ember Fields")
	_expect(main.get_node_or_null("DrownedCoast") == null, "Restart after final clear unloads Drowned Coast")
	_expect(main.get_node_or_null("StormPeaks") == null, "Restart after final clear unloads Storm Peaks")
	_expect(main.get_node_or_null("StormPeaksBoss5Arena") == null, "Restart after final clear unloads Storm Sovereign")
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

func _wait_for_failure_resolution(frames: int = 30) -> void:
	for _frame in frames:
		await physics_frame
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

func _sprite_bottom_global_y(sprite: Sprite2D) -> float:
	var texture := sprite.texture
	if texture == null:
		return sprite.global_position.y
	var texture_height := float(texture.get_height())
	var visible_bottom := texture_height
	var image := texture.get_image()
	if image != null:
		var used_rect := image.get_used_rect()
		if used_rect.size.y > 0:
			visible_bottom = float(used_rect.position.y + used_rect.size.y)
	if sprite.centered:
		visible_bottom -= texture_height * 0.5
	return sprite.global_position.y + visible_bottom * sprite.global_scale.y

func _check_ember_fields_route(area: Node, tile_layer: TileMapLayer, kira: Kira) -> void:
	var platforms: Array[Vector3i] = [
		Vector3i(3, 12, 14),
		Vector3i(22, 10, 12),
		Vector3i(39, 8, 12),
		Vector3i(56, 12, 12),
		Vector3i(73, 12, 14),
	]
	var jumps: Array[Vector2i] = []
	for index in range(platforms.size()):
		var platform := platforms[index]
		var start := Vector2i(platform.x, platform.y)
		var end := Vector2i(platform.x + platform.z - 1, platform.y)
		_expect(tile_layer.get_cell_source_id(start) != -1, "Ember Fields sketch platform starts at %s" % start)
		_expect(tile_layer.get_cell_source_id(end) != -1, "Ember Fields sketch platform ends at %s" % end)
		_expect(tile_layer.get_cell_source_id(start + Vector2i(0, 1)) != -1, "Ember Fields sketch platform has orange cracked second layer at %s" % (start + Vector2i(0, 1)))
		_expect(tile_layer.get_cell_source_id(end + Vector2i(0, 1)) != -1, "Ember Fields sketch platform has orange cracked second layer at %s" % (end + Vector2i(0, 1)))
		_expect(tile_layer.get_cell_source_id(start + Vector2i(0, 2)) == -1, "Ember Fields sketch platform uses only two tile layers at %s" % start)
		_expect(tile_layer.get_cell_source_id(end + Vector2i(0, 2)) == -1, "Ember Fields sketch platform uses only two tile layers at %s" % end)
		if index > 0:
			var previous := platforms[index - 1]
			jumps.append(Vector2i(previous.x + previous.z - 1, previous.y))
			jumps.append(start)
	_check_jump_pairs_are_reachable(jumps, kira, "Ember Fields")

	_expect((area.get_node("CheckpointMid") as Node2D).position == Vector2(1424, 208), "Ember Fields mid checkpoint is floor-aligned on the elite platform")
	_expect((area.get_node("CheckpointPreGoal") as Node2D).position == Vector2(2384, 336), "Ember Fields pre-goal checkpoint is floor-aligned on the final platform")
	_expect(area.get_node_or_null("CheckpointStart") == null, "Ember Fields start uses only the route flag, not a checkpoint marker")
	_expect((area.get_node("StartPoint/StartFlagVisual") as Sprite2D).texture != null, "Ember Fields start uses flag art")
	_expect((area.get_node("EndFlag/Sprite2D") as Sprite2D).texture != null, "Ember Fields goal uses flag art")
	_expect(_sprite_bottom_global_y(area.get_node("StartPoint/StartFlagVisual") as Sprite2D) == 388.0, "Ember Fields start flag sits into the floor lip")
	_expect(_sprite_bottom_global_y(area.get_node("EndFlag/Sprite2D") as Sprite2D) == 388.0, "Ember Fields goal flag sits into the floor lip")
	_expect((area.get_node("StartPoint") as Node2D).position == Vector2(160, 336), "Ember Fields start spawn sits inside the first platform")
	_expect((area.get_node("Party") as Node2D).position == Vector2(160, 336), "Ember Fields party starts inside the first platform")
	_expect((area.get_node("StartPoint/StartFlagVisual") as Sprite2D).global_position.x == 96.0, "Ember Fields start flag begins on the first platform edge")
	_expect(_sprite_bottom_global_y(area.get_node("CheckpointMid/Visual") as Sprite2D) == 268.0, "Ember Fields mid checkpoint sits into the floor lip")
	_expect(_sprite_bottom_global_y(area.get_node("CheckpointPreGoal/Visual") as Sprite2D) == 396.0, "Ember Fields pre-goal checkpoint sits into the floor lip")
	_expect(((area.get_node("CheckpointMid") as Checkpoint).inactive_texture as Texture2D).resource_path.ends_with("ember_fields_checkpoint_active.png"), "Ember Fields mid checkpoint uses active fire marker art")
	_expect(((area.get_node("CheckpointPreGoal") as Checkpoint).inactive_texture as Texture2D).resource_path.ends_with("ember_fields_checkpoint_saved.png"), "Ember Fields pre-goal checkpoint uses distinct saved marker art")
	_expect((area.get_node("EndFlag") as Node2D).position == Vector2(2608, 352), "Ember Fields flag sits on the final platform")
	_expect((area.get_node("Party/Camera2D") as Camera2D).limit_right >= 2816, "Ember Fields camera covers sketch route")
	_expect((area.get_node("Enemies/Grunt") as Grunt).get_spawn_position().is_equal_approx(Vector2(896, 272)), "First Grunt is on the first floating platform")
	_expect((area.get_node("Enemies/EmberFieldsElite") as Node2D).position.is_equal_approx(Vector2(1440, 208)), "Magma Guard elite is on the high center platform")
	_expect((area.get_node("Enemies/Grunt2") as Grunt).get_spawn_position().is_equal_approx(Vector2(1952, 336)), "Second Grunt is on the post-elite low platform")
	_expect((area.get_node("Enemies/Grunt3") as Grunt).get_spawn_position().is_equal_approx(Vector2(2528, 336)), "Third Grunt guards the goal platform")

func _check_storm_peaks_route(area: Node, tile_layer: TileMapLayer, kira: Kira) -> void:
	var platforms: Array[Vector3i] = [
		Vector3i(3, 12, 14),
		Vector3i(22, 10, 12),
		Vector3i(39, 8, 12),
		Vector3i(56, 12, 12),
		Vector3i(73, 12, 14),
	]
	var jumps: Array[Vector2i] = []
	for platform in platforms:
		_expect(tile_layer.get_cell_source_id(Vector2i(platform.x, platform.y)) != -1, "Storm Peaks platform starts at %s" % Vector2i(platform.x, platform.y))
		_expect(tile_layer.get_cell_source_id(Vector2i(platform.x + platform.z - 1, platform.y)) != -1, "Storm Peaks platform ends at %s" % Vector2i(platform.x + platform.z - 1, platform.y))
		_expect(tile_layer.get_cell_atlas_coords(Vector2i(platform.x, platform.y)) == Vector2i(0, 0), "Storm Peaks first layer uses normal tile at %s" % Vector2i(platform.x, platform.y))
		_expect(tile_layer.get_cell_atlas_coords(Vector2i(platform.x, platform.y + 1)) == Vector2i(1, 0), "Storm Peaks second layer uses cracked tile at %s" % Vector2i(platform.x, platform.y + 1))
		_expect(tile_layer.get_cell_source_id(Vector2i(platform.x, platform.y + 2)) == -1, "Storm Peaks platform uses only two tile layers at %s" % Vector2i(platform.x, platform.y))
	for index in range(1, platforms.size()):
		var previous := platforms[index - 1]
		var current := platforms[index]
		jumps.append(Vector2i(previous.x + previous.z - 1, previous.y))
		jumps.append(Vector2i(current.x, current.y))
	_check_jump_pairs_are_reachable(jumps, kira, "Storm Peaks")

	_expect((area.get_node("CheckpointMid") as Node2D).position == Vector2(1424, 208), "Storm Peaks mid checkpoint matches Ember/Drowned Level 1")
	_expect((area.get_node("CheckpointPreGoal") as Node2D).position == Vector2(2384, 336), "Storm Peaks pre-goal checkpoint matches Ember/Drowned Level 1")
	_expect((area.get_node("EndFlag") as Node2D).position == Vector2(2608, 352), "Storm Peaks flag sits on the matching final platform")
	_expect((area.get_node("Party/Camera2D") as Camera2D).limit_right >= 2816, "Storm Peaks camera covers matching Level 1 route")
	_expect((area.get_node("Enemies/Grunt") as Grunt).get_spawn_position().is_equal_approx(Vector2(896, 272)), "Storm Peaks first Grunt matches the Level 1 normal enemy slot")
	_expect((area.get_node("Enemies/EliteStormCaster") as Node2D).position.is_equal_approx(Vector2(1440, 208)), "Storm Peaks elite matches the Level 1 elite slot")
	_expect((area.get_node("Enemies/Grunt2") as Grunt).get_spawn_position().is_equal_approx(Vector2(1952, 336)), "Storm Peaks second Grunt matches the Level 1 normal enemy slot")
	_expect((area.get_node("Enemies/Grunt3") as Grunt).get_spawn_position().is_equal_approx(Vector2(2528, 336)), "Storm Peaks third Grunt matches the Level 1 normal enemy slot")

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

func _count_enemy_scene(area: Node, scene_path: String) -> int:
	var count := 0
	for enemy in area.get_node("Enemies").get_children():
		if enemy.scene_file_path == scene_path:
			count += 1
	return count

func _enemies_have_floor_below(area: Node) -> bool:
	var enemies := area.get_node("Enemies")
	var world: World2D = area.get_world_2d()
	if enemies == null or world == null:
		return false
	for enemy in enemies.get_children():
		if not (enemy is EnemyBase):
			continue
		var ray_start := (enemy as EnemyBase).global_position - Vector2(0.0, 32.0)
		var ray_end := (enemy as EnemyBase).global_position + Vector2(0.0, PhysicsModel.TILE_SIZE_PX * 5.0)
		var query := PhysicsRayQueryParameters2D.create(ray_start, ray_end, WORLD_LAYER, [enemy])
		var hit: Dictionary = world.direct_space_state.intersect_ray(query)
		if hit.is_empty():
			return false
	return true

func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_failures.append(message)
		print("FAIL: %s" % message)
