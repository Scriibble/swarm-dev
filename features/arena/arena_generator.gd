class_name ArenaGenerator
extends Node2D

const CELL_SIZE := 48
const GRID_SIZE := Vector2i(30, 18)
const WORLD_ORIGIN := Vector2(24, 76)
const PLAYER_START := Vector2(720, 610)
const MAX_LAYOUT_ATTEMPTS := 24
const ENEMY_COLLISION_RADIUS := 12.0
const NAVIGATION_CLEARANCE_MARGIN := 6.0
const NAVIGATION_AGENT_RADIUS := ENEMY_COLLISION_RADIUS + NAVIGATION_CLEARANCE_MARGIN
const OBSTACLE_HALF_EXTENT := 22.0
const HAZARD_SCENE: PackedScene = preload("res://features/arena/hazard.tscn")

var grid := AStarGrid2D.new()
var spawn_points: Array[Vector2] = []
var obstacle_cells: Array[Vector2i] = []
var hazard_cells: Array[Vector2i] = []
var navigation_region: NavigationRegion2D
var navigation_polygon: NavigationPolygon
var navigation_map: RID
var navigation_ready := false
var selected_layout_seed := 0
var layout_attempts := 0
var hazard_damage_by_cell: Dictionary = {}
var generated_parent: Node2D
var navigation_validation_failures := 0

func _ready() -> void:
	add_to_group("arena_navigation")

func generate(seed_value: int, parent: Node2D, core_position: Vector2) -> void:
	navigation_ready = false
	navigation_validation_failures = 0
	generated_parent = parent
	_clear_navigation_region()
	selected_layout_seed = seed_value
	_build_spawn_points()
	var accepted := false
	for attempt in range(MAX_LAYOUT_ATTEMPTS):
		var attempt_seed := int(seed_value + attempt * 104729)
		var rng := RandomNumberGenerator.new()
		rng.seed = attempt_seed
		var candidate_obstacles: Array[Vector2i] = []
		var candidate_hazards: Array[Vector2i] = []
		var candidate_hazard_damage: Dictionary = {}
		for y in GRID_SIZE.y:
			for x in GRID_SIZE.x:
				var cell := Vector2i(x, y)
				var center := _cell_center(cell)
				var safe_from_core := center.distance_to(core_position) > 220.0
				var border := x == 0 or y == 0 or x == GRID_SIZE.x - 1 or y == GRID_SIZE.y - 1
				if safe_from_core and not border and rng.randf() < 0.11:
					candidate_obstacles.append(cell)
				elif safe_from_core and not border and rng.randf() < 0.035:
					candidate_hazards.append(cell)
					candidate_hazard_damage[cell] = rng.randi_range(6, 12)
		if _layout_is_connected(candidate_obstacles, core_position):
			obstacle_cells = candidate_obstacles
			hazard_cells = candidate_hazards
			hazard_damage_by_cell = candidate_hazard_damage
			selected_layout_seed = attempt_seed
			layout_attempts = attempt + 1
			accepted = true
			break
	if not accepted:
		# A deterministic empty layout is safer than starting an unwinnable run.
		obstacle_cells.clear()
		hazard_cells.clear()
		hazard_damage_by_cell.clear()
		selected_layout_seed = seed_value
		layout_attempts = MAX_LAYOUT_ATTEMPTS
		push_warning("Arena layout could not satisfy connectivity after %d attempts; using fallback layout." % MAX_LAYOUT_ATTEMPTS)
	_configure_grid()
	_add_generated_geometry(parent)
	_build_navigation_region()

func wait_for_navigation_ready() -> bool:
	if navigation_region == null or not is_instance_valid(navigation_region):
		return false
	await get_tree().physics_frame
	var map := navigation_map
	if not map.is_valid():
		map = navigation_region.get_navigation_map()
		navigation_map = map
	if not map.is_valid():
		return false
	_configure_navigation_map(map)
	await get_tree().process_frame
	# Runtime bakes and region/map attachment are synchronized by the physics
	# server. Always give both sides multiple physics ticks before querying.
	for _frame in range(3):
		await get_tree().physics_frame
	NavigationServer2D.map_force_update(map)
	for _frame in range(2):
		await get_tree().physics_frame
	navigation_ready = _navigation_paths_are_valid(map)
	if not navigation_ready:
		if navigation_validation_failures == 0 and _install_navigation_fallback():
			navigation_validation_failures = 1
			return await wait_for_navigation_ready()
		push_warning("Navigation validation failed for accepted seed %d after fallback." % selected_layout_seed)
	return navigation_ready

func _count_valid_spawn_paths(map: RID) -> int:
	var count := 0
	var core_position := Vector2(720, 470)
	for spawn_point in spawn_points:
		if _path_exists_on_map(map, spawn_point, core_position):
			count += 1
	return count

func get_navigation_map() -> RID:
	return navigation_map

func navigation_path_exists(from_position: Vector2, target_position: Vector2) -> bool:
	var map := get_navigation_map()
	if not map.is_valid():
		return false
	var path := NavigationServer2D.map_get_path(map, from_position, target_position, true)
	return path.size() >= 2

