class_name DemonBalanceConfig
extends RefCounted

const CONFIG_PATH := "res://common/demon_balance_overrides.json"
const CONFIG_VERSION := 1

static var _applied_cache: Dictionary = {}
static var _cache_loaded := false

static func applied_overrides() -> Dictionary:
	if _cache_loaded:
		return _applied_cache.duplicate(true)
	_cache_loaded = true
	if not FileAccess.file_exists(CONFIG_PATH):
		return {}
	var text := FileAccess.get_file_as_string(CONFIG_PATH)
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary and int(parsed.get("version", 0)) == CONFIG_VERSION:
		_applied_cache = Dictionary(parsed.get("overrides", {})).duplicate(true)
	return _applied_cache.duplicate(true)

static func applied_override(demon_id: StringName) -> Dictionary:
	return Dictionary(applied_overrides().get(String(demon_id), {})).duplicate(true)

static func candidate_from_demon(demon: DemonData) -> Dictionary:
	return {
		"demon_id": String(demon.id),
		"cost": demon.cost,
		"starting_abilities": _string_array(demon.starting_abilities),
		"starting_passives": _string_array(demon.starting_passives),
		"modifiers": _string_key_dictionary(demon.modifiers),
	}

static func validate_candidate(candidate: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var demon_id := String(candidate.get("demon_id", ""))
	if demon_id not in ["demon_summoner", "demon_bulwark", "demon_harbinger"]:
		errors.append("unknown demon_id")
	var cost := int(candidate.get("cost", 0))
	if cost < 0 or cost > 500:
		errors.append("cost must be between 0 and 500")
	var abilities: Array = candidate.get("starting_abilities", [])
	var passives: Array = candidate.get("starting_passives", [])
	if abilities.is_empty() or abilities.size() > 3:
		errors.append("starting_abilities must contain one to three abilities")
	if passives.is_empty() or passives.size() > 6:
		errors.append("starting_passives must contain one to six passives")
	for value in abilities + passives:
		if String(value).is_empty():
			errors.append("starting loadout contains an empty ID")
	for ability_id in abilities:
		if RogueliteCatalog.ability_by_id(StringName(ability_id)) == null:
			errors.append("unknown starting ability: %s" % ability_id)
	for passive_id in passives:
		if RogueliteCatalog.passive_by_id(StringName(passive_id)) == null:
			errors.append("unknown starting passive: %s" % passive_id)
	var modifiers: Dictionary = candidate.get("modifiers", {})
	for key in modifiers:
		var value = modifiers[key]
		if value is float or value is int:
			if not is_finite(float(value)):
				errors.append("modifier %s is not finite" % key)
	return {"valid": errors.is_empty(), "errors": errors}

static func merge_candidate(base: Dictionary, candidate: Dictionary) -> Dictionary:
	var result := base.duplicate(true)
	for key in ["cost", "starting_abilities", "starting_passives"]:
		if candidate.has(key):
			result[key] = candidate[key]
	var modifiers: Dictionary = result.get("modifiers", {}).duplicate(true)
	for key in Dictionary(candidate.get("modifiers", {})):
		modifiers[key] = candidate.modifiers[key]
	result["modifiers"] = modifiers
	return result

static func apply_to_demon(demon: DemonData, override: Dictionary) -> DemonData:
	if override.is_empty():
		return demon
	var result: DemonData = demon.duplicate(true)
	if override.has("cost"):
		result.cost = int(override.cost)
	if override.has("starting_abilities"):
		result.starting_abilities = _string_name_array(override.starting_abilities)
	if override.has("starting_passives"):
		result.starting_passives = _string_name_array(override.starting_passives)
	for key in Dictionary(override.get("modifiers", {})):
		result.modifiers[StringName(key)] = override.modifiers[key]
	return result

static func write_applied_overrides(overrides: Dictionary) -> bool:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"version": CONFIG_VERSION, "overrides": overrides}, "\t"))
	file.close()
	_applied_cache = overrides.duplicate(true)
	_cache_loaded = true
	return true

static func clear_cache() -> void:
	_applied_cache.clear()
	_cache_loaded = false

static func _string_array(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(String(value))
	return result

static func _string_name_array(values: Array) -> Array[StringName]:
	var result: Array[StringName] = []
	for value in values:
		result.append(StringName(value))
	return result

static func _string_key_dictionary(values: Dictionary) -> Dictionary:
	var result := {}
	for key in values:
		result[String(key)] = values[key]
	return result
