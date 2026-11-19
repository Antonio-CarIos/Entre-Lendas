class_name ItemData
extends Resource
## Dados estáticos compartilhados entre o mapa e o inventário.

enum ItemCategory { USABLE, KEY_ARTIFACT, JOURNAL_CLUE, CRAFTING_MATERIAL }

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export_multiline var insight_text: String = ""
@export var category: ItemCategory = ItemCategory.USABLE
@export var icon: Texture2D
@export var consumable: bool = false
@export_multiline var lore_text: String = ""
@export var related_stage: int = 1


func get_inventory_actions() -> Array[StringName]:
	var actions: Array[StringName] = [&"examine"]
	if category == ItemCategory.JOURNAL_CLUE:
		actions.append(&"read")
	elif category == ItemCategory.CRAFTING_MATERIAL:
		actions.append(&"combine")
	return actions


func get_category_name() -> String:
	match category:
		ItemCategory.KEY_ARTIFACT:
			return "Artefato"
		ItemCategory.JOURNAL_CLUE:
			return "Leitura"
		ItemCategory.CRAFTING_MATERIAL:
			return "Material"
		_:
			return "Objeto"
