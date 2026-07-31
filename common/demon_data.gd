class_name DemonData
extends Resource

@export var id: StringName = &"demon_summoner"
@export var display_name: String = "Ash Summoner"
@export_multiline var description: String = ""
@export var cost: int = 0
@export var prerequisites: Array[StringName] = []
@export var starting_abilities: Array[StringName] = []
@export var starting_passives: Array[StringName] = []
@export var modifiers: Dictionary = {}

