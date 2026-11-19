extends Control
## Prévia por F6 isolada da sessão real; não modifica WorldState nem os mapas.

const STORY: Stage01Narrative = preload("res://core/dialogue/stage_01/stage_01_script.tres")

@onready var _hud: GameplayHUD = $GameplayHUD
@onready var _coordinator: CutsceneCoordinator = $Coordinator
@onready var _restart_button: Button = $Restart


func _ready() -> void:
	var state: Stage01State = Stage01State.new()
	state.begin()
	for phase: StringName in [&"scene_2_sunset", &"scene_3_house_clean", &"scene_4_dialogue"]:
		state.advance_to(phase)
	_hud.dialogue_context = DialogueContext.new(state, InventorySystem.new())
	_coordinator.finished.connect(_on_finished)
	_restart_button.pressed.connect(_restart)
	_restart()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_echo() and not _coordinator.running and event.is_action_pressed(&"interact"):
		_restart()
		get_viewport().set_input_as_handled()


func _restart() -> void:
	var sequence: CutsceneSequence = CutsceneSequence.new()
	sequence.id = &"preview_saci_dialogue"
	var wait: CutsceneStep = CutsceneStep.new()
	wait.kind = CutsceneStep.Kind.WAIT
	wait.duration = 1.0
	var talk: CutsceneStep = CutsceneStep.new()
	talk.kind = CutsceneStep.Kind.DIALOGUE
	talk.narrative = STORY
	talk.entry_id = &"saci.greeting"
	sequence.steps = [wait, talk]
	if _coordinator.start(sequence, _hud, self):
		_restart_button.hide()


func _on_finished(_completed: bool, _reason: String) -> void:
	_restart_button.show()
	_restart_button.grab_focus()
