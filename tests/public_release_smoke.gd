extends SceneTree

func _init() -> void:
	var failures: Array[String] = []
	if not FileAccess.file_exists("res://export_presets.cfg"):
		failures.append("Desktop export presets are required")
	if not FileAccess.file_exists("res://assets/icon.svg"):
		failures.append("Application icon is required")
	var project_text := FileAccess.get_file_as_string("res://project.godot")
	if not project_text.contains("config/icon=\"res://assets/icon.svg\""):
		failures.append("Project icon metadata is missing")
	if not project_text.contains("window/size/resizable=true"):
		failures.append("Resizable desktop window is required")
	var preset_text := FileAccess.get_file_as_string("res://export_presets.cfg")
	for preset_name in ["Windows Desktop", "Linux", "macOS"]:
		if not preset_text.contains("name=\"%s\"" % preset_name):
			failures.append("Missing export preset: %s" % preset_name)
	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("public release smoke test passed: metadata, icon, presets, and resizable window")
	quit()
