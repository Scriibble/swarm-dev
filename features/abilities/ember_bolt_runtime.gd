class_name EmberBoltRuntime
extends AbilityRuntime

const PROJECTILE_SCENE: PackedScene = preload("res://features/projectile/projectile.tscn")

func tick(delta: float) -> void:
	super.tick(delta)
	if cooldown > 0.0 or caster == null or not is_instance_valid(caster):
		return
	var direction: Vector2 = caster.last_direction.normalized()
	var projectile := PROJECTILE_SCENE.instantiate()
	caster.get_tree().current_scene.add_child(projectile)
	var color := Color("fff0a6") if evolved else Color("ff6b35")
	var size := 1.35 if evolved else 1.0
	projectile.setup_extended(caster.global_position + direction * 22.0, direction, caster.attack_damage, 1, color, 340.0 if evolved else 300.0, 2.0, size, Color("ffb52e", 0.65))
	cooldown = scaled_cooldown()
	EventBus.ability_activated.emit(data.id, caster.global_position)
