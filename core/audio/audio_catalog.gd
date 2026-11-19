class_name AudioCatalog
extends Resource

@export var cues: Array[AudioCue] = []


func find_cue(id: StringName) -> AudioCue:
	for cue: AudioCue in cues:
		if cue != null and cue.id == id:
			return cue
	return null


func get_missing_cues() -> Array[StringName]:
	var missing: Array[StringName] = []
	for cue: AudioCue in cues:
		if cue != null and cue.stream == null:
			missing.append(cue.id)
	return missing
