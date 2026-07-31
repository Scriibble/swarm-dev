class_name PassiveData
extends Resource

@export var id: StringName = &"passive"
@export var display_name: String = "Passive"
@export_multiline var description: String = ""
@export var stat: StringName = &"attack_damage"
@export var amount: float = 1.0
@export var rarity: int = 1
@export var cost: int = 0
@export var prerequisites: Array[StringName] = []

