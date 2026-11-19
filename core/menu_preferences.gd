class_name MenuPreferences
extends RefCounted
## Preferências do menu; o progresso da partida não pertence a este arquivo.

var file_path: String = "user://preferences.cfg"
var master_volume: float = 1.0
var muted: bool = false
var music_volume: float = 0.8
var music_muted: bool = false
var sfx_volume: float = 1.0
var sfx_muted: bool = false
var text_speed: float = 45.0
var reduced_effects: bool = false


func load_preferences() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(file_path) != OK:
		return
	var saved_volume: Variant = config.get_value("audio", "master_volume", 1.0)
	if (saved_volume is float or saved_volume is int) and is_finite(float(saved_volume)):
		master_volume = clampf(float(saved_volume), 0.0, 1.0)
	var saved_muted: Variant = config.get_value("audio", "muted", false)
	if saved_muted is bool:
		muted = saved_muted
	music_volume = _number(config, "audio", "music_volume", 0.8, 0.0, 1.0)
	sfx_volume = _number(config, "audio", "sfx_volume", 1.0, 0.0, 1.0)
	text_speed = _number(config, "accessibility", "text_speed", 45.0, 15.0, 120.0)
	music_muted = _boolean(config, "audio", "music_muted")
	sfx_muted = _boolean(config, "audio", "sfx_muted")
	reduced_effects = _boolean(config, "accessibility", "reduced_effects")


func apply_audio() -> void:
	AudioServer.set_bus_volume_linear(0, master_volume)
	AudioServer.set_bus_mute(0, muted)
	for bus_name: StringName in [&"Music", &"SFX"]:
		var index: int = AudioServer.get_bus_index(bus_name)
		if index >= 0:
			AudioServer.set_bus_volume_linear(index, music_volume if bus_name == &"Music" else sfx_volume)
			AudioServer.set_bus_mute(index, music_muted if bus_name == &"Music" else sfx_muted)


func save_preferences() -> Error:
	var config: ConfigFile = ConfigFile.new()
	# Preserva futuras opções de Music/SFX, texto e acessibilidade no mesmo arquivo.
	config.load(file_path)
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "muted", muted)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "music_muted", music_muted)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "sfx_muted", sfx_muted)
	config.set_value("accessibility", "text_speed", text_speed)
	config.set_value("accessibility", "reduced_effects", reduced_effects)
	return config.save(file_path)


func _number(config: ConfigFile, section: String, key: String, fallback: float, low: float, high: float) -> float:
	var value: Variant = config.get_value(section, key, fallback)
	if (value is int or value is float) and is_finite(float(value)):
		return clampf(float(value), low, high)
	return fallback


func _boolean(config: ConfigFile, section: String, key: String) -> bool:
	var value: Variant = config.get_value(section, key, false)
	return value if value is bool else false
