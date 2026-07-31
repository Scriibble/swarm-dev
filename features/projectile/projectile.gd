extends Area2D

var velocity: Vector2 = Vector2.ZERO
var damage: int = 8
var lifetime: float = 2.0
var remaining_hits: int = 1
var projectile_color := Color("ff6b35")

func setup(origin: Vector2, direction: Vector2, damage_amount: int) -> void:
	global_position = origin
	velocity = direction.normalized() * 300.0
	damage = damage_amount
	rotation = velocity.angle()
	remaining_hits = 1

func setup_extended(origin: Vector2, direction: Vector2, damage_amount: int, pierce: int, color: Color, speed: float, life: float) -> void:
	setup(origin, direction, damage_amount)
	velocity = direction.normalized() * speed
	lifetime = life
	remaining_hits = maxi(pierce, 1)
	projectile_color = color
	queue_redraw()

func _physics_process(delta: float) -> void:
	position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	for body in get_overlapping_bodies():
		if body.has_method("take_damage") and body.is_in_group("enemies"):
			body.take_damage(damage)
			remaining_hits -= 1
			if remaining_hits <= 0:
				queue_free()
				return

func _draw() -> void:
	draw_circle(Vector2.ZERO, 7.0, projectile_color)
	draw_circle(Vector2.ZERO, 3.0, Color("fff1c4"))