func direction_to_target(from_position: Vector2, target_position: Vector2) -> Vector2:
	# Compatibility helper for deterministic smoke checks. Runtime enemies use
	# NavigationAgent2D; this grid query is intentionally not used for movement.
	var from_cell := _nearest_walkable_cell(_world_to_cell(from_position), _obstacle_dictionary())
	var target_cell := _nearest_walkable_cell(_world_to_cell(target_position), _obstacle_dictionary())
	var path := grid.get_id_path(from_cell, target_cell, true)
	if path.size() >= 2:
		return from_position.direction_to(_cell_center(path[1]))
	return Vector2.ZERO

func is_position_blocked(position: Vector2, radius: float = NAVIGATION_AGENT_RADIUS) -> bool:
	for cell in obstacle_cells:
		var center := _cell_center(cell)
		var closest_point := Vector2(
			clampf(position.x, center.x - OBSTACLE_HALF_EXTENT, center.x + OBSTACLE_HALF_EXTENT),
			clampf(position.y, center.y - OBSTACLE_HALF_EXTENT, center.y + OBSTACLE_HALF_EXTENT)
		)
		if position.distance_squared_to(closest_point) < radius * radius:
			return true
	return false

func is_position_navigable(position: Vector2, radius: float = NAVIGATION_AGENT_RADIUS) -> bool:
	var arena_rect := Rect2(WORLD_ORIGIN, Vector2(GRID_SIZE * CELL_SIZE))
	var safe_rect := arena_rect.grow(-radius)
	return safe_rect.has_point(position) and not is_position_blocked(position, radius)

func _configure_grid() -> void:
	grid = AStarGrid2D.new()
	grid.region = Rect2i(Vector2i.ZERO, GRID_SIZE)
	grid.cell_size = Vector2(CELL_SIZE, CELL_SIZE)
	grid.offset = WORLD_ORIGIN
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	for cell in obstacle_cells:
		grid.set_point_solid(cell, true)

func _obstacle_dictionary() -> Dictionary:
	var blocked: Dictionary = {}
	for cell in obstacle_cells:
		blocked[cell] = true
	return blocked

func _build_spawn_points() -> void:
	spawn_points.clear()
	for x in range(2, GRID_SIZE.x - 2, 3):
		spawn_points.append(_cell_center(Vector2i(x, 0)))
		spawn_points.append(_cell_center(Vector2i(x, GRID_SIZE.y - 1)))
	for y in range(3, GRID_SIZE.y - 3, 3):
		spawn_points.append(_cell_center(Vector2i(0, y)))
		spawn_points.append(_cell_center(Vector2i(GRID_SIZE.x - 1, y)))

func _layout_is_connected(candidate_obstacles: Array[Vector2i], core_position: Vector2) -> bool:
	var blocked: Dictionary = {}
	for cell in candidate_obstacles:
		blocked[cell] = true
	var core_cell := _nearest_walkable_cell(_world_to_cell(core_position), blocked)
	if not _is_walkable(core_cell, blocked):
		return false
	var visited: Dictionary = {core_cell: true}
	var queue: Array[Vector2i] = [core_cell]
	var index := 0
	while index < queue.size():
		var current := queue[index]
		index += 1
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var typed_offset: Vector2i = offset
			var candidate: Vector2i = current + typed_offset
			if _is_walkable(candidate, blocked) and not visited.has(candidate):
				visited[candidate] = true
				queue.append(candidate)
	var required_positions: Array[Vector2] = [PLAYER_START]
	required_positions.append_array(spawn_points)
	for position in required_positions:
		var cell := _nearest_walkable_cell(_world_to_cell(position), blocked)
		if not visited.has(cell):
			return false
	return true

func _is_walkable(cell: Vector2i, blocked: Dictionary) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < GRID_SIZE.x and cell.y < GRID_SIZE.y and not blocked.has(cell)

func _nearest_walkable_cell(cell: Vector2i, blocked: Dictionary) -> Vector2i:
	if _is_walkable(cell, blocked):
		return cell
	for radius in range(1, 4):
		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				var candidate := cell + Vector2i(x, y)
				if _is_walkable(candidate, blocked):
					return candidate
	return cell

func _navigation_paths_are_valid(map: RID) -> bool:
	var core_position := Vector2(720, 470)
	if not _path_exists_on_map(map, PLAYER_START, core_position):
		return false
	for spawn_point in spawn_points:
		if not _path_exists_on_map(map, spawn_point, core_position):
			return false
	return true

func _path_exists_on_map(map: RID, from_position: Vector2, target_position: Vector2) -> bool:
	var path := NavigationServer2D.map_get_path(map, from_position, target_position, true)
	return path.size() >= 2

