extends Node

const TEST_PATH := "user://infernal_swarm_profile_migration.save"

func _ready() -> void:
	var failures: Array[String] = []
	ProfileManager.configure_save_path_for_testing(TEST_PATH)
	ProfileManager.reset_profile_for_development()
	ProfileManager.currency = 123
	ProfileManager.unlocked_demons.append(&"demon_bulwark")
	ProfileManager.save_profile()

	var legacy := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	legacy.store_var({
		"version": 2,
		"currency": 123,
		"unlocked_demons": [&"demon_summoner", &"demon_bulwark"],
		"unlocked_abilities": [&"ember_bolt"],
		"unlocked_passives": [&"emberheart", &"pickup_radius"],
		"selected_demon_id": "demon_bulwark",
	})
	legacy = null
	ProfileManager.load_profile()
	if ProfileManager.currency != 123 or &"demon_bulwark" not in ProfileManager.unlocked_demons:
		failures.append("legacy profile fields were not migrated")
	if &"pickup_radius" in ProfileManager.unlocked_passives:
		failures.append("unsupported Grave Magnet progression was not removed")

	var corrupt := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	corrupt.store_string("not a serialized profile")
	corrupt = null
	ProfileManager.currency = 999
	ProfileManager.load_profile()
	if ProfileManager.currency != 0 or ProfileManager.selected_demon_id != &"demon_summoner":
		failures.append("corrupt profile did not recover to a usable fresh profile")
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	ProfileManager.configure_save_path_for_testing("")
	ProfileManager.load_profile()
	if failures.is_empty():
		print("profile migration smoke test passed: legacy and corrupt profiles")
		get_tree().quit(0)
		return
	for failure in failures:
		push_error(failure)
	get_tree().quit(1)
