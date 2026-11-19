class_name DialogueEntry
extends Resource
## Um trecho de roteiro. Rubricas ficam separadas das falas visíveis ao jogador.

@export var id: StringName = &""
@export var scene_id: StringName = &""
@export var speaker: String = "Narração"
@export_multiline var text: String = ""
@export_multiline var stage_direction: String = ""
@export var next_id: StringName = &""
@export var event_id: StringName = &""
@export var condition_id: StringName = &""
@export var choices: Array[DialogueChoiceData] = []
@export var pages: PackedStringArray = []
@export var conditions: PackedStringArray = []
@export var effects: PackedStringArray = []
@export var cancel_allowed: bool = true
@export var source_paragraphs: PackedInt32Array = []
