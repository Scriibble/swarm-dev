extends Node

signal currency_changed(amount: int)
signal unlock_purchased(unlock_id: StringName)
signal profile_loaded
signal save_completed

const SAVE_PATH := "user://profile.save"
const SAVE_VERSION := 2

var save_path_override: String = ""
var balance_candidate_overrides: Dictionary = {}
var currency: int = 0
var unlocked_demons: Array[StringName] = [&"demon_summoner"]
var unlocked_abilities: Array[StringName] = [&"ember_bolt", &"blood_orbit", &"core_pulse"]
var unlocked_passives: Array[StringName] = [&"emberheart", &"cinder_step", &"core_ward"]
var lifetime_kills: int = 0
var lifetime_runs: int = 0
var lifetime_victories: int = 0
var lifetime_survival_seconds: int = 0
var selected_demon_id: StringName = &"demon_summoner"

func _ready() -> void:
	if OS.is_debug_build() and "--reset-profile" in OS.get_cmdline_args():
		reset_profile_for_development()
	else:
		load_profile()

func load_profile() -> void:
	if not FileAccess.file_exists(_save_path()):
		profile_loaded.emit()
		return
	var file := FileAccess.open(_save_path(), FileAccess.READ)
	if file == null:
		profile_loaded.emit()
		return
	var parsed = file.get_var()
	if parsed is Dictionary:
		currency = maxi(int(parsed.get("currency", 0)), 0)
		unlocked_demons = _validated_unlocks(parsed.get("unlocked_demons", unlocked_demons), unlocked_demons)
		unlocked_abilities = _validated_unlocks(parsed.get("unlocked_abilities", unlocked_abilities), unlocked_abilities)
		unlocked_passives = _validated_unlocks(parsed.get("unlocked_passives", unlocked_passives), unlocked_passives)
		lifetime_kills = maxi(int(parsed.get("lifetime_kills", 0)), 0)
		lifetime_runs = maxi(int(parsed.get("lifetime_runs", 0)), 0)
		lifetime_victories = maxi(int(parsed.get("lifetime_victories", 0)), 0)
		lifetime_survival_seconds = maxi(int(parsed.get("lifetime_survival_seconds", 0)), 0)
		selected_demon_id = StringName(parsed.get("selected_demon_id", "demon_summoner"))
	profile_loaded.emit()

func save_profile() -> void:
	var file := FileAccess.open(_save_path(), FileAccess.WRITE)
	if file:
		file.store_var({
			"version": SAVE_VERSION,
			"currency": currency,
			"unlocked_demons": unlocked_demons,
			"unlocked_abilities": unlocked_abilities,
			"unlocked_passives": unlocked_passives,
			"lifetime_kills": lifetime_kills,
			"lifetime_runs": lifetime_runs,
			"lifetime_victories": lifetime_victories,
			"lifetime_survival_seconds": lifetime_survival_seconds,
			"selected_demon_id": selected_demon_id,
		})
		save_completed.emit()

func reset_profile_for_development() -> bool:
	if not OS.is_debug_build():
		return false
	if FileAccess.file_exists(_save_path()):
		var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(_save_path()))
		if error != OK:
			return false
	_reset_defaults()
	profile_loaded.emit()
	return true

func configure_save_path_for_testing(path: String) -> void:
	save_path_override = path

func _save_path() -> String:
	return save_path_override if not save_path_override.is_empty() else SAVE_PATH

func _reset_defaults() -> void:
	currency = 0
	unlocked_demons = [&"demon_summoner"]
	unlocked_abilities = [&"ember_bolt", &"blood_orbit", &"core_pulse"]
	unlocked_passives = [&"emberheart", &"cinder_step", &"core_ward"]
	lifetime_kills = 0
	lifetime_runs = 0
	lifetime_victories = 0
	lifetime_survival_seconds = 0
	selected_demon_id = &"demon_summoner"

