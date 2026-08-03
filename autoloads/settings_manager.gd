extends Node

signal fullscreen_changed(enabled: bool)

const SETTINGS_PATH := "user://settings.cfg"
var fullscreen := false

func _ready() -> void:
	_load_settings()
	_apply_window_mode()

func toggle_fullscreen() -> void:
	fullscreen = not fullscreen
	_apply_window_mode()
	_save_settings()
	fullscreen_changed.emit(fullscreen)

func set_fullscreen(enabled: bool) -> void:
	if fullscreen == enabled:
		return
	fullscreen = enabled
	_apply_window_mode()
	_save_settings()
	fullscreen_changed.emit(fullscreen)

func fullscreen_label() -> String:
	return "WINDOWED" if fullscreen else "FULLSCREEN"

func _apply_window_mode() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		fullscreen = bool(config.get_value("display", "fullscreen", false))

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("display", "fullscreen", fullscreen)
	config.save(SETTINGS_PATH)
