extends GutTest
## Preparação da Cena 4. Arte sintética só em memória, nunca nos assets do jogo.

const ACTOR: PackedScene = preload("res://entities/folklore/saci/saci.tscn")
const PLAYER: PackedScene = preload("res://entities/player/player.tscn")
const HUD: PackedScene = preload("res://ui/gameplay_hud.tscn")
const SOURCE: Stage01Narrative = preload("res://core/dialogue/stage_01/stage_01_script.tres")

var _root: Node2D
var _actor: SaciActor
var _player: Player
var _hud: GameplayHUD
var _director: SaciConversation


func before_each() -> void:
	WorldState.reset()
	WorldState.stage01.begin()
	for phase: StringName in [&"scene_2_sunset", &"scene_3_house_clean", &"scene_4_dialogue"]:
		WorldState.stage01.advance_to(phase)
	_root = Node2D.new()
	add_child_autofree(_root)
	_player = PLAYER.instantiate() as Player
	_root.add_child(_player)
	_hud = HUD.instantiate() as GameplayHUD
	_root.add_child(_hud)
	_hud.bind_player(_player)
	_actor = ACTOR.instantiate() as SaciActor
	_actor.visuals = _test_visuals()
	_root.add_child(_actor)
	_director = SaciConversation.new()
	_root.add_child(_director)


func after_each() -> void:
	get_tree().paused = false
	if is_instance_valid(_root):
		_root.free()
	WorldState.reset()
	await wait_process_frames(2)


func test_catalog_keeps_all_branches_mandatory_and_stops_before_scene_five() -> void:
	var catalog: Stage01Narrative = SaciConversationScript.create()
	assert_true(catalog.get_validation_errors().is_empty())
	assert_eq(catalog.find_entry(&"saci.greeting").choices.size(), 3)
	assert_eq(catalog.find_entry(&"saci.common").choices.size(), 2)
	for entry: DialogueEntry in catalog.get_scene_entries(&"scene_04"):
		assert_false(entry.cancel_allowed)
	assert_eq(catalog.find_entry(&"saci.farewell").next_id, &"")
	assert_eq(SOURCE.find_entry(&"saci.farewell").next_id, &"whirlwind.departure")
	assert_true(SOURCE.find_entry(&"saci.identity").text.contains("(risonho)"))
	assert_false(catalog.find_entry(&"saci.identity").text.contains("(risonho)"))
	assert_true(catalog.find_entry(&"saci.identity").stage_direction.contains("Risonho"))
	assert_true(catalog.find_entry(&"saci.common").text.contains("contaram errado"))
	assert_true(catalog.find_entry(&"saci.farewell").text.contains("vento fizer curva"))
	catalog.find_entry(&"saci.greeting").choices[0].label = "Teste isolado"
	assert_eq(SOURCE.find_entry(&"saci.greeting").choices[0].label, "Eu só estava curioso")


func test_curious_story_reaches_single_handoff_without_empathy() -> void:
	await _route(&"curious", &"story")


func test_curious_plans_reaches_single_handoff_without_empathy() -> void:
	await _route(&"curious", &"plans")


func test_identity_story_reaches_single_handoff_without_empathy() -> void:
	await _route(&"identity", &"story")


func test_identity_plans_reaches_single_handoff_without_empathy() -> void:
	await _route(&"identity", &"plans")


func test_empathy_story_reaches_single_handoff_with_empathy() -> void:
	await _route(&"empathy", &"story")


func test_empathy_plans_reaches_single_handoff_with_empathy() -> void:
	await _route(&"empathy", &"plans")


func test_keyboard_cannot_cancel_or_open_inventory_during_required_choices() -> void:
	assert_true(_director.start(_actor, _hud, false))
	await _until(&"saci.greeting", true)
	assert_eq(_actor.action, &"idle")
	await _key(KEY_ESCAPE)
	await _key(KEY_TAB)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.STORY)
	assert_false(_player.movement_enabled)
	await _key(KEY_DOWN)
	await _key(KEY_DOWN)
	await _key(KEY_E)
	assert_eq(_hud.dialogue_session.entry.id, &"saci.empathy")
	assert_eq(_actor.action, &"talk")
	assert_true(WorldState.stage01.saci_empatico)
	await _until(&"saci.common", true)
	await _key(KEY_DOWN)
	await _key(KEY_E)
	assert_eq(_hud.dialogue_session.entry.id, &"saci.plans")
	await _until(&"saci.farewell", true)
	assert_eq(WorldState.stage01.phase, &"scene_4_dialogue")
	await _key(KEY_E)
	await wait_process_frames(4)
	assert_true(_director.waiting_for_whirlwind)
	assert_false(_player.movement_enabled)
	await _key(KEY_TAB)
	await _key(KEY_ESCAPE)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.SEQUENCE)
	assert_false(WorldState.stage01.has_event(&"whirlwind_departed"))
	WorldState.reset()
	assert_false(_director.waiting_for_whirlwind)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.NONE)
	assert_true(_player.movement_enabled)
	assert_eq(_actor.form, &"hidden")


