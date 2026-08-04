class_name ImpProjectile
extends Area2D

var velocity := Vector2.ZERO
var damage: int = 8
var lifetime: float = 2.5
var source: Node2D
var phase: float = 0.0
var _sprite: AnimatedSprite2D

func _ready() -> void:
	_sprite = $Visual as AnimatedSprite2D
	_sprite.sprite_frames = GeneratedArt.effect_frames(&"imp_swarm")
	_sprite.play("default")

func setup(origin: Vector2, source_node: Node2D, damage_amount: int, color: Color) -> void:
	global_position = origin
	source = source_node
	damage = damage_amount
	_sprite.modulate = color

func _physics_process(delta: float) -> void:
	lifetime -= delta
	phase += delta * 8.0
	if lifetime <= 0.0:
		queue_free()
		return
	var nearest: Node2D
	var nearest_distance := 999999.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var distance: float = global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = enemy
	if nearest:
		velocity = global_position.direction_to(nearest.global_position) * 250.0
	global_position += velocity * delta
	for body in get_overlapping_bodies():
		if body.is_in_group("arena_obstacle") or body.is_in_group("objective"):
			queue_free()
			return
		if body.has_method("take_damage") and body.is_in_group("enemies"):
			body.take_damage(damage)
			queue_free()
			return
