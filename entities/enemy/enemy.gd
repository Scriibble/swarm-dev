extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal died
signal xp_dropped(amount: int)

var data: EnemyData
var health: int
var attack_timer: float = 0.0
var path_timer: float = 0.0
@onready var _sprite: Sprite2D = %EnemySprite

func setup(enemy_data: EnemyData) -> void:
	data = enemy_data
	health = data.max_health
	_sprite.texture = data.texture
	_sprite.hframes = data.idle_frames
	_sprite.scale = Vector2.ONE * data.scale
	queue_redraw()

func _physics_process(delta: float) -> void:
	if GameManager.run_state != GameManager.RunState.PLAYING or data == null:
		return
	var core := get_tree().get_first_node_in_group("objective") as Node2D
	if core == null:
		return
	var target: Node2D = core
	var attack_range := 55.0
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if data.player_aggro_range > 0.0 and is_instance_valid(player) and global_position.distance_to(player.global_position) <= data.player_aggro_range:
		target = player
		attack_range = 42.0
	path_timer -= delta
	var direction := global_position.direction_to(target.global_position)
	if path_timer <= 0.0:
		path_timer = 0.35
		var arena := get_tree().current_scene.get_node_or_null("ArenaGenerator") as ArenaGenerator
		if arena:
			direction = arena.direction_to_target(global_position, target.global_position)
	velocity = direction * data.move_speed
	move_and_slide()
	if get_slide_collision_count() > 0:
		# Re-evaluate immediately after touching an obstacle or the core instead
		# of holding a blocked route direction until the normal path timer expires.
		path_timer = 0.0
	attack_timer -= delta
	if global_position.distance_to(target.global_position) < attack_range and attack_timer <= 0.0:
		if target.has_method("take_damage"):
			var core_damage := data.contact_damage
			if target == core:
				var multiplier = core.get("damage_multiplier")
				if multiplier != null:
					core_damage = int(round(float(core_damage) * float(multiplier)))
			target.take_damage(core_damage)
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
