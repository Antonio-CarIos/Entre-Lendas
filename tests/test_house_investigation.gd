extends GutTest
## Cena 3: inputs reais, concessões narrativas e travessia sem os pickups de teste.

const HOUSE: PackedScene = preload("res://stages/stage_01_saci/house_interior.tscn")
const BEDROOM: PackedScene = preload("res://stages/stage_01_saci/house_bedroom.tscn")
const PIPE_SCENE: PackedScene = preload("res://components/interactables/narrative_pipe.tscn")

var _previous_scene: Node
var _previous_fade: float
var _previous_reduced: bool
var _house: HouseInvestigation
var _hud: GameplayHUD
var _player: Player


func before_each() -> void:
	_previous_scene = get_tree().current_scene
	_previous_fade = WorldState.scene_transition.fade_duration
	_previous_reduced = AudioManager.preferences.reduced_effects
	WorldState.scene_transition.fade_duration = 0.12
	WorldState.reset()
	_release()


func after_each() -> void:
	_release()
	if WorldState.scene_transition.is_transitioning:
		await wait_for_signal(WorldState.scene_transition.transition_finished, 3.0)
	var current: Node = get_tree().current_scene
	get_tree().current_scene = _previous_scene
	if current != _previous_scene and is_instance_valid(current):
		current.queue_free()
	await wait_process_frames(2)
	WorldState.reset()
	WorldState.scene_transition.fade_duration = _previous_fade
	AudioManager.preferences.reduced_effects = _previous_reduced
	AudioManager.refresh_preferences()


func test_arrival_is_required_once_and_revisit_does_not_repeat_it() -> void:
	await _live(false)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.STORY)
	assert_eq(_hud.dialogue_session.entry.id, &"clean.arrival")
	assert_false(_player.movement_enabled)
	await _tap(KEY_ESCAPE)
	await _tap(KEY_TAB)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.STORY)
	assert_false(WorldState.stage01.has_event(&"intro_house_clean"))
	await _finish()
	assert_true(WorldState.stage01.has_event(&"intro_house_clean"))
	assert_true(_player.movement_enabled)
	assert_eq(_house.applied_story_state, &"house_clean")
	_replace(HOUSE)
	await wait_process_frames(3)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.NONE)


func test_f6_inactive_has_no_rewards_or_narrative_progress() -> void:
	_replace(HOUSE)
	await wait_physics_frames(3)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.NONE)
	assert_true(_player.movement_enabled)
	assert_false((_house.get_node("YSortRoot/State_Organized/Pipe") as Area2D).monitorable)
	assert_false((_house.get_node("NarrativeInteractions/Bottle") as Area2D).monitorable)
	assert_false(WorldState.stage01.active)
	assert_true(WorldState.inventory.get_items().is_empty())


func test_production_house_has_no_prototype_pickups_or_premature_bottle() -> void:
	await _live()
	assert_true(_house.find_children("*", "CollectibleItem", true, false).is_empty())
	for id: String in ["BottleCollectible", "RibbonCollectible", "SieveCollectible", "PipeCollectible"]:
		assert_false(_house.has_node("YSortRoot/" + id))
	assert_false(WorldState.stage01.can_grant_quest_item(&"garrafa_vazia", WorldState.inventory))
	assert_false(WorldState.stage01.can_grant_quest_item(&"fita_vermelha", WorldState.inventory))
	assert_false(WorldState.stage01.can_grant_quest_item(&"peneira", WorldState.inventory))
	assert_true(WorldState.inventory.get_items().is_empty())


func test_sofa_clock_and_milk_are_reachable_with_e_and_do_not_grant_items() -> void:
	await _live()
	var checks: Array[Vector2] = [Vector2(416,416), Vector2(496,390), Vector2(192,540)]
	var facings: Array[Vector2] = [Vector2.UP, Vector2.UP, Vector2.LEFT]
	var ids: Array[StringName] = [&"clean.sofa", &"clean.clock", &"clean.milk"]
	for index: int in range(checks.size()):
		assert_true(_feet_clear(checks[index]), "Pés livres em " + str(checks[index]))
		await _approach(checks[index], facings[index])
		await _tap(KEY_E)
		assert_eq(_hud.mode, GameplayHUD.ModalMode.STORY)
		if _hud.dialogue_session != null:
			assert_eq(_hud.dialogue_session.entry.id, ids[index])
		await _finish()
	assert_true(WorldState.inventory.get_items().is_empty())
	var hands: Node2D = _house.get_node("YSortRoot/State_Organized/Clock/Hands") as Node2D
	var angle: float = hands.rotation
	_house._process(0.5)
	assert_lt(hands.rotation, angle)


