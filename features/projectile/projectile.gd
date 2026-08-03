extends Area2D

var velocity: Vector2 = Vector2.ZERO
var damage: int = 8
var lifetime: float = 2.0
var remaining_hits: int = 1
var projectile_color := Color("ff6b35")
var projectile_size: float = 1.0
var trail_color := Color(1.0, 0.35, 0.12, 0.55)
var ability_id: StringName = &""

func setup(origin: Vector2, direction: Vector2, damage_amount: int) -> void:
	global_position = origin
	velocity = direction.normalized() * 300.0
	damage = damage_amount
	rotation = velocity.angle()
	remaining_hits = 1

func setup_extended(origin: Vector2, direction: Vector2, damage_amount: int, pierce: int, color: Color, speed: float, life: float, size: float = 1.0, trail: Color = Color(1.0, 0.35, 0.12, 0.55), source_ability_id: StringName = &"") -> void:
	setup(origin, direction, damage_amount)
	velocity = direction.normalized() * speed
	lifetime = life
	remaining_hits = maxi(pierce, 1)
	projectile_color = color
	projectile_size = size
	trail_color = trail
	ability_id = source_ability_id
	queue_redraw()

func _physics_process(delta: float) -> void:
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
			if ability_id != &"":
				var event_bus := get_node_or_null("/root/EventBus")
				if event_bus:
					event_bus.ability_damage_dealt.emit(ability_id, damage, StringName(body.get("data").id if body.get("data") != null else "enemy"))
			remaining_hits -= 1
			if remaining_hits <= 0:
				queue_free()
				return

func _draw() -> void:
	var direction := Vector2.RIGHT.rotated(rotation)
	draw_line(-direction * 18.0 * projectile_size, -direction * 4.0 * projectile_size, trail_color, 4.0 * projectile_size)
	draw_circle(Vector2.ZERO, 7.0 * projectile_size, projectile_color)
	draw_circle(direction * 3.0 * projectile_size, 3.0 * projectile_size, Color("fff1c4"))
