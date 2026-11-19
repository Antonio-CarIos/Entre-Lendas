extends GutTest
## Ramos reais e apresentação por input, sem depender do mouse ou de assets futuros.

const HUD: PackedScene = preload("res://ui/gameplay_hud.tscn")
const PLAYER: PackedScene = preload("res://entities/player/player.tscn")
const STORY: Stage01Narrative = preload("res://core/dialogue/stage_01/stage_01_script.tres")
const PIPE: ItemData = preload("res://core/inventory/items/stage_01/cachimbo_fumo.tres")

var _state: Stage01State
var _items: InventorySystem
var _context: DialogueContext
var _session: DialogueSession
var _hud: GameplayHUD
var _player: Player
var _root: Node2D


func before_each() -> void:
	WorldState.reset()
	_state = Stage01State.new()
	_state.begin()
	_items = InventorySystem.new()
	_context = DialogueContext.new(_state, _items)
	_session = DialogueSession.new(_context)
	_root = Node2D.new()
	add_child_autofree(_root)
	_player = PLAYER.instantiate() as Player
	_root.add_child(_player)
	_hud = HUD.instantiate() as GameplayHUD
	_root.add_child(_hud)
	_hud.bind_player(_player)
	_hud.dialogue_context = _context


func after_each() -> void:
	get_tree().paused = false
	if is_instance_valid(_root):
		_root.free()
	WorldState.reset()


func test_flags_items_clues_and_unknown_conditions_fail_closed() -> void:
	assert_false(_context.allows(&"unknown"))
	assert_false(_context.allows(&"!unknown"))
	assert_false(_context.allows(&"flag:test"))
	assert_true(_context.allows(&"!flag:test"))
	_state.record_event(&"test")
	assert_true(_context.allows(&"flag:test"))
	assert_false(_context.allows(&"item:cachimbo_fumo"))
	_items.add_item(PIPE)
	assert_true(_context.allows(&"item:cachimbo_fumo"))
	assert_false(_context.allows(&"clue:clue_origem_saci"))
	_state.unlock_clue(&"clue_origem_saci")
	assert_true(_context.allows(&"clue:clue_origem_saci"))
	assert_false(_context.allows(&"read_clue:clue_origem_saci"))
	_state.mark_clue_read(&"clue_origem_saci")
	assert_true(_context.allows_all(["flag:test", "item:cachimbo_fumo", "read_clue:clue_origem_saci"]))
	assert_false(_context.allows_all(["flag:missing", "item:cachimbo_fumo"]))


func test_catalog_roundtrip_preserves_reading_effects_tutorial_and_source_indices() -> void:
	var path: String = "user://test_stage01_dialogue_roundtrip.tres"
	assert_eq(ResourceSaver.save(STORY, path), OK)
	var restored: Stage01Narrative = ResourceLoader.load(path, "Resource", ResourceLoader.CACHE_MODE_IGNORE) as Stage01Narrative
	assert_not_null(restored)
	assert_true(restored.get_validation_errors().is_empty())
	for page: JournalEntry in JournalSystem.PAGES:
		var entry: DialogueEntry = restored.find_entry(page.dialogue_id)
		assert_true("read_clue:" + String(page.id) in entry.effects)
		assert_false(entry.source_paragraphs.is_empty())
	for panel: int in range(1,7):
		var entry: DialogueEntry = restored.find_entry(StringName("mural.panel_%d" % panel))
		assert_true("read_mural_panel:%d" % panel in entry.effects)
		assert_false(entry.source_paragraphs.is_empty())
	var arrival: DialogueEntry = restored.find_entry(&"city.arrival")
	assert_true("\n".join(arrival.pages).contains("E para interagir"))
	assert_true("\n".join(arrival.pages).contains("Tab"))
	assert_true("\n".join(arrival.pages).contains("WASD"))
	assert_false(arrival.source_paragraphs.is_empty())
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_actual_three_way_saci_branch_applies_only_selected_effect() -> void:
	_reach(&"scene_4_dialogue")
	watch_signals(_session)
	assert_true(_session.start(STORY, &"saci.greeting"))
	assert_eq(_session.get_choices().size(), 3)
	assert_false(_session.choose(&"empathy"), "Texto ainda não foi revelado")
	_read_current(_session)
	assert_false(_state.saci_empatico)
	assert_true(_session.choose(&"empathy"))
	assert_true(_state.saci_empatico)
	assert_eq(_session.entry.id, &"saci.empathy")
	assert_signal_emitted_with_parameters(_session, &"started", [&"saci.greeting"])
	assert_false(_session.choose(&"curious"), "A resposta antiga não continua ativa")
	_session.abort()
	assert_signal_emit_count(_session, &"finished", 1)