func test_pipe_memory_unlocks_page_before_pickup_and_refusal_keeps_pipe() -> void:
	await _live()
	await _start_pipe()
	assert_eq(_hud.dialogue_session.entry.id, &"clean.pipe")
	await _until(&"pipe.memory_bamboo")
	assert_true(_hud.dialogue_session.entry.text.contains("Sete anos"))
	assert_true(_hud.dialogue_session.entry.text.contains("setenta e sete"))
	assert_true(_hud.dialogue_session.entry.text.contains("cogumelo"))
	assert_eq(_hud.dialogue_session.entry.speaker, "Saci")
	await _until(&"pipe.memory_origins")
	assert_true(_hud.dialogue_session.entry.text.contains("Saci-Cererê"))
	await _until(&"journal.origin")
	assert_true(WorldState.stage01.cachimbo_memoria)
	assert_true(&"clue_origem_saci" in WorldState.stage01.get_unlocked_clues())
	assert_eq(WorldState.stage01.pistas_saci_lidas, 0)
	assert_false(WorldState.inventory.has_item(&"cachimbo_fumo"))
	await _until(&"pipe.keep", true)
	assert_eq(WorldState.stage01.pistas_saci_lidas, 1)
	await _tap(KEY_DOWN)
	await _tap(KEY_E)
	assert_eq(_hud.dialogue_session.entry.id, &"pipe.left")
	await _finish()
	assert_false(WorldState.stage01.is_quest_item_claimed(&"cachimbo_fumo"))
	assert_true((_house.get_node("YSortRoot/State_Organized/Pipe") as Node2D).visible)
	await _start_pipe()
	await _until(&"pipe.keep", true)
	await _tap(KEY_E)
	assert_eq(WorldState.inventory.get_quantity(&"cachimbo_fumo"), 1)
	await _finish()
	await wait_physics_frames(2)
	assert_false((_house.get_node("YSortRoot/State_Organized/Pipe") as Area2D).monitorable)
	assert_eq(WorldState.stage01.pistas_saci_lidas, 1)


func test_new_props_preserve_paths_to_interactions_and_active_arrival_points() -> void:
	await _live()
	var visited: Dictionary[Vector2i, bool] = {Vector2i(20,39): true}
	var queue: Array[Vector2i] = [Vector2i(20,39)]
	var head: int = 0
	while head < queue.size():
		var cell: Vector2i = queue[head]
		head += 1
		for direction: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next: Vector2i = cell + direction
			if visited.has(next) or not Rect2i(0,15,40,27).has_point(next):
				continue
			if _feet_clear(Vector2(next * 16)):
				visited[next] = true
				queue.append(next)
	for at: Vector2i in [Vector2i(416,416), Vector2i(496,400), Vector2i(192,544),
		Vector2i(384,416), Vector2i(560,400), Vector2i(496,608), Vector2i(320,448),
		Vector2i(32,400)]:
		assert_true(visited.has(at / 16), "Caminho com a largura dos pés até " + str(at))
	for name_value: String in ["FromCity", "FromBedroom", "FromBackyard", "PlayerEntrySpawn"]:
		assert_true(_feet_clear((_house.get_node("SpawnPoints/" + name_value) as Marker2D).position))


func test_cancelled_page_does_not_count_read_and_revisit_resumes_without_memory_replay() -> void:
	await _live()
	await _start_pipe()
	await _until(&"journal.origin")
	await _tap(KEY_ESCAPE)
	assert_true(WorldState.stage01.cachimbo_memoria)
	assert_eq(WorldState.stage01.pistas_saci_lidas, 0)
	await _start_pipe()
	await _until(&"journal.origin")
	await _until(&"pipe.keep", true)
	assert_eq(WorldState.stage01.pistas_saci_lidas, 1)
	await _tap(KEY_ESCAPE)
	assert_false(WorldState.stage01.is_quest_item_claimed(&"cachimbo_fumo"))
	_replace(HOUSE)
	await wait_physics_frames(3)
	await _start_pipe()
	await _until(&"pipe.keep", true)
	assert_eq(WorldState.stage01.pistas_saci_lidas, 1)


func test_house_and_bench_share_pipe_identity_even_after_offering_it() -> void:
	await _live()
	await _start_pipe()
	await _until(&"pipe.keep", true)
	await _tap(KEY_E)
	await _finish()
	assert_true(WorldState.inventory.remove_item(&"cachimbo_fumo"))
	for next_phase: StringName in [&"scene_4_dialogue", &"scene_5_whirlwind", &"scene_6_house_chaos", &"scene_7_street_hub"]:
		assert_true(WorldState.stage01.advance_to(next_phase))
	var bench: NarrativePipe = PIPE_SCENE.instantiate() as NarrativePipe
	bench.at_bench = true
	_house.add_child(bench)
	await wait_physics_frames(3)
	assert_false(bench.visible)
	assert_false(bench.monitorable)
	assert_false(WorldState.stage01.can_grant_quest_item(&"cachimbo_fumo", WorldState.inventory))
	assert_eq(WorldState.inventory.get_quantity(&"cachimbo_fumo"), 0)


