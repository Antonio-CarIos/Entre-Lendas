extends GutTest
## Fixtures WAV silenciosas existem só em memória; não simulam a entrega da trilha.

const PREFS_FILE: String = "user://test_audio_accessibility.cfg"
const MENU: PackedScene = preload("res://ui/main_menu.tscn")
const BOOK: PackedScene = preload("res://stages/stage_01_saci/scene_01_book_intro.tscn")
const HUD: PackedScene = preload("res://ui/gameplay_hud.tscn")

var _old_preferences: MenuPreferences
var _old_catalog: AudioCatalog
var _old_director: AudioDirector
var _old_context: String
var _old_processing: bool
var _bus_values: Dictionary[StringName, Dictionary] = {}
var _nodes: Array[Node] = []


func before_each() -> void:
	_old_preferences = AudioManager.preferences
	_old_catalog = AudioManager.catalog
	_old_director = AudioManager.director
	_old_context = AudioManager.scene_context
	_old_processing = AudioManager.is_processing()
	for bus: StringName in [&"Master", &"Music", &"SFX"]:
		var index: int = AudioServer.get_bus_index(bus)
		_bus_values[bus] = {"volume": AudioServer.get_bus_volume_linear(index), "mute": AudioServer.is_bus_mute(index)}
	AudioManager.set_process(false)
	AudioManager.stop_all()
	WorldState.reset()
	AudioManager.director = AudioDirector.new()
	AudioManager.preferences = MenuPreferences.new()
	AudioManager.preferences.file_path = PREFS_FILE
	AudioManager.catalog = AudioManager.DEFAULT_CATALOG
	AudioManager.refresh_preferences()
	if FileAccess.file_exists(PREFS_FILE):
		DirAccess.remove_absolute(PREFS_FILE)


func after_each() -> void:
	get_tree().paused = false
	for node: Node in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()
	WorldState.reset()
	AudioManager.stop_all()
	AudioManager.preferences = _old_preferences
	AudioManager.catalog = _old_catalog
	AudioManager.director = _old_director
	AudioManager.set_scene_context(_old_context)
	AudioManager.refresh_preferences()
	AudioManager.set_process(_old_processing)
	for bus: StringName in _bus_values:
		var index: int = AudioServer.get_bus_index(bus)
		AudioServer.set_bus_volume_linear(index, float(_bus_values[bus]["volume"]))
		AudioServer.set_bus_mute(index, bool(_bus_values[bus]["mute"]))
	if FileAccess.file_exists(PREFS_FILE):
		DirAccess.remove_absolute(PREFS_FILE)
	await wait_process_frames(2)


func test_single_service_named_buses_and_missing_assets_are_safe() -> void:
	assert_eq(ProjectSettings.get_setting("autoload/AudioManager"), "*res://core/autoloads/audio_manager.gd")
	var count: int = AudioServer.bus_count
	AudioManager.ensure_buses()
	AudioManager.ensure_buses()
	assert_eq(AudioServer.bus_count, count)
	for bus: StringName in [&"Music", &"SFX"]:
		assert_eq(AudioServer.get_bus_send(AudioServer.get_bus_index(bus)), &"Master")
	var ids: Array[StringName] = []
	for cue: AudioCue in AudioManager.DEFAULT_CATALOG.cues:
		assert_false(cue.id in ids)
		ids.append(cue.id)
		if cue.stream == null:
			assert_true(cue.id in AudioManager.DEFAULT_CATALOG.get_missing_cues())
		else:
			assert_false(cue.source.is_empty())
			assert_false(cue.license.is_empty())
	assert_null(AudioManager.play_sfx(&"not_registered"))
	assert_null(AudioManager.play_positional(&"not_registered", null, Vector2.ZERO))
	AudioManager.set_scene_context("res://ui/main_menu.tscn")
	AudioManager.director.advance(1.0)
	AudioManager.call("_sync_music")
	assert_eq(AudioManager.director.current_music, &"menu")


func test_pure_fade_switches_one_track_and_latest_request_wins() -> void:
	var director: AudioDirector = AudioDirector.new()
	director.request_music(&"menu")
	director.advance(0.4)
	director.advance(0.4)
	assert_eq(director.current_music, &"menu")
	assert_eq(director.music_gain, 1.0)
	director.request_music(&"menu")
	assert_eq(director.music_gain, 1.0)
	director.request_music(&"book")
	director.advance(0.2)
	assert_eq(director.current_music, &"menu")
	assert_almost_eq(director.music_gain, 0.5, 0.001)
	director.request_music(&"investigation")
	director.advance(0.2)
	assert_eq(director.current_music, &"investigation")
	assert_eq(director.music_gain, 0.0)
	director.advance(0.4)
	assert_eq(director.music_gain, 1.0)
	director.request_music(&"")
	director.advance(0.4)
	assert_eq(director.current_music, &"")
	assert_eq(director.music_gain, 0.0)


