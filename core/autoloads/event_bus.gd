extends Node
## Sinais globais para desacoplar mundo, diálogos e interface.
## WorldState publica aqui somente depois de atualizar seu estado.

signal entity_outcome_changed(entity_id: StringName, outcome: int)
signal nature_balance_changed(new_balance: int)
signal world_state_changed()