func test_vendor_conditions_before_and_after_investigation_and_reward_once() -> void:
	_reach(&"scene_7_street_hub")
	assert_true(_session.start(STORY, &"vendor.recipe"))
	assert_eq(_choice_ids(_session), [&"investigate", &"back"])
	_session.cancel()
	_state.mark_tram_seen()
	assert_true(_session.start(STORY, &"vendor.recipe"))
	assert_eq(_choice_ids(_session), [&"take", &"back"])
	_read_current(_session)
	assert_true(_session.choose(&"take"))
	assert_eq(_session.entry.id, &"vendor.give")
	assert_true(_session.active)
	assert_eq(_items.get_quantity(&"peneira"), 1)
	_session.abort()
	_items.remove_item(&"peneira")
	var reopened: DialogueContext = DialogueContext.new(_state, _items)
	assert_true(reopened.apply_once(&"claim_peneira", &"another-location"))
	assert_false(_items.has_item(&"peneira"), "Não regenerar uma entrega já consumida")
	assert_false(_session.start(STORY, &"vendor.give"))
	assert_true(_session.start(STORY, &"vendor.already_helped"))


func test_multi_page_text_accents_and_events_commit_only_after_last_page() -> void:
	var entry: DialogueEntry = _entry(&"read", "")
	entry.pages = ["Você vê o Saci.", "A narração termina aqui."]
	entry.event_id = &"read_complete"
	var catalog: Stage01Narrative = _catalog([entry])
	watch_signals(_session)
	assert_true(_session.start(catalog, &"read"))
	assert_eq(_session.pages[0], "Você vê o Saci.")
	_session.advance()
	assert_eq(_session.page_index, 0)
	assert_true(_session.revealed)
	_session.advance()
	assert_eq(_session.page_index, 1)
	assert_false(_session.revealed)
	assert_false(_state.has_event(&"read_complete"))
	_session.advance()
	assert_true(_session.active)
	_session.advance()
	assert_true(_state.has_event(&"read_complete"))
	assert_false(_session.active)
	assert_signal_emitted_with_parameters(_session, &"finished", [true, ""])
	assert_false(_session.advance())
	assert_signal_emit_count(_session, &"finished", 1)


func test_invalid_graph_and_blocked_node_do_not_start_or_mutate_state() -> void:
	var entry: DialogueEntry = _entry(&"bad", "Olá")
	entry.next_id = &"absent"
	assert_false(_session.start(_catalog([entry]), entry.id))
	entry.next_id = &""
	entry.conditions = ["item:cachimbo_fumo"]
	assert_false(_session.start(_catalog([entry]), entry.id))
	assert_false(_session.active)
	assert_true(_items.get_items().is_empty())


