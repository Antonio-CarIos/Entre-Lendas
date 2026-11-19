extends GutTest
## Regras narrativas puras, catálogo completo e persistência real entre mapas.

const SCRIPT: Stage01Narrative = preload("res://core/dialogue/stage_01/stage_01_script.tres")
const CITY: PackedScene = preload("res://stages/stage_01_saci/santa_teresa_map.tscn")
const HOUSE: PackedScene = preload("res://stages/stage_01_saci/house_interior.tscn")
const STORY_PATH: Array[StringName] = [
	&"scene_2_sunset", &"scene_3_house_clean", &"scene_4_dialogue", &"scene_5_whirlwind",
	&"scene_6_house_chaos", &"scene_7_street_hub", &"scene_8_climax"
]

var _state: Stage01State
var _inventory: InventorySystem
var _previous_scene: Node
var _previous_fade: float


func before_each() -> void:
	WorldState.reset()
	_state = Stage01State.new()
	_inventory = InventorySystem.new()
	_previous_scene = get_tree().current_scene
	_previous_fade = WorldState.scene_transition.fade_duration
	WorldState.scene_transition.fade_duration = 0.05


func after_each() -> void:
	if WorldState.scene_transition.is_transitioning:
		await wait_for_signal(WorldState.scene_transition.transition_finished, 2.0)
	var current: Node = get_tree().current_scene
	if current != _previous_scene:
		get_tree().current_scene = _previous_scene
		if is_instance_valid(current):
			current.queue_free()
		await wait_process_frames(2)
	WorldState.scene_transition.fade_duration = _previous_fade
	WorldState.reset()


func test_initial_state_has_no_prologue_side_effects_or_free_items() -> void:
	assert_false(_state.active)
	assert_eq(_state.phase, &"book_intro")
	assert_eq(_state.objective, "Ler Lendas do Brasil.")
	assert_eq(_state.final_outcome, WorldStateLogic.Outcome.UNDECIDED)
	assert_eq(_state.pistas_saci_lidas, 0)
	assert_eq(_state.climax_attempts, 0)
	assert_false(_state.advance_to(&"scene_2_sunset"))
	assert_false(_state.record_event(&"intro_city"))
	assert_true(_inventory.get_items().is_empty())
	assert_eq(_state.get_map_visual_state(&"santa_teresa_map"), &"")


func test_story_advances_in_order_and_rejects_unknown_repeated_backward_and_skipped_phases() -> void:
	assert_true(_state.begin())
	assert_false(_state.begin())
	watch_signals(_state)
	assert_false(_state.advance_to(&"unknown"))
	assert_false(_state.advance_to(&"scene_7_street_hub"))
	for phase: StringName in STORY_PATH:
		assert_true(_state.advance_to(phase), String(phase))
		assert_false(_state.advance_to(phase))
		assert_false(_state.advance_to(&"book_intro"))
	assert_eq(_state.climax_attempts, 1)
	assert_signal_emit_count(_state, &"phase_changed", 7)
	assert_signal_emit_count(_state, &"changed", 7)
	assert_false(_state.advance_to(&"epilogue_capture"))
	assert_false(_state.advance_to(&"completed"))


func test_empathy_only_records_the_actual_dialogue_branch_once() -> void:
	assert_false(_state.mark_empathy())
	_reach(&"scene_4_dialogue")
	assert_true(_state.mark_empathy())
	assert_false(_state.mark_empathy())
	_state.advance_to(&"scene_5_whirlwind")
	assert_true(_state.saci_empatico)
	assert_true(_state.garrafa_aberta)
	assert_false(_state.record_event(&"bottle_opened"))


func test_once_events_and_seen_introductions_survive_repeated_visits_without_repeating_effects() -> void:
	_reach(&"scene_3_house_clean")
	watch_signals(_state)
	assert_true(_state.record_event(&"pipe_memory"))
	assert_true(_state.record_event(&"intro_house_clean"))
	assert_false(_state.record_event(&"pipe_memory"))
	assert_false(_state.record_event(&""))
	assert_true(_state.cachimbo_memoria)
	var copy: Array[StringName] = _state.get_seen_events()
	copy.clear()
	assert_true(_state.has_event(&"intro_house_clean"))
	assert_signal_emit_count(_state, &"changed", 2)


