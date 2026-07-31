extends Node

enum RunState { MENU, PLAYING, PAUSED, LEVEL_UP, VICTORY, DEFEAT }

var run_state: RunState = RunState.MENU
var elapsed_time: float = 0.0
var wave_index: int = 0
var xp: int = 0
var level: int = 1
var xp_to_next: int = 80
var active_upgrades: Array[StringName] = []
var ability_ranks: Dictionary = {}
var passive_ranks: Dictionary = {}
var evolved_abilities: Array[StringName] = []
var run_seed: int = 0
var kills: int = 0
var core_health: int = 300
var core_max_health: int = 300
var current_offers: Array[UpgradeData] = []
var active_demon_id: StringName = &"demon_summoner"
var demon_modifiers: Dictionary = {}
var level_up_times: Array[float] = []
var selected_upgrade_ids: Array[StringName] = []
var evolution_selections: Array[StringName] = []
var champion_time: float = -1.0
var last_run_summary: String = ""
var _offer_rng := RandomNumberGenerator.new()

func start_run() -> void:
	reset_run()
	run_seed = int(Time.get_unix_time_from_system()) ^ randi()
	_offer_rng.seed = run_seed
	var loadout := ProfileManager.get_starting_loadout()
	active_demon_id = StringName(loadout.get("demon_id", "demon_summoner"))
	demon_modifiers = Dictionary(loadout.get("modifiers", {}))
	core_max_health = 3600 + int(demon_modifiers.get("core_max_health", 0))
	core_health = core_max_health
	for ability_id in loadout.abilities:
		ability_ranks[StringName(ability_id)] = 1
	for passive_id in loadout.passives:
		passive_ranks[StringName(passive_id)] = 1
	xp_to_next = _xp_threshold_for_level(level)
	run_state = RunState.PLAYING
	EventBus.run_started.emit()

func reset_run() -> void:
	elapsed_time = 0.0
	wave_index = 0
	xp = 0
	level = 1
	xp_to_next = 80
	active_upgrades.clear()
	ability_ranks.clear()
	passive_ranks.clear()
	evolved_abilities.clear()
	kills = 0
	core_health = 3600
	core_max_health = 3600
	current_offers.clear()
	active_demon_id = &"demon_summoner"
	demon_modifiers.clear()
	level_up_times.clear()
	selected_upgrade_ids.clear()
	evolution_selections.clear()
	champion_time = -1.0
	last_run_summary = ""
	run_state = RunState.MENU

func tick_run(delta: float) -> void:
	if run_state == RunState.PLAYING:
		elapsed_time += delta

func register_kill() -> void:
	kills += 1

func update_core_health(current: int, maximum: int) -> void:
	core_health = current
	core_max_health = maximum

func add_xp(amount: int) -> void:
	if run_state != RunState.PLAYING:
		return
	var multiplier: float = 1.0 + float(passive_ranks.get(&"xp_gain", 0)) * 0.10
	xp += maxi(1, int(round(float(amount) * multiplier)))
	EventBus.xp_gained.emit(amount, xp)
	if xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		level_up_times.append(elapsed_time)
		xp_to_next = _xp_threshold_for_level(level)
		current_offers = get_upgrade_offers()
		run_state = RunState.LEVEL_UP
		EventBus.level_up_requested.emit(current_offers)

func get_upgrade_offers() -> Array[UpgradeData]:
	var abilities: Array[AbilityData] = []
	for ability in RogueliteCatalog.ability_data():
		if ability.id in ProfileManager.unlocked_abilities:
			abilities.append(ability)
	var passives: Array[UpgradeData] = []
	for passive_data in RogueliteCatalog.passive_data():
		if passive_data.id in ProfileManager.unlocked_passives:
			var passive := UpgradeData.new()
			passive.id = passive_data.id
			passive.target_id = passive_data.id
			passive.offer_type = &"passive"
			passive.title = passive_data.display_name
			passive.description = passive_data.description
			passive.stat = passive_data.stat
			passive.amount = passive_data.amount
			passive.rarity = passive_data.rarity
			passives.append(passive)
	return UpgradeOfferGenerator.generate(abilities, passives, ability_ranks, passive_ranks, evolved_abilities, _offer_rng)

func _xp_threshold_for_level(target_level: int) -> int:
	var base_threshold := 80 + maxi(target_level - 1, 0) * 14
	return maxi(1, int(round(float(base_threshold) * float(demon_modifiers.get("xp_requirement_multiplier", 1.0)))))

func choose_upgrade(upgrade: UpgradeData) -> void:
	if upgrade.offer_type == &"evolution":
		if upgrade.target_id not in evolved_abilities:
			evolved_abilities.append(upgrade.target_id)
		ability_ranks[upgrade.target_id] = 5
		evolution_selections.append(upgrade.evolution_id)
	else:
		var target := upgrade.target_id if upgrade.target_id != &"" else upgrade.id
		if upgrade.offer_type == &"ability":
			ability_ranks[target] = mini(int(ability_ranks.get(target, 0)) + upgrade.rank_increment, 5)
		else:
			passive_ranks[target] = mini(int(passive_ranks.get(target, 0)) + upgrade.rank_increment, 5)
	active_upgrades.append(upgrade.id)
	selected_upgrade_ids.append(upgrade.id)
	run_state = RunState.PLAYING
	current_offers.clear()

func set_paused(value: bool) -> void:
	if run_state in [RunState.VICTORY, RunState.DEFEAT, RunState.LEVEL_UP]:
		return
	run_state = RunState.PAUSED if value else RunState.PLAYING
	get_tree().paused = value
	EventBus.run_paused.emit(value)

func finish_run(victory: bool) -> void:
	if run_state in [RunState.VICTORY, RunState.DEFEAT]:
		return
	run_state = RunState.VICTORY if victory else RunState.DEFEAT
	get_tree().paused = false
	var reward := RunReward.new()
	reward.survival_seconds = int(elapsed_time)
	reward.kills = kills
	reward.core_health_ratio = clampf(float(core_health) / float(maxi(core_max_health, 1)), 0.0, 1.0)
	reward.victory = victory
	reward.currency_awarded = int(reward.survival_seconds / 30) + int(reward.kills / 10) + int(floor(reward.core_health_ratio * 10.0))
	if victory:
		reward.currency_awarded += 20
	last_run_summary = get_run_summary(victory, reward.currency_awarded)
	ProfileManager.apply_run_reward(reward)
	_append_balance_log(last_run_summary)
	EventBus.run_rewarded.emit(reward)
	EventBus.run_ended.emit(victory)

func get_run_summary(victory: bool, shards: int) -> String:
	var first_level := "--"
	if not level_up_times.is_empty():
		first_level = "%ds" % int(level_up_times[0])
	return "LEVELS %d  |  FIRST LEVEL %s  |  KILLS %d  |  CORE %d%%  |  SHARDS +%d" % [level, first_level, kills, int(round(float(core_health) / float(maxi(core_max_health, 1)) * 100.0)), shards]

func _append_balance_log(summary: String) -> void:
	var file := FileAccess.open("user://balance_runs.log", FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open("user://balance_runs.log", FileAccess.WRITE)
	if file:
		file.seek_end()
		file.store_line("%s | demon=%s | victory=%s | %s | upgrades=%s | evolutions=%s" % [Time.get_datetime_string_from_system(), active_demon_id, str(run_state == RunState.VICTORY), summary, ",".join(PackedStringArray(selected_upgrade_ids)), ",".join(PackedStringArray(evolution_selections))])