func test_hat_silence_is_three_seconds_once_and_returns_lower() -> void:
	var director: AudioDirector = AudioDirector.new()
	assert_true(director.begin_hat_silence())
	assert_eq(director.silence_remaining, 3.0)
	director.advance(2.0)
	assert_false(director.begin_hat_silence())
	assert_eq(director.silence_remaining, 1.0)
	director.request_music(&"investigation")
	director.advance(0.999)
	assert_true(director.silenced)
	assert_eq(director.return_pitch, 1.0)
	director.advance(0.001)
	assert_false(director.silenced)
	assert_eq(director.return_pitch, AudioDirector.HAT_RETURN_PITCH)
	assert_eq(director.requested_music, &"investigation")
	assert_false(director.begin_hat_silence())
	director.cancel_temporary_effect()
	assert_eq(director.return_pitch, 1.0)
	assert_true(director.begin_hat_silence())
	director.advance(-1.0)
	assert_eq(director.silence_remaining, 3.0)


func test_preferences_roundtrip_preserves_future_keys_and_validates_new_fields() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("future", "keep", "untouched")
	assert_eq(config.save(PREFS_FILE), OK)
	var prefs: MenuPreferences = AudioManager.preferences
	prefs.master_volume = 0.6
	prefs.music_volume = 0.4
	prefs.sfx_volume = 0.2
	prefs.music_muted = true
	prefs.text_speed = 90.0
	prefs.reduced_effects = true
	assert_eq(prefs.save_preferences(), OK)
	var restored: MenuPreferences = MenuPreferences.new()
	restored.file_path = PREFS_FILE
	restored.load_preferences()
	assert_eq(restored.master_volume, 0.6)
	assert_eq(restored.music_volume, 0.4)
	assert_eq(restored.sfx_volume, 0.2)
	assert_true(restored.music_muted)
	assert_eq(restored.text_speed, 90.0)
	assert_true(restored.reduced_effects)
	assert_eq(config.load(PREFS_FILE), OK)
	assert_eq(config.get_value("future", "keep"), "untouched")
	config.set_value("audio", "music_volume", "loud")
	config.set_value("audio", "sfx_volume", -10)
	config.set_value("audio", "music_muted", 1)
	config.set_value("accessibility", "text_speed", 5000)
	config.set_value("accessibility", "reduced_effects", "yes")
	config.save(PREFS_FILE)
	restored.load_preferences()
	assert_eq(restored.music_volume, 0.8)
	assert_eq(restored.sfx_volume, 0.0)
	assert_eq(restored.text_speed, 120.0)
	assert_false(restored.music_muted)
	assert_false(restored.reduced_effects)


func test_user_channel_volumes_and_mutes_survive_silence_and_setting_changes() -> void:
	var prefs: MenuPreferences = AudioManager.preferences
	prefs.master_volume = 0.6
	prefs.music_volume = 0.35
	prefs.sfx_volume = 0.7
	prefs.sfx_muted = true
	AudioManager.refresh_preferences()
	AudioManager.begin_hat_silence()
	assert_true(_muted(&"Music"))
	assert_true(_muted(&"SFX"))
	assert_false(_muted(&"Master"))
	prefs.music_volume = 0.2
	prefs.music_muted = true
	prefs.sfx_muted = false
	AudioManager.refresh_preferences()
	assert_true(_muted(&"SFX"))
	AudioManager.director.advance(3.0)
	AudioManager.call("_sync_gates")
	assert_true(_muted(&"Music"))
	assert_false(_muted(&"SFX"))
	assert_almost_eq(AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(&"Music")), 0.2, 0.001)
	assert_almost_eq(AudioServer.get_bus_volume_linear(0), 0.6, 0.001)
	AudioManager.cancel_temporary_effect()
	assert_true(_muted(&"Music"))
	assert_false(_muted(&"SFX"))


func test_pause_and_scene_change_during_effect_use_wall_clock_and_latest_track() -> void:
	AudioManager.set_scene_context("res://stages/stage_01_saci/house_interior.tscn")
	AudioManager.begin_hat_silence()
	get_tree().paused = true
	assert_eq(AudioManager.process_mode, Node.PROCESS_MODE_ALWAYS)
	AudioManager.set_scene_context("res://stages/stage_01_saci/santa_teresa_map.tscn")
	AudioManager.set("_last_tick", Time.get_ticks_usec() - 3000000)
	watch_signals(AudioManager)
	AudioManager.call("_process", 0.0)
	assert_false(AudioManager.director.silenced)
	assert_eq(AudioManager.director.current_music, &"city_sunset")
	assert_almost_eq((AudioManager.get_node("Music") as AudioStreamPlayer).pitch_scale, 0.85, 0.0001)
	assert_signal_emit_count(AudioManager, &"hat_silence_finished", 1)
	AudioManager.call("_process", 0.0)
	assert_signal_emit_count(AudioManager, &"hat_silence_finished", 1)
	get_tree().paused = false