func test_missing_real_art_fails_before_lock_or_progress_and_never_uses_whirlwind() -> void:
	_actor.visuals = load("res://entities/folklore/saci/saci_visuals.tres") as SaciVisuals
	assert_eq(_director.get_validation_errors(_actor, _hud).size(), 3)
	assert_false(_director.start(_actor, _hud))
	assert_eq(_actor.form, &"hidden")
	assert_true(_player.movement_enabled)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.NONE)
	assert_eq(WorldState.stage01.phase, &"scene_4_dialogue")
	assert_false(WorldState.scene_transition.has_presentation())
	assert_true(_hud.dialogue_context.transient_effects.is_empty())


func test_bad_size_loop_or_empty_clip_is_rejected_without_aliases() -> void:
	_actor.visuals.one_leg.set_animation_loop(&"appear_down", true)
	assert_false(_director.start(_actor, _hud))
	_actor.visuals = _test_visuals()
	_actor.visuals.one_leg.clear(&"talk_down")
	assert_false(_director.start(_actor, _hud))
	_actor.visuals = _test_visuals()
	var wrong: GradientTexture2D = GradientTexture2D.new()
	wrong.width = 64
	wrong.height = 80
	_actor.visuals.one_leg.set_frame(&"idle_down", 0, wrong)
	assert_false(_director.start(_actor, _hud))
	assert_false(WorldState.scene_transition.has_presentation())


func test_busy_hud_and_wrong_phase_leave_no_callbacks_or_actor() -> void:
	_hud.show_notice("Aviso existente")
	assert_false(_director.start(_actor, _hud))
	assert_eq(_hud.mode, GameplayHUD.ModalMode.NOTICE)
	assert_true(_hud.dialogue_context.transient_effects.is_empty())
	assert_eq(_actor.form, &"hidden")
	await _key(KEY_E)
	WorldState.reset()
	assert_false(_director.start(_actor, _hud))
	assert_true(_player.movement_enabled)


func test_cancel_allows_resume_without_duplicate_empathy_or_reopening_bottle() -> void:
	assert_true(_director.start(_actor, _hud))
	assert_false(_director.start(_actor, _hud))
	await _until(&"saci.greeting", true)
	assert_true(_hud.dialogue_session.choose(&"empathy"))
	_director.cancel()
	assert_false(_director.running)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.NONE)
	assert_true(_player.movement_enabled)
	assert_true(WorldState.stage01.saci_empatico)
	assert_true(WorldState.stage01.garrafa_aberta)
	assert_eq(_actor.form, &"hidden")
	assert_false(WorldState.scene_transition.has_presentation())
	assert_true(_hud.dialogue_context.transient_effects.is_empty())
	await wait_process_frames(2)
	await _route(&"identity", &"story", false)
	assert_true(WorldState.stage01.saci_empatico)
	assert_eq(WorldState.inventory.get_items().size(), 0)


func test_reset_and_dependency_removal_restore_modal_and_presentation() -> void:
	assert_true(_director.start(_actor, _hud, false))
	await _until(&"saci.greeting")
	WorldState.reset()
	assert_false(_director.running)
	assert_true(_player.movement_enabled)
	assert_false(WorldState.scene_transition.has_presentation())
	assert_eq(_hud.mode, GameplayHUD.ModalMode.NONE)


func test_actor_removed_mid_dialogue_restores_control() -> void:
	assert_true(_director.start(_actor, _hud, false))
	await _until(&"saci.greeting")
	_actor.free()
	assert_false(_director.running)
	assert_true(_player.movement_enabled)
	assert_false(WorldState.scene_transition.has_presentation())
	assert_true(_hud.dialogue_context.transient_effects.is_empty())


