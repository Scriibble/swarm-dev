class_name DemonBalanceEvaluator
extends Node

const MAIN_SCENE: PackedScene = preload("res://levels/main.tscn")
const TEST_TIME_SCALE := 60.0
const TEST_PLAYER_HEALTH := 100000

var _current_result: DemonBalanceRunResult
var _connected := false
var _test_profile_path := ""

func _ready() -> void:
	_connect_events()

func evaluate_batch(demon_ids: Array[StringName], seeds: Array[int], overrides: Dictionary = {}) -> Array[DemonBalanceRunResult]:
	Engine.time_scale = TEST_TIME_SCALE
	_test_profile_path = "user://demon_balance_agent_profile_%d.save" % OS.get_process_id()
	ProfileManager.configure_save_path_for_testing(_test_profile_path)
	ProfileManager.reset_profile_for_development()
	ProfileManager.balance_candidate_overrides = overrides.duplicate(true)
	GameManager.suppress_balance_log = true
	var results: Array[DemonBalanceRunResult] = []
	for demon_id in demon_ids:
		for seed in seeds:
			results.append(await evaluate_run(demon_id, seed, overrides))
	_cleanup_isolated_state()
	return results

func evaluate_run(demon_id: StringName, seed: int, overrides: Dictionary = {}) -> DemonBalanceRunResult:
	_current_result = DemonBalanceRunResult.new()
	_current_result.demon_id = demon_id
	_current_result.seed = seed
	ProfileManager.selected_demon_id = demon_id
	ProfileManager.balance_candidate_overrides = overrides.duplicate(true)
	GameManager.forced_run_seed = seed
	var main_scene := MAIN_SCENE.instantiate()
	add_child(main_scene)
	await _wait_for_world(main_scene)
	var player: CharacterBody2D = main_scene.get("player")
	var core: StaticBody2D = main_scene.get("core")
	if player == null or core == null:
		_current_result.runtime_errors.append("run scene did not create player and core")
		main_scene.queue_free()
		await get_tree().process_frame
		return _current_result
	player.max_health = TEST_PLAYER_HEALTH
	player.health = TEST_PLAYER_HEALTH
	player.test_aim_direction = Vector2.RIGHT
	var safety_frames := 0
	while GameManager.run_state not in [GameManager.RunState.VICTORY, GameManager.RunState.DEFEAT] and safety_frames < 7000:
		_autoplay_frame(main_scene)
		safety_frames += 1
		await get_tree().process_frame
	if GameManager.run_state not in [GameManager.RunState.VICTORY, GameManager.RunState.DEFEAT]:
		_current_result.runtime_errors.append("run exceeded safety frame budget")
	_current_result.victory = GameManager.run_state == GameManager.RunState.VICTORY
	_current_result.survival_seconds = GameManager.elapsed_time
	_current_result.core_health_ratio = clampf(float(GameManager.core_health) / float(maxi(GameManager.core_max_health, 1)), 0.0, 1.0)
	_current_result.demon_health_ratio = clampf(float(player.health) / float(maxi(player.max_health, 1)), 0.0, 1.0)
	_current_result.kills = GameManager.kills
	_current_result.kills_per_minute = float(GameManager.kills) / maxf(GameManager.elapsed_time / 60.0, 0.01)
	_current_result.level = GameManager.level
	_current_result.first_level_seconds = GameManager.level_up_times[0] if not GameManager.level_up_times.is_empty() else -1.0
	_current_result.reward_shards = int(GameManager.last_run_summary.split("SHARDS +")[-1]) if "SHARDS +" in GameManager.last_run_summary else 0
	_current_result.upgrades = GameManager.selected_upgrade_ids.duplicate()
	_current_result.evolutions = GameManager.evolution_selections.duplicate()
	main_scene.queue_free()
	await get_tree().process_frame
	GameManager.forced_run_seed = -1
	return _current_result

func _wait_for_world(main_scene: Node) -> void:
	for _frame in 180:
		await get_tree().physics_frame
		if main_scene.get("player") != null and main_scene.get("core") != null:
			return

func _autoplay_frame(main_scene: Node) -> void:
	get_tree().paused = false
	if GameManager.run_state == GameManager.RunState.LEVEL_UP:
		if not GameManager.current_offers.is_empty():
			var player = main_scene.get("player")
			var choice: UpgradeData = _choose_balance_upgrade(GameManager.current_offers)
			GameManager.choose_upgrade(choice)
			if player and player.has_method("apply_upgrade"):
				player.apply_upgrade(choice)
		return
	if GameManager.run_state != GameManager.RunState.PLAYING:
		return
	var player = main_scene.get("player")
	var core = get_tree().get_first_node_in_group("objective")
	if player == null or core == null:
		return
	var nearest: Node2D
	var nearest_distance := 999999.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var distance: float = core.global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = enemy
	if nearest:
		var enemy_direction: Vector2 = core.global_position.direction_to(nearest.global_position)
		player.global_position = core.global_position + enemy_direction * 240.0
		player.test_aim_direction = player.global_position.direction_to(nearest.global_position)
	else:
		player.global_position = core.global_position + Vector2(0, 200)

func _choose_balance_upgrade(offers: Array[UpgradeData]) -> UpgradeData:
	var best: UpgradeData = offers[0]
	var best_score := -999999.0
	for offer in offers:
		var score := float(offer.rarity) * 10.0
		if offer.offer_type == &"evolution":
			score += 100.0
		elif offer.offer_type == &"ability":
			score += 50.0
			if offer.target_id == &"ember_bolt":
				score += 20.0
		elif offer.stat == &"attack_damage":
			score += 35.0
		elif offer.stat == &"cooldown":
			score += 30.0
		elif offer.stat == &"core_health":
			score += 25.0
		elif offer.stat == &"max_health":
			score += 15.0
		if score > best_score:
			best_score = score
			best = offer
	return best

func _connect_events() -> void:
	if _connected:
		return
	_connected = true
	EventBus.ability_activated.connect(_on_ability_activated)
	EventBus.ability_damage_dealt.connect(_on_ability_damage_dealt)

func _on_ability_activated(ability_id: StringName, _position: Vector2) -> void:
	if _current_result == null:
		return
	var key := String(ability_id)
	_current_result.ability_activations[key] = int(_current_result.ability_activations.get(key, 0)) + 1

func _on_ability_damage_dealt(ability_id: StringName, amount: int, _target_id: StringName) -> void:
	if _current_result == null:
		return
	var key := String(ability_id)
	_current_result.ability_damage[key] = int(_current_result.ability_damage.get(key, 0)) + amount

func _cleanup_isolated_state() -> void:
	Engine.time_scale = 1.0
	GameManager.forced_run_seed = -1
	GameManager.suppress_balance_log = false
	ProfileManager.balance_candidate_overrides.clear()
	if not _test_profile_path.is_empty() and FileAccess.file_exists(_test_profile_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_test_profile_path))
	ProfileManager.configure_save_path_for_testing("")
	ProfileManager.load_profile()
