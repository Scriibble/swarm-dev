extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal died

const EMBER_BOLT_RUNTIME = preload("res://features/abilities/ember_bolt_runtime.gd")
const BLOOD_ORBIT_RUNTIME = preload("res://features/abilities/blood_orbit_runtime.gd")
const CORE_PULSE_RUNTIME = preload("res://features/abilities/core_pulse_runtime.gd")
const HELLFIRE_FIELD_RUNTIME = preload("res://features/abilities/hellfire_field_runtime.gd")
const BONE_SPEAR_RUNTIME = preload("res://features/abilities/bone_spear_runtime.gd")
const CHAIN_LASH_RUNTIME = preload("res://features/abilities/chain_lash_runtime.gd")
const SOUL_DRAIN_RUNTIME = preload("res://features/abilities/soul_drain_runtime.gd")
const IMP_SWARM_RUNTIME = preload("res://features/abilities/imp_swarm_runtime.gd")
const CONTROLLER_AIM_DEADZONE := 0.2
@export var max_health: int = 100
@export var move_speed: float = 145.0
var health: int
var attack_damage: int = 12
var orbit_damage: int = 7
var core_pulse_damage: int = 14
var cooldown_bonus: float = 0.0
var attack_range: float = 180.0
var last_direction := Vector2.RIGHT
var test_aim_direction := Vector2.ZERO
@onready var _sprite: Sprite2D = %PlayerSprite
var _camera: Camera2D
var ability_runtimes: Dictionary = {}

func _ready() -> void:
	health = max_health
	_camera = Camera2D.new()
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 6.0
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = 1440
	_camera.limit_bottom = 940
	add_child(_camera)
	_apply_run_loadout()
	_setup_ability_runtimes()
	queue_redraw()

func _physics_process(delta: float) -> void:
	if GameManager.run_state != GameManager.RunState.PLAYING:
		return
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector.length_squared() > 0.01:
		velocity = input_vector * move_speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, move_speed * 8.0 * delta)
	move_and_slide()
	global_position.x = clampf(global_position.x, 80.0, 1360.0)
	global_position.y = clampf(global_position.y, 80.0, 860.0)
	if test_aim_direction.length_squared() > 0.01:
		last_direction = test_aim_direction.normalized()
	else:
		var controller_aim_direction := _get_controller_aim_direction()
		if controller_aim_direction.length_squared() > CONTROLLER_AIM_DEADZONE * CONTROLLER_AIM_DEADZONE:
			last_direction = controller_aim_direction.normalized()
		else:
			var mouse_offset := get_global_mouse_position() - global_position
			if mouse_offset.length_squared() > 64.0:
				last_direction = mouse_offset.normalized()
			elif input_vector.length_squared() > 0.01:
				last_direction = input_vector.normalized()
	for runtime in ability_runtimes.values():
		runtime.tick(delta)
	queue_redraw()

func _get_controller_aim_direction() -> Vector2:
	var strongest_aim := Vector2.ZERO
	var strongest_strength := 0.0
	for device in Input.get_connected_joypads():
		var aim := Vector2(
			Input.get_joy_axis(device, JOY_AXIS_RIGHT_X),
			Input.get_joy_axis(device, JOY_AXIS_RIGHT_Y)
		)
		var strength := aim.length_squared()
		if strength > strongest_strength:
			strongest_strength = strength
			strongest_aim = aim
	return strongest_aim

func take_damage(amount: int) -> void:
	if GameManager.run_state != GameManager.RunState.PLAYING:
		return
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	EventBus.combat_feedback.emit(global_position, amount, &"player_hit")
	_flash_sprite(Color("ff405b"))
	if health == 0:
		died.emit()
		EventBus.player_died.emit()
		GameManager.finish_run(false)

func heal(amount: int) -> void:
	if amount <= 0 or GameManager.run_state != GameManager.RunState.PLAYING:
		return
	health = mini(health + amount, max_health)
	health_changed.emit(health, max_health)

func shake_camera(amount: float) -> void:
	if _camera == null:
		return
	var tween := _camera.create_tween()
	for index in 3:
		tween.tween_property(_camera, "offset", Vector2.from_angle(float(index) * 2.1) * amount, 0.035)
	tween.tween_property(_camera, "offset", Vector2.ZERO, 0.035)

func _flash_sprite(color: Color) -> void:
	if _sprite == null:
		return
	_sprite.modulate = color
	var tween := _sprite.create_tween()
	tween.tween_property(_sprite, "modulate", Color.WHITE, 0.12)

