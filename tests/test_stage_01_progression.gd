extends GutTest
## Cena 2 pelo input real: chegada única, POIs, recusa e entrada sob fade.

const CITY: PackedScene = preload("res://stages/stage_01_saci/santa_teresa_map.tscn")
const HOUSE_PATH: String = "res://stages/stage_01_saci/house_interior.tscn"
const STORY: Stage01Narrative = preload("res://core/dialogue/stage_01/stage_01_script.tres")

var _previous_scene: Node
var _previous_fade: float
var _previous_reduced: bool
var _city: SantaTeresaMap
var _hud: GameplayHUD
var _player: Player


func before_each() -> void:
	_previous_scene = get_tree().current_scene
	_previous_fade = WorldState.scene_transition.fade_duration
	_previous_reduced = AudioManager.preferences.reduced_effects
	WorldState.scene_transition.fade_duration = 0.3
	WorldState.reset()
	_release_inputs()


func after_each() -> void:
	_release_inputs()
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


func test_arrival_runs_once_with_sunset_tutorial_and_objective_after_complete_text() -> void:
	await _live_city()
	assert_eq(_hud.mode, GameplayHUD.ModalMode.STORY)
	assert_eq(_hud.dialogue_session.entry.id, &"city.arrival")
	assert_false(_player.movement_enabled)
	assert_false(WorldState.stage01.has_event(&"intro_city"))
	assert_eq((_city.get_node("CityModulate") as CanvasModulate).color, Color("ffdfb3"))
	assert_eq(_player.position, Vector2(512, 448))
	var text: String = "\n".join(_hud.dialogue_session.pages)
	for word: String in ["letras", "dedos", "ladeira", "vento", "WASD", "E para interagir", "Tab"]:
		assert_true(text.contains(word), word)
	await _tap(KEY_ESCAPE)
	await _tap(KEY_TAB)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.STORY)
	assert_false(WorldState.stage01.has_event(&"intro_city"))
	await _finish_story()
	assert_true(_player.movement_enabled)
	assert_true(WorldState.stage01.has_event(&"intro_city"))
	assert_eq(WorldState.stage01.phase, &"scene_2_sunset")
	var objective: Label = _hud.get_node("Screen/Objective") as Label
	assert_true(objective.visible)
	assert_eq(objective.text, "Objetivo: Entrar na casa.")
	Input.action_press(&"move_right")
	var previous: Vector2 = _player.position
	await wait_physics_frames(4)
	Input.action_release(&"move_right")
	assert_gt(_player.position.x, previous.x)
	_replace_city()
	await wait_process_frames(3)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.NONE)
	assert_eq(WorldState.stage01.phase, &"scene_2_sunset")


func test_interrupted_arrival_is_represented_without_false_completion() -> void:
	await _live_city()
	await _tap(KEY_E)
	assert_false(WorldState.stage01.has_event(&"intro_city"))
	_replace_city()
	await wait_process_frames(3)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.STORY)
	assert_eq(_hud.dialogue_session.page_index, 0)
	assert_false(WorldState.stage01.has_event(&"intro_city"))
	await _finish_story()
	assert_true(WorldState.stage01.has_event(&"intro_city"))


func test_initial_tram_sign_and_window_are_reachable_by_e_without_investigation_rewards() -> void:
	await _live_city(true)
	var positions: Dictionary[StringName, Vector2] = {
		&"city.tram": Vector2(176, 352), &"city.sign": Vector2(624, 464), &"city.window": Vector2(792, 370)}
	for id: StringName in positions:
		await _approach(positions[id], Vector2.UP)
		assert_true(_feet_clear(_player, _player.position), String(id))
		await _tap(KEY_E)
		assert_eq(_hud.mode, GameplayHUD.ModalMode.STORY)
		assert_eq(_hud.dialogue_session.entry.id, id)
		assert_eq(_hud.dialogue_session.entry.text, STORY.find_entry(id).text)
		assert_false(_player.movement_enabled)
		await _finish_story()
		assert_true(_player.movement_enabled)
	assert_true(STORY.find_entry(&"city.tram").text.contains("banco ainda está quente"))
	assert_true(STORY.find_entry(&"city.window").text.contains("risadinha"))
	assert_true(WorldState.inventory.get_items().is_empty())
	assert_true(WorldState.stage01.get_unlocked_clues().is_empty())
	assert_eq(WorldState.stage01.pistas_saci_lidas, 0)
	assert_false(WorldState.stage01.viu_muro_ou_bonde)
	assert_false(WorldState.stage01.peneira_entregue)


