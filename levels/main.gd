extends Node2D

const PLAYER_SCENE: PackedScene = preload("res://entities/player/player.tscn")
const CORE_SCENE: PackedScene = preload("res://entities/core/hell_core.tscn")
const ENEMY_SCENE: PackedScene = preload("res://entities/enemy/enemy.tscn")
const DEMON_IDLE: Texture2D = preload("res://sprites/Tiny RPG Character Asset Pack 02 -Free Demon_A&Blood Monster_A/Characters(100x100 split)/Demon_A/Demon_A with shadows/Demon_A_Idle.png")
const SOLDIER_IDLE: Texture2D = preload("res://sprites/Tiny RPG Character Asset Pack 01 v2.0 -Free Soldier&Orc/Characters(100x100 split)/Soldier/Soldier with shadows/Soldier_Idle.png")
const ORC_IDLE: Texture2D = preload("res://sprites/Tiny RPG Character Asset Pack 01 v2.0 -Free Soldier&Orc/Characters(100x100 split)/Orc/Orc with shadows/Orc_Idle.png")
const WALLS_FLOOR: Texture2D = preload("res://tileset/free-2d-top-down-pixel-dungeon-asset-pack/PNG/walls_floor.png")
const ARENA_GENERATOR_SCRIPT = preload("res://features/arena/arena_generator.gd")
const HAZARD_SCENE: PackedScene = preload("res://features/arena/hazard.tscn")
const FEEDBACK_SCRIPT = preload("res://features/feedback/combat_feedback.gd")

var player: CharacterBody2D
var core: StaticBody2D
var arena_generator: ArenaGenerator
var spawn_timer: float = 1.0
var pulse_timer: float = 3.0
var orbit_timer: float = 1.0
var rng := RandomNumberGenerator.new()
var hud: CanvasLayer
var overlay: Control
var status_label: Label
var timer_label: Label
var health_label: Label
var core_label: Label
var xp_label: Label
var wave_label: Label
var upgrade_panel: PanelContainer
var upgrade_list: VBoxContainer
var reward_text: String = ""
var feedback: CombatFeedback
var hazard_timer: float = 2.0

func _ready() -> void:
	rng.seed = 92177
	_build_hud()
	feedback = FEEDBACK_SCRIPT.new()
	feedback.name = "CombatFeedback"
	add_child(feedback)
	EventBus.run_started.connect(_on_run_started)
	EventBus.run_ended.connect(_on_run_ended)
	EventBus.xp_gained.connect(_on_xp_gained)
	EventBus.level_up_requested.connect(_on_level_up_requested)
	EventBus.run_rewarded.connect(_on_run_rewarded)
	EventBus.run_paused.connect(_on_run_paused)
	set_process(false)
	queue_redraw()
	GameManager.start_run.call_deferred()

func _process(delta: float) -> void:
	if GameManager.run_state == GameManager.RunState.PLAYING:
		GameManager.tick_run(delta)
		spawn_timer -= delta
		pulse_timer -= delta
		orbit_timer -= delta
		hazard_timer -= delta
		if spawn_timer <= 0.0:
			_spawn_wave_group()
			spawn_timer = maxf(0.8, 4.5 - GameManager.elapsed_time * 0.004)
		if pulse_timer <= 0.0:
			_core_pulse()
			pulse_timer = 3.0
		if orbit_timer <= 0.0:
			_orbit_attack()
			orbit_timer = 1.15
		if hazard_timer <= 0.0:
			_area_hazard_attack()
			hazard_timer = 4.0
		if GameManager.elapsed_time >= 600.0:
			GameManager.finish_run(true)
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		if GameManager.run_state == GameManager.RunState.PLAYING:
			GameManager.set_paused(true)
		elif GameManager.run_state == GameManager.RunState.PAUSED:
			GameManager.set_paused(false)

func _build_world() -> void:
	for child in get_children():
		if child != hud and child != feedback:
			child.queue_free()
	core = CORE_SCENE.instantiate()
	core.position = Vector2(720, 470)
	add_child(core)
	core.core_destroyed.connect(func() -> void: GameManager.finish_run(false))
	core.core_health_changed.connect(func(current: int, maximum: int) -> void: GameManager.update_core_health(current, maximum))
	arena_generator = ARENA_GENERATOR_SCRIPT.new()
	arena_generator.name = "ArenaGenerator"
	add_child(arena_generator)
	arena_generator.generate(GameManager.run_seed, self, core.position)
	player = PLAYER_SCENE.instantiate()
	player.position = Vector2(720, 610)
	add_child(player)
	player.died.connect(func() -> void: GameManager.finish_run(false))
	player.health_changed.connect(func(_current: int, _maximum: int) -> void: _update_hud())

