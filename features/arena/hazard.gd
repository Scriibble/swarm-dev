extends Area2D

@export var damage: int = 8
@export var lifetime: float = -1.0
@export var evolved: bool = false
var _timer: float = 0.0
var _phase: float = 0.0
var _sprite: AnimatedSprite2D

func _ready() -> void:
	_sprite = $Visual as AnimatedSprite2D
	_sprite.sprite_frames = GeneratedArt.effect_frames(&"hellfire_field")
	_sprite.play("default")
	_sprite.scale = Vector2.ONE * (1.15 if evolved else 0.95)

func _physics_process(delta: float) -> void:
	_phase += delta * (5.0 if evolved else 3.5)
	if lifetime > 0.0:
		lifetime -= delta
		if lifetime <= 0.0:
			queue_free()
			return
	var game_manager := get_node_or_null("/root/GameManager")
	if game_manager == null or game_manager.run_state != game_manager.RunState.PLAYING:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = 0.75
	for body in get_overlapping_bodies():
		if body.has_method("take_damage") and body.is_in_group("player"):
			body.take_damage(damage)
		elif body.has_method("take_damage") and body.is_in_group("enemies"):
			body.take_damage(damage)
