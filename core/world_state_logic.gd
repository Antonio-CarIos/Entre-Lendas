class_name WorldStateLogic
extends RefCounted
## Registro moral independente da árvore de cenas.
## Cada entidade contribui -1 por captura ou +1 por amizade.

signal entity_outcome_changed(entity_id: StringName, outcome: Outcome)
signal nature_balance_changed(new_balance: int)
signal world_state_changed()

enum Outcome { UNDECIDED, CAPTURE, FRIENDSHIP }

var nature_balance: int:
	get:
		return _nature_balance

var _nature_balance: int = 0
var _entity_outcomes: Dictionary[StringName, Outcome] = {}


## Retorna false para entradas inválidas ou decisões que já estavam registradas.
func register_entity_outcome(entity_id: StringName, outcome: Outcome) -> bool:
	if entity_id == &"" or outcome not in [Outcome.CAPTURE, Outcome.FRIENDSHIP]:
		return false

	var previous: Outcome = get_entity_outcome(entity_id)
	if previous == outcome:
		return false

	_entity_outcomes[entity_id] = outcome
	_nature_balance += _outcome_weight(outcome) - _outcome_weight(previous)
	entity_outcome_changed.emit(entity_id, outcome)
	nature_balance_changed.emit(_nature_balance)
	world_state_changed.emit()
	return true


func get_entity_outcome(entity_id: StringName) -> Outcome:
	return _entity_outcomes.get(entity_id, Outcome.UNDECIDED)


## Uma cópia impede alterações externas que deixariam o equilíbrio inconsistente.
func get_entity_outcomes() -> Dictionary[StringName, Outcome]:
	return _entity_outcomes.duplicate()


func reset() -> void:
	if _entity_outcomes.is_empty():
		return

	var previous_balance: int = _nature_balance
	_entity_outcomes.clear()
	_nature_balance = 0
	if previous_balance != 0:
		nature_balance_changed.emit(_nature_balance)
	world_state_changed.emit()


func _outcome_weight(outcome: Outcome) -> int:
	match outcome:
		Outcome.CAPTURE:
			return -1
		Outcome.FRIENDSHIP:
			return 1
		_:
			return 0
