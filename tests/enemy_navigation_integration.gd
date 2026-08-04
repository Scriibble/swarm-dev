extends Node

const MAIN_SCENE: PackedScene = preload("res://levels/main.tscn")
const ENEMY_SCENE: PackedScene = preload("res://entities/enemy/enemy.tscn")
const CORE_POSITION := Vector2(720, 470)

var main_scene: Node2D

func _ready() -> void:
	main_scene = MAIN_SCENE.instantiate()
	add_child(main_scene)
	await _wait_for_world()
	var arena := main_scene.get("arena_generator") as ArenaGenerator
	var initial_positions: Array[Vector2] = []
	var enemies: Array[CharacterBody2D] = []
	var soldier_total := 0
	var orc_total := 0
	for index in mini(36, arena.spawn_points.size()):
		var enemy := ENEMY_SCENE.instantiate() as CharacterBody2D
		main_scene.add_child(enemy)
		enemy.position = arena.spawn_points[index]
		var data := EnemyData.new()
		var is_orc := index % 2 == 1
		if is_orc:
			orc_total += 1
		else:
			soldier_total += 1
		data.id = &"orc_navigation_test" if is_orc else &"soldier_navigation_test"
		data.max_health = 1000
		data.move_speed = 31.0 if is_orc else 43.0
		data.player_aggro_range = 240.0 if is_orc else 0.0
		data.contact_damage = 0
		data.attack_interval = 999.0
		data.texture = null
		enemy.setup(data)
		(enemy.get_node("NavigationAgent2D") as NavigationAgent2D).set_navigation_map(arena.get_navigation_map())
		enemies.append(enemy)
		initial_positions.append(enemy.global_position)
	var failures: Array[String] = []
	for _frame in 240:
		await get_tree().physics_frame
		for enemy in enemies:
			if is_instance_valid(enemy) and not arena.is_position_navigable(enemy.global_position):
				failures.append("enemy entered obstacle at %s" % enemy.global_position)
				break
		if not failures.is_empty():
			break
	var moved_count := 0
	var moved_soldiers := 0
	var moved_orcs := 0
	for index in enemies.size():
		if is_instance_valid(enemies[index]) and enemies[index].global_position.distance_to(initial_positions[index]) > 24.0:
			moved_count += 1
			if index % 2 == 1:
				moved_orcs += 1
			else:
				moved_soldiers += 1
	if moved_count < maxi(1, enemies.size() * 3 / 4):
		failures.append("only %d/%d enemies made meaningful progress toward the core" % [moved_count, enemies.size()])
	if moved_soldiers < maxi(1, soldier_total * 3 / 4):
		failures.append("only %d/%d soldiers made meaningful progress" % [moved_soldiers, soldier_total])
	if moved_orcs < maxi(1, orc_total * 3 / 4):
		failures.append("only %d/%d orcs made meaningful progress" % [moved_orcs, orc_total])
	main_scene.free()
	await get_tree().physics_frame
	if failures.is_empty():
		print("enemy navigation integration test passed: %d agents routed safely" % enemies.size())
		get_tree().quit(0)
		return
	for failure in failures:
		push_error(failure)
	get_tree().quit(1)

func _wait_for_world() -> void:
	for _frame in 180:
		await get_tree().physics_frame
		if main_scene.get("arena_generator") != null and main_scene.get("player") != null:
			return
	push_error("main scene did not finish building the navigation world")
	get_tree().quit(1)
