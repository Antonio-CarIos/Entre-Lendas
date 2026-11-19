extends Node
## Fachada global do registro moral. A lógica pura permanece testável em isolamento.

signal entity_outcome_changed(entity_id: StringName, outcome: WorldStateLogic.Outcome)
signal nature_balance_changed(new_balance: int)
signal world_state_changed()

const Outcome: Dictionary = WorldStateLogic.Outcome

var inventory: InventorySystem = InventorySystem.new()
var stage01: Stage01State = Stage01State.new()
var journal: JournalSystem = JournalSystem.new(stage01)
var scene_transition: SceneTransition

var nature_balance: int:
	get:
		return _state.nature_balance

var _state: WorldStateLogic = WorldStateLogic.new()
var _collected_pickups: Dictionary[StringName, bool] = {}


func _ready() -> void:
	scene_transition = SceneTransition.new()
	scene_transition.name = "SceneTransition"
	add_child(scene_transition)
	_state.entity_outcome_changed.connect(_on_entity_outcome_changed)
	_state.nature_balance_changed.connect(_on_nature_balance_changed)
	_state.world_state_changed.connect(_on_world_state_changed)
	stage01.changed.connect(_on_world_state_changed)
	stage01.ending_resolved.connect(_on_stage01_ending_resolved)


func register_entity_outcome(entity_id: StringName, outcome: WorldStateLogic.Outcome) -> bool:
	return _state.register_entity_outcome(entity_id, outcome)


func get_entity_outcome(entity_id: StringName) -> WorldStateLogic.Outcome:
	return _state.get_entity_outcome(entity_id)


func get_entity_outcomes() -> Dictionary[StringName, WorldStateLogic.Outcome]:
	return _state.get_entity_outcomes()


func reset() -> void:
	_state.reset()
	inventory.clear()
	_collected_pickups.clear()
	stage01.reset()


func start_new_game() -> void:
	reset()
	stage01.begin()


func is_pickup_collected(pickup_id: StringName) -> bool:
	return _collected_pickups.has(pickup_id)


func mark_pickup_collected(pickup_id: StringName) -> void:
	if pickup_id != &"":
		_collected_pickups[pickup_id] = true


func _on_entity_outcome_changed(entity_id: StringName, outcome: WorldStateLogic.Outcome) -> void:
	entity_outcome_changed.emit(entity_id, outcome)
	EventBus.entity_outcome_changed.emit(entity_id, outcome)


func _on_stage01_ending_resolved(outcome: WorldStateLogic.Outcome) -> void:
	register_entity_outcome(&"saci", outcome)


func _on_nature_balance_changed(new_balance: int) -> void:
	nature_balance_changed.emit(new_balance)
	EventBus.nature_balance_changed.emit(new_balance)


func _on_world_state_changed() -> void:
	world_state_changed.emit()
	EventBus.world_state_changed.emit()