func test_declining_house_shows_hesitation_and_does_not_repeat_while_standing_in_area() -> void:
	await _live_city(true)
	await _approach_door()
	assert_eq(_hud.mode, GameplayHUD.ModalMode.STORY)
	assert_eq(_hud.dialogue_session.entry.id, &"city.door")
	assert_false(_hud.dialogue_session.entry.text.contains("portão"))
	await _ready_choice()
	assert_eq(_hud.dialogue_session.get_choices()[0].label, "Sim")
	assert_eq(_hud.dialogue_session.get_choices()[1].label, "Ainda não")
	await _tap(KEY_RIGHT)
	await _tap(KEY_E)
	assert_eq(_hud.dialogue_session.entry.id, &"city.stay")
	assert_true(_hud.dialogue_session.entry.text.contains("não há para onde voltar"))
	await _finish_story()
	await wait_physics_frames(6)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.NONE)
	assert_true(_player.movement_enabled)
	assert_eq(WorldState.stage01.phase, &"scene_2_sunset")
	assert_false(WorldState.stage01.has_event(&"house_entered"))
	assert_false(WorldState.scene_transition.is_transitioning)
	await _tap(KEY_E)
	assert_eq(_hud.dialogue_session.entry.id, &"city.door")
	await _tap(KEY_ESCAPE)
	assert_true(_player.movement_enabled)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.NONE)


func test_yes_presents_fumo_and_wood_then_enters_clean_house_under_fade() -> void:
	await _live_city(true)
	await _choose_yes()
	assert_eq(_hud.dialogue_session.entry.id, &"city.enter")
	assert_true(_hud.dialogue_session.entry.text.contains("fumo de corda e madeira velha"))
	assert_eq(WorldState.stage01.phase, &"scene_2_sunset")
	assert_false(WorldState.scene_transition.is_transitioning)
	await _finish_story()
	assert_true(WorldState.scene_transition.is_transitioning)
	assert_eq(WorldState.stage01.phase, &"scene_2_sunset")
	await wait_for_signal(WorldState.scene_transition.transition_finished, 3.0)
	var house: HouseLevel = get_tree().current_scene as HouseLevel
	assert_eq(house.scene_file_path, HOUSE_PATH)
	assert_eq(WorldState.stage01.phase, &"scene_3_house_clean")
	assert_true(WorldState.stage01.has_event(&"house_entered"))
	assert_eq(house.player.position, Vector2(320, 624))
	assert_eq(house.player.facing_direction, Vector2.UP)
	assert_true(house.player.camera.is_current())
	var house_hud: GameplayHUD = house.get_node("GameplayHUD") as GameplayHUD
	assert_eq(house_hud.mode, GameplayHUD.ModalMode.STORY)
	assert_eq(house_hud.dialogue_session.entry.id, &"clean.arrival")
	assert_false(house.player.movement_enabled)
	assert_true(_feet_clear(house.player, house.player.global_position))
	assert_true(WorldState.inventory.get_items().is_empty())
	assert_eq((house.get_node("GameplayHUD/Screen/Objective") as Label).text,
		"Objetivo: Investigar a casa e a garrafa.")


func test_cancel_after_yes_does_not_commit_phase_and_next_attempt_revalidates_destination() -> void:
	await _live_city(true)
	await _choose_yes()
	await _tap(KEY_ESCAPE)
	assert_eq(WorldState.stage01.phase, &"scene_2_sunset")
	var door: SceneDoor = _city.get_node("Transitions/EnterHouse") as SceneDoor
	var path: String = door.target_scene
	door.target_scene = "res://missing_house.tscn"
	await _tap(KEY_E)
	await _ready_choice()
	await _tap(KEY_E)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.NOTICE)
	assert_true(_player.movement_enabled == false)
	assert_false(WorldState.scene_transition.is_transitioning)
	assert_false(WorldState.stage01.has_event(&"house_entered"))
	await _tap(KEY_E)
	assert_true(_player.movement_enabled)
	door.target_scene = path
	await _choose_yes(false)
	await _finish_story()
	await wait_for_signal(WorldState.scene_transition.transition_finished, 3.0)
	assert_eq(get_tree().current_scene.scene_file_path, HOUSE_PATH)
	assert_eq(WorldState.stage01.phase, &"scene_3_house_clean")


