extends Node

const DEMONS: Array[StringName] = [&"demon_summoner", &"demon_bulwark", &"demon_harbinger"]
const SEEDS: Array[int] = [424242]

func _ready() -> void:
	var evaluator := DemonBalanceEvaluator.new()
	add_child(evaluator)
	var results: Array[DemonBalanceRunResult] = await evaluator.evaluate_batch(DEMONS, SEEDS, {})
	for result in results:
		assert(result.victory, "%s failed the balance run at seed %d" % [result.demon_id, result.seed])
		assert(result.runtime_errors.is_empty(), "%s reported runtime errors: %s" % [result.demon_id, result.runtime_errors])
		print("BALANCE %s | seed=%d | result=%s | elapsed=%.1f | levels=%d | kills=%d | core=%.0f%% | abilities=%s | damage=%s" % [result.demon_id, result.seed, "VICTORY" if result.victory else "DEFEAT", result.survival_seconds, result.level, result.kills, result.core_health_ratio * 100.0, result.ability_activations, result.ability_damage])
	get_tree().quit()