func test_director_or_hud_removed_mid_dialogue_restores_control() -> void:
	assert_true(_director.start(_actor, _hud, false))
	await _until(&"saci.greeting")
	_director.free()
	assert_true(_player.movement_enabled)
	assert_false(WorldState.scene_transition.has_presentation())
	assert_eq(_actor.form, &"hidden")
	_director = SaciConversation.new()
	_root.add_child(_director)
	assert_true(_director.start(_actor, _hud, false))
	await _until(&"saci.greeting")
	_hud.free()
	assert_false(_director.running)
	assert_true(_player.movement_enabled)
	assert_false(WorldState.scene_transition.has_presentation())


func test_preexisting_player_lock_is_preserved_after_cancellation() -> void:
	_player.set_movement_enabled(false)
	assert_true(_director.start(_actor, _hud, false))
	_director.cancel()
	assert_false(_player.movement_enabled)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.NONE)


func _route(first: StringName, second: StringName, appearance: bool = true) -> void:
	var was_empathetic: bool = WorldState.stage01.saci_empatico
	watch_signals(_director)
	assert_true(_director.start(_actor, _hud, appearance))
	assert_eq(_actor.form, &"one_leg")
	assert_eq(_actor.action, &"appear" if appearance else &"idle")
	assert_false(_player.movement_enabled)
	await _until(&"saci.greeting", true)
	assert_true(_hud.dialogue_session.choose(first))
	await _until(&"saci.common", true)
	assert_true(_hud.dialogue_session.choose(second))
	await _until(&"saci.farewell", true)
	assert_eq(WorldState.stage01.phase, &"scene_4_dialogue")
	assert_false(WorldState.stage01.has_event(&"saci_farewell"))
	await _key(KEY_E)
	await wait_process_frames(4)
	assert_eq(WorldState.stage01.phase, &"scene_5_whirlwind")
	assert_eq(WorldState.stage01.saci_empatico, was_empathetic or first == &"empathy")
	assert_true(WorldState.stage01.has_event(&"saci_conversation_completed"))
	assert_signal_emit_count(_director, &"whirlwind_requested", 1)
	assert_false(_player.movement_enabled)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.SEQUENCE)
	assert_false(_director.start(_actor, _hud))
	assert_false(WorldState.stage01.has_event(&"whirlwind_departed"))
	assert_eq(_actor.collision_layer, 0)
	assert_true(_director.release_to_whirlwind())
	assert_false(_director.release_to_whirlwind())
	assert_true(_player.movement_enabled)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.NONE)
	assert_true(_hud.dialogue_context.transient_effects.is_empty())


func _until(id: StringName, reveal: bool = false) -> void:
	for index: int in range(100):
		if _hud.dialogue_session != null and _hud.dialogue_session.active \
			and _hud.dialogue_session.entry.id == id:
			if reveal:
				_hud.dialogue_session.reveal()
				# Revelar a última página sem confirmar a entrada/decisão.
				for page: int in range(_hud.dialogue_session.pages.size()):
					if _hud.dialogue_session.page_index >= _hud.dialogue_session.pages.size() - 1:
						break
					_hud.dialogue_session.advance()
					_hud.dialogue_session.reveal()
			await wait_process_frames(2)
			return
		if _hud.dialogue_session != null and _hud.dialogue_session.active:
			assert_false(_hud.dialogue_session.is_decision() and _hud.dialogue_session.revealed,
				"Ramo deve alcançar " + String(id) + " sem escolher outra resposta")
			await _key(KEY_E)
		else:
			await wait_process_frames(2)
	assert_true(false, "Não alcançou " + String(id))


func _key(code: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await wait_process_frames(2)
	event = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = false
	Input.parse_input_event(event)
	await wait_process_frames(2)


func _test_visuals() -> SaciVisuals:
	var visuals: SaciVisuals = SaciVisuals.new()
	visuals.one_leg = SpriteFrames.new()
	visuals.one_leg.remove_animation(&"default")
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.width = 32
	texture.height = 64
	for action: StringName in [&"appear", &"idle", &"talk"]:
		var clip: StringName = StringName("%s_down" % action)
		visuals.one_leg.add_animation(clip)
		visuals.one_leg.set_animation_speed(clip, 30.0)
		visuals.one_leg.set_animation_loop(clip, action != &"appear")
		visuals.one_leg.add_frame(clip, texture)
		visuals.one_leg.add_frame(clip, texture)
	return visuals
