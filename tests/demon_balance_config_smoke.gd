extends SceneTree

func _init() -> void:
	var demons := RogueliteCatalog.demon_data()
	var candidate := DemonBalanceConfig.candidate_from_demon(demons[0])
	var valid := DemonBalanceConfig.validate_candidate(candidate)
	assert(bool(valid.valid), "Catalog demon candidate must validate")
	var invalid := candidate.duplicate(true)
	invalid.cost = 9999
	assert(not bool(DemonBalanceConfig.validate_candidate(invalid).valid), "Out-of-range cost must be rejected")
	invalid = candidate.duplicate(true)
	invalid.starting_abilities = ["not_an_ability"]
	assert(not bool(DemonBalanceConfig.validate_candidate(invalid).valid), "Unknown starting ability must be rejected")
	var merged := DemonBalanceConfig.merge_candidate(candidate, {"modifiers": {"xp_requirement_multiplier": 1.05}})
	assert(is_equal_approx(float(merged.modifiers.xp_requirement_multiplier), 1.05), "Candidate modifier merge failed")
	var result := DemonBalanceRunResult.new()
	result.demon_id = &"demon_summoner"
	result.seed = 1
	result.victory = true
	result.ability_damage = {"ember_bolt": 12}
	var serialized := result.to_dictionary()
	assert(serialized.demon_id == "demon_summoner", "Run result serialization failed")
	assert(int(serialized.ability_damage.ember_bolt) == 12, "Run damage serialization failed")
	print("demon balance config smoke test passed")
	quit()
