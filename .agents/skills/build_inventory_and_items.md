# Skill: Sistema de Inventário e Diário Data-Driven (`Resource`)

Use este padrão para implementar os Itens Especiais (Gorro do Saci, Espelho da Cuca, etc.) e os Itens de Consulta (Diários, Pistas da Mula sem Cabeça).

## 1. Classe Base de Item (`res://core/inventory/item_data.gd`)
```gdscript
class_name ItemData
extends Resource

enum ItemCategory {
	USABLE,      # Itens consumíveis ou ferramentas (Pegada Falsa, Peneira)
	KEY_ARTIFACT,# Artefatos de lendas (Gorro do Saci, Espelho da Cuca, Brasa)
	JOURNAL_CLUE # Diários, cartas e pistas para consulta e dedução
}

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var category: ItemCategory = ItemCategory.USABLE
@export var icon: Texture2D
@export var consumable: bool = false

## Preenchido apenas se category == JOURNAL_CLUE
@export_multiline var lore_text: String = ""
@export var related_stage: int = 1
```

## 2. Lógica Pura do Inventário (`res://core/inventory/inventory_system.gd`)
Herda de `RefCounted` para poder ser testado via CLI sem instanciar cenas:
```gdscript
class_name InventorySystem
extends RefCounted

signal item_added(item: ItemData, quantity: int)
signal item_removed(item_id: StringName)

var _slots: Dictionary = {} # { StringName: { "data": ItemData, "qty": int } }

func add_item(item: ItemData, quantity: int = 1) -> void:
	if _slots.has(item.id):
		_slots[item.id]["qty"] += quantity
	else:
		_slots[item.id] = { "data": item, "qty": quantity }
	item_added.emit(item, _slots[item.id]["qty"])

func has_item(item_id: StringName) -> bool:
	return _slots.has(item_id) and _slots[item.id]["qty"] > 0

func get_items_by_category(cat: ItemData.ItemCategory) -> Array[ItemData]:
	var result: Array[ItemData] = []
	for entry in _slots.values():
		var data: ItemData = entry["data"]
		if data.category == cat:
			result.append(data)
	return result
```