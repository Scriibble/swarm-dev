class_name ChainLashRuntime
extends AbilityRuntime

func tick(delta: float) -> void:
	super.tick(delta)
	if cooldown > 0.0 or caster == null or not is_instance_valid(caster):
		return
	var targets := enemies_in_range(data.range + float(rank - 1) * 12.0)
	if targets.is_empty():
		return
	targets.sort_custom(func(a: Node2D, b: Node2D) -> bool: return caster.global_position.distance_squared_to(a.global_position) < caster.global_position.distance_squared_to(b.global_position))
	var chain: Array[Node2D] = []
	for target in targets:
		if chain.size() >= (7 if evolved else data.chain_count + rank - 1):
			break
		chain.append(target)
	var previous: Vector2 = caster.global_position
	var damage := float(scaled_damage())
	for target in chain:
		target.take_damage(maxi(1, int(round(damage))))
		_spawn_arc(previous, target.global_position)
		previous = target.global_position
		damage *= 0.82 if evolved else data.damage_falloff
	cooldown = scaled_cooldown()
	EventBus.ability_activated.emit(data.id, caster.global_position)

func _spawn_arc(from_point: Vector2, to_point: Vector2) -> void:
	var arc := GeneratedArt.effect_sprite(&"chain_lash")
	var midpoint := from_point.lerp(to_point, 0.5)
	var distance := from_point.distance_to(to_point)
	arc.position = midpoint
	arc.rotation = from_point.angle_to_point(to_point)
	arc.scale = Vector2(maxf(distance / 72.0, 0.8), 0.8 if not evolved else 1.0)
	arc.z_index = 8
	caster.get_tree().current_scene.add_child(arc)
	var tween := arc.create_tween()
	tween.tween_property(arc, "modulate:a", 0.0, 0.22 if evolved else 0.16)
	tween.tween_callback(arc.queue_free)
