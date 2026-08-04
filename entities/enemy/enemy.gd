extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal died
signal xp_dropped(amount: int)

const NAVIGATION_RADIUS := 18.0
const TARGET_UPDATE_INTERVAL := 0.15
const REPATH_INTERVAL := 0.35
const STUCK_REPATH_TIME := 0.75
const STUCK_FAILSAFE_TIME := 1.5

@export var debug_navigation := false

var data: EnemyData
var health: int
var attack_timer: float = 0.0
var target_update_timer: float = 0.0
var stuck_timer: float = 0.0
var last_position := Vector2.ZERO
var last_target: Node2D
var last_target_position := Vector2.INF
var navigation_state: StringName = &"waiting"
var force_repath := false
var _safe_velocity := Vector2.ZERO
var _safe_velocity_ready := false

@onready var _sprite: Sprite2D = %EnemySprite
@onready var _navigation_agent: NavigationAgent2D = %NavigationAgent2D

func _ready() -> void:
	_navigation_agent.radius = NAVIGATION_RADIUS
	_navigation_agent.avoidance_enabled = true
	_navigation_agent.neighbor_distance = 112.0
	_navigation_agent.max_neighbors = 16
	_navigation_agent.path_desired_distance = 2.0
	_navigation_agent.path_max_distance = 180.0
	_navigation_agent.velocity_computed.connect(_on_safe_velocity_computed)
	last_position = global_position

func setup(enemy_data: EnemyData) -> void:
	data = enemy_data
	health = data.max_health
	var arena := _find_arena()
	if arena != null and arena.get_navigation_map().is_valid():
		_navigation_agent.set_navigation_map(arena.get_navigation_map())
	_sprite.texture = data.texture
	_sprite.hframes = data.idle_frames
	_sprite.scale = Vector2.ONE * data.scale
	target_update_timer = 0.0
	stuck_timer = 0.0
	force_repath = false
	navigation_state = &"waiting"
	_safe_velocity = Vector2.ZERO
	_safe_velocity_ready = false
	last_position = global_position
	queue_redraw()

func _physics_process(delta: float) -> void:
	if GameManager.run_state != GameManager.RunState.PLAYING or data == null:
		velocity = Vector2.ZERO
		return
	var core := get_tree().get_first_node_in_group("objective") as Node2D
	if core == null:
		velocity = Vector2.ZERO
		navigation_state = &"waiting"
		return
	var arena := _find_arena()
	var target: Node2D = core
	var attack_range := 55.0
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if data.player_aggro_range > 0.0 and is_instance_valid(player) and global_position.distance_to(player.global_position) <= data.player_aggro_range:
		target = player
		attack_range = 42.0

	_update_navigation_target(target, attack_range, delta)
	var desired_velocity := Vector2.ZERO
	if _navigation_agent.is_navigation_finished():
		navigation_state = &"arrived" if _navigation_agent.is_target_reachable() else &"waiting"
	else:
		var next_path_position := _navigation_agent.get_next_path_position()
		if next_path_position != Vector2.ZERO or global_position.distance_squared_to(_navigation_agent.target_position) < 64.0:
			desired_velocity = global_position.direction_to(next_path_position) * data.move_speed
			navigation_state = &"navigating"
		else:
			navigation_state = &"waiting"
	if desired_velocity.length_squared() > 1.0:
		_navigation_agent.velocity = desired_velocity
		if not _navigation_agent.avoidance_enabled:
			_safe_velocity = desired_velocity
			_safe_velocity_ready = true
	else:
		_navigation_agent.velocity = Vector2.ZERO
		_safe_velocity = Vector2.ZERO
		_safe_velocity_ready = false
	_apply_safe_movement(arena, delta)
	_update_stuck_state(desired_velocity, delta)

	attack_timer -= delta
	if is_instance_valid(target) and global_position.distance_to(target.global_position) < attack_range and attack_timer <= 0.0:
		if target.has_method("take_damage"):
			var core_damage := data.contact_damage
			if target == core:
				var multiplier = core.get("damage_multiplier")
				if multiplier != null:
					core_damage = int(round(float(core_damage) * float(multiplier)))
			target.take_damage(core_damage)
		attack_timer = data.attack_interval

	queue_redraw()

