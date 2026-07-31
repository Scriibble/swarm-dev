extends SceneTree

func _init() -> void:
	var abilities := RogueliteCatalog.ability_data()
	var passives := RogueliteCatalog.passive_data()
	var demons := RogueliteCatalog.demon_data()
	assert(abilities.size() == 8, "Expected eight abilities")
	assert(passives.size() == 9, "Expected nine passives")
	assert(demons.size() == 3, "Expected three demons")
	var expected_starting_abilities := {
		&"demon_summoner": &"ember_bolt",
		&"demon_bulwark": &"core_pulse",
		&"demon_harbinger": &"blood_orbit",
	}
	for demon in demons:
		assert(demon.starting_abilities.size() == 1, "Each demon must start with one ability")
		assert(demon.starting_abilities[0] == expected_starting_abilities[demon.id], "Demon starting ability mismatch")
	var bulwark := RogueliteCatalog.demon_by_id(&"demon_bulwark")
	assert(bool(bulwark.modifiers.get("dual_core_pulse", false)), "Core Bulwark must pulse from both the core and the player")
	assert(is_equal_approx(float(bulwark.modifiers.get("player_core_pulse_cooldown_multiplier", 1.0)), 0.5), "Core Bulwark player pulse must be twice as fast")
	var all_ids: Array[StringName] = []
	for entry in abilities + passives + demons:
		assert(entry.id not in all_ids, "Catalog IDs must be unique")
		all_ids.append(entry.id)
	var bone_spear := RogueliteCatalog.ability_by_id(&"bone_spear")
	var chain_lash := RogueliteCatalog.ability_by_id(&"chain_lash")
	var soul_drain := RogueliteCatalog.ability_by_id(&"life_drain")
	assert(bone_spear.pierce_count >= 2, "Bone Spear must pierce")
	assert(chain_lash.chain_count >= 3, "Chain Lash must chain")
	assert(soul_drain.heal_ratio > 0.0, "Soul Drain must heal")
	var projectile_scene: PackedScene = load("res://features/projectile/projectile.tscn")
	var imp_projectile_scene: PackedScene = load("res://features/abilities/imp_projectile.tscn")
	var projectile: Area2D = projectile_scene.instantiate() as Area2D
	var imp_projectile: Area2D = imp_projectile_scene.instantiate() as Area2D
	assert(projectile.collision_mask == 26, "Player projectiles must collide with enemies, objectives, and obstacles")
	assert(imp_projectile.collision_mask == 26, "Imp projectiles must collide with enemies, objectives, and obstacles")
	projectile.free()
	imp_projectile.free()
	var player_scene_text := FileAccess.get_file_as_string("res://entities/player/player.tscn")
	var enemy_scene_text := FileAccess.get_file_as_string("res://entities/enemy/enemy.tscn")
	var core_scene_text := FileAccess.get_file_as_string("res://entities/core/hell_core.tscn")
	assert(player_scene_text.contains("collision_mask = 24"), "Player must collide with the hell-core and obstacles")
	assert(enemy_scene_text.contains("collision_mask = 26"), "Enemies must collide with the hell-core, enemies, and obstacles")
	assert(core_scene_text.contains("collision_mask = 7"), "Hell-core must participate in player, enemy, and projectile collisions")
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
	var evolution_rng := RandomNumberGenerator.new()
	evolution_rng.seed = 99
	var evolution_offers := UpgradeOfferGenerator.generate([bone_spear], [RogueliteCatalog.passive_by_id(&"attack_damage")], {&"bone_spear": 5}, {&"attack_damage": 1}, [], evolution_rng)
	var found_evolution := false
	for offer in evolution_offers:
		if offer.offer_type == &"evolution" and offer.id == &"grave_lance":
			found_evolution = true
	assert(found_evolution, "Grave Lance must be offered at max rank with its passive")
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
	for spawn_point in generator_a.spawn_points:
		assert(generator_a.direction_to_target(spawn_point, Vector2(720, 470)).length_squared() > 0.01, "Spawn path direction must be valid")
	print("roguelite smoke test passed: offers=%d obstacles=%d hazards=%d" % [offers.size(), generator_a.obstacle_cells.size(), generator_a.hazard_cells.size()])
	parent_a.free()
	parent_b.free()
	quit()