func get_catalog() -> Dictionary:
	var result := {"demons": {}, "abilities": {}, "passives": {}}
	for demon in RogueliteCatalog.demon_data():
		var effective_demon := DemonBalanceConfig.apply_to_demon(demon, DemonBalanceConfig.applied_override(demon.id))
		result.demons[effective_demon.id] = {"title": effective_demon.display_name, "description": effective_demon.description, "kind": "demon", "cost": effective_demon.cost, "prerequisites": effective_demon.prerequisites, "starting_abilities": effective_demon.starting_abilities, "starting_passives": effective_demon.starting_passives}
	for ability in RogueliteCatalog.ability_data():
		result.abilities[ability.id] = {"title": ability.display_name, "description": _ability_description(ability), "kind": "ability", "cost": ability.cost, "prerequisites": ability.prerequisites}
	for passive in RogueliteCatalog.passive_data():
		result.passives[passive.id] = {"title": passive.display_name, "description": passive.description, "kind": "passive", "cost": passive.cost, "prerequisites": passive.prerequisites}
	return result

func get_starting_loadout() -> Dictionary:
	var demon := RogueliteCatalog.demon_by_id(selected_demon_id)
	if demon == null:
		demon = RogueliteCatalog.demon_by_id(&"demon_summoner")
	var override := Dictionary(balance_candidate_overrides.get(demon.id, DemonBalanceConfig.applied_override(demon.id)))
	var effective_demon := DemonBalanceConfig.apply_to_demon(demon, override)
	return {"demon_id": effective_demon.id, "abilities": effective_demon.starting_abilities, "passives": effective_demon.starting_passives, "modifiers": effective_demon.modifiers}

func select_demon(demon_id: StringName) -> bool:
	if demon_id not in unlocked_demons:
		return false
	selected_demon_id = demon_id
	save_profile()
	return true

func can_purchase(unlock_id: StringName) -> bool:
	var entry := _find_unlock(unlock_id)
	if entry.is_empty() or _is_unlocked(unlock_id):
		return false
	for prerequisite in entry.get("prerequisites", []):
		if not _is_unlocked(StringName(prerequisite)):
			return false
	return currency >= int(entry.get("cost", 0))

func purchase_unlock(unlock_id: StringName) -> bool:
	if not can_purchase(unlock_id):
		return false
	var entry := _find_unlock(unlock_id)
	currency -= int(entry.get("cost", 0))
	match StringName(entry.get("kind", "ability")):
		&"demon": unlocked_demons.append(unlock_id)
		&"ability": unlocked_abilities.append(unlock_id)
		&"passive": unlocked_passives.append(unlock_id)
	unlock_purchased.emit(unlock_id)
	currency_changed.emit(currency)
	save_profile()
	return true

func apply_run_reward(reward: RunReward) -> void:
	currency += reward.currency_awarded
	lifetime_kills += reward.kills
	lifetime_runs += 1
	lifetime_victories += 1 if reward.victory else 0
	lifetime_survival_seconds += reward.survival_seconds
	currency_changed.emit(currency)
	save_profile()

func _is_unlocked(unlock_id: StringName) -> bool:
	return unlock_id in unlocked_demons or unlock_id in unlocked_abilities or unlock_id in unlocked_passives

func _find_unlock(unlock_id: StringName) -> Dictionary:
	return get_catalog().get("demons", {}).get(unlock_id, get_catalog().get("abilities", {}).get(unlock_id, get_catalog().get("passives", {}).get(unlock_id, {})))

func _validated_unlocks(value: Variant, defaults: Array[StringName]) -> Array[StringName]:
	var result: Array[StringName] = []
	if value is Array:
		for item in value:
			result.append(StringName(item))
	for default_id in defaults:
		if default_id not in result:
			result.append(default_id)
	return result

func _ability_description(ability: AbilityData) -> String:
	match ability.behavior_type:
		&"bone_spear": return "Large mouse-directed projectile that pierces invaders."
		&"chain_lash": return "Lashes between nearby invaders with falling damage."
		&"soul_drain": return "Drains a nearby invader and restores demon health."
	return ability.display_name + " power."
