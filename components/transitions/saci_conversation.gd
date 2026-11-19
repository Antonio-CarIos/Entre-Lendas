class_name SaciConversation
extends Node
## Preparação isolada da Cena 4. Só inicia com a arte humana validada.
## O mapa chama start após o Pop; a integração aguarda os assets de perna única.

signal finished(completed: bool, reason: String)
signal whirlwind_requested(actor: SaciActor)

var running: bool = false
var waiting_for_whirlwind: bool = false
var _hud: GameplayHUD
var _actor: SaciActor
var _state: Stage01State
var _coordinator: CutsceneCoordinator
var _session: DialogueSession
var _committing: bool = false
var _idle_effect: StringName


func get_validation_errors(actor: SaciActor, hud: GameplayHUD) -> PackedStringArray:
	var errors: PackedStringArray = []
	if not is_instance_valid(hud) or not hud.is_inside_tree() or hud.dialogue_context == null:
		errors.append("HUD indisponível")
	if not is_instance_valid(actor) or not actor.is_inside_tree() or actor.visuals == null:
		errors.append("Ator indisponível")
		return errors
	for action: StringName in [&"appear", &"idle", &"talk"]:
		if not actor.visuals.supports(&"one_leg", action, &"down"):
			errors.append("one_leg/%s_down" % action)
			continue
		var frames: SpriteFrames = actor.visuals.one_leg
		var clip: StringName = StringName("%s_down" % action)
		if frames.get_animation_loop(clip) != (action != &"appear"):
			errors.append("Loop incorreto: " + String(clip))
	if errors.is_empty() and _appearance_duration(actor) > 60.0:
		errors.append("Aparição excede a duração suportada")
	return errors


func start(actor: SaciActor, hud: GameplayHUD, replay_appearance: bool = true) -> bool:
	if not is_inside_tree() or running or waiting_for_whirlwind \
		or not get_validation_errors(actor, hud).is_empty():
		return false
	var state: Stage01State = hud.dialogue_context.state
	if not state.active or state.phase != &"scene_4_dialogue" \
		or state.has_event(&"saci_conversation_completed"):
		return false
	_hud = hud
	_actor = actor
	_state = state
	_idle_effect = StringName("saci_idle_%d" % get_instance_id())
	_coordinator = CutsceneCoordinator.new()
	add_child(_coordinator)
	_coordinator.finished.connect(_on_finished)
	_hud.dialogue_context.transient_effects[_idle_effect] = _idle
	if not _coordinator.start(_sequence(replay_appearance), hud, self):
		_clear_bindings()
		_coordinator.queue_free()
		return false
	running = true
	_state.changed.connect(_on_state_changed)
	_actor.tree_exiting.connect(_on_actor_exiting)
	_hud.tree_exiting.connect(_on_hud_exiting)
	_actor.set_body_solid(false)
	_actor.show_form(&"one_leg", Vector2.DOWN)
	if replay_appearance:
		_actor.play_action(&"appear")
	return true


## O controlador da Cena 5 deve adquirir seu bloqueio na mesma chamada após release.
func release_to_whirlwind() -> bool:
	if not waiting_for_whirlwind:
		return false
	waiting_for_whirlwind = false
	_clear_bindings()
	if is_instance_valid(_hud):
		_hud.end_sequence(self)
	return true


func cancel() -> void:
	if is_instance_valid(_coordinator) and _coordinator.running:
		_coordinator.cancel()
	elif waiting_for_whirlwind:
		release_to_whirlwind()
		if is_instance_valid(_actor):
			_actor.hide_actor()


func _exit_tree() -> void:
	cancel()
	_clear_bindings()


func _process(_delta: float) -> void:
	if not running or not is_instance_valid(_hud) or _hud.dialogue_session == null:
		return
	if _session != _hud.dialogue_session and _hud.dialogue_session.active:
		_session = _hud.dialogue_session
		_session.changed.connect(_sync_speaking)
		_sync_speaking()


