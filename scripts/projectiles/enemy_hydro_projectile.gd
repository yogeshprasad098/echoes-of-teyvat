class_name EnemyHydroProjectile
extends Area2D

const PhysicsModel := preload("res://scripts/core/game_physics.gd")
const DROWNED_ELITE_VFX_FRAMES := preload("res://resources/sprite_frames/drowned_coast_reef_tidecaller_vfx_sprite_frames.tres")
const ENEMY_VFX := preload("res://scripts/effects/enemy_vfx_effect.gd")

@export var damage: float = 12.0
@export var speed: float = PhysicsModel.TILE_SIZE_PX * 5.0
@export var lifetime_sec: float = 3.0
@export var impact_vfx_frames: SpriteFrames = DROWNED_ELITE_VFX_FRAMES
@export var projectile_animation: StringName = &"bubble_orb"
@export var impact_animation: StringName = &"large_splash_hit"
@export var impact_scale: Vector2 = Vector2.ONE

@onready var sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var lifetime_timer: Timer = %LifetimeTimer

var _direction: Vector2 = Vector2.RIGHT
var _released: bool = false

func _ready() -> void:
	collision_layer = PhysicsModel.PROJECTILE_LAYER
	collision_mask = PhysicsModel.PLAYER_LAYER | PhysicsModel.WORLD_LAYER
	body_entered.connect(_on_body_entered)
	lifetime_timer.timeout.connect(_release)
	lifetime_timer.start(lifetime_sec)
	if sprite:
		sprite.play(projectile_animation)

func launch(start_position: Vector2, direction: Vector2) -> void:
	global_position = start_position
	_direction = direction.normalized()
	if _direction == Vector2.ZERO:
		_direction = Vector2.RIGHT
	if sprite:
		sprite.flip_h = _direction.x < 0.0

func _physics_process(delta: float) -> void:
	global_position += _direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if _released:
		return
	if body is CharacterBase:
		body.take_damage(damage)
		_spawn_impact()
		_release()
	elif body is TileMapLayer or body is TileMap or body is StaticBody2D:
		_spawn_impact()
		_release()

func _spawn_impact() -> void:
	ENEMY_VFX.spawn(
		get_parent(),
		impact_vfx_frames,
		impact_animation,
		global_position,
		false,
		impact_scale,
		11
	)

func _release() -> void:
	if _released:
		return
	_released = true
	queue_free()
