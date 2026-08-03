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
const MAX_ACTIVE_ENEMIES := 60

var player: CharacterBody2D
var core: StaticBody2D
var arena_generator: ArenaGenerator
var spawn_timer: float = 1.0
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
var start_button: Button
var reward_text: String = ""
var feedback: CombatFeedback
var _menu_navigation_cooldown := 0.0
var _menu_accept_was_pressed := false

func _ready() -> void:
	# The pause and level-up overlays must continue receiving controller input
	# while the gameplay portion of the scene tree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	_update_controller_menu_input(delta)
	if GameManager.run_state == GameManager.RunState.PLAYING:
		GameManager.tick_run(delta)
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			_spawn_wave_group()
			spawn_timer = maxf(1.0, 6.5 - GameManager.elapsed_time * 0.007)
		if GameManager.elapsed_time >= 600.0:
			GameManager.finish_run(true)
	_update_hud()

func _input(event: InputEvent) -> void:
	if not overlay.visible and not upgrade_panel.visible:
		return
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A:
		var focused := get_viewport().gui_get_focus_owner()
		if focused is BaseButton and not focused.disabled:
			focused.emit_signal("pressed")
			get_viewport().set_input_as_handled()
		_menu_accept_was_pressed = true
	elif event is InputEventJoypadMotion and event.axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y] and _menu_navigation_cooldown <= 0.0:
		var direction := Vector2(Input.get_joy_axis(event.device, JOY_AXIS_LEFT_X), Input.get_joy_axis(event.device, JOY_AXIS_LEFT_Y))
		if direction.length_squared() > 0.42:
			_move_controller_focus(direction.normalized())
			_menu_navigation_cooldown = 0.22

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if GameManager.run_state == GameManager.RunState.PLAYING:
			GameManager.set_paused(true)
		elif GameManager.run_state == GameManager.RunState.PAUSED:
			GameManager.set_paused(false)
		return
	if not event.is_action_pressed("confirm"):
		return
	var focused := get_viewport().gui_get_focus_owner()
	if focused is BaseButton and not focused.disabled:
		focused.emit_signal("pressed")
		get_viewport().set_input_as_handled()

func _build_world() -> void:
	for child in get_children():
		if child != hud and child != feedback:
			child.queue_free()
	core = CORE_SCENE.instantiate()
	core.max_health = GameManager.core_max_health
	core.damage_multiplier = float(GameManager.demon_modifiers.get("core_damage_multiplier", core.damage_multiplier))
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
	if get_tree().get_nodes_in_group("enemies").size() >= MAX_ACTIVE_ENEMIES:
		return
	GameManager.wave_index = int(GameManager.elapsed_time / 20.0) + 1
	var count := mini(2 + GameManager.wave_index, 12)
	if GameManager.elapsed_time >= 540.0:
		if GameManager.champion_time < 0.0:
			GameManager.champion_time = GameManager.elapsed_time
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
	data.player_aggro_range = 240.0 if is_orc else 0.0
	data.xp_value = 4 if is_orc else 3
	data.texture = ORC_IDLE if is_orc else SOLDIER_IDLE
	data.idle_frames = 6
	data.scale = 0.68
	return data

func _on_run_started() -> void:
	_build_world()
	overlay.visible = false
	upgrade_panel.visible = false
	set_process(true)

func _on_run_ended(victory: bool) -> void:
	set_process(false)
	overlay.visible = true
	status_label.text = ("HELLS DEFENDED" if victory else "THE HELLS HAVE FALLEN") + "\n" + reward_text + "\n" + GameManager.last_run_summary
	status_label.modulate = Color("ffb52e") if victory else Color("ff5b70")
	start_button.text = "RETURN TO STRONGHOLD"
	start_button.grab_focus.call_deferred()

func _on_run_paused(is_paused: bool) -> void:
	if is_paused:
		overlay.visible = true
		status_label.text = "PAUSED"
		start_button.text = "RESUME"
		start_button.grab_focus.call_deferred()
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
		button.focus_mode = Control.FOCUS_ALL
		button.add_to_group("controller_menu_option")
		button.text = "%s\n%s" % [choice.title, choice.description]
		button.custom_minimum_size = Vector2(390, 62)
		button.pressed.connect(_choose_upgrade.bind(choice))
		upgrade_list.add_child(button)
	if upgrade_list.get_child_count() > 0:
		(upgrade_list.get_child(0) as Button).grab_focus.call_deferred()

