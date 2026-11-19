class_name HouseInvestigationScript
extends RefCounted
## Adaptação de encenação da Cena 3; o roteiro-fonte compartilhado fica imutável.

const SOURCE: Stage01Narrative = preload("res://core/dialogue/stage_01/stage_01_script.tres")


static func create() -> Stage01Narrative:
	var catalog: Stage01Narrative = SOURCE.duplicate(true) as Stage01Narrative
	var memory: DialogueEntry = catalog.find_entry(&"pipe.memory_origins")
	memory.effects.append("clue:clue_origem_saci")
	memory.next_id = &"journal.origin"
	var origin: DialogueEntry = catalog.find_entry(&"journal.origin")
	origin.speaker = "Diário — Origem do Saci"
	origin.next_id = &"pipe.keep"
	catalog.find_entry(&"clean.arrival").cancel_allowed = false
	# A Cena 4 será encenada na Task 2.10. Entregar a fase uma vez após o Pop,
	# sem executar antecipadamente a conversa e as escolhas do Saci.
	var opening: DialogueEntry = catalog.find_entry(&"bottle.open")
	opening.next_id = &""
	opening.cancel_allowed = false
	return catalog
