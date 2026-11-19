class_name DialogueInteractable
extends Area2D
## Texto de conversa reutilizável, apresentado pelo HUD ao receber interação.

signal interacted()

@export var speaker: String = ""
@export_multiline var message: String = ""
@export var narrative: Stage01Narrative
@export var entry_id: StringName = &""


func get_dialogue_text() -> String:
	return message if speaker.is_empty() else "%s: %s" % [speaker, message]