func _spawn_wave_group() -> void:
	GameManager.wave_index = int(GameManager.elapsed_time / 20.0) + 1
	var count := mini(3 + GameManager.wave_index, 16)
	if GameManager.elapsed_time >= 540.0:
		count = 1
	for i in count:
		var data := _make_enemy_data(i % 2 == 1)
		if GameManager.elapsed_time >= 540.0:
			data.max_health = 180
			data.move_speed = 26.0
			data.contact_damage = 30
			data.xp_value = 25
		var enemy := ENEMY_SCENE.instantiate()
		add_child(enemy)
		var angle := rng.randf_range(0.0, TAU)
		var distance := rng.randf_range(430.0, 570.0)
		if arena_generator and not arena_generator.spawn_points.is_empty():
			enemy.position = arena_generator.spawn_points[rng.randi_range(0, arena_generator.spawn_points.size() - 1)]
		else:
			enemy.position = Vector2(720, 470) + Vector2.from_angle(angle) * distance
		enemy.setup(data)

func _make_enemy_data(is_orc: bool) -> EnemyData:
	var data := EnemyData.new()
	data.id = &"orc" if is_orc else &"soldier"
	data.display_name = "Orc" if is_orc else "Soldier"
	data.max_health = 28 if is_orc else 20
	data.move_speed = 31.0 if is_orc else 43.0
	data.contact_damage = 12 if is_orc else 8
	data.attack_interval = 1.25 if is_orc else 0.8
	data.xp_value = 4 if is_orc else 3
	data.texture = ORC_IDLE if is_orc else SOLDIER_IDLE
	data.idle_frames = 6
	data.scale = 0.68
	return data

func _core_pulse() -> void:
	if core == null or not is_instance_valid(core):
		return
	if player == null or not is_instance_valid(player) or not player.has_ability(&"core_pulse"):
		return
	var damage: int = player.core_pulse_damage + GameManager.level * 2
	damage = int(round(float(damage) * float(GameManager.demon_modifiers.get("core_effectiveness", 1.0))))
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.global_position.distance_to(core.global_position) <= 170.0:
			enemy.take_damage(damage)

func _orbit_attack() -> void:
	if player == null or not is_instance_valid(player):
		return
	if not player.has_ability(&"blood_orbit"):
		return
	var nearest: Node2D
	var nearest_distance: float = player.attack_range
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var distance: float = player.global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest = enemy
			nearest_distance = distance
	if nearest:
		var damage: int = player.orbit_damage + GameManager.level
		if GameManager.active_demon_id == &"demon_harbinger" and player.global_position.distance_to(nearest.global_position) < 180.0:
			damage = int(round(float(damage) * (1.0 + float(GameManager.demon_modifiers.get("close_damage", 0.0)))))
		nearest.take_damage(damage)

func _area_hazard_attack() -> void:
	if player == null or not is_instance_valid(player) or not player.has_ability(&"area_hazard"):
		return
	var target := core.global_position
	var nearest_distance := 999999.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var distance: float = enemy.global_position.distance_to(core.global_position)
		if distance < nearest_distance and distance < 300.0:
			nearest_distance = distance
			target = enemy.global_position
	var hazard := HAZARD_SCENE.instantiate()
	hazard.position = target
	hazard.damage = 12 + GameManager.level * 2
	hazard.lifetime = 3.0
	add_child(hazard)

func _on_run_started() -> void:
	_build_world()
	overlay.visible = false
	upgrade_panel.visible = false
	set_process(true)

func _on_run_ended(victory: bool) -> void:
	set_process(false)
	overlay.visible = true
	status_label.text = ("HELLS DEFENDED" if victory else "THE HELLS HAVE FALLEN") + "\n" + reward_text
	status_label.modulate = Color("ffb52e") if victory else Color("ff5b70")
	$HUD/Overlay/Center/StartButton.text = "RUN AGAIN"

func _on_run_paused(is_paused: bool) -> void:
	if is_paused:
		overlay.visible = true
		status_label.text = "PAUSED"
		$HUD/Overlay/Center/StartButton.text = "RESUME"
	else:
		overlay.visible = false

func _on_xp_gained(_amount: int, _total: int) -> void:
	pass

func _on_level_up_requested(choices: Array[UpgradeData]) -> void:
	_show_upgrade_choices(choices)

func _on_run_rewarded(reward: RunReward) -> void:
	reward_text = "+%d INFERNAL SHARDS" % reward.currency_awarded

func _show_upgrade_choices(choices: Array[UpgradeData]) -> void:
	get_tree().paused = true
	upgrade_panel.visible = true
	for child in upgrade_list.get_children():
		child.queue_free()
	for choice in choices:
		var button := Button.new()
		button.text = "%s\n%s" % [choice.title, choice.description]
		button.custom_minimum_size = Vector2(390, 62)
		button.pressed.connect(_choose_upgrade.bind(choice))
		upgrade_list.add_child(button)

