class_name EnemyVfxEffect
extends Node2D

## Lightweight one-shot animated enemy VFX spawned from SpriteFrames resources.

static func spawn(
	parent: Node,
	sprite_frames: SpriteFrames,
	animation: StringName,
	world_position: Vector2,
	flip_h: bool = false,
	scale_value: Vector2 = Vector2.ONE,
	z: int = 9
) -> AnimatedSprite2D:
	if parent == null or sprite_frames == null:
		return null
	var sprite := AnimatedSprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.sprite_frames = sprite_frames
	sprite.animation = animation
	sprite.autoplay = String(animation)
	sprite.global_position = world_position
	sprite.flip_h = flip_h
	sprite.scale = scale_value
	sprite.z_index = z
	sprite.animation_finished.connect(sprite.queue_free, CONNECT_ONE_SHOT)
	parent.add_child(sprite)
	sprite.play(animation)
	if sprite_frames.has_animation(animation) and sprite_frames.get_animation_loop(animation):
		var duration := _animation_duration(sprite_frames, animation)
		if duration > 0.0:
			sprite.get_tree().create_timer(duration, false).timeout.connect(_free_instance_if_valid.bind(sprite.get_instance_id()), CONNECT_ONE_SHOT)
	return sprite

static func _animation_duration(sprite_frames: SpriteFrames, animation: StringName) -> float:
	var speed := sprite_frames.get_animation_speed(animation)
	if speed <= 0.0:
		return 0.0
	var frame_count := sprite_frames.get_frame_count(animation)
	var duration := 0.0
	for frame_index in frame_count:
		duration += sprite_frames.get_frame_duration(animation, frame_index) / speed
	return duration

static func _free_instance_if_valid(sprite_id: int) -> void:
	var sprite := instance_from_id(sprite_id) as AnimatedSprite2D
	if sprite != null:
		sprite.queue_free()
