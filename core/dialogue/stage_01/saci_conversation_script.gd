class_name SaciConversationScript
extends RefCounted
## Encenação da Cena 4. Não executa a saída/desmaio da Cena 5 antecipadamente.

const SOURCE: Stage01Narrative = preload("res://core/dialogue/stage_01/stage_01_script.tres")


static func create() -> Stage01Narrative:
	var catalog: Stage01Narrative = SOURCE.duplicate(true) as Stage01Narrative
	for entry: DialogueEntry in catalog.get_scene_entries(&"scene_04"):
		entry.cancel_allowed = false
	catalog.find_entry(&"saci.farewell").next_id = &""
	var identity: DialogueEntry = catalog.find_entry(&"saci.identity")
	identity.text = identity.text.replace("Saci.(risonho)", "Saci.")
	identity.stage_direction = "Risonho. " + identity.stage_direction
	return catalog
