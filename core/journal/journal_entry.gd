class_name JournalEntry
extends Resource
## Página do livro: conteúdo estático, sem estado de leitura no Resource compartilhado.

@export var id: StringName = &""
@export var title: String = ""
@export_multiline var text: String = ""
@export var origin: String = ""
@export var illustration: Texture2D
@export var dialogue_id: StringName = &""
@export var bonus: bool = false