func _choose_upgrade(upgrade: UpgradeData) -> void:
	GameManager.choose_upgrade(upgrade)
	player.apply_upgrade(upgrade)
	get_tree().paused = false
	upgrade_panel.visible = false

func _update_controller_menu_input(delta: float) -> void:
	if not overlay.visible and not upgrade_panel.visible:
		_menu_accept_was_pressed = false
		return
	_menu_navigation_cooldown = maxf(_menu_navigation_cooldown - delta, 0.0)
	var direction := _get_controller_menu_direction()
	if direction.length_squared() > 0.42 and _menu_navigation_cooldown <= 0.0:
		_move_controller_focus(direction.normalized())
		_menu_navigation_cooldown = 0.22
	var accept_pressed := false
	for device in Input.get_connected_joypads():
		if Input.is_joy_button_pressed(device, JOY_BUTTON_A):
			accept_pressed = true
			break
	if accept_pressed and not _menu_accept_was_pressed:
		var focused := get_viewport().gui_get_focus_owner()
		if focused is BaseButton and not focused.disabled:
			focused.emit_signal("pressed")
	_menu_accept_was_pressed = accept_pressed

func _get_controller_menu_direction() -> Vector2:
	var strongest := Vector2.ZERO
	var strongest_strength := 0.0
	for device in Input.get_connected_joypads():
		var direction := Vector2(Input.get_joy_axis(device, JOY_AXIS_LEFT_X), Input.get_joy_axis(device, JOY_AXIS_LEFT_Y))
		if direction.length_squared() > strongest_strength:
			strongest = direction
			strongest_strength = direction.length_squared()
	return strongest

func _move_controller_focus(direction: Vector2) -> void:
	var focused := get_viewport().gui_get_focus_owner() as Control
	var options: Array[Control] = []
	for node in get_tree().get_nodes_in_group("controller_menu_option"):
		if node is Control and is_instance_valid(node) and node.visible and not node.disabled and node.focus_mode != Control.FOCUS_NONE:
			options.append(node)
	if options.is_empty():
		return
	if focused == null or not options.has(focused):
		options[0].grab_focus()
		return
	var origin := focused.global_position + focused.size * 0.5
	var best: Control
	var best_score := INF
	for option in options:
		if option == focused:
			continue
		var offset: Vector2 = option.global_position + option.size * 0.5 - origin
		var forward := offset.dot(direction)
		if forward <= 4.0:
			continue
		var score := forward + absf(offset.cross(direction)) * 1.5
		if score < best_score:
			best = option
			best_score = score
	if best:
		best.grab_focus()

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
	help.text = "WASD / LEFT STICK MOVE  •  MOUSE / RIGHT STICK AIM  •  SPACE / MENU PAUSE  •  AUTO-CAST"
	help.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	help.position = Vector2(22, -34)
	help.size = Vector2(700, 28)
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
	var center_frame := CenterContainer.new()
	center_frame.name = "CenterFrame"
	center_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center_frame)
	var center := VBoxContainer.new()
	center.name = "Center"
	center.custom_minimum_size = Vector2(680, 0)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 10)
	center_frame.add_child(center)
	var title := Label.new()
	title.text = "INFERNAL SWARM"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.modulate = Color("ff7a36")
	center.add_child(title)
	status_label = Label.new()
	status_label.text = "DEFEND THE HELLS"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.custom_minimum_size = Vector2(680, 86)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 20)
	center.add_child(status_label)
	start_button = Button.new()
	start_button.name = "StartButton"
	start_button.focus_mode = Control.FOCUS_ALL
	start_button.text = "BEGIN THE INVASION"
	start_button.custom_minimum_size = Vector2(300, 54)
	start_button.pressed.connect(_start_button_pressed)
	center.add_child(start_button)
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
	if GameManager.run_state in [GameManager.RunState.VICTORY, GameManager.RunState.DEFEAT]:
		get_tree().change_scene_to_file("res://levels/stronghold.tscn")
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
