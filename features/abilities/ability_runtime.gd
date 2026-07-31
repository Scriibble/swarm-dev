class_name AbilityRuntime
extends Node

var caster: CharacterBody2D
var data: AbilityData
var rank: int = 1
var evolved: bool = false
var cooldown: float = 0.0

func setup(owner_node: CharacterBody2D, ability_data: AbilityData, ability_rank: int, is_evolved: bool) -> void:
	caster = owner_node
	data = ability_data
	rank = ability_rank
	evolved = is_evolved

func tick(delta: float) -> void:
	cooldown = maxf(cooldown - delta, 0.0)

func scaled_damage() -> int:
	return data.base_damage + maxi(rank - 1, 0) * 5 + (8 if evolved else 0)

func scaled_cooldown() -> float:
	return maxf(data.cooldown - float(rank - 1) * 0.07 - float(caster.cooldown_bonus), 0.18)

func enemies_in_range(max_range: float) -> Array[Node2D]:
	var result: Array[Node2D] = []
	if caster == null or not is_instance_valid(caster):
		return result
	for node in caster.get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(node) and caster.global_position.distance_to(node.global_position) <= max_range:
			result.append(node)
	return result
