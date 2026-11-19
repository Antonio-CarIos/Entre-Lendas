class_name DialogueChoiceData
extends Resource
## Resposta estática; condições e efeitos são avaliados por DialogueContext.

@export var id: StringName = &""
@export var label: String = ""
@export var next_id: StringName = &""
@export var condition_id: StringName = &""
@export var effect_id: StringName = &""
@export var conditions: PackedStringArray = []
@export var effects: PackedStringArray = []
