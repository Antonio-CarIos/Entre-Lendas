class_name Stage01State
extends RefCounted
## Progresso narrativo da sessão. Portas, UI e mapas apenas consultam/consomem esta API.

signal changed()
signal phase_changed(new_phase: StringName)
signal ending_resolved(outcome: WorldStateLogic.Outcome)

const BASE_CLUES: Array[StringName] = [
	&"clue_origem_saci", &"clue_poder_gorro_parede", &"clue_gorro_vermelho",
	&"clue_mural_origens", &"clue_inquerito_1917", &"clue_crina_cavalo", &"clue_bambu_rachado"
]
const BONUS_CLUE: StringName = &"clue_dia_do_saci_bonus"
const PHASES: Array[StringName] = [
	&"book_intro", &"scene_2_sunset", &"scene_3_house_clean", &"scene_4_dialogue",
	&"scene_5_whirlwind", &"scene_6_house_chaos", &"scene_7_street_hub", &"scene_8_climax",
	&"epilogue_capture", &"epilogue_friendship", &"incomplete_recovery", &"completed"
]
const NEXT_PHASES: Dictionary[StringName, StringName] = {
	&"book_intro": &"scene_2_sunset", &"scene_2_sunset": &"scene_3_house_clean",
	&"scene_3_house_clean": &"scene_4_dialogue", &"scene_4_dialogue": &"scene_5_whirlwind",
	&"scene_5_whirlwind": &"scene_6_house_chaos", &"scene_6_house_chaos": &"scene_7_street_hub",
	&"scene_7_street_hub": &"scene_8_climax", &"scene_8_climax": &"incomplete_recovery",
	&"incomplete_recovery": &"scene_7_street_hub",
	&"epilogue_capture": &"completed", &"epilogue_friendship": &"completed"
}

var active: bool:
	get: return _active
var phase: StringName:
	get: return _phase
var saci_empatico: bool:
	get: return _saci_empatico
var muro_pintado: bool:
	get: return _mural_symbol != &""
var muro_simbolo_escolhido: StringName:
	get: return _mural_symbol
var viu_muro_ou_bonde: bool:
	get: return _saw_wall_or_tram
var peneira_entregue: bool:
	get: return _claimed_items.has(&"peneira")
var gorro_obtido: bool:
	get: return _claimed_items.has(&"gorro_saci")
var cachimbo_memoria: bool:
	get: return _events.has(&"pipe_memory")
var garrafa_aberta: bool:
	get: return _events.has(&"bottle_opened")
var climax_attempts: int:
	get: return _climax_attempts
var final_outcome: WorldStateLogic.Outcome:
	get: return _outcome
var pistas_saci_lidas: int:
	get: return _read_clues.size() - int(_read_clues.has(BONUS_CLUE))
var objective: String:
	get:
		match _phase:
			&"book_intro": return "Ler Lendas do Brasil."
			&"scene_2_sunset": return "Entrar na casa."
			&"scene_3_house_clean": return "Investigar a casa e a garrafa."
			&"scene_4_dialogue": return "Ouvir o Saci."
			&"scene_5_whirlwind": return "O vento toma a casa."
			&"scene_6_house_chaos", &"scene_7_street_hub", &"incomplete_recovery":
				return "Descobrir o que aconteceu."
			&"scene_8_climax": return "Encontrar o Saci no alto da ladeira."
			&"completed": return "Fase do Saci concluída."
			_: return "Ver o que ficou depois do vento."

var _active: bool = false
var _phase: StringName = &"book_intro"
var _saci_empatico: bool = false
var _mural_symbol: StringName = &""
var _saw_wall_or_tram: bool = false
var _climax_attempts: int = 0
var _outcome: WorldStateLogic.Outcome = WorldStateLogic.Outcome.UNDECIDED
var _events: Dictionary[StringName, bool] = {}
var _claimed_items: Dictionary[StringName, bool] = {}
var _unlocked_clues: Array[StringName] = []
var _read_clues: Array[StringName] = []
var _mural_panels: Array[int] = []


func begin() -> bool:
	if _active:
		return false
	_active = true
	changed.emit()
	return true


func reset() -> void:
	var had_phase: bool = _phase != &"book_intro"
	var was_dirty: bool = _active or not _events.is_empty() or not _unlocked_clues.is_empty()
	_active = false
	_phase = &"book_intro"
	_saci_empatico = false
	_mural_symbol = &""
	_saw_wall_or_tram = false
	_climax_attempts = 0
	_outcome = WorldStateLogic.Outcome.UNDECIDED
	_events.clear()
	_claimed_items.clear()
	_unlocked_clues.clear()
	_read_clues.clear()
	_mural_panels.clear()
	if had_phase:
		phase_changed.emit(_phase)
	if was_dirty or had_phase:
		changed.emit()


func advance_to(next_phase: StringName) -> bool:
	if not _active or NEXT_PHASES.get(_phase, &"") != next_phase or next_phase == &"":
		return false
	_phase = next_phase
	if next_phase == &"scene_4_dialogue":
		_events[&"bottle_opened"] = true
	elif next_phase == &"scene_8_climax":
		_climax_attempts += 1
	phase_changed.emit(_phase)
	changed.emit()
	return true


## Narração, memória e efeitos de uma vez; revisitar uma interação não os reaplica.
func record_event(event_id: StringName) -> bool:
	if not _active or event_id == &"" or _events.has(event_id) or event_id == &"bottle_opened":
		return false
	_events[event_id] = true
	changed.emit()
	return true


func has_event(event_id: StringName) -> bool:
	return _events.has(event_id)


func get_seen_events() -> Array[StringName]:
	var result: Array[StringName] = []
	result.assign(_events.keys())
	return result


