class_name DialogueContext
extends RefCounted
## Adaptador puro. IDs desconhecidos falham fechados; viagens exigem callback explícito.

var state: Stage01State
var inventory: InventorySystem
var conditions: Dictionary[StringName, Callable] = {}
var effects: Dictionary[StringName, Callable] = {}
## Intenções/validações de viagem são reavaliadas a cada escolha, sem flag persistente.
var transient_effects: Dictionary[StringName, Callable] = {}
var _applied: Dictionary[StringName, bool] = {}


func _init(stage: Stage01State, items: InventorySystem) -> void:
	state = stage
	inventory = items


func allows(condition: StringName) -> bool:
	if condition == &"":
		return true
	var expression: String = String(condition)
	if expression.begins_with("!"):
		return not allows(StringName(expression.substr(1))) if knows(StringName(expression.substr(1))) else false
	if conditions.has(condition):
		return bool(conditions[condition].call()) if conditions[condition].is_valid() else false
	if expression.begins_with("flag:"):
		return state.has_event(StringName(expression.substr(5)))
	if expression.begins_with("item:"):
		return inventory.has_item(StringName(expression.substr(5)))
	if expression.begins_with("clue:"):
		return StringName(expression.substr(5)) in state.get_unlocked_clues()
	if expression.begins_with("read_clue:"):
		return StringName(expression.substr(10)) in state.get_read_clues()
	match condition:
		&"wall_or_tram_seen": return state.viu_muro_ou_bonde
		&"wall_or_tram_unseen": return not state.viu_muro_ou_bonde
		&"sieve_claimed": return state.peneira_entregue
		&"sieve_not_claimed": return not state.peneira_entregue
		&"three_read_clues": return state.pistas_saci_lidas >= 3
		&"four_read_clues": return state.pistas_saci_lidas >= 4
		&"friendship_ready": return state.is_friendship_prepared(inventory)
		&"saci_empatico": return state.saci_empatico
		&"painted_gorro": return state.muro_simbolo_escolhido == &"gorro"
		&"painted_bambu": return state.muro_simbolo_escolhido == &"bambu"
		&"painted_redemoinho": return state.muro_simbolo_escolhido == &"redemoinho"
	return false


func knows(condition: StringName) -> bool:
	var expression: String = String(condition)
	return condition == &"" or conditions.has(condition) or expression.begins_with("flag:") \
		or expression.begins_with("item:") or expression.begins_with("clue:") \
		or expression.begins_with("read_clue:") or condition in [
			&"wall_or_tram_seen", &"wall_or_tram_unseen", &"sieve_claimed", &"sieve_not_claimed",
			&"three_read_clues", &"four_read_clues", &"friendship_ready", &"saci_empatico",
			&"painted_gorro", &"painted_bambu", &"painted_redemoinho"]


func allows_all(requirements: PackedStringArray) -> bool:
	for condition: String in requirements:
		if not allows(StringName(condition)):
			return false
	return true


## A chave deve ser estável por nó/resposta/etapa. Reserva antes de emitir sinais.
func apply_once(effect: StringName, key: StringName) -> bool:
	if effect == &"":
		return true
	if transient_effects.has(effect):
		return bool(transient_effects[effect].call()) if transient_effects[effect].is_valid() else false
	var marker: StringName = StringName("dialogue_effect:" + String(key))
	if _applied.has(marker) or state.has_event(marker):
		return true
	_applied[marker] = true
	if not _apply(effect):
		_applied.erase(marker)
		return false
	if state.active:
		state.record_event(marker)
		_applied.erase(marker)
	return true


func _apply(effect: StringName) -> bool:
	if effects.has(effect):
		return bool(effects[effect].call()) if effects[effect].is_valid() else false
	var expression: String = String(effect)
	if expression.begins_with("flag:"):
		var event_id: StringName = StringName(expression.substr(5))
		return state.has_event(event_id) or state.record_event(event_id)
	if expression.begins_with("clue:"):
		var clue: StringName = StringName(expression.substr(5))
		return clue in state.get_unlocked_clues() or state.unlock_clue(clue)
	if expression.begins_with("read_clue:"):
		var clue: StringName = StringName(expression.substr(10))
		return clue in state.get_read_clues() or state.mark_clue_read(clue)
	if expression.begins_with("read_mural_panel:"):
		var panel_text: String = expression.substr(17)
		if not panel_text.is_valid_int():
			return false
		var panel: int = panel_text.to_int()
		if panel < 1 or panel > 6:
			return false
		if panel not in state.get_read_mural_panels() and not state.read_mural_panel(panel):
			return false
		if &"clue_mural_origens" in state.get_unlocked_clues():
			state.mark_clue_read(&"clue_mural_origens")
		return true
	if expression.begins_with("phase:"):
		var phase: StringName = StringName(expression.substr(6))
		return state.phase == phase or state.advance_to(phase)
	if expression.begins_with("claim_"):
		var id: StringName = StringName(expression.substr(6))
		if state.is_quest_item_claimed(id):
			return true
		var path: String = "res://core/inventory/items/stage_01/%s.tres" % id
		if not ResourceLoader.exists(path, "Resource"):
			return false
		return state.grant_quest_item(load(path) as ItemData, inventory)
	match effect:
		&"mark_empathy": return state.saci_empatico or state.mark_empathy()
		&"paint_gorro", &"paint_bambu", &"paint_redemoinho":
			var symbol: StringName = StringName(expression.substr(6))
			return state.muro_simbolo_escolhido == symbol or state.paint_mural(symbol)
	return false
