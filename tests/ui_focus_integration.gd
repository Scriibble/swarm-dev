extends Node

const STRONGHOLD_SCENE: PackedScene = preload("res://levels/stronghold.tscn")
const MAIN_SCENE: PackedScene = preload("res://levels/main.tscn")
const MENU_FOCUS = preload("res://common/menu_focus_navigation.gd")

func _ready() -> void:
	var failures: Array[String] = []
	_validate_controller_direction_actions(failures)
	var stronghold := STRONGHOLD_SCENE.instantiate()
	add_child(stronghold)
	await get_tree().process_frame
	var stronghold_options: Array = stronghold.get("_menu_options")
	if stronghold_options.size() < 2:
		failures.append("Stronghold did not expose its focusable menu options")
	else:
		for option in stronghold_options:
			if not option is Control or option.focus_mode == Control.FOCUS_NONE:
				failures.append("Stronghold contains a non-focusable actionable option")
				break
		var first_menu_option := stronghold_options[0] as Control
		var second_menu_option := stronghold_options[1] as Control
		first_menu_option.grab_focus()
		var down_event := InputEventAction.new()
		down_event.action = "ui_down"
		down_event.pressed = true
		MENU_FOCUS.handle_ui_input(down_event, stronghold_options)
		if get_viewport().gui_get_focus_owner() != second_menu_option:
			failures.append("ui_down did not move focus to the next stronghold option")
		first_menu_option.grab_focus()
		var stick_down_event := InputEventJoypadMotion.new()
		stick_down_event.axis = JOY_AXIS_LEFT_Y
		stick_down_event.axis_value = 1.0
		MENU_FOCUS.handle_ui_input(stick_down_event, stronghold_options)
		var first_stick_target := get_viewport().gui_get_focus_owner()
		MENU_FOCUS.handle_ui_input(stick_down_event, stronghold_options)
		if first_stick_target != second_menu_option or get_viewport().gui_get_focus_owner() != second_menu_option:
			failures.append("held left-stick navigation advanced more than one menu option")
	stronghold.free()
	await get_tree().process_frame

	var main := MAIN_SCENE.instantiate()
	add_child(main)
	await _wait_for_world(main)
	GameManager.add_xp(GameManager.xp_to_next)
	await get_tree().process_frame
	await get_tree().process_frame
	var upgrade_list: VBoxContainer = main.get("upgrade_list")
	if upgrade_list == null or upgrade_list.get_child_count() != 3:
		failures.append("Level-up did not create three focusable upgrade cards")
	else:
		var first_upgrade := upgrade_list.get_child(0) as Button
		if first_upgrade == null or first_upgrade.focus_mode == Control.FOCUS_NONE:
			failures.append("First upgrade card is not focusable")
		else:
			first_upgrade.grab_focus()
			first_upgrade.pressed.emit()
			await get_tree().process_frame
			if GameManager.run_state != GameManager.RunState.PLAYING:
				failures.append("Mapped controller accept action did not select an upgrade")
	main.free()
	await get_tree().physics_frame
	if failures.is_empty():
		print("UI focus integration test passed: stronghold and upgrade accept flow")
		get_tree().quit(0)
		return
	for failure in failures:
		push_error(failure)
	get_tree().quit(1)

func _validate_controller_direction_actions(failures: Array[String]) -> void:
	var expected_buttons := {
		"ui_up": JOY_BUTTON_DPAD_UP,
		"ui_down": JOY_BUTTON_DPAD_DOWN,
		"ui_left": JOY_BUTTON_DPAD_LEFT,
		"ui_right": JOY_BUTTON_DPAD_RIGHT,
	}
	for action in expected_buttons:
		var found := false
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadButton and event.button_index == expected_buttons[action]:
				found = true
				break
		if not found:
			failures.append("%s is missing its D-pad button mapping" % action)

func _wait_for_world(main: Node) -> void:
	for _frame in 180:
		await get_tree().physics_frame
		if main.get("player") != null and main.get("core") != null:
			return
	push_error("main scene did not finish building for UI focus test")
	get_tree().quit(1)