func test_quest_item_gates_follow_the_story_and_do_not_place_sieve_or_ribbon_in_clean_house() -> void:
	_reach(&"scene_3_house_clean")
	assert_false(_state.grant_quest_item(_item("garrafa_vazia"), _inventory))
	assert_false(_state.grant_quest_item(_item("peneira"), _inventory))
	assert_false(_state.grant_quest_item(_item("fita_vermelha"), _inventory))
	assert_false(_state.grant_quest_item(_item("gorro_saci"), _inventory))
	assert_true(_state.grant_quest_item(_item("cachimbo_fumo"), _inventory))
	_reach(&"scene_6_house_chaos")
	assert_true(_state.grant_quest_item(_item("garrafa_vazia"), _inventory))
	_reach(&"scene_7_street_hub")
	assert_true(_state.grant_quest_item(_item("fita_vermelha"), _inventory))
	assert_true(_state.grant_quest_item(_item("gorro_saci"), _inventory))
	assert_false(_state.grant_quest_item(_item("peneira_cruz"), _inventory))
	assert_false(_state.grant_quest_item(null, _inventory))
	assert_false(_state.can_grant_quest_item(&"peneira", null))
	assert_true(_state.gorro_obtido)


func test_pipe_is_one_logical_item_even_when_removed_before_visiting_the_other_location() -> void:
	_reach(&"scene_3_house_clean")
	assert_true(_state.grant_quest_item(_item("cachimbo_fumo"), _inventory))
	assert_false(_state.grant_quest_item(_item("cachimbo_fumo"), _inventory))
	_inventory.remove_item(&"cachimbo_fumo")
	_reach(&"scene_7_street_hub")
	assert_false(_state.grant_quest_item(_item("cachimbo_fumo"), _inventory))
	assert_true(_state.is_quest_item_claimed(&"cachimbo_fumo"))
	assert_eq(_inventory.get_quantity(&"cachimbo_fumo"), 0)


func test_sieve_requires_wall_or_tram_and_cannot_be_reclaimed_after_combining() -> void:
	_reach(&"scene_7_street_hub")
	assert_false(_state.grant_quest_item(_item("peneira"), _inventory))
	assert_true(_state.mark_tram_seen())
	assert_false(_state.mark_tram_seen())
	assert_true(_state.grant_quest_item(_item("peneira"), _inventory))
	assert_true(_state.peneira_entregue)
	assert_true(_state.grant_quest_item(_item("fita_vermelha"), _inventory))
	assert_true(_inventory.combine_items(&"fita_vermelha", &"peneira"))
	assert_false(_state.grant_quest_item(_item("peneira"), _inventory))
	assert_false(_state.grant_quest_item(_item("fita_vermelha"), _inventory))
	assert_eq(_inventory.get_quantity(&"peneira_cruz"), 1)


func test_inventory_signal_reentry_cannot_duplicate_quest_rewards() -> void:
	_reach(&"scene_7_street_hub")
	_inventory.item_added.connect(func(item: ItemData, _quantity: int) -> void:
		assert_false(_state.grant_quest_item(item, _inventory))
	)
	assert_true(_state.grant_quest_item(_item("fita_vermelha"), _inventory))
	assert_eq(_inventory.get_quantity(&"fita_vermelha"), 1)


func test_wall_read_in_any_order_unlocks_one_aggregate_clue_only_after_five_informative_panels() -> void:
	_reach(&"scene_7_street_hub")
	assert_false(_state.unlock_clue(&"clue_mural_origens"))
	for index: int in [6,4,1,5,2]:
		assert_true(_state.read_mural_panel(index))
	assert_true(_state.viu_muro_ou_bonde)
	assert_true(_state.can_grant_quest_item(&"peneira", _inventory))
	assert_false(&"clue_mural_origens" in _state.get_unlocked_clues())
	assert_false(_state.read_mural_panel(0))
	assert_false(_state.read_mural_panel(7))
	assert_true(_state.read_mural_panel(3))
	assert_false(_state.read_mural_panel(3))
	assert_eq(_state.get_unlocked_clues().size(), 1)
	assert_eq(_state.pistas_saci_lidas, 0)
	assert_true(_state.mark_clue_read(&"clue_mural_origens"))
	assert_eq(_state.pistas_saci_lidas, 1)
	var panels: Array[int] = _state.get_read_mural_panels()
	panels.clear()
	assert_eq(_state.get_read_mural_panels().size(), 6)


