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
	var beam := Line2D.new()
	beam.points = PackedVector2Array([caster.global_position, target.global_position])
	beam.width = 8.0
	beam.default_color = Color("ff385f")
	beam.begin_cap_mode = Line2D.LINE_CAP_ROUND
	beam.end_cap_mode = Line2D.LINE_CAP_ROUND
	beam.z_index = 8
	caster.get_tree().current_scene.add_child(beam)
	var core_line := Line2D.new()
	core_line.points = PackedVector2Array([caster.global_position, target.global_position])
	core_line.width = 2.0
	core_line.default_color = Color("ffd1d9")
	core_line.z_index = 9
	caster.get_tree().current_scene.add_child(core_line)
	var tween := beam.create_tween()
	tween.tween_property(beam, "modulate:a", 0.0, 0.25)
	tween.tween_callback(beam.queue_free)
	var core_tween := core_line.create_tween()
	core_tween.tween_property(core_line, "modulate:a", 0.0, 0.25)
	core_tween.tween_callback(core_line.queue_free)
	cooldown = scaled_cooldown()
	EventBus.ability_activated.emit(data.id, caster.global_position)