func test_story_hat_grant_is_single_and_reset_or_menu_cancels_effect_without_losing_preferences() -> void:
	WorldState.start_new_game()
	for phase: StringName in Stage01State.PHASES.slice(1, 7):
		assert_true(WorldState.stage01.advance_to(phase))
	var hat: ItemData = load("res://core/inventory/items/stage_01/gorro_saci.tres") as ItemData
	assert_true(WorldState.stage01.grant_quest_item(hat, WorldState.inventory))
	assert_true(AudioManager.director.silenced)
	AudioManager.director.advance(1.0)
	WorldState.stage01.record_event(&"other_event")
	assert_eq(AudioManager.director.silence_remaining, 2.0)
	assert_true(WorldState.stage01.has_event(&"hat_audio_started"))
	AudioManager.preferences.music_volume = 0.25
	WorldState.start_new_game()
	assert_false(AudioManager.director.silenced)
	assert_eq(AudioManager.director.return_pitch, 1.0)
	assert_eq(AudioManager.preferences.music_volume, 0.25)
	assert_true(AudioManager.begin_hat_silence())
	AudioManager.set_scene_context("res://ui/main_menu.tscn")
	assert_false(AudioManager.director.silenced)
	assert_eq(AudioManager.director.requested_music, &"menu")


func test_real_players_share_buses_one_bgm_and_positional_voice_follows_map_lifetime() -> void:
	var catalog: AudioCatalog = AudioCatalog.new()
	for id: StringName in [&"menu", &"book", &"ui_move"]:
		var cue: AudioCue = AudioCue.new()
		cue.id = id
		cue.kind = AudioCue.Kind.SFX if id == &"ui_move" else AudioCue.Kind.MUSIC
		cue.stream = _wav()
		catalog.cues.append(cue)
	AudioManager.catalog = catalog
	AudioManager.set_scene_context("res://ui/main_menu.tscn")
	AudioManager.director.advance(1.0)
	AudioManager.call("_sync_music")
	var music: AudioStreamPlayer = AudioManager.get_node("Music") as AudioStreamPlayer
	assert_true(music.playing)
	assert_eq(music.bus, &"Music")
	assert_eq((music.stream as AudioStreamWAV).loop_mode, AudioStreamWAV.LOOP_FORWARD)
	assert_eq((catalog.find_cue(&"menu").stream as AudioStreamWAV).loop_mode, AudioStreamWAV.LOOP_DISABLED)
	AudioManager.set_scene_context("res://stages/stage_01_saci/scene_01_book_intro.tscn")
	AudioManager.director.advance(1.0)
	AudioManager.call("_sync_music")
	assert_eq(AudioManager.get_node("Music"), music)
	assert_true(music.playing)
	var world: Node2D = Node2D.new()
	_track(world)
	var voice: AudioStreamPlayer2D = AudioManager.play_positional(&"ui_move", world, Vector2(80, 60))
	assert_not_null(voice)
	assert_eq(voice.bus, &"SFX")
	assert_eq(voice.global_position, Vector2(80, 60))
	assert_true(voice.playing)
	world.free()
	assert_false(is_instance_valid(voice))
	assert_null(AudioManager.play_sfx(&"menu"), "Não reproduzir BGM no canal de SFX")
	AudioManager.begin_hat_silence()
	assert_null(AudioManager.play_sfx(&"ui_move"))


func test_menu_keyboard_changes_channels_text_and_reduced_effects_with_shared_preferences() -> void:
	var menu: MainMenu = MENU.instantiate() as MainMenu
	menu.preferences_path = PREFS_FILE
	_track(menu)
	menu.show_page(MainMenu.Page.OPTIONS)
	await _tap(KEY_DOWN)
	await _tap(KEY_DOWN)
	await _tap(KEY_LEFT)
	assert_eq(AudioManager.preferences.music_volume, 0.75)
	await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	assert_true(AudioManager.preferences.music_muted)
	await _tap(KEY_DOWN)
	await _tap(KEY_LEFT)
	assert_eq(AudioManager.preferences.sfx_volume, 0.95)
	await _tap(KEY_DOWN)
	await _tap(KEY_E)
	assert_true(AudioManager.preferences.sfx_muted)
	await _tap(KEY_DOWN)
	await _tap(KEY_RIGHT)
	assert_eq(AudioManager.preferences.text_speed, 60.0)
	await _tap(KEY_DOWN)
	await _tap(KEY_ENTER)
	assert_true(AudioManager.preferences.reduced_effects)
	var restored: MenuPreferences = MenuPreferences.new()
	restored.file_path = PREFS_FILE
	restored.load_preferences()
	assert_eq(restored.text_speed, 60.0)
	assert_true(restored.reduced_effects)
	await _tap(KEY_DOWN)
	await _tap(KEY_E)
	assert_eq(menu.page, MainMenu.Page.MAIN)


