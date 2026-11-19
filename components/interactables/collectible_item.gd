class_name CollectibleItem
extends Area2D
## A confirmação é responsabilidade do HUD; esta área apenas efetua a coleta.

@export var item_data: ItemData
@export var persistent_id: StringName = &""

var collected: bool = false

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	if persistent_id != &"" and WorldState.is_pickup_collected(persistent_id):
		collected = true
		hide()
		set_deferred(&"monitorable", false)
		queue_free()
		return
	if item_data != null:
		sprite.texture = item_data.icon


func collect(inventory: InventorySystem) -> bool:
	if collected or is_queued_for_deletion() or inventory == null:
		return false
	if not inventory.add_item(item_data):
		return false
	collected = true
	WorldState.mark_pickup_collected(persistent_id)
	hide()
	set_deferred(&"monitorable", false)
	queue_free()
	return true