func mark_empathy() -> bool:
	if _phase != &"scene_4_dialogue" or _saci_empatico:
		return false
	_saci_empatico = true
	changed.emit()
	return true


func paint_mural(symbol: StringName) -> bool:
	if _phase != &"scene_7_street_hub" or muro_pintado or symbol not in [&"gorro", &"bambu", &"redemoinho"]:
		return false
	_mural_symbol = symbol
	changed.emit()
	return true


func mark_tram_seen() -> bool:
	if _phase != &"scene_7_street_hub" or _saw_wall_or_tram:
		return false
	_saw_wall_or_tram = true
	changed.emit()
	return true


## Chamar após terminar o texto do quadro, não apenas entrar na área.
func read_mural_panel(panel: int) -> bool:
	if _phase != &"scene_7_street_hub" or panel < 1 or panel > 6 or panel in _mural_panels:
		return false
	_mural_panels.append(panel)
	_saw_wall_or_tram = true
	var complete: bool = true
	for index: int in range(1, 6):
		complete = complete and index in _mural_panels
	if complete and &"clue_mural_origens" not in _unlocked_clues:
		_unlocked_clues.append(&"clue_mural_origens")
	changed.emit()
	return true


func get_read_mural_panels() -> Array[int]:
	return _mural_panels.duplicate()


func unlock_clue(clue_id: StringName) -> bool:
	if not _active or clue_id not in BASE_CLUES or clue_id in _unlocked_clues:
		return false
	# A pista agregada exige os cinco quadros informativos, em qualquer ordem.
	if clue_id == &"clue_mural_origens":
		for panel: int in range(1, 6):
			if panel not in _mural_panels:
				return false
	_unlocked_clues.append(clue_id)
	changed.emit()
	return true


func mark_clue_read(clue_id: StringName) -> bool:
	if clue_id not in _unlocked_clues or clue_id in _read_clues:
		return false
	_read_clues.append(clue_id)
	if pistas_saci_lidas == BASE_CLUES.size() and BONUS_CLUE not in _unlocked_clues:
		_unlocked_clues.append(BONUS_CLUE)
	changed.emit()
	return true


func get_unlocked_clues() -> Array[StringName]:
	return _unlocked_clues.duplicate()


func get_read_clues() -> Array[StringName]:
	return _read_clues.duplicate()


func is_quest_item_claimed(item_id: StringName) -> bool:
	return _claimed_items.has(item_id)


func can_grant_quest_item(item_id: StringName, inventory: InventorySystem) -> bool:
	if not _active or inventory == null or is_quest_item_claimed(item_id) or inventory.has_item(item_id):
		return false
	var investigating: bool = _phase in [&"scene_7_street_hub", &"incomplete_recovery"]
	match item_id:
		&"cachimbo_fumo": return _phase == &"scene_3_house_clean" or investigating
		&"garrafa_vazia": return garrafa_aberta and (_phase == &"scene_6_house_chaos" or investigating)
		&"fita_vermelha", &"gorro_saci": return investigating
		&"peneira": return investigating and _saw_wall_or_tram
		_: return false


func grant_quest_item(item: ItemData, inventory: InventorySystem) -> bool:
	if item == null or not can_grant_quest_item(item.id, inventory):
		return false
	# Registrar antes do sinal de inventário impede uma segunda entrega reentrante.
	_claimed_items[item.id] = true
	if not inventory.add_item(item):
		_claimed_items.erase(item.id)
		return false
	changed.emit()
	return true


func is_capture_prepared(inventory: InventorySystem) -> bool:
	return inventory != null and inventory.has_item(&"peneira_cruz") and inventory.has_item(&"garrafa_vazia")


func is_friendship_prepared(inventory: InventorySystem, pipe_offered: bool = false) -> bool:
	return inventory != null and (pipe_offered or inventory.has_item(&"cachimbo_fumo")) and pistas_saci_lidas >= 3


## Consumo/reserva pertencem ao futuro controlador de batalha, não ao registro moral.
func resolve_ending(result: WorldStateLogic.Outcome, inventory: InventorySystem, calm_progress: int = 0, pipe_offered: bool = false) -> bool:
	if _phase != &"scene_8_climax" or _outcome != WorldStateLogic.Outcome.UNDECIDED:
		return false
	if result == WorldStateLogic.Outcome.CAPTURE:
		if not is_capture_prepared(inventory):
			return false
		_phase = &"epilogue_capture"
	elif result == WorldStateLogic.Outcome.FRIENDSHIP:
		if calm_progress < 100 or not is_friendship_prepared(inventory, pipe_offered):
			return false
		_phase = &"epilogue_friendship"
	else:
		return false
	_outcome = result
	ending_resolved.emit(result)
	phase_changed.emit(_phase)
	changed.emit()
	return true


## Consulta pura: carregar mapas nunca faz advance_to() nem reinicia progresso.
func get_map_visual_state(map_id: StringName) -> StringName:
	if map_id not in [&"house_interior", &"house_bedroom", &"house_backyard", &"santa_teresa_map"]:
		return &""
	if not _active:
		return &""
	if _outcome == WorldStateLogic.Outcome.CAPTURE:
		return &"epilogue_capture"
	if _outcome == WorldStateLogic.Outcome.FRIENDSHIP:
		return &"epilogue_friendship"
	if _phase == &"incomplete_recovery":
		return &"incomplete_recovery"
	var chaotic: bool = _phase in [&"scene_6_house_chaos", &"scene_7_street_hub", &"scene_8_climax"]
	if map_id == &"santa_teresa_map":
		return &"scene_7_street_hub" if chaotic else &"scene_2_sunset"
	return &"house_chaos" if chaotic else &"house_clean"
