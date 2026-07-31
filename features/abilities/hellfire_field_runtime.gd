class_name HellfireFieldRuntime
extends AbilityRuntime

const HAZARD_SCENE: PackedScene = preload("res://features/arena/hazard.tscn")

func tick(delta: float) -> void:
	super.tick(delta)
	if cooldown > 0.0 or caster == null or not is_instance_valid(caster):
		return
	var core := caster.get_tree().get_first_node_in_group("objective") as Node2D
	if core == null:
		return
	var target := core.global_position
	var nearest_distance := 999999.0
	for enemy in caster.get_tree().get_nodes_in_group("enemies"):
		var distance: float = enemy.global_position.distance_to(core.global_position)
		if distance < nearest_distance and distance <= data.range + float(rank - 1) * 15.0:
			nearest_distance = distance
			target = enemy.global_position
	var hazard := HAZARD_SCENE.instantiate()
	hazard.position = target
	hazard.damage = data.base_damage + rank * 2 + (8 if evolved else 0)
	hazard.lifetime = 3.0 if not evolved else 4.5
	hazard.evolved = evolved
	caster.get_tree().current_scene.add_child(hazard)
	EventBus.ability_activated.emit(data.id, target)
	cooldown = scaled_cooldown()
