extends GutTest
## Testes da lógica pura e da publicação pelos autoloads reais.

var _state: WorldStateLogic


func before_each() -> void:
	_state = WorldStateLogic.new()
	WorldState.reset()
	watch_signals(_state)
	watch_signals(WorldState)
	watch_signals(EventBus)


func after_each() -> void:
	WorldState.reset()
	_state = null


func test_initial_state_is_neutral_and_undecided() -> void:
	assert_eq(_state.nature_balance, 0)
	assert_true(_state.get_entity_outcomes().is_empty())
	assert_eq(_state.get_entity_outcome(&"saci"), WorldStateLogic.Outcome.UNDECIDED)


func test_friendship_restores_nature_and_records_decision() -> void:
	assert_true(_state.register_entity_outcome(&"saci", WorldStateLogic.Outcome.FRIENDSHIP))
	assert_eq(_state.nature_balance, 1)
	assert_eq(_state.get_entity_outcome(&"saci"), WorldStateLogic.Outcome.FRIENDSHIP)


func test_capture_degrades_nature_and_records_decision() -> void:
	assert_true(_state.register_entity_outcome(&"mula", WorldStateLogic.Outcome.CAPTURE))
	assert_eq(_state.nature_balance, -1)
	assert_eq(_state.get_entity_outcome(&"mula"), WorldStateLogic.Outcome.CAPTURE)


func test_mixed_decisions_accumulate_independently() -> void:
	_state.register_entity_outcome(&"saci", WorldStateLogic.Outcome.FRIENDSHIP)
	_state.register_entity_outcome(&"mula", WorldStateLogic.Outcome.CAPTURE)
	_state.register_entity_outcome(&"caipora", WorldStateLogic.Outcome.FRIENDSHIP)
	assert_eq(_state.nature_balance, 1)
	assert_eq(_state.get_entity_outcomes().size(), 3)
	assert_eq(_state.get_entity_outcome(&"saci"), WorldStateLogic.Outcome.FRIENDSHIP)
	assert_eq(_state.get_entity_outcome(&"mula"), WorldStateLogic.Outcome.CAPTURE)


func test_repeating_decision_does_not_accumulate_or_emit_again() -> void:
	_state.register_entity_outcome(&"saci", WorldStateLogic.Outcome.FRIENDSHIP)
	assert_false(_state.register_entity_outcome(&"saci", WorldStateLogic.Outcome.FRIENDSHIP))
	assert_eq(_state.nature_balance, 1)
	assert_signal_emit_count(_state, &"entity_outcome_changed", 1)
	assert_signal_emit_count(_state, &"nature_balance_changed", 1)
	assert_signal_emit_count(_state, &"world_state_changed", 1)


func test_replacing_capture_with_friendship_removes_previous_weight() -> void:
	_state.register_entity_outcome(&"saci", WorldStateLogic.Outcome.CAPTURE)
	assert_true(_state.register_entity_outcome(&"saci", WorldStateLogic.Outcome.FRIENDSHIP))
	assert_eq(_state.nature_balance, 1)
	assert_eq(_state.get_entity_outcomes().size(), 1)
	assert_eq(_state.get_entity_outcome(&"saci"), WorldStateLogic.Outcome.FRIENDSHIP)
	assert_signal_emitted_with_parameters(_state, &"nature_balance_changed", [1])


func test_replacing_friendship_with_capture_preserves_other_decisions() -> void:
	_state.register_entity_outcome(&"saci", WorldStateLogic.Outcome.FRIENDSHIP)
	_state.register_entity_outcome(&"mula", WorldStateLogic.Outcome.FRIENDSHIP)
	_state.register_entity_outcome(&"saci", WorldStateLogic.Outcome.CAPTURE)
	assert_eq(_state.nature_balance, 0)
	assert_eq(_state.get_entity_outcome(&"saci"), WorldStateLogic.Outcome.CAPTURE)
	assert_eq(_state.get_entity_outcome(&"mula"), WorldStateLogic.Outcome.FRIENDSHIP)


func test_outcome_change_emits_signals_with_current_values() -> void:
	_state.register_entity_outcome(&"saci", WorldStateLogic.Outcome.CAPTURE)
	assert_signal_emitted_with_parameters(
		_state, &"entity_outcome_changed", [&"saci", WorldStateLogic.Outcome.CAPTURE]
	)
	assert_signal_emitted_with_parameters(_state, &"nature_balance_changed", [-1])
	assert_signal_emit_count(_state, &"world_state_changed", 1)


func test_empty_entity_id_is_rejected_without_changes() -> void:
	assert_false(_state.register_entity_outcome(&"", WorldStateLogic.Outcome.CAPTURE))
	_assert_unchanged_neutral_state()


func test_undecided_is_not_a_registerable_outcome() -> void:
	assert_false(_state.register_entity_outcome(&"saci", WorldStateLogic.Outcome.UNDECIDED))
	_assert_unchanged_neutral_state()


func test_unknown_outcome_is_rejected_without_changes() -> void:
	var invalid_outcome: WorldStateLogic.Outcome = 99 as WorldStateLogic.Outcome
	assert_false(_state.register_entity_outcome(&"saci", invalid_outcome))
	_assert_unchanged_neutral_state()


