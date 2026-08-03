class_name BloodOrbitRuntime
extends AbilityRuntime

var orbit_angle: float = 0.0

func _ready() -> void:
	queue_redraw()

func tick(delta: float) -> void:
	super.tick(delta)
	orbit_angle = fmod(orbit_angle + delta * (2.6 if evolved else 2.0), TAU)
	queue_redraw()
	if cooldown > 0.0 or caster == null or not is_instance_valid(caster):
		return
	var targets := enemies_in_range(data.range + float(rank - 1) * 12.0)
	if targets.is_empty():
		return
	targets.sort_custom(func(a: Node2D, b: Node2D) -> bool: return caster.global_position.distance_squared_to(a.global_position) < caster.global_position.distance_squared_to(b.global_position))
	var target: Node2D = targets[0]
	var damage: int = caster.orbit_damage + (8 if evolved else 0)
	if GameManager.active_demon_id == &"demon_harbinger" and caster.global_position.distance_to(target.global_position) < 180.0:
		damage = int(round(float(damage) * (1.0 + float(GameManager.demon_modifiers.get("close_damage", 0.0)))))
	target.take_damage(damage)
	record_damage(damage, target)
	EventBus.ability_activated.emit(data.id, target.global_position)
	cooldown = scaled_cooldown()

func _draw() -> void:
	var radius := 34.0 + float(rank) * 3.0
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(0.55, 0.08, 0.22, 0.42), 2.0)
	var orb_position := Vector2.from_angle(orbit_angle) * radius
	draw_circle(orb_position, 8.0 if evolved else 6.0, Color("ff385f") if evolved else Color("b52f63"))
	draw_circle(orb_position, 3.0, Color("ffd1d9"))
	if evolved:
		draw_arc(Vector2.ZERO, radius + 9.0, -orbit_angle, -orbit_angle + PI * 1.35, 18, Color("ffb52e", 0.8), 2.0)
