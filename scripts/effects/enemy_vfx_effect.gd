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
	return sprite