func _build_navigation_region() -> void:
	navigation_region = NavigationRegion2D.new()
	navigation_region.name = "NavigationRegion2D"
	navigation_region.navigation_layers = 1
	navigation_polygon = NavigationPolygon.new()
	navigation_polygon.agent_radius = NAVIGATION_AGENT_RADIUS
	# Use Godot's runtime source-geometry bake so the obstacle cutouts are
	# represented in the actual navmesh, rather than as disconnected tile quads.
	navigation_polygon.cell_size = 4.0
	var source_geometry := NavigationMeshSourceGeometryData2D.new()
	var arena_rect := PackedVector2Array([
		WORLD_ORIGIN,
		WORLD_ORIGIN + Vector2(0, GRID_SIZE.y * CELL_SIZE),
		WORLD_ORIGIN + Vector2(GRID_SIZE.x * CELL_SIZE, GRID_SIZE.y * CELL_SIZE),
		WORLD_ORIGIN + Vector2(GRID_SIZE.x * CELL_SIZE, 0),
	])
	source_geometry.add_traversable_outline(arena_rect)
	for cell in obstacle_cells:
		var center := _cell_center(cell)
		var clearance_extent := OBSTACLE_HALF_EXTENT + NAVIGATION_AGENT_RADIUS
		var obstacle_rect := PackedVector2Array([
			center + Vector2(-clearance_extent, -clearance_extent),
			center + Vector2(-clearance_extent, clearance_extent),
			center + Vector2(clearance_extent, clearance_extent),
			center + Vector2(clearance_extent, -clearance_extent),
		])
		source_geometry.add_obstruction_outline(obstacle_rect)
	NavigationServer2D.bake_from_source_geometry_data(navigation_polygon, source_geometry)
	navigation_region.navigation_polygon = navigation_polygon
	navigation_region.enabled = true
	add_child(navigation_region)
	navigation_region.enabled = true
	navigation_map = navigation_region.get_navigation_map()
	if navigation_map.is_valid():
		_configure_navigation_map(navigation_map)
	NavigationServer2D.region_set_navigation_polygon(navigation_region.get_rid(), navigation_polygon)

func _configure_navigation_map(map: RID) -> void:
	NavigationServer2D.map_set_active(map, true)
	NavigationServer2D.map_set_cell_size(map, 4.0)
	NavigationServer2D.map_set_edge_connection_margin(map, 2.0)

func _clear_navigation_region() -> void:
	if navigation_region != null and is_instance_valid(navigation_region):
		var region_rid := navigation_region.get_rid()
		if region_rid.is_valid():
			NavigationServer2D.region_set_map(region_rid, RID())
		navigation_region.free()
	navigation_map = RID()
	navigation_region = null
	navigation_polygon = null

func _install_navigation_fallback() -> bool:
	if generated_parent == null or not is_instance_valid(generated_parent):
		return false
	for obstacle in get_tree().get_nodes_in_group("arena_obstacle"):
		if is_instance_valid(obstacle):
			obstacle.free()
	obstacle_cells.clear()
	_configure_grid()
	_clear_navigation_region()
	_build_navigation_region()
	layout_attempts = MAX_LAYOUT_ATTEMPTS
	return true

func _exit_tree() -> void:
	_clear_navigation_region()

func _add_generated_geometry(parent: Node2D) -> void:
	for cell in obstacle_cells:
		_add_obstacle(parent, _cell_center(cell))
	for cell in hazard_cells:
		_add_hazard(parent, _cell_center(cell), int(hazard_damage_by_cell.get(cell, 8)))

func _cell_center(cell: Vector2i) -> Vector2:
	return WORLD_ORIGIN + Vector2(cell * CELL_SIZE) + Vector2.ONE * CELL_SIZE * 0.5

func _world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i(floor((world_position.x - WORLD_ORIGIN.x) / CELL_SIZE), floor((world_position.y - WORLD_ORIGIN.y) / CELL_SIZE))

func _add_obstacle(parent: Node2D, center: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = "GeneratedObstacle"
	body.add_to_group("arena_obstacle")
	body.collision_layer = 16
	body.collision_mask = 0
	body.position = center
	body.z_index = 2
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(44, 44)
	shape.shape = rectangle
	body.add_child(shape)
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([-22, -22, 22, -22, 22, 22, -22, 22])
	visual.color = Color("63346d")
	body.add_child(visual)
	var inner := Polygon2D.new()
	inner.polygon = PackedVector2Array([-16, -16, -16, 16, 16, 16, 16, -16])
	inner.color = Color("3b1c48")
	body.add_child(inner)
	var outline := Line2D.new()
	outline.points = PackedVector2Array([
		Vector2(-22, -22), Vector2(22, -22), Vector2(22, 22), Vector2(-22, 22), Vector2(-22, -22)
	])
	outline.width = 2.0
	outline.default_color = Color("c36bd0")
	outline.antialiased = false
	body.add_child(outline)
	parent.add_child(body)

func _add_hazard(parent: Node2D, center: Vector2, damage: int) -> void:
	var hazard := HAZARD_SCENE.instantiate()
	hazard.position = center
	hazard.damage = damage
	parent.add_child(hazard)
