class_name ImpProjectile
extends Area2D

var velocity := Vector2.ZERO
var damage: int = 8
var lifetime: float = 2.5
var source: Node2D
var phase: float = 0.0
var ability_id: StringName = &""

func setup(origin: Vector2, source_node: Node2D, damage_amount: int, color: Color, source_ability_id: StringName = &"") -> void:
	global_position = origin
	source = source_node
	damage = damage_amount
	ability_id = source_ability_id
	$Visual.color = color
	queue_redraw()

func _physics_process(delta: float) -> void:
	lifetime -= delta
	phase += delta * 8.0
	queue_redraw()
	if lifetime <= 0.0:
		queue_free()
		return
	var nearest: Node2D
	var nearest_distance := 999999.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var distance: float = global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = enemy
	if nearest:
		velocity = global_position.direction_to(nearest.global_position) * 250.0
	global_position += velocity * delta
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
			queue_free()
			return

func _draw() -> void:
	var pulse := 1.0 + sin(phase) * 0.12
	draw_circle(Vector2.ZERO, 7.0 * pulse, Color("a44dff", 0.22))
	draw_circle(Vector2.ZERO, 3.0, Color("ffe1ff"))
