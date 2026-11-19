extends Node
## Único serviço persistente de som. Recursos ausentes permanecem silenciosos.

signal preferences_changed()
signal hat_silence_finished()

const DEFAULT_CATALOG: AudioCatalog = preload("res://core/audio/stage_01_audio.tres")
const MAX_VOICES: int = 16

var preferences: MenuPreferences = MenuPreferences.new()
var director: AudioDirector = AudioDirector.new()
var catalog: AudioCatalog = DEFAULT_CATALOG
var scene_context: String = ""
var ambience_id: StringName = &""
var _music: AudioStreamPlayer
var _ambience: AudioStreamPlayer
var _music_id: StringName = &""
var _voices: Array[WeakRef] = []
var _last_tick: int = 0
var _silence_applied: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ensure_buses()
	preferences.load_preferences()
	_music = AudioStreamPlayer.new()
	_music.name = "Music"
	_music.bus = &"Music"
	add_child(_music)
	_ambience = AudioStreamPlayer.new()
	_ambience.name = "Ambience"
	_ambience.bus = &"SFX"
	add_child(_ambience)
	refresh_preferences()
	WorldState.stage01.changed.connect(_on_stage_changed)
	WorldState.scene_transition.transition_finished.connect(_on_travel_finished)
	_last_tick = Time.get_ticks_usec()


func _process(_delta: float) -> void:
	var now: int = Time.get_ticks_usec()
	var seconds: float = float(now - _last_tick) / 1000000.0
	_last_tick = now
	var was_silenced: bool = director.silenced
	director.advance(seconds)
	_sync_music()
	_sync_gates()
	if was_silenced and not director.silenced:
		hat_silence_finished.emit()


