extends Area2D

@export var damage: int = 8
@export var lifetime: float = -1.0
@export var evolved: bool = false
var _timer: float = 0.0
var _phase: float = 0.0

func _physics_process(delta: float) -> void:
	_phase += delta * (5.0 if evolved else 3.5)
	queue_redraw()
	if lifetime > 0.0:
		lifetime -= delta
		if lifetime <= 0.0:
			queue_free()
			return
	var game_manager := get_node_or_null("/root/GameManager")
	if game_manager == null or game_manager.run_state != game_manager.RunState.PLAYING:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = 0.75
	for body in get_overlapping_bodies():
		if body.has_method("take_damage") and body.is_in_group("player"):
			body.take_damage(damage)
		elif body.has_method("take_damage") and body.is_in_group("enemies"):
			body.take_damage(damage)

func _draw() -> void:
	var radius := 25.0 if evolved else 20.0
	var color := Color("ffb52e", 0.8) if evolved else Color("ff713d", 0.65)
	draw_arc(Vector2.ZERO, radius + sin(_phase) * 3.0, 0.0, TAU, 24, color, 2.0)
	draw_arc(Vector2.ZERO, radius * 0.55, _phase, _phase + PI * 1.4, 16, Color("fff1a6", 0.75), 2.0)
