class_name Stage01Narrative
extends Resource
## Catálogo de texto sem efeitos colaterais; carregar o Resource não avança a fase.

@export var source_document: String = "Fase 1 - Saci.odt"
@export var entries: Array[DialogueEntry] = []


func find_entry(entry_id: StringName) -> DialogueEntry:
	for entry: DialogueEntry in entries:
		if entry != null and entry.id == entry_id:
			return entry
	return null


func get_scene_entries(scene_id: StringName) -> Array[DialogueEntry]:
	var result: Array[DialogueEntry] = []
	for entry: DialogueEntry in entries:
		if entry != null and entry.scene_id == scene_id:
			result.append(entry)
	return result


func get_validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = []
	var ids: Dictionary[StringName, bool] = {}
	for entry: DialogueEntry in entries:
		if entry == null:
			errors.append("Entrada nula")
			continue
		if entry.id == &"" or ids.has(entry.id):
			errors.append("ID vazio/duplicado: " + String(entry.id))
		ids[entry.id] = true
		if entry.text.strip_edges().is_empty() and entry.pages.is_empty():
			errors.append("Texto vazio: " + String(entry.id))
	for entry: DialogueEntry in entries:
		if entry == null:
			continue
		if entry.next_id != &"" and not ids.has(entry.next_id):
			errors.append("Destino ausente: " + String(entry.next_id))
		var choices: Dictionary[StringName, bool] = {}
		for choice: DialogueChoiceData in entry.choices:
			if choice == null:
				errors.append("Escolha nula: " + String(entry.id))
				continue
			if choice.id == &"" or choices.has(choice.id) or choice.label.is_empty():
				errors.append("Escolha inválida: " + String(entry.id))
			choices[choice.id] = true
			if choice.next_id != &"" and not ids.has(choice.next_id):
				errors.append("Destino de escolha ausente: " + String(choice.next_id))
	return errors
