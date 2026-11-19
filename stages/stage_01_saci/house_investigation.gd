class_name HouseInvestigation
extends HouseLevel
## Investigação do térreo/quarto sem reconstruir tiles, escadas ou móveis existentes.

signal bottle_opening_completed()

var narrative: Stage01Narrative
var _shown_entry: StringName = &""
var _effect: Tween
var _base_light: Color

@onready var _light: CanvasModulate = $HouseModulate
@onready var _interactions: Node2D = $NarrativeInteractions


func _ready() -> void:
	super._ready()
	_base_light = _light.color
	narrative = HouseInvestigationScript.create()
	_hud.dialogue_context.transient_effects[&"open_bottle"] = _can_open_bottle
	_hud.dialogue_finished.connect(_on_house_dialogue_finished)
	WorldState.stage01.changed.connect(_refresh_story_policy)
	WorldState.scene_transition.transition_finished.connect(_on_arrival_transition_finished)
	AudioManager.preferences_changed.connect(_restore_effects)
	for area: DialogueInteractable in _interactions.get_children():
		area.narrative = narrative
		area.interacted.connect(_on_interacted)
	var pipe: NarrativePipe = get_node_or_null("YSortRoot/State_Organized/Pipe") as NarrativePipe
	if pipe != null:
		pipe.interacted.connect(_on_interacted)
	_refresh_story_policy()
	_try_arrival.call_deferred()


func _exit_tree() -> void:
	_restore_effects()


func _process(delta: float) -> void:
	var hands: Node2D = get_node_or_null("YSortRoot/State_Organized/Clock/Hands") as Node2D
	if hands != null:
		hands.rotation -= delta * 0.22


func _on_arrival_transition_finished(path: String) -> void:
	if path == scene_file_path:
		_try_arrival()


func _try_arrival() -> void:
	if not has_node("YSortRoot/State_Organized/Pipe") or get_tree().current_scene != self \
		or WorldState.scene_transition.is_transitioning:
		return
	if WorldState.stage01.active and WorldState.stage01.phase == &"scene_3_house_clean" \
		and not WorldState.stage01.has_event(&"intro_house_clean") \
		and _hud.mode == GameplayHUD.ModalMode.NONE and player.movement_enabled:
		_hud.start_dialogue(narrative, &"clean.arrival")


func _refresh_story_policy() -> void:
	var clean: bool = WorldState.stage01.active and WorldState.stage01.phase == &"scene_3_house_clean"
	for area: DialogueInteractable in _interactions.get_children():
		area.set_deferred(&"monitorable", clean)
	var bottle: Node2D = get_node_or_null("YSortRoot/State_Organized/ClosedBottle") as Node2D
	if bottle != null:
		bottle.visible = not WorldState.stage01.garrafa_aberta


func _can_open_bottle() -> bool:
	return get_tree().current_scene == self and WorldState.stage01.active \
		and WorldState.stage01.phase == &"scene_3_house_clean" and not WorldState.stage01.garrafa_aberta


func _on_interacted() -> void:
	_shown_entry = &""
	if _hud.dialogue_session != null:
		_hud.dialogue_session.changed.connect(_on_story_changed)
		_on_story_changed()


func _on_story_changed() -> void:
	var id: StringName = _hud.dialogue_session.entry.id
	if id == _shown_entry:
		return
	_shown_entry = id
	_restore_effects()
	if id in [&"pipe.memory_bamboo", &"pipe.memory_origins"]:
		if not AudioManager.preferences.reduced_effects:
			_effect = create_tween()
			_effect.tween_property(_light, ^"color", _base_light * Color(0.86, 0.89, 0.96), 0.3)
	elif id == &"bottle.leave":
		AudioManager.play_sfx(&"bamboo_crack")
		var bottle: Node2D = get_node("YSortRoot/State_Organized/ClosedBottle") as Node2D
		AudioManager.play_positional(&"saci_laugh", self, bottle.global_position)
		if not AudioManager.preferences.reduced_effects:
			_effect = create_tween()
			for angle: float in [0.07, -0.07, 0.04, -0.04, 0.0]:
				_effect.tween_property(bottle, ^"rotation", angle, 0.09)
			_effect.parallel().tween_property(_light, ^"color", _base_light * Color(0.82, 0.82, 0.86), 0.2)
			_effect.tween_property(_light, ^"color", _base_light, 0.3)
	elif id == &"bottle.open":
		AudioManager.play_sfx(&"cork_pop")


func _restore_effects() -> void:
	if _effect != null and _effect.is_valid():
		_effect.kill()
	_effect = null
	if is_instance_valid(_light):
		_light.color = _base_light
	var bottle: Node2D = get_node_or_null("YSortRoot/State_Organized/ClosedBottle") as Node2D
	if bottle != null:
		bottle.rotation = 0.0


func _on_house_dialogue_finished(completed: bool, _reason: String) -> void:
	_restore_effects()
	if completed and _hud.dialogue_session.entry.id == &"bottle.open" and _can_open_bottle():
		if WorldState.stage01.advance_to(&"scene_4_dialogue"):
			bottle_opening_completed.emit()