func _choose_upgrade(upgrade: UpgradeData) -> void:
	GameManager.choose_upgrade(upgrade)
	player.apply_upgrade(upgrade)
	get_tree().paused = false
	upgrade_panel.visible = false

func _update_hud() -> void:
	if not is_instance_valid(timer_label):
		return
	var remaining := maxi(0, 600 - int(GameManager.elapsed_time))
	timer_label.text = "%02d:%02d" % [remaining / 60, remaining % 60]
	wave_label.text = "WAVE %02d" % GameManager.wave_index
	xp_label.text = "LEVEL %d   XP %d / %d" % [GameManager.level, GameManager.xp, GameManager.xp_to_next]
	if player and is_instance_valid(player):
		health_label.text = "DEMON  %d / %d" % [player.health, player.max_health]
	if core and is_instance_valid(core):
		core_label.text = "CORE  %d / %d" % [core.health, core.max_health]

func _build_hud() -> void:
	hud = CanvasLayer.new()
	hud.name = "HUD"
	hud.layer = 10
	add_child(hud)
	var top := ColorRect.new()
	top.color = Color(0.04, 0.02, 0.08, 0.88)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.custom_minimum_size.y = 52.0
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(top)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	top.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	margin.add_child(row)
	for item in ["DEMON", "CORE", "LEVEL", "WAVE", "TIME"]:
		var label := Label.new()
		label.text = item
		label.add_theme_font_size_override("font_size", 16)
		row.add_child(label)
		if item == "DEMON": health_label = label
		elif item == "CORE": core_label = label
		elif item == "LEVEL": xp_label = label
		elif item == "WAVE": wave_label = label
		else: timer_label = label
	var help := Label.new()
	help.text = "WASD / LEFT STICK MOVE  •  AIM WITH MOUSE  •  SPACE PAUSE  •  AUTO-CAST"
	help.position = Vector2(22, 890)
	help.add_theme_color_override("font_color", Color(0.72, 0.62, 0.8, 0.9))
	hud.add_child(help)
	overlay = Control.new()
	overlay.name = "Overlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.01, 0.04, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	var center := VBoxContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.position = Vector2(-210, -100)
	center.size = Vector2(420, 200)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	overlay.add_child(center)
	var title := Label.new()
	title.text = "INFERNAL SWARM"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.modulate = Color("ff7a36")
	center.add_child(title)
	status_label = Label.new()
	status_label.text = "DEFEND THE HELLS"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 20)
	center.add_child(status_label)
	var start := Button.new()
	start.name = "StartButton"
	start.text = "BEGIN THE INVASION"
	start.custom_minimum_size = Vector2(300, 54)
	start.pressed.connect(_start_button_pressed)
	center.add_child(start)
	hud.add_child(overlay)
	overlay.visible = true
	upgrade_panel = PanelContainer.new()
	upgrade_panel.set_anchors_preset(Control.PRESET_CENTER)
	upgrade_panel.position = Vector2(-230, -180)
	upgrade_panel.size = Vector2(460, 360)
	upgrade_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	var upgrade_box := VBoxContainer.new()
	upgrade_box.add_theme_constant_override("separation", 14)
	upgrade_panel.add_child(upgrade_box)
	var heading := Label.new()
	heading.text = "CHOOSE AN INFERNAL GIFT"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 22)
	upgrade_box.add_child(heading)
	upgrade_list = VBoxContainer.new()
	upgrade_list.add_theme_constant_override("separation", 8)
	upgrade_box.add_child(upgrade_list)
	hud.add_child(upgrade_panel)
	upgrade_panel.visible = false

func _start_button_pressed() -> void:
	if GameManager.run_state == GameManager.RunState.PAUSED:
		GameManager.set_paused(false)
		return
	GameManager.start_run()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1440, 940), Color("1a0d24"), true)
	draw_texture_rect(WALLS_FLOOR, Rect2(12, 64, 1416, 828), true, Color(0.72, 0.44, 0.82, 0.12))
	for x in range(0, 1440, 48):
		for y in range(52, 940, 48):
			var shade := Color("25132e") if (int(x / 48) + int(y / 48)) % 2 == 0 else Color("21102a")
			draw_rect(Rect2(x, y, 47, 47), shade, true)
	for x in range(0, 1440, 48):
		draw_rect(Rect2(x, 52, 48, 12), Color("3b1a49"), true)
		draw_rect(Rect2(x, 892, 48, 48), Color("0e0915"), true)
	for y in range(52, 940, 48):
		draw_rect(Rect2(0, y, 12, 48), Color("0e0915"), true)
		draw_rect(Rect2(1428, y, 12, 48), Color("0e0915"), true)
