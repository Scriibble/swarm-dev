class_name ImpSwarmRuntime
extends AbilityRuntime

const IMP_SCENE: PackedScene = preload("res://features/abilities/imp_projectile.tscn")

func tick(delta: float) -> void:
	super.tick(delta)
	if cooldown > 0.0 or caster == null or not is_instance_valid(caster):
		return
	var count := 3 + mini(rank, 3) + (2 if evolved else 0)
	for index in count:
		var imp := IMP_SCENE.instantiate()
		var angle := float(index) / float(count) * TAU + Time.get_ticks_msec() * 0.001
		caster.get_tree().current_scene.add_child(imp)
		imp.setup(caster.global_position + Vector2.from_angle(angle) * 28.0, caster, data.base_damage + rank * 2 + (6 if evolved else 0), Color("d576ff") if evolved else Color("a44dff"), data.id)
	EventBus.ability_activated.emit(data.id, caster.global_position)
	cooldown = scaled_cooldown()
