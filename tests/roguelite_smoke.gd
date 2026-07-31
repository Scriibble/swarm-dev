extends SceneTree

func _init() -> void:
	var abilities := RogueliteCatalog.ability_data()
	var passives := RogueliteCatalog.passive_data()
	assert(abilities.size() == 8, "Expected eight abilities")
	assert(passives.size() == 8, "Expected eight passives")
	var ability_ranks := {&"ember_bolt": 1, &"blood_orbit": 1, &"core_pulse": 1}
	var passive_ranks := {&"emberheart": 1, &"cinder_step": 1, &"core_ward": 1}
	var rng := RandomNumberGenerator.new()
	rng.seed = 424242
	var offers := UpgradeOfferGenerator.generate(abilities.slice(0, 3), passives.slice(0, 3), ability_ranks, passive_ranks, [], rng)
	assert(offers.size() == 3, "Expected three upgrade offers")
	var ids: Array[StringName] = []
	for offer in offers:
		assert(offer.id not in ids, "Upgrade offers must be unique")
		ids.append(offer.id)
	var generator_a := ArenaGenerator.new()
	var parent_a := Node2D.new()
	root.add_child(parent_a)
	parent_a.add_child(generator_a)
	generator_a.generate(98765, parent_a, Vector2(720, 470))
	var generator_b := ArenaGenerator.new()
	var parent_b := Node2D.new()
	root.add_child(parent_b)
	parent_b.add_child(generator_b)
	generator_b.generate(98765, parent_b, Vector2(720, 470))
	assert(generator_a.obstacle_cells == generator_b.obstacle_cells, "Arena obstacles must be deterministic")
	assert(generator_a.hazard_cells == generator_b.hazard_cells, "Arena hazards must be deterministic")
	print("roguelite smoke test passed: offers=%d obstacles=%d hazards=%d" % [offers.size(), generator_a.obstacle_cells.size(), generator_a.hazard_cells.size()])
	parent_a.free()
	parent_b.free()
	quit()
