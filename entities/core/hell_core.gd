extends StaticBody2D

signal core_health_changed(current: int, maximum: int)
signal core_destroyed

@export var max_health: int = 300
@export var damage_multiplier: float = 0.06
const CORE_TEXTURE: Texture2D = preload("res://assets/placeholder/hell_core_placeholder.png")
var health: int
var _sprite: Sprite2D

func _ready() -> void:
	health = max_health
	_sprite = Sprite2D.new()
	_sprite.texture = CORE_TEXTURE
	_sprite.scale = Vector2.ONE * 0.12
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.z_index = 1
	add_child(_sprite)
	queue_redraw()

func take_damage(amount: int) -> void:
	health = maxi(health - amount, 0)
	core_health_changed.emit(health, max_health)
	EventBus.core_damaged.emit(amount, health)
	EventBus.combat_feedback.emit(global_position, amount, &"core_hit")
	if _sprite:
		_sprite.modulate = Color("fff1a8")
		var flash := _sprite.create_tween()
		flash.tween_property(_sprite, "modulate", Color.WHITE, 0.16)
	queue_redraw()
	if health == 0:
		core_destroyed.emit()
		GameManager.finish_run(false)

func increase_max_health(amount: int) -> void:
	max_health += amount
	health += amount
	core_health_changed.emit(health, max_health)
	GameManager.update_core_health(health, max_health)

func _draw() -> void:
	draw_arc(Vector2.ZERO, 76.0, -PI / 2.0, -PI / 2.0 + TAU * float(health) / max_health, 48, Color("ffb12e"), 5.0)
