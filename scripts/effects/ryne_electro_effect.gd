class_name RyneElectroEffect
extends Node2D
## Sprite-based one-shot electro VFX for Ryne attacks, impacts, skills, and movement.

const SCENE: PackedScene = preload("res://scenes/effects/ryne_electro_effect.tscn")

@onready var sprite: AnimatedSprite2D = %AnimatedSprite2D

static func spawn_slash(world_position: Vector2, facing: int) -> void:
	spawn_punch_impact_spark(world_position, facing)

static func spawn_impact(world_position: Vector2) -> void:
	spawn_lightning_impact(world_position)

static func spawn_punch_impact_spark(world_position: Vector2, facing: int = 1, visual_scale: float = 0.72) -> void:
	_spawn(world_position, facing, &"punch_impact_spark", visual_scale)

static func spawn_lightning_impact(world_position: Vector2, facing: int = 1, visual_scale: float = 0.58) -> void:
	_spawn(world_position, facing, &"lightning_impact", visual_scale)

static func spawn_electric_burst(world_position: Vector2, facing: int = 1, visual_scale: float = 0.58) -> void:
	_spawn(world_position, facing, &"electric_burst", visual_scale)

static func spawn_shockwave_ring(world_position: Vector2, facing: int = 1, visual_scale: float = 0.62) -> void:
	_spawn(world_position, facing, &"shockwave_ring", visual_scale)

static func spawn_stun_static(world_position: Vector2, facing: int = 1, visual_scale: float = 0.8) -> void:
	_spawn(world_position, facing, &"stun_static", visual_scale)

static func spawn_dodge_afterimage(world_position: Vector2, facing: int = 1, visual_scale: float = 0.72) -> void:
	_spawn(world_position, facing, &"dodge_afterimage", visual_scale)

static func _spawn(world_position: Vector2, facing: int, animation: StringName, visual_scale: float) -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return
	var fx: RyneElectroEffect = null
	var pool := tree.root.get_node_or_null("ProjectilePool")
	if pool and pool.has_method("spawn_projectile"):
		fx = pool.spawn_projectile(SCENE, tree.current_scene, world_position) as RyneElectroEffect
	else:
		fx = SCENE.instantiate() as RyneElectroEffect
		fx.global_position = world_position
		tree.current_scene.add_child(fx)
	if fx:
		fx.play(animation, facing, visual_scale)

func _ready() -> void:
	if sprite:
		sprite.animation_finished.connect(_release)

func reset_projectile() -> void:
	visible = true
	scale = Vector2.ONE
	rotation = 0.0
	modulate = Color.WHITE
	if sprite:
		sprite.visible = true
		sprite.stop()
		sprite.frame = 0

func play(animation: StringName, facing: int = 1, visual_scale: float = 1.0) -> void:
	if sprite == null or sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(animation):
		_release()
		return
	scale = Vector2(visual_scale * float(facing), visual_scale)
	sprite.play(animation)

func _release() -> void:
	var tree := get_tree()
	var pool := tree.root.get_node_or_null("ProjectilePool") if tree else null
	if pool and pool.has_method("release_projectile"):
		pool.release_projectile(self)
	else:
		queue_free()
