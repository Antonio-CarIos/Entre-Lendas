class_name AudioCue
extends Resource
## Um som com origem/licença rastreáveis. stream vazio é uma pendência explícita.

enum Kind { MUSIC, AMBIENCE, SFX }

@export var id: StringName = &""
@export var kind: Kind = Kind.SFX
@export var stream: AudioStream
@export var source: String = ""
@export var license: String = ""