func test_bench_can_grant_refused_house_pipe_without_repeating_memory() -> void:
	await _live()
	await _start_pipe()
	await _until(&"pipe.keep", true)
	await _tap(KEY_DOWN)
	await _tap(KEY_E)
	await _finish()
	for next_phase: StringName in [&"scene_4_dialogue", &"scene_5_whirlwind", &"scene_6_house_chaos", &"scene_7_street_hub"]:
		WorldState.stage01.advance_to(next_phase)
	var bench: NarrativePipe = PIPE_SCENE.instantiate() as NarrativePipe
	bench.at_bench = true
	bench.position = Vector2(320, 440)
	_house.add_child(bench)
	await _approach(Vector2(320,472), Vector2.UP)
	await _tap(KEY_E)
	assert_eq(_hud.dialogue_session.entry.id, &"bench.pipe")
	await _until(&"pipe.keep", true)
	await _tap(KEY_E)
	await _finish()
	assert_eq(WorldState.inventory.get_quantity(&"cachimbo_fumo"), 1)
	assert_eq(WorldState.stage01.pistas_saci_lidas, 1)


func test_bottle_leave_restores_control_and_requires_fresh_interaction_to_retry() -> void:
	await _live()
	await _start_bottle()
	await _until(&"bottle.choice", true)
	await _tap(KEY_DOWN)
	await _tap(KEY_E)
	assert_eq(_hud.dialogue_session.entry.id, &"bottle.leave")
	assert_true(_hud.dialogue_session.entry.text.contains("Tec."))
	assert_true(_hud.dialogue_session.entry.text.contains("risadinha"))
	await _finish()
	assert_true(_player.movement_enabled)
	await wait_process_frames(8)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.NONE)
	assert_false(WorldState.stage01.garrafa_aberta)
	assert_true(WorldState.inventory.get_items().is_empty())
	assert_eq((_house.get_node("HouseModulate") as CanvasModulate).color, Color.WHITE)
	await _tap(KEY_E)
	await _until(&"bottle.choice", true)
	await _tap(KEY_ESCAPE)
	assert_true(_player.movement_enabled)


func test_opening_commits_only_after_pop_once_and_never_grants_empty_bottle() -> void:
	await _live()
	await _start_bottle()
	await _until(&"bottle.choice", true)
	await _tap(KEY_E)
	assert_eq(_hud.dialogue_session.entry.id, &"bottle.open")
	assert_false(WorldState.stage01.garrafa_aberta)
	await _tap(KEY_ESCAPE)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.STORY)
	watch_signals(_house)
	await _finish()
	assert_eq(WorldState.stage01.phase, &"scene_4_dialogue")
	assert_true(WorldState.stage01.garrafa_aberta)
	assert_signal_emit_count(_house, &"bottle_opening_completed", 1)
	assert_false(WorldState.inventory.has_item(&"garrafa_vazia"))
	await wait_physics_frames(3)
	await _tap(KEY_E)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.NONE)
	assert_signal_emit_count(_house, &"bottle_opening_completed", 1)
	assert_false((_house.get_node("YSortRoot/State_Organized/ClosedBottle") as Node2D).visible)


func test_reduced_effects_keep_memory_and_leave_text_without_tint_or_vibration() -> void:
	AudioManager.preferences.reduced_effects = true
	await _live()
	await _start_pipe()
	await _until(&"pipe.memory_bamboo")
	assert_null(_house.get("_effect"))
	assert_eq((_house.get_node("HouseModulate") as CanvasModulate).color, Color.WHITE)
	await _tap(KEY_ESCAPE)
	await _start_bottle()
	await _until(&"bottle.choice", true)
	await _tap(KEY_DOWN)
	await _tap(KEY_E)
	assert_null(_house.get("_effect"))
	assert_eq((_house.get_node("YSortRoot/State_Organized/ClosedBottle") as Node2D).rotation, 0.0)
	await _finish()
	assert_true(_player.movement_enabled)


