extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal died
signal xp_dropped(amount: int)

var data: EnemyData
var health: int
var attack_timer: float = 0.0
var path_timer: float = 0.0
var _sprite: Sprite2D

func setup(enemy_data: EnemyData) -> void:
	data = enemy_data
	health = data.max_health
	_sprite = Sprite2D.new()
	_sprite.texture = data.texture
	_sprite.hframes = data.idle_frames
	_sprite.scale = Vector2.ONE * data.scale
	add_child(_sprite)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if GameManager.run_state != GameManager.RunState.PLAYING or data == null:
		return
	var core := get_tree().get_first_node_in_group("objective") as Node2D
	if core == null:
		return
	path_timer -= delta
	var direction := global_position.direction_to(core.global_position)
	if path_timer <= 0.0:
		path_timer = 0.35
		var arena := get_tree().current_scene.get_node_or_null("ArenaGenerator") as ArenaGenerator
		if arena:
			direction = arena.direction_to_target(global_position, core.global_position)
	velocity = direction * data.move_speed
	move_and_slide()
	attack_timer -= delta
	if global_position.distance_to(core.global_position) < 55.0 and attack_timer <= 0.0:
		if core.has_method("take_damage"):
			var core_damage := data.contact_damage
			var multiplier = core.get("damage_multiplier")
			if multiplier != null:
				core_damage = int(round(float(core_damage) * float(multiplier)))
			core.take_damage(core_damage)
		attack_timer = data.attack_interval

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