func _update_navigation_target(target: Node2D, attack_range: float, delta: float) -> void:
	target_update_timer = maxf(target_update_timer - delta, 0.0)
	if not is_instance_valid(target):
		return
	var target_changed := target != last_target
	var target_moved := last_target_position == Vector2.INF or target.global_position.distance_squared_to(last_target_position) > 144.0
	if target_changed or (target_update_timer <= 0.0 and target_moved) or force_repath:
		_navigation_agent.target_desired_distance = attack_range
		_navigation_agent.target_position = target.global_position
		last_target = target
		last_target_position = target.global_position
		target_update_timer = TARGET_UPDATE_INTERVAL
		force_repath = false

func _find_arena() -> ArenaGenerator:
	var current_scene := get_tree().current_scene
	if current_scene != null:
		var scene_arena := current_scene.get_node_or_null("ArenaGenerator") as ArenaGenerator
		if scene_arena != null:
			return scene_arena
	return get_tree().get_first_node_in_group("arena_navigation") as ArenaGenerator

func _apply_safe_movement(arena: ArenaGenerator, delta: float) -> void:
	if not _safe_velocity_ready or _safe_velocity.length_squared() <= 1.0:
		velocity = Vector2.ZERO
		return
	var previous_position := global_position
	var proposed_position := global_position + _safe_velocity * delta
	if arena != null and not arena.is_position_navigable(proposed_position, NAVIGATION_RADIUS):
		velocity = Vector2.ZERO
		_request_repath()
		navigation_state = &"blocked"
		return
	velocity = _safe_velocity
	move_and_slide()
	if arena != null and not arena.is_position_navigable(global_position, NAVIGATION_RADIUS):
		global_position = previous_position
		velocity = Vector2.ZERO
		_request_repath()
		navigation_state = &"blocked"

func _update_stuck_state(desired_velocity: Vector2, delta: float) -> void:
	var moved_distance := global_position.distance_to(last_position)
	last_position = global_position
	if desired_velocity.length_squared() > 1.0 and moved_distance < 0.25:
		stuck_timer += delta
	else:
		stuck_timer = 0.0
	if stuck_timer >= STUCK_REPATH_TIME and navigation_state != &"repathing":
		_request_repath()
		navigation_state = &"repathing"
	if stuck_timer >= STUCK_FAILSAFE_TIME:
		_request_repath()
		stuck_timer = 0.0
		navigation_state = &"waiting"

func _request_repath() -> void:
	# Reset the agent from the enemy's current position. Reassigning the real
	# target on the next physics tick makes this a genuine fresh query instead
	# of repeatedly asking for the same cached path.
	_navigation_agent.target_position = global_position
	force_repath = true
	_safe_velocity = Vector2.ZERO
	_safe_velocity_ready = false

func _on_safe_velocity_computed(safe_velocity: Vector2) -> void:
	_safe_velocity = safe_velocity
	_safe_velocity_ready = true

func take_damage(amount: int) -> void:
	health = maxi(health - amount, 0)
	health_changed.emit(health, data.max_health)
	EventBus.combat_feedback.emit(global_position, amount, &"enemy_hit")
	if _sprite:
		_sprite.modulate = Color("fff1c4")
		var flash := _sprite.create_tween()
		flash.tween_property(_sprite, "modulate", Color.WHITE, 0.08)
	if health == 0:
		died.emit()
		EventBus.combat_feedback.emit(global_position, 0, &"enemy_death")
		xp_dropped.emit(data.xp_value)
		GameManager.register_kill()
		GameManager.add_xp(data.xp_value)
		queue_free()

func _draw() -> void:
	draw_circle(Vector2(0, 22), 14.0, Color(0, 0, 0, 0.2))
	if not debug_navigation or not is_instance_valid(_navigation_agent):
		return
	var path := _navigation_agent.get_current_navigation_path()
	for index in range(1, path.size()):
		draw_line(to_local(path[index - 1]), to_local(path[index]), Color("66d9ff"), 2.0)
	var status_color := Color("ff5b70") if navigation_state in [&"blocked", &"waiting"] else Color("6dff9a")
	draw_circle(Vector2.ZERO, 4.0, status_color)
