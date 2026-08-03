extends Node

const TEST_SAVE_PATH := "user://infernal_swarm_integration_profile.save"
const ALL_ABILITIES: Array[StringName] = [
	&"ember_bolt", &"blood_orbit", &"core_pulse", &"area_hazard",
	&"bone_spear", &"chain_lash", &"imp_swarm", &"life_drain"
]
var last_ability_activated: StringName = &""

func _ready() -> void:
	EventBus.ability_activated.connect(_on_ability_activated)
	await _run_integration_suite()
	get_tree().quit()

func _on_ability_activated(ability_id: StringName, _position: Vector2) -> void:
	last_ability_activated = ability_id

func _run_integration_suite() -> void:
	ProfileManager.configure_save_path_for_testing(TEST_SAVE_PATH)
	ProfileManager.reset_profile_for_development()
	assert(ProfileManager.currency == 0, "Development profile reset must clear currency")
	assert(not ProfileManager.can_purchase(&"demon_bulwark"), "Locked demon must require currency")

	ProfileManager.currency = 1000
	assert(ProfileManager.purchase_unlock(&"demon_bulwark"), "Core Bulwark purchase should succeed")
	assert(ProfileManager.select_demon(&"demon_bulwark"), "Unlocked demon should be selectable")
	ProfileManager.unlocked_abilities = ALL_ABILITIES.duplicate()
	ProfileManager.save_profile()
	ProfileManager.currency = 0
	ProfileManager.selected_demon_id = &"demon_summoner"
	ProfileManager.load_profile()
	assert(ProfileManager.currency == 950, "Profile load must restore saved currency")
	assert(ProfileManager.selected_demon_id == &"demon_bulwark", "Profile load must restore demon selection")

	var main_scene := preload("res://levels/main.tscn").instantiate()
	add_child(main_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(GameManager.run_state == GameManager.RunState.PLAYING, "Main scene must start a run")
	assert(GameManager.active_demon_id == &"demon_bulwark", "Run must use the selected demon")
	var player: CharacterBody2D = main_scene.get("player")
	var core: StaticBody2D = main_scene.get("core")
	assert(player != null and core != null, "Run must create player and core")

	var elapsed_before_pause := GameManager.elapsed_time
	GameManager.set_paused(true)
	assert(GameManager.run_state == GameManager.RunState.PAUSED, "Pause must update run state")
	GameManager.tick_run(10.0)
	assert(is_equal_approx(GameManager.elapsed_time, elapsed_before_pause), "Paused run time must not advance")
	GameManager.set_paused(false)
	assert(GameManager.run_state == GameManager.RunState.PLAYING, "Resume must restore playing state")

	GameManager.add_xp(GameManager.xp_to_next)
	assert(GameManager.run_state == GameManager.RunState.LEVEL_UP, "XP threshold must request a level-up")
	assert(GameManager.current_offers.size() == 3, "Level-up must offer three upgrades")
	var selected_offer: UpgradeData = GameManager.current_offers[0]
	GameManager.choose_upgrade(selected_offer)
	player.apply_upgrade(selected_offer)
	assert(GameManager.run_state == GameManager.RunState.PLAYING, "Choosing an upgrade must resume the run")
	assert(selected_offer.id in GameManager.selected_upgrade_ids, "Chosen upgrade must be recorded")

	for ability_id in ALL_ABILITIES:
		var ability_upgrade := UpgradeData.new()
		ability_upgrade.id = ability_id
		ability_upgrade.target_id = ability_id
		ability_upgrade.offer_type = &"ability"
		ability_upgrade.rank_increment = 1
		GameManager.choose_upgrade(ability_upgrade)
		player.apply_upgrade(ability_upgrade)
		assert(player.ability_runtimes.has(ability_id), "Ability runtime missing: %s" % ability_id)
		assert(player.has_ability(ability_id), "Ability rank missing: %s" % ability_id)

	var evolution := UpgradeData.new()
	evolution.id = &"inferno_bolt"
	evolution.target_id = &"ember_bolt"
	evolution.offer_type = &"evolution"
	evolution.evolution_id = &"inferno_bolt"
	GameManager.choose_upgrade(evolution)
	player.apply_upgrade(evolution)
	assert(&"ember_bolt" in GameManager.evolved_abilities, "Evolution must be recorded")
	assert(player.ability_runtimes[&"ember_bolt"].evolved, "Evolution must activate runtime behavior")

	player.global_position = core.global_position + Vector2(-120, 0)
	player.test_aim_direction = Vector2.RIGHT
	for ability_id in ALL_ABILITIES:
		for runtime in player.ability_runtimes.values():
			runtime.cooldown = 999.0
		var enemy := preload("res://entities/enemy/enemy.tscn").instantiate()
		main_scene.add_child(enemy)
		var enemy_data := EnemyData.new()
		enemy_data.id = &"integration_target"
		enemy_data.max_health = 10000
		enemy_data.move_speed = 0.0
		enemy_data.contact_damage = 0
		enemy_data.attack_interval = 999.0
		enemy_data.texture = null
		enemy.position = core.global_position + Vector2(-70, 0)
		enemy.setup(enemy_data)
		last_ability_activated = &""
		var runtime = player.ability_runtimes[ability_id]
		runtime.cooldown = 0.0
		runtime.tick(0.1)
		assert(last_ability_activated == ability_id, "Ability did not activate: %s" % ability_id)
		enemy.queue_free()

	var runs_before_defeat := ProfileManager.lifetime_runs
	player.take_damage(999999)
	assert(GameManager.run_state == GameManager.RunState.DEFEAT, "Player defeat must end the run")
	assert(ProfileManager.lifetime_runs == runs_before_defeat + 1, "Defeat must award and save a run result")
	main_scene.queue_free()
	await get_tree().process_frame

	var core_scene := preload("res://levels/main.tscn").instantiate()
	add_child(core_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	var test_core: StaticBody2D = core_scene.get("core")
	test_core.take_damage(999999)
	assert(GameManager.run_state == GameManager.RunState.DEFEAT, "Core destruction must end the run")
	core_scene.queue_free()
	await get_tree().process_frame

	var victory_scene := preload("res://levels/main.tscn").instantiate()
	add_child(victory_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	GameManager.elapsed_time = 600.0
	GameManager.finish_run(true)
	assert(GameManager.run_state == GameManager.RunState.VICTORY, "Victory must end the run")
	victory_scene.queue_free()
	await get_tree().process_frame

	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))
	ProfileManager.configure_save_path_for_testing("")
	ProfileManager.load_profile()
	print("lifecycle integration test passed: pause, upgrades, abilities, evolution, defeat, victory, rewards, and persistence")