func test_effect_signal_reentry_and_revisit_do_not_duplicate_rewards() -> void:
	_reach(&"scene_3_house_clean")
	var entry: DialogueEntry = _entry(&"reward", "Um cachimbo.")
	entry.effects = ["claim_cachimbo_fumo"]
	var catalog: Stage01Narrative = _catalog([entry])
	_items.item_added.connect(func(_item: ItemData, _quantity: int) -> void:
		_session.advance()
		_context.apply_once(&"claim_cachimbo_fumo", &"reward/0")
	)
	assert_true(_session.start(catalog, entry.id))
	_session.reveal()
	_session.advance()
	assert_eq(_items.get_quantity(PIPE.id), 1)
	assert_true(_session.start(catalog, entry.id))
	_session.reveal()
	_session.advance()
	assert_eq(_items.get_quantity(PIPE.id), 1)
	_state.reset()
	_state.begin()
	_reach(&"scene_3_house_clean")
	_items.clear()
	assert_true(_session.start(catalog, entry.id))
	_session.reveal()
	_session.advance()
	assert_eq(_items.get_quantity(PIPE.id), 1, "Novo Jogo limpa as reservas")


func test_keyboard_reveal_does_not_confirm_and_arrows_select_third_answer() -> void:
	var catalog: Stage01Narrative = _decision()
	assert_true(_hud.start_dialogue(catalog, &"question"))
	assert_false(_player.movement_enabled)
	await _key(KEY_E)
	assert_eq(_hud.dialogue_session.entry.id, &"question")
	assert_false(_state.has_event(&"selected_third"))
	assert_eq((_hud.get_node("Screen/Story") as DialogueView).choices_box.get_child_count(), 3)
	await _key(KEY_DOWN)
	await _key(KEY_DOWN)
	await _key(KEY_ENTER)
	assert_true(_state.has_event(&"selected_third"))
	assert_eq(_hud.dialogue_session.entry.id, &"answer")
	await _key(KEY_E)
	await _key(KEY_E)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.NONE)
	assert_true(_player.movement_enabled)


func test_echo_cannot_confirm_and_inventory_cannot_replace_mandatory_dialogue() -> void:
	var catalog: Stage01Narrative = _decision()
	catalog.entries[0].cancel_allowed = false
	assert_true(_hud.start_dialogue(catalog, &"question"))
	await _key(KEY_E)
	var echo: InputEventKey = InputEventKey.new()
	echo.keycode = KEY_E
	echo.pressed = true
	echo.echo = true
	Input.parse_input_event(echo)
	await wait_process_frames(1)
	await _key(KEY_TAB)
	await _key(KEY_ESCAPE)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.STORY)
	assert_eq(_hud.dialogue_session.entry.id, &"question")
	assert_false(_player.movement_enabled)
	assert_false(_hud.dialogue_session.cancel())
	_hud.dialogue_session.abort()
	assert_true(_player.movement_enabled)


func test_cancel_preserves_previous_player_lock_and_does_not_commit_unread_effects() -> void:
	_player.set_movement_enabled(false)
	var entry: DialogueEntry = _entry(&"cancel", "Pode voltar.")
	entry.effects = ["flag:should_not_happen"]
	assert_true(_hud.start_dialogue(_catalog([entry]), entry.id))
	await _key(KEY_ESCAPE)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.NONE)
	assert_false(_player.movement_enabled)
	assert_false(_state.has_event(&"should_not_happen"))
	_player.set_movement_enabled(true)
	assert_true(_hud.start_dialogue(_catalog([entry]), entry.id))
	await _key(KEY_ESCAPE)
	assert_true(_player.movement_enabled)


func test_unknown_effect_fails_and_unlocks_movement_without_fake_success() -> void:
	var entry: DialogueEntry = _entry(&"failure", "Efeito indisponível.")
	entry.effects = ["missing_effect"]
	watch_signals(_hud)
	assert_true(_hud.start_dialogue(_catalog([entry]), entry.id))
	await _key(KEY_E)
	await _key(KEY_E)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.NONE)
	assert_true(_player.movement_enabled)
	assert_signal_emitted_with_parameters(_hud, &"dialogue_finished",
		[false, "Não foi possível aplicar os efeitos de failure"])


