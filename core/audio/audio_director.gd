class_name AudioDirector
extends RefCounted
## Estado puro de uma única BGM. O relógio recebido independe da pausa do mapa.

const HAT_SILENCE_SECONDS: float = 3.0
const HAT_RETURN_PITCH: float = 0.85

var requested_music: StringName = &""
var current_music: StringName = &""
var music_gain: float = 0.0
var fade_seconds: float = 0.4
var _silence_usec: int = 0
var silence_remaining: float:
	get: return float(_silence_usec) / 1000000.0
var return_pitch: float = 1.0
var hat_effect_applied: bool = false

var silenced: bool:
	get: return silence_remaining > 0.0


func request_music(cue_id: StringName) -> void:
	requested_music = cue_id


func begin_hat_silence() -> bool:
	if hat_effect_applied:
		return false
	hat_effect_applied = true
	_silence_usec = roundi(HAT_SILENCE_SECONDS * 1000000.0)
	return_pitch = 1.0
	return true


func advance(seconds: float) -> void:
	if not is_finite(seconds) or seconds <= 0.0:
		return
	if silenced:
		_silence_usec = maxi(0, _silence_usec - roundi(seconds * 1000000.0))
		if not silenced:
			return_pitch = HAT_RETURN_PITCH
	var amount: float = seconds / maxf(0.001, fade_seconds)
	if current_music != requested_music:
		music_gain = maxf(0.0, music_gain - amount)
		if music_gain <= 0.0:
			current_music = requested_music
	else:
		music_gain = minf(1.0, music_gain + amount) if current_music != &"" else 0.0


func cancel_temporary_effect() -> void:
	_silence_usec = 0
	return_pitch = 1.0
	hat_effect_applied = false


func reset() -> void:
	cancel_temporary_effect()
	requested_music = &""
	current_music = &""
	music_gain = 0.0
