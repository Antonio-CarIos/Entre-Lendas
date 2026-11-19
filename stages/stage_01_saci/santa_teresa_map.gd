class_name SantaTeresaMap
extends HouseLevel
## Cidade do concept_street; aparência derivada do progresso global quando ativo.

const SUNSET: Color = Color("ffdfb3")
const STREET_HUB: Color = Color("9eaab8")
const STORY: Stage01Narrative = preload("res://core/dialogue/stage_01/stage_01_script.tres")

@export_enum("concept_daylight", "scene_2_sunset", "scene_7_street_hub") var phase: String = "concept_daylight"

var _window_tween: Tween
var _vendor_message: String = ""

@onready var _entrance: SceneDoor = $Transitions/EnterHouse
@onready var _window: Sprite2D = $YSortRoot/SharedProps/HouseFacade/LeftWindow
@onready var _window_scale: Vector2 = _window.scale
@onready var _vendor: DialogueInteractable = $YSortRoot/SharedProps/Quitanda/Quitandeira/InteractionArea


func _ready() -> void:
	super._ready()
	_vendor_message = _vendor.message
	_hud.dialogue_context.transient_effects[&"enter_house"] = _can_enter_house
	_hud.dialogue_finished.connect(_on_city_dialogue_finished)
	WorldState.stage01.changed.connect(_refresh_story_policy)
	WorldState.scene_transition.transition_finished.connect(_on_arrival_transition_finished)
	AudioManager.preferences_changed.connect(_refresh_window_motion)
	($NarrativeInteractions/HouseWindow as DialogueInteractable).interacted.connect(_on_window_interacted)
	_refresh_story_policy()
	if not WorldState.stage01.active:
		apply_city_state(StringName(phase))
	_try_arrival.call_deferred()


func _exit_tree() -> void:
	_stop_window_motion()


func _on_arrival_transition_finished(scene_path: String) -> void:
	if scene_path == scene_file_path:
		_try_arrival()


func _try_arrival() -> void:
	var state: Stage01State = WorldState.stage01
	if get_tree().current_scene != self or WorldState.scene_transition.is_transitioning:
		return
	if state.active and state.phase == &"scene_2_sunset" and not state.has_event(&"intro_city") \
		and _hud.mode == GameplayHUD.ModalMode.NONE and player.movement_enabled:
		_hud.start_dialogue(STORY, &"city.arrival")


func _refresh_story_policy() -> void:
	var state: Stage01State = WorldState.stage01
	var early: bool = state.active and state.phase in [
		&"scene_2_sunset", &"scene_3_house_clean", &"scene_4_dialogue", &"scene_5_whirlwind"]
	for area: DialogueInteractable in [$NarrativeInteractions/Tram,
		$NarrativeInteractions/StreetSign, $NarrativeInteractions/HouseWindow]:
		area.set_deferred(&"monitorable", early)
	_entrance.narrative = STORY if state.active and state.phase == &"scene_2_sunset" else null
	_entrance.entry_id = &"city.door" if _entrance.narrative != null else &""
	_vendor.message = "Boa tarde, minha filha! A casa logo ali está com a porta entreaberta. Parece que alguém está esperando você." \
		if early else _vendor_message
	_refresh_window_motion()


func _can_enter_house() -> bool:
	return WorldState.stage01.active and WorldState.stage01.phase == &"scene_2_sunset" \
		and WorldState.scene_transition.can_open_map(self, _entrance.target_scene,
			_entrance.target_spawn, &"scene_3_house_clean")


func _on_city_dialogue_finished(completed: bool, reason: String) -> void:
	if not completed:
		if reason not in ["cancelled", "scene_exited", "travel_started", "sequence_ended"]:
			_hud.show_notice("Não foi possível entrar na casa. A porta continua aqui; tente novamente.")
		return
	if _hud.dialogue_session.entry.id != &"city.enter":
		return
	# Só confirmar o texto de entrada autoriza a viagem; avanço ocorre sob o fade.
	if not WorldState.scene_transition.open_map(self, _entrance.target_scene,
		_entrance.target_spawn, &"scene_3_house_clean", &"house_entered"):
		_hud.show_notice("Não foi possível entrar na casa. Tente novamente pela porta.")
	else:
		AudioManager.play_sfx(&"door_open")


func _refresh_window_motion() -> void:
	var enabled: bool = WorldState.stage01.active and WorldState.stage01.phase in [
		&"scene_2_sunset", &"scene_3_house_clean", &"scene_4_dialogue", &"scene_5_whirlwind"]
	if not enabled or AudioManager.preferences.reduced_effects:
		_stop_window_motion()
		return
	if _window_tween != null and _window_tween.is_valid():
		return
	_window_tween = create_tween().set_loops()
	_window_tween.tween_property(_window, ^"scale:x", _window_scale.x * 0.65, 0.35)
	_window_tween.tween_property(_window, ^"scale:x", _window_scale.x, 0.35)
	_window_tween.tween_interval(3.0)


func _stop_window_motion() -> void:
	if _window_tween != null and _window_tween.is_valid():
		_window_tween.kill()
	_window_tween = null
	if is_instance_valid(_window):
		_window.scale = _window_scale


func _on_window_interacted() -> void:
	AudioManager.play_positional(&"saci_laugh", self, _window.global_position)


func _apply_map_visual_state(visual_state: StringName) -> void:
	super._apply_map_visual_state(visual_state)
	if visual_state in [&"scene_2_sunset", &"scene_7_street_hub"]:
		apply_city_state(visual_state)


func apply_city_state(new_phase: StringName) -> void:
	if new_phase not in [&"concept_daylight", &"scene_2_sunset", &"scene_7_street_hub"]:
		return
	phase = String(new_phase)
	var color: Color = Color.WHITE
	if new_phase == &"scene_2_sunset":
		color = SUNSET
	elif new_phase == &"scene_7_street_hub":
		color = STREET_HUB
	($CityModulate as CanvasModulate).color = color