func test_legacy_vendor_notice_and_collectible_confirmation_still_work() -> void:
	var vendor: DialogueInteractable = DialogueInteractable.new()
	vendor.speaker = "Quitandeira"
	vendor.message = "Olá!"
	_root.add_child(vendor)
	_hud._on_interaction_requested(vendor)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.NOTICE)
	assert_eq((_hud.get_node("Screen/Dialogue/Text") as Label).text, "Quitandeira: Olá!")
	await _key(KEY_E)
	assert_true(_player.movement_enabled)
	var collectible: CollectibleItem = preload("res://components/interactables/collectible_item.tscn").instantiate() as CollectibleItem
	collectible.item_data = PIPE
	_root.add_child(collectible)
	_hud._on_interaction_requested(collectible)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.CONFIRM)
	await _key(KEY_ESCAPE)
	assert_false(collectible.collected)
	assert_true(_player.movement_enabled)


func test_story_interactable_opens_resource_instead_of_legacy_message() -> void:
	var target: DialogueInteractable = DialogueInteractable.new()
	target.narrative = _decision()
	target.entry_id = &"question"
	_root.add_child(target)
	_hud._on_interaction_requested(target)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.STORY)
	assert_eq(_hud.dialogue_session.entry.speaker, "Saci")
	_hud.dialogue_session.abort()


func test_skip_runs_effects_but_waits_for_mandatory_decision_and_reward_once() -> void:
	var coordinator: CutsceneCoordinator = _coordinator()
	var sequence: CutsceneSequence = CutsceneSequence.new()
	sequence.id = &"skip_test"
	var wait: CutsceneStep = _step(CutsceneStep.Kind.WAIT)
	wait.duration = 60.0
	var logical: CutsceneStep = _step(CutsceneStep.Kind.EFFECT)
	logical.effect_id = &"flag:before_decision"
	var talk: CutsceneStep = _step(CutsceneStep.Kind.DIALOGUE)
	talk.narrative = _decision()
	talk.narrative.entries[0].cancel_allowed = false
	talk.entry_id = &"question"
	var after: CutsceneStep = _step(CutsceneStep.Kind.EFFECT)
	after.effect_id = &"flag:sequence_complete"
	sequence.steps = [wait, logical, talk, after]
	watch_signals(coordinator)
	assert_true(coordinator.start(sequence, _hud, _root))
	assert_false(_player.movement_enabled)
	coordinator.request_skip()
	await wait_process_frames(6)
	assert_true(_state.has_event(&"before_decision"))
	assert_false(_state.has_event(&"sequence_complete"))
	assert_true(coordinator.running)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.STORY)
	coordinator.request_skip()
	await _key(KEY_ESCAPE)
	assert_true(coordinator.running)
	assert_false(_state.has_event(&"sequence_complete"))
	await _key(KEY_E)
	await _key(KEY_ENTER)
	await _key(KEY_E)
	await _key(KEY_ENTER)
	await wait_process_frames(4)
	assert_true(_state.has_event(&"sequence_complete"))
	assert_false(coordinator.running)
	assert_true(_player.movement_enabled)
	assert_false(WorldState.scene_transition.has_presentation())
	assert_signal_emitted_with_parameters(coordinator, &"finished", [true, ""])


