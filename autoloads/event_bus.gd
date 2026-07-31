extends Node

signal run_started
signal run_paused(is_paused: bool)
signal xp_gained(amount: int, total: int)
signal level_up_requested(choices: Array[UpgradeData])
signal player_died
signal core_damaged(amount: int, remaining: int)
signal run_ended(victory: bool)
signal run_rewarded(reward: RunReward)
signal ability_activated(ability_id: StringName, position: Vector2)
signal combat_feedback(position: Vector2, amount: int, kind: StringName)
signal evolution_selected(evolution_id: StringName, position: Vector2)