func test_stairs_keep_bed_inspection_and_progress_on_round_trip() -> void:
	await _live()
	WorldState.stage01.record_event(&"pipe_memory")
	assert_true(WorldState.scene_transition.travel_to(_house, _player, BEDROOM.resource_path, &"FromHouseInterior"))
	await wait_for_signal(WorldState.scene_transition.transition_finished, 3.0)
	_house = get_tree().current_scene as HouseInvestigation
	_hud = _house.get_node("GameplayHUD") as GameplayHUD
	_player = _house.player
	assert_eq(_player.position, Vector2(496,328))
	assert_true(_player.movement_enabled)
	assert_true(_house.has_node("YSortRoot/State_Organized/Bed/BraidedHorsehair"))
	await _approach(Vector2(128,288), Vector2.UP)
	await _tap(KEY_E)
	assert_eq(_hud.dialogue_session.entry.id, &"clean.bed")
	assert_true(_hud.dialogue_session.entry.text.contains("crina"))
	await _finish()
	await _approach(Vector2(496,328), Vector2.DOWN)
	Input.action_press(&"move_down")
	await wait_until(func() -> bool: return WorldState.scene_transition.is_transitioning, 2.0)
	Input.action_release(&"move_down")
	assert_true(WorldState.scene_transition.is_transitioning)
	await wait_for_signal(WorldState.scene_transition.transition_finished, 3.0)
	_house = get_tree().current_scene as HouseInvestigation
	assert_eq(_house.player.position, Vector2(496,608))
	assert_true(WorldState.stage01.cachimbo_memoria)
	assert_eq(WorldState.stage01.phase, &"scene_3_house_clean")
	assert_true(_house.player.movement_enabled)


func test_local_catalog_is_valid_and_does_not_change_shared_journal_or_source_links() -> void:
	var catalog: Stage01Narrative = HouseInvestigationScript.create()
	assert_true(catalog.get_validation_errors().is_empty())
	assert_eq(catalog.find_entry(&"journal.origin").next_id, &"pipe.keep")
	assert_eq(HouseInvestigationScript.SOURCE.find_entry(&"journal.origin").next_id, &"")
	assert_eq(HouseInvestigationScript.SOURCE.find_entry(&"bottle.open").next_id, &"saci.appears")
	assert_eq(HouseInvestigationScript.SOURCE.find_entry(&"pipe.memory_origins").next_id, &"pipe.keep")


func _live(arrived: bool = true) -> void:
	WorldState.start_new_game()
	WorldState.stage01.advance_to(&"scene_2_sunset")
	WorldState.stage01.advance_to(&"scene_3_house_clean")
	if arrived:
		WorldState.stage01.record_event(&"intro_house_clean")
	_replace(HOUSE)
	await wait_physics_frames(3)


func _replace(scene: PackedScene) -> void:
	var current: Node = get_tree().current_scene
	if current != _previous_scene and is_instance_valid(current):
		get_tree().current_scene = _previous_scene
		current.free()
	_house = scene.instantiate() as HouseInvestigation
	get_tree().root.add_child(_house)
	get_tree().current_scene = _house
	_hud = _house.get_node("GameplayHUD") as GameplayHUD
	_player = _house.player


func _start_pipe() -> void:
	assert_true(_feet_clear(Vector2(380,410)))
	await _approach(Vector2(380,410), Vector2.UP)
	await _tap(KEY_E)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.STORY)


func _start_bottle() -> void:
	await _approach(Vector2(560,394), Vector2.UP)
	await _tap(KEY_E)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.STORY)


func _approach(at: Vector2, facing: Vector2) -> void:
	_player.position = at
	_player.facing_direction = facing
	_player.call("_update_presentation", Vector2.ZERO)
	await wait_physics_frames(3)


func _until(id: StringName, ready_choice: bool = false) -> void:
	var limit: int = 80
	while _hud.dialogue_session.active and limit > 0:
		if _hud.dialogue_session.entry.id == id and (not ready_choice or \
			(_hud.dialogue_session.revealed and _hud.dialogue_session.is_decision())):
			return
		await _tap(KEY_E)
		limit -= 1
	assert_true(false, "Trecho esperado: " + String(id))


func _finish() -> void:
	var limit: int = 80
	while _hud.dialogue_session != null and _hud.dialogue_session.active and limit > 0:
		await _tap(KEY_E)
		limit -= 1
	assert_gt(limit, 0, "Diálogo não deve criar loop")


func _feet_clear(at: Vector2) -> bool:
	var collider: CollisionShape2D = _player.get_node("CollisionShape2D") as CollisionShape2D
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = collider.shape
	query.transform = Transform2D(0.0, at) * collider.transform
	query.collision_mask = 1
	return _player.get_world_2d().direct_space_state.intersect_shape(query).is_empty()


func _release() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"interact", &"open_inventory"]:
		Input.action_release(action)


func _tap(key: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	await wait_process_frames(2)
	event = InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	Input.parse_input_event(event)
	await wait_process_frames(2)
