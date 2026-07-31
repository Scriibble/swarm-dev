extends Node

const DEMONS: Array[StringName] = [&"demon_summoner", &"demon_bulwark", &"demon_harbinger"]

func _ready() -> void:
	Engine.time_scale = 20.0
	_run_all_demons.call_deferred()

func _run_all_demons() -> void:
	for demon_id in DEMONS:
		get_tree().paused = false
		var main_scene := preload("res://levels/main.tscn").instantiate()
		add_child(main_scene)
		await get_tree().process_frame
		await get_tree().process_frame
		ProfileManager.selected_demon_id = demon_id
		GameManager.start_run()
		var safety_frames := 0
		while GameManager.run_state not in [GameManager.RunState.VICTORY, GameManager.RunState.DEFEAT] and safety_frames < 7000:
			_autoplay_frame(main_scene)
			safety_frames += 1
			await get_tree().process_frame
		print("BALANCE %s | state=%s | elapsed=%.1f | %s | levels=%s | upgrades=%s | evolutions=%s" % [demon_id, GameManager.run_state, GameManager.elapsed_time, GameManager.last_run_summary, GameManager.level_up_times, GameManager.selected_upgrade_ids, GameManager.evolution_selections])
		main_scene.queue_free()
		await get_tree().process_frame
	Engine.time_scale = 1.0
	get_tree().quit()

func _autoplay_frame(main_scene: Node) -> void:
	get_tree().paused = false
	if GameManager.run_state == GameManager.RunState.LEVEL_UP:
		if not GameManager.current_offers.is_empty():
			var player = main_scene.get("player")
			var choice: UpgradeData = GameManager.current_offers[0]
			GameManager.choose_upgrade(choice)
			if player and player.has_method("apply_upgrade"):
				player.apply_upgrade(choice)
		get_tree().paused = false
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
		player.global_position = core.global_position + core.global_position.direction_to(nearest.global_position) * 250.0
		player.last_direction = player.global_position.direction_to(nearest.global_position)
	else:
		player.global_position = core.global_position + Vector2(0, 200)
