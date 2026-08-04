extends Control

const MENU_FOCUS = preload("res://common/menu_focus_navigation.gd")

var currency_label: Label
var catalog_box: VBoxContainer
var selected_label: Label
var start_button: Button
var display_button: Button
var _menu_options: Array[Control] = []

func _ready() -> void:
	_build_ui()
	ProfileManager.currency_changed.connect(func(_amount: int) -> void: _refresh_ui())
	ProfileManager.unlock_purchased.connect(func(_unlock_id: StringName) -> void: _refresh_ui())

func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("12091b")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_bottom", 32)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)
	var title := Label.new()
	title.text = "THE INFERNAL STRONGHOLD"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.modulate = Color("ff7a36")
	root.add_child(title)
	currency_label = Label.new()
	currency_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	currency_label.add_theme_font_size_override("font_size", 20)
	root.add_child(currency_label)
	selected_label = Label.new()
	selected_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(selected_label)
	start_button = Button.new()
	start_button.text = "BEGIN RUN"
	start_button.focus_mode = Control.FOCUS_ALL
	start_button.custom_minimum_size = Vector2(0, 54)
	start_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://levels/main.tscn"))
	root.add_child(start_button)
	display_button = Button.new()
	display_button.text = "DISPLAY: %s" % SettingsManager.fullscreen_label()
	display_button.focus_mode = Control.FOCUS_ALL
	display_button.custom_minimum_size = Vector2(0, 42)
	display_button.pressed.connect(func() -> void:
		SettingsManager.toggle_fullscreen()
		display_button.text = "DISPLAY: %s" % SettingsManager.fullscreen_label()
	)
	root.add_child(display_button)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	catalog_box = VBoxContainer.new()
	catalog_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	catalog_box.add_theme_constant_override("separation", 7)
	scroll.add_child(catalog_box)
	_refresh_ui()

func _unhandled_input(event: InputEvent) -> void:
	if MENU_FOCUS.handle_ui_input(event, _menu_options):
		get_viewport().set_input_as_handled()

func _refresh_ui() -> void:
	if not is_instance_valid(currency_label):
		return
	currency_label.text = "INFERNAL SHARDS: %d" % ProfileManager.currency
	selected_label.text = "SELECTED DEMON: %s" % String(ProfileManager.selected_demon_id).capitalize()
	for child in catalog_box.get_children():
		child.queue_free()
	_menu_options.clear()
	_menu_options.append(start_button)
	_menu_options.append(display_button)
	var catalog := ProfileManager.get_catalog()
	_add_section("DEMONS", catalog.get("demons", {}), ProfileManager.unlocked_demons, true)
	_add_section("ABILITIES", catalog.get("abilities", {}), ProfileManager.unlocked_abilities, false)
	_add_section("PASSIVES", catalog.get("passives", {}), ProfileManager.unlocked_passives, false)
	MENU_FOCUS.wire_linear(_menu_options)
	start_button.grab_focus.call_deferred()

func _add_section(title: String, entries: Dictionary, unlocked: Array[StringName], demon_section: bool) -> void:
	var heading := Label.new()
	heading.text = title
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_font_size_override("font_size", 20)
	heading.modulate = Color("b985d1")
	catalog_box.add_child(heading)
	for unlock_id in entries:
		var entry: Dictionary = entries[unlock_id]
		var button := Button.new()
		button.focus_mode = Control.FOCUS_ALL
		var is_unlocked: bool = unlock_id in unlocked
		var prerequisites: Array = entry.get("prerequisites", [])
		var prerequisite_text := ""
		if not prerequisites.is_empty():
			prerequisite_text = " | Requires: " + ", ".join(PackedStringArray(prerequisites))
		button.text = ("[UNLOCKED] " if is_unlocked else "[LOCKED] ") + entry.get("title", String(unlock_id)) + " — " + entry.get("description", "") + (" | Cost: %d" % int(entry.get("cost", 0)) if not is_unlocked else "") + prerequisite_text
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 50)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size", 14)
		if is_unlocked:
			if demon_section:
				button.pressed.connect(ProfileManager.select_demon.bind(unlock_id))
			else:
				button.disabled = true
		else:
			button.disabled = not ProfileManager.can_purchase(unlock_id)
			button.pressed.connect(ProfileManager.purchase_unlock.bind(unlock_id))
		catalog_box.add_child(button)
		_menu_options.append(button)
