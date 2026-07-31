class_name BoneSpearRuntime
extends AbilityRuntime

const PROJECTILE_SCENE: PackedScene = preload("res://features/projectile/projectile.tscn")

func tick(delta: float) -> void:
	super.tick(delta)
	if cooldown > 0.0 or caster == null or not is_instance_valid(caster):
		return
	var direction: Vector2 = caster.last_direction.normalized()
	var projectile := PROJECTILE_SCENE.instantiate()
	caster.get_tree().current_scene.add_child(projectile)
	projectile.setup_extended(caster.global_position + direction * 24.0, direction, scaled_damage(), 5 if evolved else data.pierce_count + 1, Color("d8d4ec"), 440.0, 0.8)
	cooldown = scaled_cooldown()
	EventBus.ability_activated.emit(data.id, caster.global_position)