func test_returned_decisions_cannot_mutate_internal_state() -> void:
	_state.register_entity_outcome(&"saci", WorldStateLogic.Outcome.FRIENDSHIP)
	var snapshot: Dictionary[StringName, WorldStateLogic.Outcome] = _state.get_entity_outcomes()
	snapshot[&"saci"] = WorldStateLogic.Outcome.CAPTURE
	snapshot[&"cuca"] = WorldStateLogic.Outcome.CAPTURE
	assert_eq(_state.get_entity_outcome(&"saci"), WorldStateLogic.Outcome.FRIENDSHIP)
	assert_eq(_state.get_entity_outcome(&"cuca"), WorldStateLogic.Outcome.UNDECIDED)
	assert_eq(_state.nature_balance, 1)


func test_pure_instances_do_not_share_state() -> void:
	var other_state: WorldStateLogic = WorldStateLogic.new()
	_state.register_entity_outcome(&"saci", WorldStateLogic.Outcome.CAPTURE)
	assert_eq(other_state.nature_balance, 0)
	assert_true(other_state.get_entity_outcomes().is_empty())
	assert_eq(WorldState.nature_balance, 0)
	assert_signal_not_emitted(EventBus, &"world_state_changed")


func test_reset_clears_decisions_and_notifies_balance_change() -> void:
	_state.register_entity_outcome(&"saci", WorldStateLogic.Outcome.FRIENDSHIP)
	_state.reset()
	assert_eq(_state.nature_balance, 0)
	assert_true(_state.get_entity_outcomes().is_empty())
	assert_eq(_state.get_entity_outcome(&"saci"), WorldStateLogic.Outcome.UNDECIDED)
	assert_signal_emitted_with_parameters(_state, &"nature_balance_changed", [0])
	assert_signal_emit_count(_state, &"world_state_changed", 2)


func test_reset_clears_balanced_history_without_redundant_balance_signal() -> void:
	_state.register_entity_outcome(&"saci", WorldStateLogic.Outcome.FRIENDSHIP)
	_state.register_entity_outcome(&"mula", WorldStateLogic.Outcome.CAPTURE)
	_state.reset()
	assert_true(_state.get_entity_outcomes().is_empty())
	assert_eq(_state.nature_balance, 0)
	assert_signal_emit_count(_state, &"nature_balance_changed", 2)
	assert_signal_emit_count(_state, &"world_state_changed", 3)


func test_reset_on_empty_state_emits_nothing() -> void:
	_state.reset()
	_assert_unchanged_neutral_state()


func test_autoload_records_decision_and_publishes_local_and_global_signals() -> void:
	assert_true(WorldState.register_entity_outcome(&"saci", WorldState.Outcome.FRIENDSHIP))
	assert_eq(WorldState.nature_balance, 1)
	assert_eq(WorldState.get_entity_outcome(&"saci"), WorldStateLogic.Outcome.FRIENDSHIP)
	assert_eq(WorldState.get_entity_outcomes().size(), 1)
	assert_signal_emitted_with_parameters(
		WorldState, &"entity_outcome_changed", [&"saci", WorldStateLogic.Outcome.FRIENDSHIP]
	)
	assert_signal_emitted_with_parameters(WorldState, &"nature_balance_changed", [1])
	assert_signal_emit_count(WorldState, &"world_state_changed", 1)
	assert_signal_emitted_with_parameters(
		EventBus, &"entity_outcome_changed", [&"saci", WorldStateLogic.Outcome.FRIENDSHIP]
	)
	assert_signal_emitted_with_parameters(EventBus, &"nature_balance_changed", [1])
	assert_signal_emit_count(EventBus, &"world_state_changed", 1)


func test_autoload_repeated_decision_does_not_republish() -> void:
	WorldState.register_entity_outcome(&"mula", WorldState.Outcome.CAPTURE)
	assert_false(WorldState.register_entity_outcome(&"mula", WorldState.Outcome.CAPTURE))
	assert_eq(WorldState.nature_balance, -1)
	assert_signal_emit_count(EventBus, &"entity_outcome_changed", 1)
	assert_signal_emit_count(EventBus, &"nature_balance_changed", 1)
	assert_signal_emit_count(EventBus, &"world_state_changed", 1)


func test_autoload_reset_publishes_neutral_state() -> void:
	WorldState.register_entity_outcome(&"cuca", WorldState.Outcome.CAPTURE)
	WorldState.reset()
	assert_eq(WorldState.nature_balance, 0)
	assert_eq(WorldState.get_entity_outcome(&"cuca"), WorldStateLogic.Outcome.UNDECIDED)
	assert_true(WorldState.get_entity_outcomes().is_empty())
	assert_signal_emitted_with_parameters(EventBus, &"nature_balance_changed", [0])
	assert_signal_emit_count(EventBus, &"world_state_changed", 2)


func _assert_unchanged_neutral_state() -> void:
	assert_eq(_state.nature_balance, 0)
	assert_true(_state.get_entity_outcomes().is_empty())
	assert_signal_not_emitted(_state, &"entity_outcome_changed")
	assert_signal_not_emitted(_state, &"nature_balance_changed")
	assert_signal_not_emitted(_state, &"world_state_changed")
