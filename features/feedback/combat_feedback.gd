class_name CombatFeedback
extends Node2D

func _ready() -> void:
	EventBus.combat_feedback.connect(_on_combat_feedback)
	EventBus.ability_activated.connect(_on_ability_activated)

func _on_combat_feedback(position: Vector2, amount: int, kind: StringName) -> void:
	if kind == &"core_hit":
		show_core_hit(position, amount)
	elif kind == &"enemy_death":
		_spawn_burst(position, Color("ff713d"), 1.0)
	else:
		_spawn_number(position, amount, Color("ffe1a6") if kind == &"enemy_hit" else Color("ff5b70"))
		_spawn_burst(position, Color("fff1c4") if kind == &"enemy_hit" else Color("ff385f"), 0.45)

func _on_ability_activated(ability_id: StringName, position: Vector2) -> void:
	if ability_id in [&"bone_spear", &"chain_lash", &"soul_drain"]:
		_spawn_burst(position, Color("d8d4ec") if ability_id == &"bone_spear" else Color("b968ff"), 0.35)

func show_core_hit(position: Vector2, amount: int) -> void:
	_spawn_number(position + Vector2(0, -80), amount, Color("ffb52e"))
	_spawn_burst(position, Color("ffb52e"), 1.0)

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
	var burst := Polygon2D.new()
	burst.polygon = PackedVector2Array([Vector2(0, -12), Vector2(5, -5), Vector2(12, 0), Vector2(5, 5), Vector2(0, 12), Vector2(-5, 5), Vector2(-12, 0), Vector2(-5, -5)])
	burst.position = position
	burst.color = color
	burst.modulate.a = 0.85
	burst.z_index = 19
	add_child(burst)
	var tween := burst.create_tween()
	tween.set_parallel(true)
	tween.tween_property(burst, "scale", Vector2.ONE * (2.0 + scale_amount), 0.22)
	tween.tween_property(burst, "modulate:a", 0.0, 0.22)
	tween.chain().tween_callback(burst.queue_free)