func test_sequence_failure_restores_camera_animation_fade_and_player() -> void:
	var coordinator: CutsceneCoordinator = _coordinator()
	var original: Vector2 = _player.camera.global_position
	var original_animation: StringName = _player.animated_sprite.animation
	var sequence: CutsceneSequence = CutsceneSequence.new()
	sequence.id = &"restore_test"
	var camera: CutsceneStep = _step(CutsceneStep.Kind.CAMERA)
	camera.target_path = _root.get_path_to(_player.camera)
	camera.camera_position = Vector2(200, 300)
	camera.duration = 0.0
	var animation: CutsceneStep = _step(CutsceneStep.Kind.ANIMATION)
	animation.target_path = _root.get_path_to(_player.animated_sprite)
	animation.animation = &"walk_left"
	animation.duration = 0.01
	var fade: CutsceneStep = _step(CutsceneStep.Kind.FADE)
	fade.fade_alpha = 1.0
	fade.duration = 0.01
	var failure: CutsceneStep = _step(CutsceneStep.Kind.EFFECT)
	failure.effect_id = &"missing"
	sequence.steps = [camera, animation, fade, failure]
	watch_signals(coordinator)
	assert_true(coordinator.start(sequence, _hud, _root))
	await wait_process_frames(15)
	assert_false(coordinator.running)
	assert_eq(_player.camera.global_position, original)
	assert_eq(_player.animated_sprite.animation, original_animation)
	assert_true(_player.movement_enabled)
	assert_false(WorldState.scene_transition.has_presentation())
	assert_false((WorldState.scene_transition.get_node("Fade") as ColorRect).visible)
	assert_signal_emit_count(coordinator, &"finished", 1)


func test_coordinator_deleted_during_wait_restores_modal_and_presentation() -> void:
	var coordinator: CutsceneCoordinator = _coordinator()
	var sequence: CutsceneSequence = CutsceneSequence.new()
	sequence.id = &"deleted"
	var wait: CutsceneStep = _step(CutsceneStep.Kind.WAIT)
	wait.duration = 60.0
	sequence.steps = [wait]
	assert_true(coordinator.start(sequence, _hud, _root))
	await wait_process_frames(2)
	coordinator.free()
	assert_eq(_hud.mode, GameplayHUD.ModalMode.NONE)
	assert_true(_player.movement_enabled)
	assert_false(WorldState.scene_transition.has_presentation())


func test_coordinator_works_on_control_screen_without_player_and_respects_pause() -> void:
	var control: Control = Control.new()
	_root.add_child(control)
	var hud: GameplayHUD = HUD.instantiate() as GameplayHUD
	control.add_child(hud)
	var coordinator: CutsceneCoordinator = CutsceneCoordinator.new()
	control.add_child(coordinator)
	var sequence: CutsceneSequence = CutsceneSequence.new()
	sequence.id = &"control_screen"
	var wait: CutsceneStep = _step(CutsceneStep.Kind.WAIT)
	wait.duration = 60.0
	sequence.steps = [wait]
	assert_true(coordinator.start(sequence, hud, control))
	await wait_process_frames(2)
	var index: int = coordinator.step_index
	get_tree().paused = true
	await wait_process_frames(2)
	assert_eq(coordinator.step_index, index)
	get_tree().paused = false
	coordinator.request_skip()
	await wait_process_frames(3)
	assert_false(coordinator.running)
	assert_eq(hud.mode, GameplayHUD.ModalMode.NONE)
	assert_false(WorldState.scene_transition.has_presentation())


func test_hud_deleted_during_required_dialogue_restores_player_and_sequence_ownership() -> void:
	var coordinator: CutsceneCoordinator = _coordinator()
	var sequence: CutsceneSequence = CutsceneSequence.new()
	sequence.id = &"hud_deleted"
	var talk: CutsceneStep = _step(CutsceneStep.Kind.DIALOGUE)
	talk.narrative = _decision()
	talk.narrative.entries[0].cancel_allowed = false
	talk.entry_id = &"question"
	sequence.steps = [talk]
	assert_true(coordinator.start(sequence, _hud, _root))
	await wait_process_frames(2)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.STORY)
	_hud.free()
	assert_false(coordinator.running)
	assert_true(_player.movement_enabled)
	assert_false(WorldState.scene_transition.has_presentation())