func test_invalid_spawn_rejects_before_entry_text_and_retry_after_repair_succeeds() -> void:
	await _live_city(true)
	var door: SceneDoor = _city.get_node("Transitions/EnterHouse") as SceneDoor
	door.target_spawn = &"missing_spawn"
	await _approach_door()
	await _ready_choice()
	await _tap(KEY_E)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.NOTICE)
	assert_eq(WorldState.stage01.phase, &"scene_2_sunset")
	assert_false(WorldState.stage01.has_event(&"house_entered"))
	await _tap(KEY_E)
	door.target_spawn = &"FromCity"
	await _choose_yes(false)
	await _finish_story()
	await wait_for_signal(WorldState.scene_transition.transition_finished, 3.0)
	assert_eq(WorldState.stage01.phase, &"scene_3_house_clean")


func test_return_to_city_keeps_progress_and_uses_ordinary_door_without_repeating_arrival() -> void:
	await _live_city(true)
	await _choose_yes()
	await _finish_story()
	await wait_for_signal(WorldState.scene_transition.transition_finished, 3.0)
	var house: HouseLevel = get_tree().current_scene as HouseLevel
	var arrival: GameplayHUD = house.get_node("GameplayHUD") as GameplayHUD
	while arrival.dialogue_session != null and arrival.dialogue_session.active:
		arrival.dialogue_session.advance()
	var inventory: InventorySystem = WorldState.inventory
	var pipe: ItemData = load("res://core/inventory/items/stage_01/cachimbo_fumo.tres") as ItemData
	assert_true(WorldState.stage01.grant_quest_item(pipe, inventory))
	WorldState.stage01.unlock_clue(&"clue_origem_saci")
	WorldState.stage01.mark_clue_read(&"clue_origem_saci")
	assert_true(WorldState.scene_transition.travel_to(house, house.player, CITY.resource_path, &"FromHouseInterior"))
	await wait_for_signal(WorldState.scene_transition.transition_finished, 3.0)
	_city = get_tree().current_scene as SantaTeresaMap
	_hud = _city.get_node("GameplayHUD") as GameplayHUD
	_player = _city.player
	assert_eq(_player.position, Vector2(856, 368))
	assert_eq(_player.facing_direction, Vector2.DOWN)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.NONE)
	assert_eq(WorldState.stage01.phase, &"scene_3_house_clean")
	assert_eq(WorldState.inventory, inventory)
	assert_eq(inventory.get_quantity(&"cachimbo_fumo"), 1)
	assert_eq(WorldState.stage01.pistas_saci_lidas, 1)
	await _approach_door()
	assert_eq(_hud.mode, GameplayHUD.ModalMode.DOOR_CONFIRM)
	assert_eq((_hud.get_node("Screen/Dialogue/Text") as Label).text, "Deseja entrar na casa?")
	await _tap(KEY_ESCAPE)
	assert_true(_player.movement_enabled)


func test_later_phase_disables_initial_clue_variants_and_early_vendor_never_grants_sieve() -> void:
	await _live_city(true)
	await _approach(Vector2(144, 560), Vector2.UP)
	await _tap(KEY_E)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.NOTICE)
	assert_true((_hud.get_node("Screen/Dialogue/Text") as Label).text.contains("porta entreaberta"))
	await _tap(KEY_E)
	assert_false(WorldState.inventory.has_item(&"peneira"))
	assert_eq(WorldState.stage01.climax_attempts, 0)
	assert_eq(_city.get_node("Transitions").get_child_count(), 1)
	for phase: StringName in Stage01State.PHASES.slice(2, 7):
		assert_true(WorldState.stage01.advance_to(phase))
	await wait_physics_frames(3)
	for name_value: String in ["Tram", "StreetSign", "HouseWindow"]:
		assert_false((_city.get_node("NarrativeInteractions/" + name_value) as Area2D).monitorable)
	assert_null((_city.get_node("Transitions/EnterHouse") as SceneDoor).narrative)
	assert_eq(WorldState.stage01.phase, &"scene_7_street_hub")
	assert_true(WorldState.stage01.get_unlocked_clues().is_empty())