func test_dialogue_speed_updates_live_and_reveal_still_requires_separate_advance() -> void:
	var view: DialogueView = load("res://ui/dialogue_view.tscn").instantiate() as DialogueView
	_track(view)
	assert_eq(view.characters_per_second, 45.0)
	AudioManager.preferences.text_speed = 120.0
	AudioManager.refresh_preferences()
	assert_eq(view.characters_per_second, 120.0)
	var entry: DialogueEntry = DialogueEntry.new()
	entry.id = &"reading"
	entry.text = "Uma história comprida para ser revelada pelo teclado."
	var catalog: Stage01Narrative = Stage01Narrative.new()
	catalog.entries = [entry]
	var session: DialogueSession = DialogueSession.new(DialogueContext.new(WorldState.stage01, WorldState.inventory))
	assert_true(session.start(catalog, &"reading"))
	view.present(session)
	var event: InputEventAction = InputEventAction.new()
	event.action = &"interact"
	event.pressed = true
	view.handle_input(event)
	assert_true(session.revealed)
	assert_true(session.active)
	view.handle_input(event)
	assert_false(session.active)


func test_reduced_book_effect_retains_text_duration_and_destination_contract() -> void:
	AudioManager.preferences.reduced_effects = true
	var book: BookIntro = BOOK.instantiate() as BookIntro
	book.dissolve_duration = 10.0
	_track(book)
	book.escurecer_tela()
	assert_eq(book.step, BookIntro.Step.DISSOLVING)
	assert_false((book.get_node("Letras") as Control).visible)
	assert_true((book.get_node("Interface/Title") as Label).text.contains("letras"))
	await wait_process_frames(3)
	var material: ShaderMaterial = (book.get_node("Livro") as TextureRect).material as ShaderMaterial
	assert_eq(float(material.get_shader_parameter(&"glow")), 0.0)
	assert_eq(float(material.get_shader_parameter(&"dissolve")), 0.0)
	assert_eq(book.proxima_cena, "res://stages/stage_01_saci/santa_teresa_map.tscn")
	assert_eq(book.dissolve_duration, 10.0)


func test_reduced_sequence_omits_flash_but_runs_logical_effect_and_restores_modal() -> void:
	AudioManager.preferences.reduced_effects = true
	WorldState.start_new_game()
	var root: Node2D = Node2D.new()
	_track(root)
	var hud: GameplayHUD = HUD.instantiate() as GameplayHUD
	root.add_child(hud)
	var coordinator: CutsceneCoordinator = CutsceneCoordinator.new()
	root.add_child(coordinator)
	var sequence: CutsceneSequence = CutsceneSequence.new()
	sequence.id = &"reduced_sequence"
	var flash: CutsceneStep = CutsceneStep.new()
	flash.kind = CutsceneStep.Kind.FADE
	flash.intense_effect = true
	flash.fade_alpha = 1.0
	flash.duration = 0.01
	var effect: CutsceneStep = CutsceneStep.new()
	effect.kind = CutsceneStep.Kind.EFFECT
	effect.effect_id = &"flag:reduced_effect_done"
	sequence.steps = [flash, effect]
	assert_true(coordinator.start(sequence, hud, root))
	await wait_process_frames(2)
	assert_eq(float(coordinator.get("_alpha")), 0.0)
	await wait_process_frames(5)
	assert_false(coordinator.running)
	assert_true(WorldState.stage01.has_event(&"reduced_effect_done"))
	assert_eq(hud.mode, GameplayHUD.ModalMode.NONE)
	assert_false(WorldState.scene_transition.has_presentation())


func _track(node: Node) -> void:
	get_tree().root.add_child(node)
	_nodes.append(node)


func _muted(bus: StringName) -> bool:
	return AudioServer.is_bus_mute(AudioServer.get_bus_index(bus))


func _wav() -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var data: PackedByteArray = []
	data.resize(44100)
	data.fill(0)
	stream.data = data
	return stream


func _tap(key: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	await wait_process_frames(2)
	event = InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	Input.parse_input_event(event)
	await wait_process_frames(2)
