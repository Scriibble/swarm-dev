class_name CombatFeedback
extends Node2D

func _ready() -> void:
	EventBus.combat_feedback.connect(_on_combat_feedback)
	EventBus.ability_activated.connect(_on_ability_activated)
	EventBus.evolution_selected.connect(_on_evolution_selected)

func _on_combat_feedback(position: Vector2, amount: int, kind: StringName) -> void:
	if kind == &"core_hit":
		show_core_hit(position, amount)
	elif kind == &"enemy_death":
		_spawn_burst(position, Color("ff713d"), 1.0)
	else:
		if kind == &"player_hit":
			var player := get_tree().get_first_node_in_group("player")
			if player and player.has_method("shake_camera"):
				player.shake_camera(5.0)
		_spawn_number(position, amount, Color("ffe1a6") if kind == &"enemy_hit" else Color("ff5b70"))
		_spawn_burst(position, Color("fff1c4") if kind == &"enemy_hit" else Color("ff385f"), 0.45)

func _on_ability_activated(ability_id: StringName, position: Vector2) -> void:
	var color := Color("ff6b35")
	match ability_id:
		&"blood_orbit": color = Color("ff385f")
		&"core_pulse":
			color = Color("ffb52e")
			_spawn_pulse_ring(position, color, 170.0)
		&"hazard": color = Color("ff713d")
		&"bone_spear": color = Color("d8d4ec")
		&"chain_lash": color = Color("b968ff")
		&"soul_drain": color = Color("ff385f")
		&"summon": color = Color("a44dff")
	_spawn_burst(position, color, 0.5)

func _on_evolution_selected(evolution_id: StringName, position: Vector2) -> void:
	var color := Color("d8d4ec") if evolution_id == &"grave_lance" else Color("b968ff")
	_spawn_burst(position, color, 2.5)
	_spawn_ring(position, color, 72.0)
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("shake_camera"):
		player.shake_camera(10.0)

func show_core_hit(position: Vector2, amount: int) -> void:
	_spawn_number(position + Vector2(0, -80), amount, Color("ffb52e"))
	_spawn_burst(position, Color("ffb52e"), 1.0)
	_spawn_ring(position, Color("ffb52e"), 58.0)
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("shake_camera"):
		player.shake_camera(7.0)

func _spawn_number(position: Vector2, amount: int, color: Color) -> void:
	var label := Label.new()
	label.text = str(amount)
	label.position = position + Vector2(-8, -20)
	label.z_index = 20
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 26.0, 0.45)
	tween.tween_property(label, "modulate:a", 0.0, 0.45)
	tween.chain().tween_callback(label.queue_free)

func _spawn_burst(position: Vector2, color: Color, scale_amount: float) -> void:
	if get_child_count() > 120:
		return
	var burst := GeneratedArt.effect_sprite(&"impact_burst")
	burst.position = position
	burst.modulate = color
	burst.modulate.a = 0.85
	burst.z_index = 19
	add_child(burst)
	var tween := burst.create_tween()
	tween.set_parallel(true)
	tween.tween_property(burst, "scale", Vector2.ONE * (0.7 + scale_amount * 0.45), 0.22)
	tween.tween_property(burst, "modulate:a", 0.0, 0.22)
	tween.chain().tween_callback(burst.queue_free)

func _spawn_ring(position: Vector2, color: Color, radius: float) -> void:
	if get_child_count() > 120:
		return
	var ring := GeneratedArt.effect_sprite(&"evolution_burst" if color.b > color.r else &"core_pulse")
	ring.position = position
	ring.modulate = color
	ring.z_index = 18
	ring.scale = Vector2.ONE * maxf(radius / 96.0, 0.8)
	add_child(ring)
	var tween := ring.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2.ONE * 1.45, 0.3)
	tween.tween_property(ring, "modulate:a", 0.0, 0.3)
	tween.chain().tween_callback(ring.queue_free)

func _spawn_pulse_ring(position: Vector2, color: Color, radius: float) -> void:
	if get_child_count() > 120:
		return
	var ring := GeneratedArt.effect_sprite(&"core_pulse")
	ring.position = position
	ring.scale = Vector2.ONE * 0.08
	ring.modulate = color
	ring.modulate.a = 0.95
	ring.z_index = 18
	add_child(ring)
	var tween := ring.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "scale", Vector2.ONE * 1.06, 0.24)
	tween.tween_property(ring, "modulate:a", 0.0, 0.38)
	tween.chain().tween_callback(ring.queue_free)
