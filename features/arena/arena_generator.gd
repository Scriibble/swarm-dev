class_name ArenaGenerator
extends Node2D

const CELL_SIZE := 48
const GRID_SIZE := Vector2i(30, 18)
const WORLD_ORIGIN := Vector2(24, 76)
const HAZARD_SCENE: PackedScene = preload("res://features/arena/hazard.tscn")

var grid := AStarGrid2D.new()
var spawn_points: Array[Vector2] = []
var obstacle_cells: Array[Vector2i] = []
var hazard_cells: Array[Vector2i] = []

func generate(seed_value: int, parent: Node2D, core_position: Vector2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	grid = AStarGrid2D.new()
	grid.region = Rect2i(Vector2i.ZERO, GRID_SIZE)
	grid.cell_size = Vector2(CELL_SIZE, CELL_SIZE)
	grid.offset = WORLD_ORIGIN
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	spawn_points.clear()
	obstacle_cells.clear()
	hazard_cells.clear()
	for y in GRID_SIZE.y:
		for x in GRID_SIZE.x:
			var cell := Vector2i(x, y)
			var center := WORLD_ORIGIN + Vector2(cell * CELL_SIZE) + Vector2.ONE * CELL_SIZE * 0.5
			var safe_from_core := center.distance_to(core_position) > 220.0
			var border := x == 0 or y == 0 or x == GRID_SIZE.x - 1 or y == GRID_SIZE.y - 1
			if safe_from_core and not border and rng.randf() < 0.11:
				obstacle_cells.append(cell)
				grid.set_point_solid(cell, true)
				_add_obstacle(parent, center)
			elif safe_from_core and not border and rng.randf() < 0.035:
				hazard_cells.append(cell)
				_add_hazard(parent, center, rng.randi_range(6, 12))
	for x in range(2, GRID_SIZE.x - 2, 3):
		spawn_points.append(WORLD_ORIGIN + Vector2(x * CELL_SIZE + CELL_SIZE / 2.0, CELL_SIZE * 0.5))
		spawn_points.append(WORLD_ORIGIN + Vector2(x * CELL_SIZE + CELL_SIZE / 2.0, (GRID_SIZE.y - 1) * CELL_SIZE + CELL_SIZE * 0.5))
	for y in range(3, GRID_SIZE.y - 3, 3):
		spawn_points.append(WORLD_ORIGIN + Vector2(CELL_SIZE * 0.5, y * CELL_SIZE + CELL_SIZE * 0.5))
		spawn_points.append(WORLD_ORIGIN + Vector2((GRID_SIZE.x - 1) * CELL_SIZE + CELL_SIZE * 0.5, y * CELL_SIZE + CELL_SIZE * 0.5))
	grid.update()

func direction_to_target(from_position: Vector2, target_position: Vector2) -> Vector2:
	var from_cell := _world_to_cell(from_position)
	var target_cell := _world_to_cell(target_position)
	if not grid.is_in_boundsv(from_cell) or not grid.is_in_boundsv(target_cell):
		return from_position.direction_to(target_position)
	var path := grid.get_id_path(from_cell, target_cell, true)
	if path.size() >= 2:
		var next_cell: Vector2i = path[1]
		var next_position := WORLD_ORIGIN + Vector2(next_cell * CELL_SIZE) + Vector2.ONE * CELL_SIZE * 0.5
		return from_position.direction_to(next_position)
	return from_position.direction_to(target_position)

func _world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i(floor((world_position.x - WORLD_ORIGIN.x - CELL_SIZE * 0.5) / CELL_SIZE), floor((world_position.y - WORLD_ORIGIN.y - CELL_SIZE * 0.5) / CELL_SIZE))

func _add_obstacle(parent: Node2D, center: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = "GeneratedObstacle"
	# Obstacles use their own layer so the player never gets blocked by an
	# enemy body that happens to be standing nearby.
	body.collision_layer = 16
	body.collision_mask = 0
	body.position = center
	body.z_index = 2
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(40, 40)
	shape.shape = rectangle
	body.add_child(shape)
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([-22, -22, 22, -22, 22, 22, -22, 22])
	visual.color = Color("63346d")
	body.add_child(visual)
	var inner := Polygon2D.new()
	inner.polygon = PackedVector2Array([-16, -16, 16, -16, 16, 16, -16, 16])
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
