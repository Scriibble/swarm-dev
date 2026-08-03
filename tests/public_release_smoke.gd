extends SceneTree

func _init() -> void:
	assert(FileAccess.file_exists("res://export_presets.cfg"), "Desktop export presets are required")
	assert(FileAccess.file_exists("res://assets/icon.svg"), "Application icon is required")
	var project_text := FileAccess.get_file_as_string("res://project.godot")
	assert(project_text.contains("config/icon=\"res://assets/icon.svg\""), "Project icon metadata is missing")
	assert(project_text.contains("window/size/resizable=true"), "Resizable desktop window is required")
	var preset_text := FileAccess.get_file_as_string("res://export_presets.cfg")
	for preset_name in ["Windows Desktop", "Linux", "macOS"]:
		assert(preset_text.contains("name=\"%s\"" % preset_name), "Missing export preset: %s" % preset_name)
	print("public release smoke test passed: metadata, icon, presets, and resizable window")
	quit()