func test_f6_inactive_does_not_start_narration_or_change_phase_and_sign_uses_real_asset() -> void:
	_replace_city()
	await wait_process_frames(3)
	assert_false(WorldState.stage01.active)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.NONE)
	assert_true(_player.movement_enabled)
	assert_false((_hud.get_node("Screen/Objective") as Label).visible)
	var board: Sprite2D = _city.get_node("YSortRoot/SharedProps/StreetSign/WoodBoard") as Sprite2D
	assert_eq(board.texture.resource_path, "res://assets/art/props/stage_01/street/colonial_props_atlas.png")
	assert_true(Rect2(Vector2.ZERO, board.texture.get_size()).encloses(board.region_rect))
	assert_eq((_city.get_node("YSortRoot/SharedProps/StreetSign/Text") as Label).text, "RUA DO SACI")


func test_reduced_effects_stop_window_motion_and_keep_readable_risadinha() -> void:
	AudioManager.preferences.reduced_effects = true
	await _live_city(true)
	var window: Sprite2D = _city.get_node("YSortRoot/SharedProps/HouseFacade/LeftWindow") as Sprite2D
	var original: Vector2 = window.scale
	await wait_process_frames(5)
	assert_eq(window.scale, original)
	assert_null(_city.get("_window_tween"))
	await _approach(Vector2(792, 370), Vector2.UP)
	await _tap(KEY_E)
	assert_true(_hud.dialogue_session.entry.text.contains("risadinha"))
	await _finish_story()
	AudioManager.preferences.reduced_effects = false
	AudioManager.refresh_preferences()
	assert_not_null(_city.get("_window_tween"))
	assert_true(_player.movement_enabled)


func test_phase_change_during_entry_fade_restores_source_movement_without_committing_entry() -> void:
	await _live_city(true)
	await _choose_yes()
	await _finish_story()
	assert_true(WorldState.scene_transition.is_transitioning)
	assert_false(_player.movement_enabled)
	WorldState.reset()
	await wait_for_signal(WorldState.scene_transition.transition_finished, 3.0)
	assert_eq(get_tree().current_scene, _city)
	assert_true(_player.movement_enabled)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.NONE)
	assert_false((WorldState.scene_transition.get_node("Fade") as ColorRect).visible)
	assert_false(WorldState.stage01.has_event(&"house_entered"))


func _live_city(already_arrived: bool = false) -> void:
	WorldState.start_new_game()
	assert_true(WorldState.stage01.advance_to(&"scene_2_sunset"))
	if already_arrived:
		WorldState.stage01.record_event(&"intro_city")
	_replace_city()
	await wait_physics_frames(3)


func _replace_city() -> void:
	var current: Node = get_tree().current_scene
	if current != _previous_scene and is_instance_valid(current):
		get_tree().current_scene = _previous_scene
		current.free()
	_city = CITY.instantiate() as SantaTeresaMap
	get_tree().root.add_child(_city)
	get_tree().current_scene = _city
	_hud = _city.get_node("GameplayHUD") as GameplayHUD
	_player = _city.player


func _approach(at: Vector2, facing: Vector2) -> void:
	_player.global_position = at
	_player.facing_direction = facing
	_player.call("_update_presentation", Vector2.ZERO)
	await wait_physics_frames(3)


func _approach_door() -> void:
	await _approach(Vector2(856, 368), Vector2.UP)
	Input.action_press(&"move_up")
	await wait_physics_frames(8)
	Input.action_release(&"move_up")
	await wait_process_frames(1)


func _ready_choice() -> void:
	var limit: int = 20
	while _hud.mode == GameplayHUD.ModalMode.STORY and limit > 0:
		if _hud.dialogue_session.is_decision() and _hud.dialogue_session.revealed:
			return
		await _tap(KEY_E)
		limit -= 1
	assert_true(false, "A escolha deve estar disponível")


func _choose_yes(approach: bool = true) -> void:
	if approach:
		await _approach_door()
	else:
		await _tap(KEY_E)
	await _ready_choice()
	await _tap(KEY_E)


func _finish_story() -> void:
	var limit: int = 40
	while is_instance_valid(_hud) and _hud.mode == GameplayHUD.ModalMode.STORY and limit > 0:
		await _tap(KEY_E)
		limit -= 1
	assert_gt(limit, 0, "O texto termina sem loop")


func _feet_clear(traveler: Player, at: Vector2) -> bool:
	var shape: CollisionShape2D = traveler.get_node("CollisionShape2D") as CollisionShape2D
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = shape.shape
	query.transform = Transform2D(0.0, at) * shape.transform
	query.collision_mask = 1
	return traveler.get_world_2d().direct_space_state.intersect_shape(query).is_empty()


func _release_inputs() -> void:
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
