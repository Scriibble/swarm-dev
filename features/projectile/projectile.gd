extends Area2D

var velocity: Vector2 = Vector2.ZERO
var damage: int = 8
var lifetime: float = 2.0
var remaining_hits: int = 1
var projectile_color := Color("ff6b35")
var projectile_size: float = 1.0
var trail_color := Color(1.0, 0.35, 0.12, 0.55)
var effect_id: StringName = &"ember_bolt"
var _sprite: AnimatedSprite2D

func _ready() -> void:
	_sprite = get_node_or_null("Visual") as AnimatedSprite2D
	_sprite.sprite_frames = GeneratedArt.effect_frames(effect_id)
	_sprite.play("default")

func setup(origin: Vector2, direction: Vector2, damage_amount: int) -> void:
	global_position = origin
	velocity = direction.normalized() * 300.0
	damage = damage_amount
	rotation = velocity.angle()
	remaining_hits = 1

func setup_extended(origin: Vector2, direction: Vector2, damage_amount: int, pierce: int, color: Color, speed: float, life: float, size: float = 1.0, trail: Color = Color(1.0, 0.35, 0.12, 0.55)) -> void:
	setup(origin, direction, damage_amount)
	velocity = direction.normalized() * speed
	lifetime = life
	remaining_hits = maxi(pierce, 1)
	projectile_color = color
	projectile_size = size
	trail_color = trail
	_set_effect(effect_id)

func set_effect_id(value: StringName) -> void:
	effect_id = value
	_set_effect(effect_id)

func _set_effect(value: StringName) -> void:
	if _sprite == null:
		return
	_sprite.sprite_frames = GeneratedArt.effect_frames(value)
	_sprite.play("default")
	_sprite.scale = Vector2.ONE * projectile_size

func _physics_process(delta: float) -> void:
	if velocity.length_squared() > 0.01:
		rotation = velocity.angle()
	position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	for body in get_overlapping_bodies():
		if body.is_in_group("arena_obstacle") or body.is_in_group("objective"):
			queue_free()
			return
		if body.has_method("take_damage") and body.is_in_group("enemies"):
			body.take_damage(damage)
			remaining_hits -= 1
			if remaining_hits <= 0:
				queue_free()
				return
