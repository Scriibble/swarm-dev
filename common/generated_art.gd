class_name GeneratedArt
extends RefCounted

const CHARACTER_ACTIONS := {
	"idle": {"count": 4, "fps": 5.0, "loop": true},
	"walk": {"count": 6, "fps": 9.0, "loop": true},
	"attack": {"count": 4, "fps": 12.0, "loop": false},
	"hurt": {"count": 4, "fps": 14.0, "loop": false},
	"death": {"count": 6, "fps": 9.0, "loop": false},
}

const EFFECT_ACTION := {"count": 4, "fps": 16.0, "loop": false}

static func character_frames(bundle: StringName) -> SpriteFrames:
	var frames := SpriteFrames.new()
	_remove_default_animation(frames)
	for action_name in CHARACTER_ACTIONS:
		var action: Dictionary = CHARACTER_ACTIONS[action_name]
		_add_animation(frames, String(action_name), "res://assets/generated/characters/%s/%s/%s-%d.png" % [bundle, action_name, action_name, 1], int(action["count"]), float(action["fps"]), bool(action["loop"]))
	return frames

static func effect_frames(effect_id: StringName) -> SpriteFrames:
	var frames := SpriteFrames.new()
	_remove_default_animation(frames)
	_add_animation(frames, "default", "res://assets/generated/effects/%s/%s-%d.png" % [effect_id, effect_id, 1], int(EFFECT_ACTION["count"]), float(EFFECT_ACTION["fps"]), false)
	return frames

static func character_sprite(bundle: StringName) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = character_frames(bundle)
	sprite.animation = &"idle"
	sprite.play()
	sprite.centered = true
	return sprite

static func effect_sprite(effect_id: StringName) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = effect_frames(effect_id)
	sprite.animation = &"default"
	sprite.play()
	sprite.centered = true
	return sprite

static func prop_sprite(prop_id: StringName) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/generated/props/infernal-arena/%s/prop.png" % prop_id)
	sprite.centered = true
	return sprite

static func _remove_default_animation(frames: SpriteFrames) -> void:
	if frames.has_animation("default"):
		frames.remove_animation("default")

static func _add_animation(frames: SpriteFrames, animation_name: String, first_path: String, count: int, fps: float, loops: bool) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, loops)
	var prefix := first_path.trim_suffix("1.png")
	for index in range(1, count + 1):
		var texture := load(prefix + "%d.png" % index) as Texture2D
		if texture != null:
			frames.add_frame(animation_name, texture)
