extends Node

const TEST_SEEDS: Array[int] = [0, 1, 7, 42, 98765, 424242, 900001, 1900001]
const CORE_POSITION := Vector2(720, 470)

func _ready() -> void:
	await _run_navigation_checks()

func _run_navigation_checks() -> void:
	var failures: Array[String] = []
	for seed in TEST_SEEDS:
		var parent := Node2D.new()
		add_child(parent)
		var generator := ArenaGenerator.new()
		parent.add_child(generator)
		generator.generate(seed, parent, CORE_POSITION)
		if not await generator.wait_for_navigation_ready():
			failures.append("seed %d did not produce a valid synchronized navigation map" % seed)
		else:
			for spawn_point in generator.spawn_points:
				if not generator.navigation_path_exists(spawn_point, CORE_POSITION):
					failures.append("seed %d has no spawn-to-core path from %s" % [seed, spawn_point])
					break
				var path := NavigationServer2D.map_get_path(generator.get_navigation_map(), spawn_point, CORE_POSITION, true)
				for point in path:
					if generator.is_position_blocked(point):
						failures.append("seed %d produced a path inside an obstacle at %s" % [seed, point])
						break
		parent.free()
		await get_tree().physics_frame
	if failures.is_empty():
		print("navigation integration test passed: %d deterministic layouts" % TEST_SEEDS.size())
		get_tree().quit(0)
		return
	for failure in failures:
		push_error(failure)
	get_tree().quit(1)
