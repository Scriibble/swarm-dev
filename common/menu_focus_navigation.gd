class_name MenuFocusNavigation
extends RefCounted

const ANALOG_NAVIGATION_REPEAT := 0.20
static var _next_analog_navigation_time_by_viewport: Dictionary = {}

static func wire_linear(options: Array[Control]) -> void:
	var active: Array[Control] = []
	for option in options:
		if is_instance_valid(option) and option.visible and option.focus_mode != Control.FOCUS_NONE and not option.disabled:
			active.append(option)
	for index in active.size():
		var option := active[index]
		var previous := active[(index - 1 + active.size()) % active.size()] if not active.is_empty() else option
		var next := active[(index + 1) % active.size()] if not active.is_empty() else option
		option.focus_neighbor_top = option.get_path_to(previous)
		option.focus_neighbor_bottom = option.get_path_to(next)
		option.focus_previous = option.get_path_to(previous)
		option.focus_next = option.get_path_to(next)

static func handle_ui_input(event: InputEvent, options: Array[Control]) -> bool:
	var direction := Vector2i.ZERO
	if event.is_action_pressed("ui_up"):
		direction = Vector2i.UP
	elif event.is_action_pressed("ui_down"):
		direction = Vector2i.DOWN
	elif event.is_action_pressed("ui_left"):
		direction = Vector2i.LEFT
	elif event.is_action_pressed("ui_right"):
		direction = Vector2i.RIGHT
	if direction == Vector2i.ZERO:
		return false

	var active: Array[Control] = []
	for option in options:
		if is_instance_valid(option) and option.visible and option.focus_mode != Control.FOCUS_NONE and not option.disabled:
			active.append(option)
	if active.is_empty():
		return false

	var viewport := active[0].get_viewport()
	if event is InputEventJoypadMotion:
		var viewport_id := viewport.get_instance_id()
		var now := Time.get_ticks_msec() / 1000.0
		if now < float(_next_analog_navigation_time_by_viewport.get(viewport_id, 0.0)):
			# Consume held-stick events during the repeat interval without
			# advancing focus again.
			return true
		_next_analog_navigation_time_by_viewport[viewport_id] = now + ANALOG_NAVIGATION_REPEAT
	var focused := viewport.gui_get_focus_owner() as Control
	if focused == null or not active.has(focused):
		active[0].grab_focus()
		return true

	var target: Control
	if direction == Vector2i.UP:
		target = _neighbor_from(focused, focused.focus_neighbor_top)
	elif direction == Vector2i.DOWN:
		target = _neighbor_from(focused, focused.focus_neighbor_bottom)
	elif direction == Vector2i.LEFT:
		target = _neighbor_from(focused, focused.focus_neighbor_left)
	else:
		target = _neighbor_from(focused, focused.focus_neighbor_right)
	if target == null or not active.has(target):
		return false
	target.grab_focus()
	return true

static func _neighbor_from(control: Control, node_path: NodePath) -> Control:
	if node_path.is_empty():
		return null
	return control.get_node_or_null(node_path) as Control
