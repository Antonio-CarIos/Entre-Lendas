class_name InventorySystem
extends RefCounted
## Inventário independente da árvore de cenas; cada ID ocupa um único slot.

signal item_added(item: ItemData, quantity: int)
signal item_removed(item_id: StringName)
signal inventory_changed()

const CROSS_SIEVE: ItemData = preload("res://core/inventory/items/stage_01/peneira_cruz.tres")

var _items: Dictionary[StringName, ItemData] = {}
var _quantities: Dictionary[StringName, int] = {}


func add_item(item: ItemData, quantity: int = 1) -> bool:
	if item == null or item.id == &"" or quantity <= 0:
		return false
	if not _items.has(item.id):
		_items[item.id] = item
	_quantities[item.id] = get_quantity(item.id) + quantity
	item_added.emit(_items[item.id], _quantities[item.id])
	inventory_changed.emit()
	return true


func remove_item(item_id: StringName, quantity: int = 1) -> bool:
	if quantity <= 0 or get_quantity(item_id) < quantity:
		return false
	_quantities[item_id] -= quantity
	if _quantities[item_id] == 0:
		_quantities.erase(item_id)
		_items.erase(item_id)
	item_removed.emit(item_id)
	inventory_changed.emit()
	return true


func has_item(item_id: StringName) -> bool:
	return get_quantity(item_id) > 0


func get_quantity(item_id: StringName) -> int:
	return _quantities.get(item_id, 0)


func get_items() -> Array[ItemData]:
	var items: Array[ItemData] = []
	for item: ItemData in _items.values():
		items.append(item)
	return items


func get_items_by_category(category: ItemData.ItemCategory) -> Array[ItemData]:
	var items: Array[ItemData] = []
	for item: ItemData in _items.values():
		if item.category == category:
			items.append(item)
	return items


func can_combine(item_a_id: StringName, item_b_id: StringName) -> bool:
	var recipe: bool = (
		(item_a_id == &"fita_vermelha" and item_b_id == &"peneira")
		or (item_a_id == &"peneira" and item_b_id == &"fita_vermelha")
	)
	return recipe and has_item(item_a_id) and has_item(item_b_id)


func combine_items(item_a_id: StringName, item_b_id: StringName) -> bool:
	if not can_combine(item_a_id, item_b_id):
		return false
	# Complete a transação antes dos sinais para nunca publicar um inventário parcial.
	for item_id: StringName in [item_a_id, item_b_id]:
		_quantities[item_id] -= 1
		if _quantities[item_id] == 0:
			_quantities.erase(item_id)
			_items.erase(item_id)
	_items[CROSS_SIEVE.id] = CROSS_SIEVE
	_quantities[CROSS_SIEVE.id] = get_quantity(CROSS_SIEVE.id) + 1
	item_removed.emit(item_a_id)
	item_removed.emit(item_b_id)
	item_added.emit(CROSS_SIEVE, get_quantity(CROSS_SIEVE.id))
	inventory_changed.emit()
	return true


func clear() -> void:
	if _items.is_empty():
		return
	var ids: Array[StringName] = []
	ids.assign(_items.keys())
	_items.clear()
	_quantities.clear()
	for item_id: StringName in ids:
		item_removed.emit(item_id)
	inventory_changed.emit()