func test_sequence_sound_and_animation_player_can_run_and_cancel_cleanly() -> void:
	var animator: AnimationPlayer = AnimationPlayer.new()
	_root.add_child(animator)
	var animation: Animation = Animation.new()
	animation.length = 10.0
	var library: AnimationLibrary = AnimationLibrary.new()
	library.add_animation(&"presentation", animation)
	animator.add_animation_library(&"", library)
	var coordinator: CutsceneCoordinator = _coordinator()
	var sequence: CutsceneSequence = CutsceneSequence.new()
	sequence.id = &"sound_animation"
	var visual: CutsceneStep = _step(CutsceneStep.Kind.ANIMATION)
	visual.target_path = _root.get_path_to(animator)
	visual.animation = &"presentation"
	visual.duration = 60.0
	var sound: CutsceneStep = _step(CutsceneStep.Kind.SOUND)
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.data = PackedByteArray([0, 0, 0, 0])
	sound.sound = stream
	sound.duration = 60.0
	sound.skippable = false
	sequence.steps = [visual, sound]
	assert_true(coordinator.start(sequence, _hud, _root))
	await wait_process_frames(2)
	assert_true(animator.is_playing())
	coordinator.request_skip()
	await wait_process_frames(2)
	assert_eq(coordinator.step_index, 1)
	assert_eq(coordinator.get_child_count(), 1)
	coordinator.cancel()
	assert_false(animator.is_playing())
	assert_false((coordinator.get_child(0) as AudioStreamPlayer).playing)
	assert_true(_player.movement_enabled)
	assert_false(WorldState.scene_transition.has_presentation())


func test_active_sequence_refuses_second_owner_travel_and_inventory() -> void:
	var coordinator: CutsceneCoordinator = _coordinator()
	var other: CutsceneCoordinator = _coordinator()
	var sequence: CutsceneSequence = CutsceneSequence.new()
	sequence.id = &"priority"
	var wait: CutsceneStep = _step(CutsceneStep.Kind.WAIT)
	wait.duration = 60.0
	sequence.steps = [wait]
	assert_true(coordinator.start(sequence, _hud, _root))
	assert_false(other.start(sequence, _hud, _root))
	var previous_scene: Node = get_tree().current_scene
	assert_false(WorldState.scene_transition.open_scene(previous_scene, "res://ui/main_menu.tscn"))
	assert_false(_hud.start_dialogue(_decision(), &"question"))
	await _key(KEY_TAB)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.SEQUENCE)
	coordinator.cancel()
	assert_true(_player.movement_enabled)


func test_scene_exit_releases_fade_and_actor_without_orphans() -> void:
	var coordinator: CutsceneCoordinator = _coordinator()
	var sequence: CutsceneSequence = CutsceneSequence.new()
	sequence.id = &"root_deleted"
	var fade: CutsceneStep = _step(CutsceneStep.Kind.FADE)
	fade.duration = 60.0
	sequence.steps = [fade]
	assert_true(coordinator.start(sequence, _hud, _root))
	await wait_process_frames(2)
	_root.free()
	assert_false(WorldState.scene_transition.has_presentation())
	assert_false((WorldState.scene_transition.get_node("Fade") as ColorRect).visible)


func test_mandatory_question_without_available_answers_is_rejected() -> void:
	var catalog: Stage01Narrative = _decision()
	catalog.entries[0].cancel_allowed = false
	for choice: DialogueChoiceData in catalog.entries[0].choices:
		choice.condition_id = &"flag:locked"
	assert_false(_hud.start_dialogue(catalog, &"question"))
	assert_eq(_hud.mode, GameplayHUD.ModalMode.NONE)
	assert_true(_player.movement_enabled)


func test_registered_effect_runs_once_across_reopened_context_and_respects_failure() -> void:
	_context.effects[&"local_event"] = func() -> bool:
		return _state.record_event(&"effect_called")
	assert_true(_context.apply_once(&"local_event", &"callback_test"))
	var reopened: DialogueContext = DialogueContext.new(_state, _items)
	assert_true(reopened.apply_once(&"local_event", &"callback_test"))
	assert_false(reopened.apply_once(&"unregistered", &"callback_missing"))
	assert_true(_state.has_event(&"effect_called"))
	assert_false(_state.has_event(&"dialogue_effect:callback_missing"))