func test_painting_validates_symbol_and_keeps_the_first_choice() -> void:
	assert_false(_state.paint_mural(&"gorro"))
	_reach(&"scene_7_street_hub")
	assert_false(_state.paint_mural(&"horse"))
	assert_true(_state.paint_mural(&"bambu"))
	assert_false(_state.paint_mural(&"bambu"))
	assert_false(_state.paint_mural(&"redemoinho"))
	assert_true(_state.muro_pintado)
	assert_eq(_state.muro_simbolo_escolhido, &"bambu")


func test_unlocking_is_not_reading_and_repeated_reading_does_not_inflate_preparation() -> void:
	_reach(&"scene_3_house_clean")
	assert_false(_state.unlock_clue(&"not_a_clue"))
	assert_false(_state.mark_clue_read(&"clue_crina_cavalo"))
	assert_true(_state.unlock_clue(&"clue_origem_saci"))
	assert_eq(_state.pistas_saci_lidas, 0)
	assert_true(_state.mark_clue_read(&"clue_origem_saci"))
	assert_false(_state.mark_clue_read(&"clue_origem_saci"))
	assert_false(_state.unlock_clue(&"clue_origem_saci"))
	assert_eq(_state.pistas_saci_lidas, 1)
	var copy: Array[StringName] = _state.get_unlocked_clues()
	copy.clear()
	assert_eq(_state.get_unlocked_clues().size(), 1)


func test_bonus_requires_seven_unique_read_base_clues_and_does_not_count_as_an_eighth() -> void:
	_reach(&"scene_7_street_hub")
	assert_false(_state.unlock_clue(Stage01State.BONUS_CLUE))
	for panel: int in range(1, 6):
		_state.read_mural_panel(panel)
	for clue: StringName in Stage01State.BASE_CLUES:
		_state.unlock_clue(clue)
		_state.mark_clue_read(clue)
	assert_eq(_state.pistas_saci_lidas, 7)
	assert_true(Stage01State.BONUS_CLUE in _state.get_unlocked_clues())
	assert_true(_state.mark_clue_read(Stage01State.BONUS_CLUE))
	assert_eq(_state.pistas_saci_lidas, 7)
	var read: Array[StringName] = _state.get_read_clues()
	read.clear()
	assert_eq(_state.get_read_clues().size(), 8)


func test_capture_and_friendship_preparation_are_independent_and_require_real_resources() -> void:
	_reach(&"scene_7_street_hub")
	assert_false(_state.is_capture_prepared(_inventory))
	assert_false(_state.is_friendship_prepared(_inventory))
	_inventory.add_item(_item("gorro_saci"))
	assert_false(_state.is_friendship_prepared(_inventory))
	_inventory.add_item(_item("peneira_cruz"))
	assert_false(_state.is_capture_prepared(_inventory))
	_inventory.add_item(_item("garrafa_vazia"))
	assert_true(_state.is_capture_prepared(_inventory))
	_inventory.add_item(_item("cachimbo_fumo"))
	assert_false(_state.is_friendship_prepared(_inventory))
	_read_three_clues(_state)
	assert_true(_state.is_friendship_prepared(_inventory))
	_inventory.remove_item(&"cachimbo_fumo")
	assert_false(_state.is_friendship_prepared(_inventory))
	assert_true(_state.is_friendship_prepared(_inventory, true))
	assert_false(_state.is_capture_prepared(null))
	assert_false(_state.is_friendship_prepared(null))


func test_incomplete_recovery_preserves_investigation_and_allows_another_attempt_without_moral_result() -> void:
	_reach(&"scene_7_street_hub")
	_state.paint_mural(&"gorro")
	_state.mark_tram_seen()
	_state.grant_quest_item(_item("peneira"), _inventory)
	_read_three_clues(_state)
	_state.advance_to(&"scene_8_climax")
	assert_false(_state.resolve_ending(WorldStateLogic.Outcome.CAPTURE, _inventory))
	assert_true(_state.advance_to(&"incomplete_recovery"))
	assert_eq(_state.final_outcome, WorldStateLogic.Outcome.UNDECIDED)
	assert_eq(_state.get_map_visual_state(&"house_interior"), &"incomplete_recovery")
	assert_true(_inventory.has_item(&"peneira"))
	assert_eq(_state.pistas_saci_lidas, 3)
	assert_eq(_state.muro_simbolo_escolhido, &"gorro")
	assert_true(_state.advance_to(&"scene_7_street_hub"))
	assert_true(_state.advance_to(&"scene_8_climax"))
	assert_eq(_state.climax_attempts, 2)


