extends SceneTree

const CHARACTER_BUNDLES := [&"ash_summoner", &"core_bulwark", &"blood_harbinger", &"human_soldier", &"orc"]
const EFFECTS := [&"ember_bolt", &"bone_spear", &"imp_swarm", &"blood_orbit", &"hellfire_field", &"chain_lash", &"soul_drain", &"core_pulse", &"impact_burst", &"evolution_burst"]

func _init() -> void:
	for bundle in CHARACTER_BUNDLES:
		var frames := GeneratedArt.character_frames(bundle)
		assert(frames.get_animation_names().size() == 5, "%s must expose five character animations" % bundle)
		assert(frames.get_frame_count("idle") == 4, "%s idle frame count" % bundle)
		assert(frames.get_frame_count("walk") == 6, "%s walk frame count" % bundle)
		assert(frames.get_frame_count("attack") == 4, "%s attack frame count" % bundle)
		assert(frames.get_frame_count("hurt") == 4, "%s hurt frame count" % bundle)
		assert(frames.get_frame_count("death") == 6, "%s death frame count" % bundle)
		for action in [&"idle", &"walk", &"attack", &"hurt", &"death"]:
			for frame_index in frames.get_frame_count(action):
				var texture := frames.get_frame_texture(action, frame_index)
				var used_rect := texture.get_image().get_used_rect()
				assert(used_rect.size.x <= 96 and used_rect.size.y <= 96, "%s %s frame exceeds normalized character envelope" % [bundle, action])
	for effect in EFFECTS:
		var effect_frames := GeneratedArt.effect_frames(effect)
		assert(effect_frames.get_frame_count("default") == 4, "%s effect frame count" % effect)
	var projectile := preload("res://features/projectile/projectile.tscn").instantiate()
	var hazard := preload("res://features/arena/hazard.tscn").instantiate()
	root.add_child(projectile)
	root.add_child(hazard)
	await process_frame
	assert(projectile.get_node("Visual").sprite_frames.get_frame_count("default") == 4, "projectile visual is animated")
	assert(hazard.get_node("Visual").sprite_frames.get_frame_count("default") == 4, "hazard visual is animated")
	projectile.queue_free()
	hazard.queue_free()
	print("generated art smoke test passed: bundles=%d effects=%d" % [CHARACTER_BUNDLES.size(), EFFECTS.size()])
	quit()
