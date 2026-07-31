class_name UpgradeOfferGenerator
extends RefCounted

static func generate(abilities: Array, passives: Array, ability_ranks: Dictionary, passive_ranks: Dictionary, evolved: Array[StringName], rng: RandomNumberGenerator) -> Array[UpgradeData]:
	var pool: Array[UpgradeData] = []
	for ability in abilities:
		var rank: int = int(ability_ranks.get(ability.id, 0))
		if rank < ability.max_rank:
			pool.append(_ability_offer(ability, rank))
	for passive_data in passives:
		var passive := passive_data as UpgradeData
		if passive == null and passive_data is PassiveData:
			passive = _passive_offer(passive_data as PassiveData)
		if passive == null:
			continue
		var rank: int = int(passive_ranks.get(passive.target_id, 0))
		if rank < 5:
			pool.append(passive)
	for ability in abilities:
		var rank: int = int(ability_ranks.get(ability.id, 0))
		if rank >= ability.max_rank and ability.evolution_id != &"" and ability.evolution_id not in evolved and int(passive_ranks.get(ability.compatible_passive_id, 0)) > 0:
			var evolution := _ability_offer(ability, rank)
			evolution.offer_type = &"evolution"
			evolution.id = ability.evolution_id
			evolution.target_id = ability.id
			evolution.evolution_id = ability.evolution_id
			evolution.title = "Evolution: " + evolution.title
			evolution.description = "Transform " + evolution.title.replace("Evolution: ", "") + " into its evolved form."
			pool.append(evolution)
	var result: Array[UpgradeData] = []
	while result.size() < 3 and not pool.is_empty():
		var offer := _weighted_pick(pool, rng)
		result.append(offer)
		pool.erase(offer)
	return result

static func _ability_offer(ability: AbilityData, rank: int) -> UpgradeData:
	var offer := UpgradeData.new()
	offer.id = ability.id
	offer.target_id = ability.id
	offer.offer_type = &"ability"
	offer.title = ability.display_name + " %d/%d" % [rank + 1, ability.max_rank]
	offer.description = "Increase this ability's rank."
	offer.rarity = ability.rarity
	offer.rank_increment = 1
	offer.evolution_id = ability.evolution_id
	offer.compatible_passive_id = ability.compatible_passive_id
	return offer

static func _passive_offer(passive_data: PassiveData) -> UpgradeData:
	var passive := UpgradeData.new()
	passive.id = passive_data.id
	passive.target_id = passive_data.id
	passive.offer_type = &"passive"
	passive.title = passive_data.display_name
	passive.description = passive_data.description
	passive.stat = passive_data.stat
	passive.amount = passive_data.amount
	passive.rarity = passive_data.rarity
	return passive

static func _weighted_pick(pool: Array[UpgradeData], rng: RandomNumberGenerator) -> UpgradeData:
	var total: float = 0.0
	for offer in pool:
		total += 1.0 / float(maxi(offer.rarity, 1))
	var roll := rng.randf() * total
	for offer in pool:
		roll -= 1.0 / float(maxi(offer.rarity, 1))
		if roll <= 0.0:
			return offer
	return pool.back()