func test_capture_resolution_registers_world_morality_exactly_once_and_survives_completion() -> void:
	WorldState.start_new_game()
	_state = WorldState.stage01
	_inventory = WorldState.inventory
	_reach(&"scene_8_climax")
	_inventory.add_item(_item("peneira_cruz"))
	_inventory.add_item(_item("garrafa_vazia"))
	watch_signals(WorldState)
	assert_true(_state.resolve_ending(WorldStateLogic.Outcome.CAPTURE, _inventory))
	assert_eq(WorldState.nature_balance, -1)
	assert_false(_state.resolve_ending(WorldStateLogic.Outcome.CAPTURE, _inventory))
	assert_signal_emit_count(WorldState, &"entity_outcome_changed", 1)
	assert_eq(_state.phase, &"epilogue_capture")
	assert_true(_state.advance_to(&"completed"))
	assert_eq(_state.get_map_visual_state(&"santa_teresa_map"), &"epilogue_capture")


func test_friendship_cannot_bypass_clues_or_calm_even_with_the_hat() -> void:
	_reach(&"scene_8_climax")
	_inventory.add_item(_item("cachimbo_fumo"))
	_inventory.add_item(_item("gorro_saci"))
	assert_false(_state.resolve_ending(WorldStateLogic.Outcome.FRIENDSHIP, _inventory, 100))
	_read_three_clues(_state)
	assert_false(_state.resolve_ending(WorldStateLogic.Outcome.FRIENDSHIP, _inventory, 99))
	assert_false(_state.resolve_ending(WorldStateLogic.Outcome.UNDECIDED, _inventory, 100))
	assert_true(_state.resolve_ending(WorldStateLogic.Outcome.FRIENDSHIP, _inventory, 100))
	assert_eq(_state.get_map_visual_state(&"house_bedroom"), &"epilogue_friendship")


func test_new_game_resets_story_items_events_moral_result_and_all_other_domains() -> void:
	WorldState.start_new_game()
	_state = WorldState.stage01
	_inventory = WorldState.inventory
	_reach(&"scene_4_dialogue")
	_state.mark_empathy()
	_reach(&"scene_7_street_hub")
	_state.paint_mural(&"redemoinho")
	_state.mark_tram_seen()
	_state.grant_quest_item(_item("peneira"), _inventory)
	_state.grant_quest_item(_item("gorro_saci"), _inventory)
	_state.record_event(&"pipe_memory")
	_read_three_clues(_state)
	WorldState.mark_pickup_collected(&"a_pickup")
	WorldState.register_entity_outcome(&"saci", WorldStateLogic.Outcome.CAPTURE)
	WorldState.start_new_game()
	assert_same(WorldState.stage01, _state)
	assert_true(_state.active)
	assert_eq(_state.phase, &"book_intro")
	assert_false(_state.saci_empatico)
	assert_false(_state.muro_pintado)
	assert_eq(_state.muro_simbolo_escolhido, &"")
	assert_false(_state.viu_muro_ou_bonde)
	assert_false(_state.peneira_entregue)
	assert_false(_state.gorro_obtido)
	assert_false(_state.cachimbo_memoria)
	assert_false(_state.garrafa_aberta)
	assert_true(_state.get_read_mural_panels().is_empty())
	assert_true(_state.get_seen_events().is_empty())
	assert_true(_state.get_unlocked_clues().is_empty())
	assert_true(_state.get_read_clues().is_empty())
	assert_true(_inventory.get_items().is_empty())
	assert_false(WorldState.is_pickup_collected(&"a_pickup"))
	assert_eq(WorldState.nature_balance, 0)
	WorldState.reset()
	assert_false(_state.active)


func test_map_state_consultation_cannot_change_story_or_restore_a_chaotic_house() -> void:
	_reach(&"scene_7_street_hub")
	watch_signals(_state)
	for map_id: StringName in [&"house_interior",&"house_bedroom",&"house_backyard",&"santa_teresa_map"]:
		assert_ne(_state.get_map_visual_state(map_id), &"")
		assert_eq(_state.phase, &"scene_7_street_hub")
	assert_eq(_state.get_map_visual_state(&"house_interior"), &"house_chaos")
	assert_eq(_state.get_map_visual_state(&"santa_teresa_map"), &"scene_7_street_hub")
	assert_eq(_state.get_map_visual_state(&"unknown"), &"")
	assert_signal_not_emitted(_state, &"changed")