func _sequence(replay_appearance: bool) -> CutsceneSequence:
	var sequence: CutsceneSequence = CutsceneSequence.new()
	sequence.id = &"saci_conversation"
	var appearance: CutsceneStep = CutsceneStep.new()
	appearance.duration = _appearance_duration(_actor) if replay_appearance else 0.0
	var idle: CutsceneStep = CutsceneStep.new()
	idle.kind = CutsceneStep.Kind.EFFECT
	idle.effect_id = _idle_effect
	var dialogue: CutsceneStep = CutsceneStep.new()
	dialogue.kind = CutsceneStep.Kind.DIALOGUE
	dialogue.narrative = SaciConversationScript.create()
	dialogue.entry_id = &"saci.appears"
	sequence.steps = [appearance, idle, dialogue]
	return sequence


func _appearance_duration(actor: SaciActor) -> float:
	var frames: SpriteFrames = actor.visuals.one_leg
	var duration: float = 0.0
	for index: int in range(frames.get_frame_count(&"appear_down")):
		duration += frames.get_frame_duration(&"appear_down", index)
	return duration / frames.get_animation_speed(&"appear_down")


func _idle() -> bool:
	return is_instance_valid(_actor) and _actor.play_action(&"idle", Vector2.DOWN)


func _sync_speaking() -> void:
	if not running or not is_instance_valid(_actor) or _session == null or not _session.active:
		return
	var speaking: bool = _session.entry.speaker == "Saci" and not _session.revealed
	var action: StringName = &"talk" if speaking else &"idle"
	if _actor.action != action:
		if not _actor.play_action(action, Vector2.DOWN):
			cancel()


func _on_finished(completed: bool, reason: String) -> void:
	var coordinator: CutsceneCoordinator = _coordinator
	running = false
	_clear_session()
	if completed and _state.active and _state.phase == &"scene_4_dialogue" \
		and _state.has_event(&"saci_farewell") \
		and get_validation_errors(_actor, _hud).is_empty():
		# Uma única transição após a última confirmação; não no início da despedida.
		_committing = true
		waiting_for_whirlwind = _hud.begin_sequence(self)
		completed = waiting_for_whirlwind and _state.advance_to(&"scene_5_whirlwind")
		if completed:
			_state.record_event(&"saci_conversation_completed")
		_committing = false
	else:
		completed = false
	if completed:
		_idle()
		finished.emit(true, "")
		whirlwind_requested.emit(_actor)
	else:
		release_to_whirlwind()
		_clear_bindings()
		if is_instance_valid(_actor):
			_actor.hide_actor()
		finished.emit(false, reason if not reason.is_empty() else "handoff_unavailable")
	if is_instance_valid(coordinator):
		coordinator.queue_free()


func _on_state_changed() -> void:
	var expected_phase: StringName = &"scene_5_whirlwind" if waiting_for_whirlwind else &"scene_4_dialogue"
	if not _committing and (not _state.active or _state.phase != expected_phase):
		cancel()


func _on_actor_exiting() -> void:
	cancel()


func _on_hud_exiting() -> void:
	cancel()


func _clear_session() -> void:
	if _session != null and _session.changed.is_connected(_sync_speaking):
		_session.changed.disconnect(_sync_speaking)
	_session = null


func _clear_bindings() -> void:
	_clear_session()
	if _state != null and _state.changed.is_connected(_on_state_changed):
		_state.changed.disconnect(_on_state_changed)
	if is_instance_valid(_actor) and _actor.tree_exiting.is_connected(_on_actor_exiting):
		_actor.tree_exiting.disconnect(_on_actor_exiting)
	if is_instance_valid(_hud):
		if _hud.dialogue_context != null:
			_hud.dialogue_context.transient_effects.erase(_idle_effect)
		if _hud.tree_exiting.is_connected(_on_hud_exiting):
			_hud.tree_exiting.disconnect(_on_hud_exiting)
