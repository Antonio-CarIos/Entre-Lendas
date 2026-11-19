class_name NarrativePipe
extends DialogueInteractable
## Casa e banco são oportunidades para a mesma unidade, inclusive após consumo.

@export var at_bench: bool = false


func _ready() -> void:
	narrative = HouseInvestigationScript.create()
	WorldState.stage01.changed.connect(refresh_story_policy)
	refresh_story_policy()


func refresh_story_policy() -> void:
	var state: Stage01State = WorldState.stage01
	var allowed: bool = state.active and not state.is_quest_item_claimed(&"cachimbo_fumo") \
		and (state.phase in [&"scene_7_street_hub", &"incomplete_recovery"] if at_bench \
		else state.phase == &"scene_3_house_clean")
	visible = allowed
	set_deferred(&"monitorable", allowed)
	entry_id = &"bench.pipe" if at_bench else &"clean.pipe"
	var description: DialogueEntry = narrative.find_entry(entry_id)
	description.next_id = &"pipe.memory_bamboo"
	if state.cachimbo_memoria:
		description.next_id = &"pipe.keep" if &"clue_origem_saci" in state.get_read_clues() else &"journal.origin"