func test_dialogue_layout_and_text_fit_different_viewport_sizes() -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(640, 360)
	_root.add_child(viewport)
	var hud: GameplayHUD = HUD.instantiate() as GameplayHUD
	viewport.add_child(hud)
	var catalog: Stage01Narrative = _decision()
	catalog.entries[0].text = "Você vê o vento passar.\nA narração continua com acentos: coração, memória e Saci-Pererê.\n".repeat(4)
	for viewport_size: Vector2i in [Vector2i(640,360), Vector2i(360,640), Vector2i(960,360), Vector2i(320,240)]:
		viewport.size = viewport_size
		await wait_process_frames(2)
		assert_true(hud.start_dialogue(catalog, &"question"))
		_read_current(hud.dialogue_session)
		await wait_process_frames(3)
		var view: DialogueView = hud.get_node("Screen/Story") as DialogueView
		var bounds: Rect2 = Rect2(Vector2.ZERO, Vector2(viewport_size))
		assert_true(bounds.encloses(view.get_global_rect()), str(viewport_size))
		assert_true(view.get_global_rect().encloses(view.body_label.get_global_rect()))
		assert_true(view.get_global_rect().encloses(view.hint_label.get_global_rect()))
		var font: Font = view.body_label.get_theme_font(&"font")
		var size: int = view.body_label.get_theme_font_size(&"font_size")
		for page: String in hud.dialogue_session.pages:
			var measured: Vector2 = font.get_multiline_string_size(page,
				HORIZONTAL_ALIGNMENT_LEFT, view.body_label.size.x, size)
			assert_lte(measured.y, view.body_label.size.y, "Texto inteiro deve caber: " + str(viewport_size))
		hud.dialogue_session.abort()


func _entry(id: StringName, text: String) -> DialogueEntry:
	var result: DialogueEntry = DialogueEntry.new()
	result.id = id
	result.text = text
	return result


func _catalog(entries: Array[DialogueEntry]) -> Stage01Narrative:
	var result: Stage01Narrative = Stage01Narrative.new()
	result.entries = entries
	return result


func _decision() -> Stage01Narrative:
	var question: DialogueEntry = _entry(&"question", "Escolha uma resposta: você está pronta?")
	question.speaker = "Saci"
	for index: int in range(3):
		var choice: DialogueChoiceData = DialogueChoiceData.new()
		choice.id = StringName("option_%d" % index)
		choice.label = "Resposta %d" % (index + 1)
		choice.next_id = &"answer"
		if index == 2:
			choice.effect_id = &"flag:selected_third"
		question.choices.append(choice)
	return _catalog([question, _entry(&"answer", "Obrigada! Até já.")])


func _read_current(session: DialogueSession) -> void:
	while session.page_index < session.pages.size() - 1:
		session.reveal()
		session.advance()
	session.reveal()


func _choice_ids(session: DialogueSession) -> Array[StringName]:
	var result: Array[StringName] = []
	for choice: DialogueChoiceData in session.get_choices():
		result.append(choice.id)
	return result


func _reach(phase: StringName) -> void:
	var guard: int = 0
	while _state.phase != phase and guard < 8:
		_state.advance_to(Stage01State.NEXT_PHASES[_state.phase])
		guard += 1


func _step(kind: CutsceneStep.Kind) -> CutsceneStep:
	var result: CutsceneStep = CutsceneStep.new()
	result.kind = kind
	return result


func _coordinator() -> CutsceneCoordinator:
	var result: CutsceneCoordinator = CutsceneCoordinator.new()
	_root.add_child(result)
	return result


func _key(code: Key) -> void:
	var press: InputEventKey = InputEventKey.new()
	press.keycode = code
	press.physical_keycode = code
	press.pressed = true
	Input.parse_input_event(press)
	await wait_process_frames(1)
	var release: InputEventKey = InputEventKey.new()
	release.keycode = code
	release.physical_keycode = code
	Input.parse_input_event(release)
	await wait_process_frames(1)
