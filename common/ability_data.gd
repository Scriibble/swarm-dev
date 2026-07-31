class_name AbilityData
extends Resource

@export var id: StringName = &"ability"
@export var display_name: String = "Ability"
@export var cooldown: float = 1.0
@export var range: float = 180.0
@export var damage: int = 8
@export var duration: float = 0.2
@export var directional: bool = true
@export var max_rank: int = 5
@export var rarity: int = 1
@export var compatible_passive_id: StringName = &""
@export var evolution_id: StringName = &""
@export var behavior_type: StringName = &"projectile"
@export var base_damage: int = 8
@export var pierce_count: int = 0
@export var chain_count: int = 0
@export var damage_falloff: float = 0.65
@export var heal_ratio: float = 0.0
@export var cost: int = 0
@export var prerequisites: Array[StringName] = []