func apply_upgrade(upgrade: UpgradeData) -> void:
	if upgrade.offer_type == &"evolution":
		var evolved_runtime = ability_runtimes.get(upgrade.target_id)
		if evolved_runtime:
			evolved_runtime.evolved = true
		else:
			_ensure_runtime(upgrade.target_id, true)
		EventBus.evolution_selected.emit(upgrade.evolution_id, global_position)
		return
	if upgrade.offer_type == &"ability":
		_ensure_runtime(upgrade.target_id, false)
		match upgrade.target_id:
			&"ember_bolt": attack_damage += 4
			&"blood_orbit": orbit_damage += 3
			&"core_pulse": core_pulse_damage += 3
		return
	match upgrade.stat:
		&"attack_damage": attack_damage += int(upgrade.amount)
		&"move_speed": move_speed += upgrade.amount
		&"max_health": max_health += int(upgrade.amount); health += int(upgrade.amount)
		&"core_health": _increase_core_health(int(upgrade.amount))
		&"cooldown": cooldown_bonus += upgrade.amount
		&"range": attack_range += upgrade.amount

func _apply_run_loadout() -> void:
	for passive_id in GameManager.passive_ranks:
		var rank: int = int(GameManager.passive_ranks[passive_id])
		match StringName(passive_id):
			&"emberheart": attack_damage += rank * 4
			&"cinder_step": move_speed += rank * 18
			&"core_ward": _increase_core_health(rank * 25)
			&"attack_damage": attack_damage += rank * 5
			&"cooldown": cooldown_bonus += rank * 0.04
			&"range": attack_range += rank * 25
			&"max_health": max_health += rank * 20; health += rank * 20
	for ability_id in GameManager.ability_ranks:
		var rank: int = int(GameManager.ability_ranks[ability_id])
		match StringName(ability_id):
			&"ember_bolt": attack_damage += maxi(rank - 1, 0) * 4
			&"blood_orbit": orbit_damage += maxi(rank - 1, 0) * 3
			&"core_pulse": core_pulse_damage += maxi(rank - 1, 0) * 3
			_: pass
	_apply_demon_modifier()

func _setup_ability_runtimes() -> void:
	for ability_id in GameManager.ability_ranks:
		_ensure_runtime(StringName(ability_id), StringName(ability_id) in GameManager.evolved_abilities)

func _ensure_runtime(ability_id: StringName, evolved: bool) -> void:
	if ability_runtimes.has(ability_id):
		ability_runtimes[ability_id].rank = int(GameManager.ability_ranks.get(ability_id, 1))
		ability_runtimes[ability_id].evolved = evolved or ability_runtimes[ability_id].evolved
		return
	var data := RogueliteCatalog.ability_by_id(ability_id)
	if data == null:
		return
	var runtime: AbilityRuntime
	match data.behavior_type:
		&"projectile": runtime = EMBER_BOLT_RUNTIME.new()
		&"orbit": runtime = BLOOD_ORBIT_RUNTIME.new()
		&"core_pulse": runtime = CORE_PULSE_RUNTIME.new()
		&"hazard": runtime = HELLFIRE_FIELD_RUNTIME.new()
		&"bone_spear": runtime = BONE_SPEAR_RUNTIME.new()
		&"chain_lash": runtime = CHAIN_LASH_RUNTIME.new()
		&"soul_drain": runtime = SOUL_DRAIN_RUNTIME.new()
		&"summon": runtime = IMP_SWARM_RUNTIME.new()
		_:
			return
	runtime.setup(self, data, int(GameManager.ability_ranks.get(ability_id, 1)), evolved)
	ability_runtimes[ability_id] = runtime
	add_child(runtime)

func has_ability(ability_id: StringName) -> bool:
	return int(GameManager.ability_ranks.get(ability_id, 0)) > 0

func _apply_demon_modifier() -> void:
	if GameManager.active_demon_id == &"demon_bulwark":
		max_health += 20
		health += 20
	elif GameManager.active_demon_id == &"demon_harbinger":
		attack_damage = int(round(float(attack_damage) * 1.08))

func _increase_core_health(amount: int) -> void:
	var core := get_tree().get_first_node_in_group("objective")
	if core and core.has_method("increase_max_health"):
		core.increase_max_health(amount)

func _draw() -> void:
	draw_circle(Vector2(0, 24), 18.0, Color(0, 0, 0, 0.26))
