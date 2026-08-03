class_name DemonBalanceRunResult
extends RefCounted

var demon_id: StringName
var seed: int
var victory := false
var survival_seconds := 0.0
var core_health_ratio := 0.0
var demon_health_ratio := 0.0
var kills := 0
var kills_per_minute := 0.0
var level := 1
var first_level_seconds := -1.0
var reward_shards := 0
var ability_activations: Dictionary = {}
var ability_damage: Dictionary = {}
var upgrades: Array[StringName] = []
var evolutions: Array[StringName] = []
var runtime_errors: Array[String] = []

func to_dictionary() -> Dictionary:
	return {
		"demon_id": String(demon_id),
		"seed": seed,
		"victory": victory,
		"survival_seconds": survival_seconds,
		"core_health_ratio": core_health_ratio,
		"demon_health_ratio": demon_health_ratio,
		"kills": kills,
		"kills_per_minute": kills_per_minute,
		"level": level,
		"first_level_seconds": first_level_seconds,
		"reward_shards": reward_shards,
		"ability_activations": ability_activations,
		"ability_damage": ability_damage,
		"upgrades": _string_array(upgrades),
		"evolutions": _string_array(evolutions),
		"runtime_errors": runtime_errors,
	}

func _string_array(values: Array[StringName]) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(String(value))
	return result