func ensure_buses() -> void:
	for bus_name: StringName in [&"Music", &"SFX"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
		AudioServer.set_bus_send(AudioServer.get_bus_index(bus_name), &"Master")


func refresh_preferences() -> void:
	preferences.apply_audio()
	_sync_gates(true)
	preferences_changed.emit()


func set_scene_context(scene_path: String) -> void:
	if scene_path.get_file().get_basename() == "main_menu":
		cancel_temporary_effect()
	scene_context = scene_path
	_refresh_context()


func _on_travel_finished(scene_path: String) -> void:
	if not scene_path.is_empty():
		set_scene_context(scene_path)


func _on_stage_changed() -> void:
	var state: Stage01State = WorldState.stage01
	if not state.active:
		cancel_temporary_effect()
	elif state.gorro_obtido and not state.has_event(&"hat_audio_started"):
		# Reservar antes do sinal reentrante; coleta repetida não estende os três segundos.
		state.record_event(&"hat_audio_started")
		begin_hat_silence()
	_refresh_context()


func _refresh_context() -> void:
	var state: Stage01State = WorldState.stage01
	var music: StringName = &""
	var ambience: StringName = &""
	var map_name: String = scene_context.get_file().get_basename()
	if map_name == "main_menu":
		music = &"menu"
	elif map_name == "scene_01_book_intro":
		music = &"book"
	elif map_name in ["house_interior", "house_bedroom", "house_backyard", "santa_teresa_map", "saci_climax", "saci_turn_combat"]:
		music = &"city_sunset" if map_name in ["santa_teresa_map", "house_backyard"] else &"house_clean"
		ambience = &"city_wind" if map_name in ["santa_teresa_map", "house_backyard"] else &"house_ambience"
		if map_name in ["saci_climax", "saci_turn_combat"]:
			music = &"climax"
		if state.active:
			match state.phase:
				&"scene_4_dialogue": music = &"saci_conversation"
				&"scene_5_whirlwind": music = &"whirlwind"
				&"scene_6_house_chaos", &"scene_7_street_hub": music = &"investigation"
				&"scene_8_climax": music = &"climax"
				&"incomplete_recovery": music = &"recovery"
				&"epilogue_capture": music = &"epilogue_capture"
				&"epilogue_friendship": music = &"epilogue_friendship"
				&"completed":
					music = &"epilogue_friendship" if state.final_outcome == WorldStateLogic.Outcome.FRIENDSHIP else &"epilogue_capture"
	director.request_music(music)
	set_ambience(ambience)


func set_ambience(cue_id: StringName) -> void:
	if ambience_id == cue_id:
		return
	ambience_id = cue_id
	_ambience.stop()
	_ambience.stream = _get_stream(cue_id, AudioCue.Kind.AMBIENCE)
	if _ambience.stream != null:
		_ambience.play()


func begin_hat_silence() -> bool:
	if not director.begin_hat_silence():
		return false
	_sync_gates(true)
	return true


func cancel_temporary_effect() -> void:
	director.cancel_temporary_effect()
	_sync_gates(true)
	if is_instance_valid(_music):
		_music.pitch_scale = 1.0


func stop_all() -> void:
	director.reset()
	_music.stop()
	_music.stream = null
	_music_id = &""
	_ambience.stop()
	_ambience.stream = null
	ambience_id = &""
	for voice: WeakRef in _voices:
		var node: Node = voice.get_ref() as Node
		if is_instance_valid(node):
			node.queue_free()
	_voices.clear()
	_sync_gates(true)


func play_sfx(cue_id: StringName) -> AudioStreamPlayer:
	var stream: AudioStream = _get_stream(cue_id, AudioCue.Kind.SFX)
	if stream == null or director.silenced:
		return null
	var voice: AudioStreamPlayer = AudioStreamPlayer.new()
	voice.stream = stream
	voice.bus = &"SFX"
	add_child(voice)
	_register_voice(voice)
	voice.finished.connect(voice.queue_free)
	voice.play()
	return voice


func play_positional(cue_id: StringName, world: Node2D, position: Vector2) -> AudioStreamPlayer2D:
	var stream: AudioStream = _get_stream(cue_id, AudioCue.Kind.SFX)
	if stream == null or director.silenced or not is_instance_valid(world) or not world.is_inside_tree():
		return null
	var voice: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	voice.stream = stream
	voice.bus = &"SFX"
	voice.max_distance = 480.0
	world.add_child(voice)
	voice.global_position = position
	_register_voice(voice)
	voice.finished.connect(voice.queue_free)
	voice.play()
	return voice


func _register_voice(node: Node) -> void:
	for index: int in range(_voices.size() - 1, -1, -1):
		if _voices[index].get_ref() == null:
			_voices.remove_at(index)
	if _voices.size() >= MAX_VOICES:
		var oldest: Node = _voices.pop_front().get_ref() as Node
		if is_instance_valid(oldest):
			oldest.queue_free()
	_voices.append(weakref(node))


func _get_stream(cue_id: StringName, kind: AudioCue.Kind) -> AudioStream:
	var cue: AudioCue = catalog.find_cue(cue_id) if catalog != null else null
	if cue == null or cue.kind != kind or cue.stream == null:
		return null
	var stream: AudioStream = cue.stream.duplicate() as AudioStream
	var loop: bool = kind != AudioCue.Kind.SFX
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
		if loop and (stream as AudioStreamWAV).loop_end == 0:
			(stream as AudioStreamWAV).loop_end = maxi(1, roundi(stream.get_length() * (stream as AudioStreamWAV).mix_rate))
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = loop
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = loop
	return stream


func _sync_music() -> void:
	if _music_id != director.current_music:
		_music_id = director.current_music
		_music.stop()
		_music.stream = _get_stream(_music_id, AudioCue.Kind.MUSIC)
		if _music.stream != null:
			_music.play()
	_music.volume_linear = director.music_gain
	_music.pitch_scale = director.return_pitch


func _sync_gates(force: bool = false) -> void:
	if not force and _silence_applied == director.silenced:
		return
	_silence_applied = director.silenced
	for bus_name: StringName in [&"Music", &"SFX"]:
		var index: int = AudioServer.get_bus_index(bus_name)
		if index >= 0:
			var muted: bool = preferences.music_muted if bus_name == &"Music" else preferences.sfx_muted
			AudioServer.set_bus_mute(index, muted or director.silenced)