func test_real_city_house_round_trip_reapplies_global_state_and_keeps_flags_items_and_phase() -> void:
	WorldState.start_new_game()
	_state = WorldState.stage01
	_inventory = WorldState.inventory
	_reach(&"scene_7_street_hub")
	_state.paint_mural(&"bambu")
	_state.grant_quest_item(_item("fita_vermelha"), _inventory)
	var city: HouseLevel = CITY.instantiate() as HouseLevel
	get_tree().root.add_child(city)
	get_tree().current_scene = city
	assert_eq(city.applied_story_state, &"scene_7_street_hub")
	assert_eq((city.get_node("CityModulate") as CanvasModulate).color, Color("9eaab8"))
	assert_true(WorldState.scene_transition.travel_to(city, city.player, HOUSE.resource_path, &"FromCity"))
	await wait_for_signal(WorldState.scene_transition.transition_finished, 2.0)
	var house: HouseLevel = get_tree().current_scene as HouseLevel
	assert_eq(house.applied_story_state, &"house_chaos")
	# Variantes de arte vazias ainda não estão prontas: não sumir com os móveis existentes.
	assert_false(house.story_variants_ready)
	assert_true((house.get_node("YSortRoot/State_Organized") as Node2D).visible)
	assert_true(WorldState.scene_transition.travel_to(house, house.player, CITY.resource_path, &"FromHouseInterior"))
	await wait_for_signal(WorldState.scene_transition.transition_finished, 2.0)
	city = get_tree().current_scene as HouseLevel
	assert_eq(city.applied_story_state, &"scene_7_street_hub")
	assert_eq(_state.phase, &"scene_7_street_hub")
	assert_eq(_state.muro_simbolo_escolhido, &"bambu")
	assert_eq(_inventory.get_quantity(&"fita_vermelha"), 1)
	assert_same(WorldState.stage01, _state)


func test_narrative_resource_covers_eight_scenes_all_branches_seven_pois_and_three_endings() -> void:
	assert_eq(SCRIPT.get_validation_errors().size(), 0, str(SCRIPT.get_validation_errors()))
	assert_eq(SCRIPT.entries.size(), 130)
	for scene_number: int in range(1, 9):
		assert_false(SCRIPT.get_scene_entries(StringName("scene_%02d" % scene_number)).is_empty())
	for entry_id: StringName in [
		&"city.sign", &"clean.bed", &"pipe.memory_bamboo", &"saci.empathy", &"saci.plans",
		&"chaos.sofa", &"clothes.true_cap", &"bench.pipe", &"mural.panel_6", &"tram.newspapers",
		&"yard.horse", &"yard.ribbon", &"vendor.recipe", &"bamboo.crack", &"journal.bonus",
		&"capture.epilogue", &"friendship.empathy", &"friendship.paint_bambu", &"incomplete.clock"
	]:
		assert_not_null(SCRIPT.find_entry(entry_id), String(entry_id))
	assert_eq(SCRIPT.find_entry(&"saci.greeting").choices.size(), 3)
	assert_eq(SCRIPT.find_entry(&"saci.common").choices.size(), 2)
	assert_eq(SCRIPT.find_entry(&"mural.symbols").choices.size(), 3)
	assert_string_contains(SCRIPT.find_entry(&"pipe.memory_bamboo").text, "setenta e sete")
	assert_string_contains(SCRIPT.find_entry(&"saci.empathy").text, "Dentro da garrafa não tem vento")
	assert_string_contains(SCRIPT.find_entry(&"vendor.recipe").text, "garrafa bem tampada")
	assert_string_contains(SCRIPT.find_entry(&"battle.question").stage_direction, "quadrado vermelho")
	assert_null(SCRIPT.find_entry(&"missing"))
	assert_false(WorldState.stage01.active, "Carregar catálogo não executa diálogos nem avança a história")


func _reach(target: StringName) -> void:
	if not _state.active:
		_state.begin()
	for next: StringName in STORY_PATH:
		if _state.phase == target:
			return
		if Stage01State.PHASES.find(next) > Stage01State.PHASES.find(_state.phase):
			assert_true(_state.advance_to(next))


func _read_three_clues(state: Stage01State) -> void:
	for clue: StringName in [&"clue_origem_saci", &"clue_crina_cavalo", &"clue_bambu_rachado"]:
		state.unlock_clue(clue)
		state.mark_clue_read(clue)


func _item(id: String) -> ItemData:
	return load("res://core/inventory/items/stage_01/"+id+".tres") as ItemData
