class_name JournalSystem
extends RefCounted
## Consulta ao mesmo Stage01State da sessão; trocar de mapa não cria outro progresso.

const PAGES: Array[JournalEntry] = [
	preload("res://core/journal/pages/stage_01/clue_origem_saci.tres"),
	preload("res://core/journal/pages/stage_01/clue_poder_gorro_parede.tres"),
	preload("res://core/journal/pages/stage_01/clue_gorro_vermelho.tres"),
	preload("res://core/journal/pages/stage_01/clue_mural_origens.tres"),
	preload("res://core/journal/pages/stage_01/clue_inquerito_1917.tres"),
	preload("res://core/journal/pages/stage_01/clue_crina_cavalo.tres"),
	preload("res://core/journal/pages/stage_01/clue_bambu_rachado.tres"),
	preload("res://core/journal/pages/stage_01/clue_dia_do_saci_bonus.tres")
]

var state: Stage01State


func _init(stage: Stage01State) -> void:
	state = stage


func find_entry(id: StringName) -> JournalEntry:
	for page: JournalEntry in PAGES:
		if page.id == id:
			return page
	return null


func get_entries() -> Array[JournalEntry]:
	var result: Array[JournalEntry] = []
	for page: JournalEntry in PAGES:
		if page.id in state.get_unlocked_clues():
			result.append(page)
	return result


func is_read(id: StringName) -> bool:
	return id in state.get_read_clues()


func get_new_count() -> int:
	var count: int = 0
	for page: JournalEntry in get_entries():
		if not is_read(page.id):
			count += 1
	return count


## Uma sessão de DialogueSession conclui o efeito só após a última página confirmada.
func make_dialogue(id: StringName) -> Stage01Narrative:
	var page: JournalEntry = find_entry(id)
	if page == null or id not in state.get_unlocked_clues():
		return null
	var entry: DialogueEntry = DialogueEntry.new()
	entry.id = page.dialogue_id
	entry.scene_id = &"journal"
	entry.speaker = page.title
	entry.text = page.text
	entry.condition_id = StringName("clue:" + String(id))
	entry.effects = PackedStringArray(["read_clue:" + String(id)])
	var catalog: Stage01Narrative = Stage01Narrative.new()
	catalog.entries = [entry]
	return catalog
