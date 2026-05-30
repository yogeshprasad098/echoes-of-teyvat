class_name MarinaVfxEffect
extends Node2D
## Sprite-based one-shot hydro VFX for Marina attacks, impacts, and movement accents.

const SCENE: PackedScene = preload("res://scenes/effects/marina_vfx_effect.tscn")

@onready var sprite: AnimatedSprite2D = %AnimatedSprite2D

static func spawn_water_splash_impact(world_position: Vector2, facing: int = 1, visual_scale: float = 0.58) -> void:
	_spawn(world_position, facing, &"water_splash_impact", visual_scale)

static func spawn_water_orb_pop(world_position: Vector2, facing: int = 1, visual_scale: float = 0.58) -> void:
	_spawn(world_position, facing, &"water_orb_pop", visual_scale)

static func spawn_heal_aura(world_position: Vector2, facing: int = 1, visual_scale: float = 0.58) -> void:
	_spawn(world_position, facing, &"heal_aura_skill", visual_scale)

static func spawn_dodge_water_trail(world_position: Vector2, facing: int = 1, visual_scale: float = 0.72) -> void:
	_spawn(world_position, facing, &"dodge_water_trail", visual_scale)

static func _spawn(world_position: Vector2, facing: int, animation: StringName, visual_scale: float) -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return
	var fx: MarinaVfxEffect = null
	var pool := tree.root.get_node_or_null("ProjectilePool")
	if pool and pool.has_method("spawn_projectile"):
		fx = pool.spawn_projectile(SCENE, tree.current_scene, world_position) as MarinaVfxEffect
	else:
		fx = SCENE.instantiate() as MarinaVfxEffect
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
