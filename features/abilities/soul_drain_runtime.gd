class_name SoulDrainRuntime
extends AbilityRuntime

func tick(delta: float) -> void:
	super.tick(delta)
	if cooldown > 0.0 or caster == null or not is_instance_valid(caster):
		return
	var targets := enemies_in_range(data.range + float(rank - 1) * 15.0)
	if targets.is_empty():
		return
	targets.sort_custom(func(a: Node2D, b: Node2D) -> bool: return caster.global_position.distance_squared_to(a.global_position) < caster.global_position.distance_squared_to(b.global_position))
	var target: Node2D = targets[0]
	var damage := scaled_damage()
	target.take_damage(damage)
	caster.heal(maxi(1, int(round(float(damage) * data.heal_ratio * (1.25 if GameManager.active_demon_id == &"demon_harbinger" else 1.0)))))
	var beam := GeneratedArt.effect_sprite(&"soul_drain")
	var distance := caster.global_position.distance_to(target.global_position)
	beam.position = caster.global_position.lerp(target.global_position, 0.5)
	beam.rotation = caster.global_position.angle_to_point(target.global_position)
	beam.scale = Vector2(maxf(distance / 64.0, 0.8), 0.75)
	beam.z_index = 8
	caster.get_tree().current_scene.add_child(beam)
	var tween := beam.create_tween()
	tween.tween_property(beam, "modulate:a", 0.0, 0.25)
	tween.tween_callback(beam.queue_free)
	cooldown = scaled_cooldown()
	EventBus.ability_activated.emit(data.id, caster.global_position)
