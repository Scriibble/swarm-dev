class_name RogueliteCatalog
extends RefCounted

static func ability_data() -> Array[AbilityData]:
	return [
		_ability(&"ember_bolt", "Ember Bolt", &"projectile", 1, &"emberheart", &"inferno_bolt", 12, 0.32, 180.0, 0, 0, 0.65, 0.0, 0),
		_ability(&"blood_orbit", "Blood Orbit", &"orbit", 1, &"attack_damage", &"crimson_orbit", 7, 1.15, 180.0, 0, 0, 0.65, 0.0, 0),
		_ability(&"core_pulse", "Core Pulse", &"core_pulse", 1, &"core_ward", &"cataclysm_pulse", 14, 3.0, 170.0, 0, 0, 0.65, 0.0, 0),
		_ability(&"area_hazard", "Hellfire Field", &"hazard", 2, &"range", &"hellstorm", 10, 4.0, 210.0, 0, 0, 0.65, 0.0, 25),
		_ability(&"bone_spear", "Bone Spear", &"bone_spear", 2, &"attack_damage", &"grave_lance", 28, 1.05, 420.0, 2, 0, 0.65, 0.0, 30),
		_ability(&"chain_lash", "Chain Lash", &"chain_lash", 3, &"cooldown", &"writhing_chain", 22, 2.15, 240.0, 0, 4, 0.65, 0.0, 35),
		_ability(&"imp_swarm", "Imp Swarm", &"summon", 3, &"xp_gain", &"greater_swarm", 9, 3.5, 260.0, 0, 0, 0.65, 0.0, 40),
		_ability(&"life_drain", "Soul Drain", &"soul_drain", 2, &"max_health", &"soul_furnace", 16, 1.55, 220.0, 0, 0, 0.65, 0.35, 45),
	]

static func passive_data() -> Array[PassiveData]:
	return [
		_passive(&"emberheart", "Emberheart", "+4 attack damage per rank.", &"attack_damage", 4.0, 0, []),
		_passive(&"cinder_step", "Cinder Step", "+18 movement speed per rank.", &"move_speed", 18.0, 0, []),
		_passive(&"core_ward", "Core Ward", "+25 maximum core health per rank.", &"core_health", 25.0, 0, []),
		_passive(&"attack_damage", "Infernal Might", "+5 attack damage per rank.", &"attack_damage", 5.0, 20, [&"emberheart"]),
		_passive(&"cooldown", "Quickened Flame", "Faster attack cooldown per rank.", &"cooldown", 0.04, 25, [&"cinder_step"]),
		_passive(&"range", "Long Reach", "+25 attack range per rank.", &"range", 25.0, 25, [&"emberheart"]),
		_passive(&"xp_gain", "Soul Siphon", "+10% XP per rank.", &"xp_gain", 0.10, 30, [&"core_ward"]),
		_passive(&"pickup_radius", "Grave Magnet", "+35 pickup radius per rank.", &"pickup_radius", 35.0, 20, [&"cinder_step"]),
	]

static func demon_data() -> Array[DemonData]:
	return [
		_demon(&"demon_summoner", "Ash Summoner", "Balanced mobile summoner.", 0, [], [&"ember_bolt", &"blood_orbit", &"core_pulse"], [&"emberheart", &"cinder_step", &"core_ward"], {}),
		_demon(&"demon_bulwark", "Core Bulwark", "Defensive core guardian.", 50, [&"demon_summoner"], [&"core_pulse", &"area_hazard", &"ember_bolt"], [&"core_ward", &"max_health", &"pickup_radius"], {"core_max_health": 30, "core_effectiveness": 1.15}),
		_demon(&"demon_harbinger", "Blood Harbinger", "Aggressive close-range predator.", 75, [&"demon_summoner"], [&"blood_orbit", &"chain_lash", &"life_drain"], [&"attack_damage", &"cooldown", &"xp_gain"], {"close_damage": 0.12, "drain_effectiveness": 1.25}),
	]

static func ability_by_id(id: StringName) -> AbilityData:
	for ability in ability_data():
		if ability.id == id:
			return ability
	return null

static func passive_by_id(id: StringName) -> PassiveData:
	for passive in passive_data():
		if passive.id == id:
			return passive
	return null

static func demon_by_id(id: StringName) -> DemonData:
	for demon in demon_data():
		if demon.id == id:
			return demon
	return null

static func _ability(id: StringName, title: String, behavior: StringName, rarity: int, passive: StringName, evolution: StringName, damage: int, cooldown: float, ability_range: float, pierce: int, chains: int, falloff: float, heal: float, cost: int) -> AbilityData:
	var ability := AbilityData.new()
	ability.id = id
	ability.display_name = title
	ability.behavior_type = behavior
	ability.rarity = rarity
	ability.compatible_passive_id = passive
	ability.evolution_id = evolution
	ability.max_rank = 5
	ability.base_damage = damage
	ability.damage = damage
	ability.cooldown = cooldown
	ability.range = ability_range
	ability.pierce_count = pierce
	ability.chain_count = chains
	ability.damage_falloff = falloff
	ability.heal_ratio = heal
	ability.cost = cost
	return ability

static func _passive(id: StringName, title: String, description: String, stat: StringName, amount: float, cost: int, prerequisites: Array[StringName]) -> PassiveData:
	var passive := PassiveData.new()
	passive.id = id
	passive.display_name = title
	passive.description = description
	passive.stat = stat
	passive.amount = amount
	passive.cost = cost
	passive.prerequisites = prerequisites
	return passive

static func _demon(id: StringName, title: String, description: String, cost: int, prerequisites: Array[StringName], abilities: Array[StringName], passives: Array[StringName], modifiers: Dictionary) -> DemonData:
	var demon := DemonData.new()
	demon.id = id
	demon.display_name = title
	demon.description = description
	demon.cost = cost
	demon.prerequisites = prerequisites
	demon.starting_abilities = abilities
	demon.starting_passives = passives
	demon.modifiers = modifiers
	return demon
