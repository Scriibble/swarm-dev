class_name CorePulseRuntime
extends AbilityRuntime

var player_cooldown: float = 0.0

func tick(delta: float) -> void:
	super.tick(delta)
	player_cooldown = maxf(player_cooldown - delta, 0.0)
	if caster == null or not is_instance_valid(caster):
		return
	var core := caster.get_tree().get_first_node_in_group("objective") as Node2D
	if core == null:
		return
	var pulse_range := data.range + float(rank - 1) * 10.0 + (40.0 if evolved else 0.0)
	var damage: int = caster.core_pulse_damage + (10 if evolved else 0)
	damage = int(round(float(damage) * float(GameManager.demon_modifiers.get("core_effectiveness", 1.0))))
	var pulse_cooldown := scaled_cooldown()
	var dual_pulse := bool(GameManager.demon_modifiers.get("dual_core_pulse", false))
	if dual_pulse and player_cooldown <= 0.0:
		_emit_pulse(caster.global_position, pulse_range, damage)
		var player_cooldown_multiplier := float(GameManager.demon_modifiers.get("player_core_pulse_cooldown_multiplier", 0.5))
		player_cooldown = pulse_cooldown * player_cooldown_multiplier
	if cooldown <= 0.0:
		_emit_pulse(core.global_position, pulse_range, damage)
		cooldown = pulse_cooldown

func _emit_pulse(origin: Vector2, pulse_range: float, damage: int) -> void:
	for enemy in caster.get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy.global_position.distance_to(origin) <= pulse_range:
			enemy.take_damage(damage)
	EventBus.ability_activated.emit(data.id, origin)
