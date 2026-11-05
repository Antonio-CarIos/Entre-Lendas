# Skill: Testes Unitários Headless via GUT

Sempre que criar classes de lógica pura (`InventorySystem`, `WorldState`, `CombatCalculator`, `DialogueConditionChecker`), escreva testes automatizados em `res://tests/`.

## 1. Estrutura de um Teste GUT
```gdscript
extends GutTest

func test_nature_balance_shifts_on_choice() -> void:
	var state := WorldStateLogic.new()
	assert_eq(state.nature_balance, 0, "Equilíbrio inicial deve ser neutro (0)")
	
	state.register_entity_outcome(&"saci", WorldStateLogic.Outcome.FRIENDSHIP)
	assert_gt(state.nature_balance, 0, "Amizade deve aumentar o equilíbrio da natureza")
	
	state.register_entity_outcome(&"mula", WorldStateLogic.Outcome.CAPTURE)
	assert_eq(state.get_entity_outcome(&"mula"), WorldStateLogic.Outcome.CAPTURE)
```

## 2. Comando de Execução via CLI
```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```