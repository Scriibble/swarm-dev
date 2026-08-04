extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal died
signal xp_dropped(amount: int)

var data: EnemyData
var health: int
var attack_timer: float = 0.0
var path_timer: float = 0.0
var _sprite: AnimatedSprite2D
var _animation_lock: float = 0.0
var _dead: bool = false

func setup(enemy_data: EnemyData) -> void:
	data = enemy_data
	health = data.max_health
	_sprite = GeneratedArt.character_sprite(data.animation_bundle)
	_sprite.scale = Vector2.ONE * data.scale
	add_child(_sprite)
	_sprite.animation_finished.connect(_on_animation_finished)
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
	_animation_lock = maxf(_animation_lock - delta, 0.0)
	attack_timer -= delta
	if global_position.distance_to(core.global_position) < 55.0 and attack_timer <= 0.0:
		if core.has_method("take_damage"):
			var core_damage := data.contact_damage
			var multiplier = core.get("damage_multiplier")
			if multiplier != null:
				core_damage = int(round(float(core_damage) * float(multiplier)))
			core.take_damage(core_damage)
			_play_action(&"attack")
		attack_timer = data.attack_interval
	if _animation_lock <= 0.0 and not _dead and not (_sprite.animation in [&"attack", &"hurt"] and _sprite.is_playing()):
		_play_action(&"walk" if velocity.length_squared() > 0.01 else &"idle")

func take_damage(amount: int) -> void:
	health = maxi(health - amount, 0)
	health_changed.emit(health, data.max_health)
	EventBus.combat_feedback.emit(global_position, amount, &"enemy_hit")
	if _sprite:
		_sprite.modulate = Color("fff1c4")
		var flash := _sprite.create_tween()
		flash.tween_property(_sprite, "modulate", Color.WHITE, 0.08)
	if health == 0:
		_dead = true
		_play_action(&"death")
		died.emit()
		EventBus.combat_feedback.emit(global_position, 0, &"enemy_death")
		xp_dropped.emit(data.xp_value)
		GameManager.register_kill()
		GameManager.add_xp(data.xp_value)
		call_deferred("_queue_free_after_death")
	else:
		_play_action(&"hurt")

func _play_action(action: StringName) -> void:
	if _sprite == null:
		return
	_sprite.play(action)
	if action == &"attack":
		_animation_lock = 0.18
	elif action == &"hurt":
		_animation_lock = 0.22

func _on_animation_finished() -> void:
	if not _dead and _sprite.animation in [&"attack", &"hurt"]:
		_play_action(&"walk" if velocity.length_squared() > 0.01 else &"idle")

func _queue_free_after_death() -> void:
	if _sprite:
		await _sprite.animation_finished
	queue_free()

func _draw() -> void:
	draw_circle(Vector2(0, 22), 14.0, Color(0, 0, 0, 0.2))
