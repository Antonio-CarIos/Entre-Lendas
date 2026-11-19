extends GutTest
## Lógica pura e fluxo real de input/coleta/HUD no laboratório separado do roteiro, sem pré-popular o inventário.

const HOUSE: PackedScene = preload("res://tests/fixtures/inventory_mechanics_lab.tscn")
const BOTTLE: ItemData = preload("res://core/inventory/items/stage_01/garrafa_vazia.tres")
const PIPE: ItemData = preload("res://core/inventory/items/stage_01/cachimbo_fumo.tres")
const ITEM_IDS: Array[StringName] = [
	&"cachimbo_fumo", &"fita_vermelha", &"garrafa_vazia", &"gorro_saci",
	&"pagina_diario", &"pagina_livro", &"peneira", &"peneira_cruz"
]

var _inventory: InventorySystem


func before_each() -> void:
	WorldState.reset()
	_inventory = InventorySystem.new()
	watch_signals(_inventory)
	_release_actions()


func after_each() -> void:
	_release_actions()
	WorldState.reset()


func test_initial_inventory_is_empty_and_instances_are_independent() -> void:
	assert_true(_inventory.get_items().is_empty())
	assert_false(_inventory.has_item(BOTTLE.id))
	assert_eq(_inventory.get_quantity(BOTTLE.id), 0)
	assert_true(WorldState.inventory.get_items().is_empty())
	_inventory.add_item(BOTTLE)
	assert_true(WorldState.inventory.get_items().is_empty())


func test_addition_stacks_and_emits_current_quantity() -> void:
	assert_true(_inventory.add_item(BOTTLE))
	assert_true(_inventory.add_item(BOTTLE, 2))
	assert_eq(_inventory.get_quantity(BOTTLE.id), 3)
	assert_eq(_inventory.get_items().size(), 1)
	assert_signal_emitted_with_parameters(_inventory, &"item_added", [BOTTLE, 3])
	assert_signal_emit_count(_inventory, &"inventory_changed", 2)


func test_invalid_additions_do_not_mutate_or_emit() -> void:
	assert_false(_inventory.add_item(null))
	assert_false(_inventory.add_item(ItemData.new()))
	assert_false(_inventory.add_item(BOTTLE, 0))
	assert_false(_inventory.add_item(BOTTLE, -1))
	assert_true(_inventory.get_items().is_empty())
	assert_signal_not_emitted(_inventory, &"inventory_changed")


func test_partial_and_final_removal_keep_quantities_consistent() -> void:
	_inventory.add_item(BOTTLE, 3)
	assert_true(_inventory.remove_item(BOTTLE.id, 2))
	assert_eq(_inventory.get_quantity(BOTTLE.id), 1)
	assert_true(_inventory.has_item(BOTTLE.id))
	assert_true(_inventory.remove_item(BOTTLE.id))
	assert_false(_inventory.has_item(BOTTLE.id))
	assert_true(_inventory.get_items().is_empty())
	assert_signal_emit_count(_inventory, &"item_removed", 2)


func test_invalid_removal_keeps_inventory_unchanged() -> void:
	_inventory.add_item(BOTTLE)
	assert_false(_inventory.remove_item(BOTTLE.id, 2))
	assert_false(_inventory.remove_item(BOTTLE.id, 0))
	assert_false(_inventory.remove_item(BOTTLE.id, -1))
	assert_false(_inventory.remove_item(&"unknown"))
	assert_eq(_inventory.get_quantity(BOTTLE.id), 1)
	assert_signal_not_emitted(_inventory, &"item_removed")


func test_category_queries_and_array_copies() -> void:
	var page: ItemData = load("res://core/inventory/items/stage_01/pagina_diario.tres")
	_inventory.add_item(BOTTLE)
	_inventory.add_item(page)
	var clues: Array[ItemData] = _inventory.get_items_by_category(ItemData.ItemCategory.JOURNAL_CLUE)
	assert_eq(clues.size(), 1)
	assert_eq(clues[0], page)
	clues.clear()
	var items: Array[ItemData] = _inventory.get_items()
	items.clear()
	assert_eq(_inventory.get_items().size(), 2)


func test_clear_and_world_reset_empty_the_existing_instance() -> void:
	_inventory.add_item(BOTTLE)
	_inventory.clear()
	assert_true(_inventory.get_items().is_empty())
	assert_signal_emitted_with_parameters(_inventory, &"item_removed", [BOTTLE.id])
	var shared: InventorySystem = WorldState.inventory
	shared.add_item(PIPE)
	WorldState.reset()
	assert_eq(WorldState.inventory, shared)
	assert_true(shared.get_items().is_empty())


func test_every_phase_one_png_has_matching_resource_and_clean_icon() -> void:
	var png_count: int = 0
	for file_name: String in DirAccess.get_files_at("res://assets/art/items/stage_01"):
		if file_name.ends_with(".png"):
			png_count += 1
	assert_eq(png_count, ITEM_IDS.size())
	for item_id: StringName in ITEM_IDS:
		var item: ItemData = load("res://core/inventory/items/stage_01/%s.tres" % item_id)
		assert_not_null(item)
		assert_eq(item.id, item_id)
		assert_false(item.display_name.is_empty())
		assert_false(item.description.is_empty())
		assert_eq(item.icon.resource_path, "res://assets/art/items/stage_01/%s.png" % item_id)
		assert_eq(item.icon.get_size(), Vector2(32.0, 32.0))


func test_input_map_includes_e_and_tab() -> void:
	assert_true(_has_key(&"interact", KEY_E))
	assert_true(_has_key(&"open_inventory", KEY_TAB))


func test_house_starts_with_empty_slots_and_four_shining_collectibles() -> void:
	var house: Node2D = _add_house()
	var hud: GameplayHUD = house.get_node("GameplayHUD") as GameplayHUD
	assert_eq(hud.mode, GameplayHUD.ModalMode.NONE)
	assert_true(WorldState.inventory.get_items().is_empty())
	var slots: GridContainer = hud.get_node("Screen/Inventory/SlotScroll/Slots")
	assert_eq(slots.get_child_count(), 9)
	for slot: Node in slots.get_children():
		var icon: TextureRect = slot.get_node("Icon") as TextureRect
		assert_null(icon.texture)
		assert_null(icon.material)
	for node_name: String in ["BottleCollectible", "PipeCollectible", "RibbonCollectible", "SieveCollectible"]:
		var item: CollectibleItem = house.get_node("YSortRoot/" + node_name) as CollectibleItem
		assert_eq(item.collision_layer, 4)
		assert_eq(item.collision_mask, 0)
		assert_eq(item.sprite.texture, item.item_data.icon)
		assert_is(item.sprite.material, ShaderMaterial)


func test_e_opens_confirmation_without_collecting_and_no_keeps_item() -> void:
	var house: Node2D = _add_house()
	var hud: GameplayHUD = house.get_node("GameplayHUD") as GameplayHUD
	var player: Player = house.get_node("YSortRoot/Player") as Player
	await wait_physics_frames(3)
	await _tap_key(KEY_E)
	assert_eq(hud.mode, GameplayHUD.ModalMode.CONFIRM)
	assert_false(player.movement_enabled)
	var text: Label = hud.get_node("Screen/Dialogue/Text") as Label
	assert_eq(text.text, "Deseja pegar Garrafa Vazia?")
	assert_true(WorldState.inventory.get_items().is_empty())
	var no_button: Button = hud.get_node("Screen/Dialogue/No") as Button
	no_button.pressed.emit()
	assert_eq(hud.mode, GameplayHUD.ModalMode.NONE)
	assert_true(player.movement_enabled)
	assert_true(house.has_node("YSortRoot/BottleCollectible"))
	assert_true(WorldState.inventory.get_items().is_empty())


func test_yes_collects_once_removes_from_map_and_updates_clean_ui() -> void:
	var house: Node2D = _add_house()
	var hud: GameplayHUD = house.get_node("GameplayHUD") as GameplayHUD
	var player: Player = house.get_node("YSortRoot/Player") as Player
	await wait_physics_frames(3)
	await _tap_key(KEY_E)
	var yes_button: Button = hud.get_node("Screen/Dialogue/Yes") as Button
	yes_button.pressed.emit()
	yes_button.pressed.emit()
	await wait_process_frames(2)
	assert_eq(WorldState.inventory.get_quantity(BOTTLE.id), 1)
	assert_false(house.has_node("YSortRoot/BottleCollectible"))
	assert_eq(hud.mode, GameplayHUD.ModalMode.NOTICE)
	assert_false(player.movement_enabled)
	var text: Label = hud.get_node("Screen/Dialogue/Text") as Label
	assert_eq(text.text,
		"Você coletou Garrafa Vazia! Pressione TAB para abrir o inventário.")
	await _tap_key(KEY_TAB)
	assert_eq(hud.mode, GameplayHUD.ModalMode.INVENTORY)
	var icon: TextureRect = hud.get_node("Screen/Inventory/SlotScroll/Slots/Slot00/Icon")
	assert_eq(icon.texture, BOTTLE.icon)
	assert_null(icon.material)
	assert_false(player.movement_enabled)
	await _tap_key(KEY_TAB)
	assert_eq(hud.mode, GameplayHUD.ModalMode.NONE)
	assert_true(player.movement_enabled)


func test_keyboard_can_select_no_then_confirm_with_e() -> void:
	var house: Node2D = _add_house()
	var hud: GameplayHUD = house.get_node("GameplayHUD") as GameplayHUD
	await wait_physics_frames(3)
	await _tap_key(KEY_E)
	await _tap_key(KEY_RIGHT)
	var no_button: Button = hud.get_node("Screen/Dialogue/No") as Button
	assert_true(no_button.has_focus())
	await _tap_key(KEY_E)
	assert_eq(hud.mode, GameplayHUD.ModalMode.NONE)
	assert_true(WorldState.inventory.get_items().is_empty())
	assert_true(house.has_node("YSortRoot/BottleCollectible"))


func test_tab_pauses_movement_and_escape_closes_empty_inventory() -> void:
	var house: Node2D = _add_house()
	var hud: GameplayHUD = house.get_node("GameplayHUD") as GameplayHUD
	var player: Player = house.get_node("YSortRoot/Player") as Player
	Input.action_press(&"move_right")
	await wait_physics_frames(3)
	await _tap_key(KEY_TAB)
	var paused_at: Vector2 = player.position
	await wait_physics_frames(5)
	assert_eq(player.position, paused_at)
	assert_eq(player.velocity, Vector2.ZERO)
	assert_eq(hud.mode, GameplayHUD.ModalMode.INVENTORY)
	Input.action_release(&"move_right")
	await _tap_key(KEY_ESCAPE)
	assert_eq(hud.mode, GameplayHUD.ModalMode.NONE)
	assert_true(player.movement_enabled)


func test_slots_refresh_for_addition_stacking_and_removal() -> void:
	var house: Node2D = _add_house()
	var hud: GameplayHUD = house.get_node("GameplayHUD") as GameplayHUD
	var icon: TextureRect = hud.get_node("Screen/Inventory/SlotScroll/Slots/Slot00/Icon")
	var quantity: Label = hud.get_node("Screen/Inventory/SlotScroll/Slots/Slot00/Quantity")
	WorldState.inventory.add_item(PIPE, 2)
	assert_eq(icon.texture, PIPE.icon)
	assert_eq(quantity.text, "2")
	WorldState.inventory.remove_item(PIPE.id, 2)
	assert_null(icon.texture)
	assert_eq(quantity.text, "")


func test_collectible_cannot_be_collected_twice_before_queue_free() -> void:
	var house: Node2D = _add_house()
	var item: CollectibleItem = house.get_node("YSortRoot/BottleCollectible") as CollectibleItem
	assert_true(item.collect(WorldState.inventory))
	assert_false(item.collect(WorldState.inventory))
	assert_eq(WorldState.inventory.get_quantity(BOTTLE.id), 1)
	await wait_process_frames(2)
	assert_false(is_instance_valid(item))


func test_item_freed_during_confirmation_does_not_add_or_error() -> void:
	var house: Node2D = _add_house()
	var hud: GameplayHUD = house.get_node("GameplayHUD") as GameplayHUD
	await wait_physics_frames(3)
	await _tap_key(KEY_E)
	house.get_node("YSortRoot/BottleCollectible").queue_free()
	await wait_process_frames(2)
	var button: Button = hud.get_node("Screen/Dialogue/Yes") as Button
	button.pressed.emit()
	assert_eq(hud.mode, GameplayHUD.ModalMode.NONE)
	assert_true(WorldState.inventory.get_items().is_empty())


func test_categories_define_examine_read_and_combine_actions() -> void:
	for item_id: StringName in ITEM_IDS:
		var item: ItemData = load("res://core/inventory/items/stage_01/%s.tres" % item_id)
		var actions: Array[StringName] = item.get_inventory_actions()
		assert_eq(actions[0], &"examine")
		assert_false(item.insight_text.is_empty())
		if item_id in [&"pagina_diario", &"pagina_livro"]:
			assert_eq(actions.size(), 2)
			assert_eq(actions[1], &"read")
			assert_false(item.lore_text.is_empty())
		elif item_id in [&"fita_vermelha", &"peneira"]:
			assert_eq(actions.size(), 2)
			assert_eq(actions[1], &"combine")
		else:
			assert_eq(actions.size(), 1)


func test_combination_requires_both_materials_and_valid_recipe() -> void:
	var ribbon: ItemData = load("res://core/inventory/items/stage_01/fita_vermelha.tres")
	_inventory.add_item(ribbon)
	assert_false(_inventory.can_combine(&"fita_vermelha", &"peneira"))
	assert_false(_inventory.combine_items(&"fita_vermelha", &"peneira"))
	assert_false(_inventory.combine_items(&"fita_vermelha", &"fita_vermelha"))
	assert_eq(_inventory.get_quantity(ribbon.id), 1)
	_inventory.add_item(BOTTLE)
	assert_false(_inventory.combine_items(BOTTLE.id, ribbon.id))
	assert_signal_emit_count(_inventory, &"inventory_changed", 2)


func test_combination_consumes_materials_atomically_and_accepts_reverse_order() -> void:
	var ribbon: ItemData = load("res://core/inventory/items/stage_01/fita_vermelha.tres")
	var sieve: ItemData = load("res://core/inventory/items/stage_01/peneira.tres")
	_inventory.add_item(ribbon)
	_inventory.add_item(sieve)
	assert_true(_inventory.combine_items(sieve.id, ribbon.id))
	assert_false(_inventory.has_item(ribbon.id))
	assert_false(_inventory.has_item(sieve.id))
	assert_eq(_inventory.get_quantity(&"peneira_cruz"), 1)
	assert_eq(_inventory.get_items().size(), 1)
	assert_signal_emit_count(_inventory, &"inventory_changed", 3)
	assert_signal_emit_count(_inventory, &"item_removed", 2)
	assert_false(_inventory.combine_items(sieve.id, ribbon.id))
	assert_eq(_inventory.get_quantity(&"peneira_cruz"), 1)


func test_combination_preserves_extra_material_quantities() -> void:
	_inventory.add_item(load("res://core/inventory/items/stage_01/fita_vermelha.tres"), 3)
	_inventory.add_item(load("res://core/inventory/items/stage_01/peneira.tres"), 2)
	assert_true(_inventory.combine_items(&"fita_vermelha", &"peneira"))
	assert_eq(_inventory.get_quantity(&"fita_vermelha"), 2)
	assert_eq(_inventory.get_quantity(&"peneira"), 1)
	assert_eq(_inventory.get_quantity(&"peneira_cruz"), 1)


func test_arrow_navigation_selects_items_in_three_columns() -> void:
	for item_id: StringName in ITEM_IDS:
		WorldState.inventory.add_item(load("res://core/inventory/items/stage_01/%s.tres" % item_id))
	var house: Node2D = _add_house()
	var panel: InventoryPanel = house.get_node("GameplayHUD/Screen/Inventory") as InventoryPanel
	await _tap_key(KEY_TAB)
	assert_eq(panel.selected_index, 0)
	await _tap_key(KEY_RIGHT)
	assert_eq(panel.selected_index, 1)
	await _tap_key(KEY_DOWN)
	assert_eq(panel.selected_index, 4)
	var name_label: Label = panel.get_node("SelectedName") as Label
	assert_eq(name_label.text, "Página do Diário")
	await _tap_key(KEY_LEFT)
	assert_eq(panel.selected_index, 3)
	await _tap_key(KEY_UP)
	assert_eq(panel.selected_index, 0)


func test_reading_tab_shows_page_text_and_keyboard_scrolls_then_returns() -> void:
	var page: ItemData = load("res://core/inventory/items/stage_01/pagina_livro.tres")
	WorldState.inventory.add_item(page)
	var house: Node2D = _add_house()
	var hud: GameplayHUD = house.get_node("GameplayHUD") as GameplayHUD
	var panel: InventoryPanel = hud.get_node("Screen/Inventory") as InventoryPanel
	await _tap_key(KEY_TAB)
	await _tap_key(KEY_E)
	assert_eq(panel.focus_zone, InventoryPanel.FocusZone.ACTIONS)
	await _tap_key(KEY_RIGHT)
	var title: Label = panel.get_node("Info/Title") as Label
	var body: RichTextLabel = panel.get_node("Info/Body") as RichTextLabel
	assert_false((panel.get_node("Info") as Panel).visible)
	await _tap_key(KEY_ENTER)
	assert_eq(panel.focus_zone, InventoryPanel.FocusZone.DETAILS)
	assert_true((panel.get_node("Info") as Panel).visible)
	assert_eq(title.text, "Ler")
	assert_eq(body.text, page.lore_text)
	await _tap_key(KEY_DOWN)
	assert_gt(body.get_v_scroll_bar().value, 0.0)
	await _tap_key(KEY_ESCAPE)
	assert_eq(panel.focus_zone, InventoryPanel.FocusZone.ACTIONS)
	assert_false((panel.get_node("Info") as Panel).visible)
	await _tap_key(KEY_ESCAPE)
	assert_eq(panel.focus_zone, InventoryPanel.FocusZone.ITEMS)
	await _tap_key(KEY_ESCAPE)
	assert_eq(hud.mode, GameplayHUD.ModalMode.NONE)


func test_disabled_combine_enables_with_partner_and_requires_confirmation() -> void:
	WorldState.inventory.add_item(load("res://core/inventory/items/stage_01/fita_vermelha.tres"))
	var house: Node2D = _add_house()
	var panel: InventoryPanel = house.get_node("GameplayHUD/Screen/Inventory") as InventoryPanel
	await _tap_key(KEY_TAB)
	await _tap_key(KEY_E)
	await _tap_key(KEY_RIGHT)
	var combine: Button = panel.get_node("Options").get_child(1) as Button
	assert_eq(combine.text, "Combinar")
	assert_true(combine.disabled)
	assert_eq(combine.get_theme_color(&"font_disabled_color"), Color(0.4, 0.4, 0.38, 1.0))
	await _tap_key(KEY_E)
	assert_eq(panel.focus_zone, InventoryPanel.FocusZone.ACTIONS)
	WorldState.inventory.add_item(load("res://core/inventory/items/stage_01/peneira.tres"))
	assert_false(combine.disabled)
	await _tap_key(KEY_E)
	assert_eq(panel.focus_zone, InventoryPanel.FocusZone.CONFIRM)
	var modal: Panel = panel.get_node("CenterModal") as Panel
	assert_true(modal.visible)
	assert_eq(modal.get_global_rect().get_center(), panel.get_global_rect().get_center())
	assert_false((panel.get_node("Info") as Panel).visible)
	await _tap_key(KEY_E)
	assert_eq(panel.focus_zone, InventoryPanel.FocusZone.ACTIONS)
	assert_true(WorldState.inventory.has_item(&"fita_vermelha"))
	assert_true(WorldState.inventory.has_item(&"peneira"))
	await _tap_key(KEY_E)
	await _tap_key(KEY_LEFT)
	await _tap_key(KEY_E)
	assert_false(WorldState.inventory.has_item(&"fita_vermelha"))
	assert_false(WorldState.inventory.has_item(&"peneira"))
	assert_true(WorldState.inventory.has_item(&"peneira_cruz"))
	assert_eq(panel.focus_zone, InventoryPanel.FocusZone.RESULT)
	assert_true(modal.visible)
	assert_eq((modal.get_node("Text") as Label).text,
		"Você combinou fita vermelha e peneira!\nO resultado é uma peneira com cruz.")
	assert_eq((modal.get_node("ResultIcon") as TextureRect).texture, InventorySystem.CROSS_SIEVE.icon)
	assert_false((panel.get_node("Info") as Panel).visible)
	var name_label: Label = panel.get_node("SelectedName") as Label
	assert_eq(name_label.text, "Peneira com Cruz")
	var icon: TextureRect = panel.get_node("SlotScroll/Slots/Slot00/Icon") as TextureRect
	assert_eq(icon.texture, InventorySystem.CROSS_SIEVE.icon)
	var examine: Button = panel.get_node("Options").get_child(0) as Button
	assert_eq(examine.text, "Examinar")
	assert_false(combine.visible)
	await _tap_key(KEY_RIGHT)
	assert_eq(panel.focus_zone, InventoryPanel.FocusZone.RESULT)
	assert_eq(WorldState.inventory.get_quantity(&"peneira_cruz"), 1)
	await _tap_key(KEY_ENTER)
	assert_eq(panel.focus_zone, InventoryPanel.FocusZone.ITEMS)
	assert_false(modal.visible)
	assert_false((panel.get_node("Info") as Panel).visible)


func test_canceling_recipe_leaves_both_materials() -> void:
	WorldState.inventory.add_item(load("res://core/inventory/items/stage_01/peneira.tres"))
	WorldState.inventory.add_item(load("res://core/inventory/items/stage_01/fita_vermelha.tres"))
	var house: Node2D = _add_house()
	var panel: InventoryPanel = house.get_node("GameplayHUD/Screen/Inventory") as InventoryPanel
	await _tap_key(KEY_TAB)
	await _tap_key(KEY_E)
	await _tap_key(KEY_RIGHT)
	await _tap_key(KEY_E)
	assert_eq(panel.focus_zone, InventoryPanel.FocusZone.CONFIRM)
	await _tap_key(KEY_ESCAPE)
	assert_eq(panel.focus_zone, InventoryPanel.FocusZone.ACTIONS)
	assert_false((panel.get_node("CenterModal") as Panel).visible)
	assert_true(WorldState.inventory.has_item(&"fita_vermelha"))
	assert_true(WorldState.inventory.has_item(&"peneira"))
	assert_false(WorldState.inventory.has_item(&"peneira_cruz"))


func test_mouse_cannot_change_inventory_selection() -> void:
	WorldState.inventory.add_item(BOTTLE)
	WorldState.inventory.add_item(PIPE)
	var house: Node2D = _add_house()
	var panel: InventoryPanel = house.get_node("GameplayHUD/Screen/Inventory") as InventoryPanel
	await _tap_key(KEY_TAB)
	var second_slot: Button = panel.get_node("SlotScroll/Slots/Slot01") as Button
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.position = second_slot.get_global_rect().get_center()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	Input.parse_input_event(click)
	await wait_process_frames(1)
	click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	Input.parse_input_event(click)
	assert_eq(panel.selected_index, 0)
	assert_eq(panel.focus_zone, InventoryPanel.FocusZone.ITEMS)


func test_inventory_background_pixel_font_and_map_scale() -> void:
	var house: Node2D = _add_house()
	var panel: InventoryPanel = house.get_node("GameplayHUD/Screen/Inventory") as InventoryPanel
	await _tap_key(KEY_TAB)
	var background: TextureRect = panel.get_node("Background") as TextureRect
	var background_atlas: AtlasTexture = background.texture as AtlasTexture
	assert_eq(background_atlas.atlas.resource_path, "res://assets/art/ui/ui_inventory_background.png")
	assert_eq(background.size, Vector2(640.0, 360.0))
	var font: Font = panel.get_theme_default_font()
	assert_eq(font.resource_path, "res://assets/fonts/entre_lendas_pixel.fnt")
	for index: int in range("áàâãéêíóôõúüçÁÃÉÓÇ".length()):
		assert_true(font.has_char("áàâãéêíóôõúüçÁÃÉÓÇ".unicode_at(index)))
	var item: CollectibleItem = house.get_node("YSortRoot/BottleCollectible") as CollectibleItem
	assert_eq(item.sprite.scale, Vector2(0.75, 0.75))
	assert_eq(item.sprite.texture.get_size() * item.sprite.scale, Vector2(24.0, 24.0))
	assert_eq(BOTTLE.icon.get_size(), Vector2(32.0, 32.0))


func test_description_requires_explicit_examine_and_hides_when_leaving() -> void:
	WorldState.inventory.add_item(BOTTLE)
	WorldState.inventory.add_item(PIPE)
	var house: Node2D = _add_house()
	var panel: InventoryPanel = house.get_node("GameplayHUD/Screen/Inventory") as InventoryPanel
	var info: Panel = panel.get_node("Info") as Panel
	assert_false(panel.has_node("ItemsPanel"))
	await _tap_key(KEY_TAB)
	assert_false(info.visible)
	await _tap_key(KEY_E)
	assert_false(info.visible)
	await _tap_key(KEY_DOWN)
	assert_eq(panel.focus_zone, InventoryPanel.FocusZone.ACTIONS)
	assert_false(info.visible)
	await _tap_key(KEY_ENTER)
	assert_true(info.visible)
	assert_eq((info.get_node("Title") as Label).text, "Examinar")
	assert_eq((info.get_node("Body") as RichTextLabel).text,
		BOTTLE.description + "\n\n" + BOTTLE.insight_text)
	await _tap_key(KEY_ESCAPE)
	assert_false(info.visible)
	await _tap_key(KEY_ESCAPE)
	await _tap_key(KEY_RIGHT)
	assert_eq(panel.selected_index, 1)
	assert_false(info.visible)
	await _tap_key(KEY_E)
	await _tap_key(KEY_E)
	assert_true(info.visible)
	await _tap_key(KEY_TAB)
	await _tap_key(KEY_TAB)
	assert_false(info.visible)


func test_scrollbars_use_the_provided_pixel_art_for_text_and_slots() -> void:
	var house: Node2D = _add_house()
	var panel: InventoryPanel = house.get_node("GameplayHUD/Screen/Inventory") as InventoryPanel
	var body: RichTextLabel = panel.get_node("Info/Body") as RichTextLabel
	var slots: ScrollContainer = panel.get_node("SlotScroll") as ScrollContainer
	for scrollbar: VScrollBar in [body.get_v_scroll_bar(), slots.get_v_scroll_bar()]:
		var track: StyleBoxTexture = scrollbar.get_theme_stylebox(&"scroll") as StyleBoxTexture
		var thumb: StyleBoxTexture = scrollbar.get_theme_stylebox(&"grabber") as StyleBoxTexture
		assert_not_null(track)
		assert_not_null(thumb)
		assert_eq(track.texture.resource_path, "res://assets/art/ui/ui_scrollbar_track.png")
		var atlas: AtlasTexture = thumb.texture as AtlasTexture
		assert_eq(atlas.atlas.resource_path, "res://assets/art/ui/ui_scrollbar.png")
		assert_eq(atlas.region, Rect2(117.0, 116.0, 22.0, 32.0))


func test_inventory_covers_resized_viewports_and_centers_its_modal() -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(960, 540)
	add_child_autofree(viewport)
	var scene: PackedScene = load("res://ui/inventory_panel.tscn")
	var panel: InventoryPanel = scene.instantiate() as InventoryPanel
	viewport.add_child(panel)
	panel.open_inventory()
	await wait_process_frames(2)
	var background: TextureRect = panel.get_node("Background") as TextureRect
	var modal: Panel = panel.get_node("CenterModal") as Panel
	assert_eq(panel.size, Vector2(960.0, 540.0))
	assert_eq(background.get_global_rect(), Rect2(Vector2.ZERO, panel.size))
	assert_true(modal.get_global_rect().get_center().is_equal_approx(panel.size * 0.5))
	viewport.size = Vector2i(1024, 600)
	await wait_process_frames(2)
	assert_eq(panel.size, Vector2(1024.0, 600.0))
	assert_eq(background.get_global_rect(), Rect2(Vector2.ZERO, panel.size))
	assert_true(modal.get_global_rect().get_center().is_equal_approx(panel.size * 0.5))


func test_sieve_is_reachable_and_can_be_collected_with_e() -> void:
	var house: Node2D = _add_house()
	var player: Player = house.get_node("YSortRoot/Player") as Player
	var hud: GameplayHUD = house.get_node("GameplayHUD") as GameplayHUD
	var sieve: CollectibleItem = house.get_node("YSortRoot/SieveCollectible") as CollectibleItem
	var sieve_icon: Texture2D = sieve.item_data.icon
	assert_eq(sieve.item_data.id, &"peneira")
	await wait_physics_frames(3)
	assert_false(player.test_move(player.global_transform, Vector2(48.0, 16.0)))
	player.position += Vector2(48.0, 16.0)
	Input.action_press(&"move_down")
	await wait_physics_frames(1)
	Input.action_release(&"move_down")
	await wait_physics_frames(3)
	await _tap_key(KEY_E)
	assert_eq(hud.mode, GameplayHUD.ModalMode.CONFIRM)
	assert_eq((hud.get_node("Screen/Dialogue/Text") as Label).text, "Deseja pegar Peneira?")
	(hud.get_node("Screen/Dialogue/Yes") as Button).pressed.emit()
	await wait_process_frames(2)
	assert_true(WorldState.inventory.has_item(&"peneira"))
	assert_false(house.has_node("YSortRoot/SieveCollectible"))
	await _tap_key(KEY_TAB)
	var icon: TextureRect = hud.get_node("Screen/Inventory/SlotScroll/Slots/Slot00/Icon")
	assert_eq(icon.texture, sieve_icon)


func _add_house() -> Node2D:
	var house: Node2D = HOUSE.instantiate() as Node2D
	add_child_autofree(house)
	return house


func _tap_key(key: Key) -> void:
	var pressed: InputEventKey = InputEventKey.new()
	pressed.keycode = key
	pressed.physical_keycode = key
	pressed.pressed = true
	Input.parse_input_event(pressed)
	await wait_process_frames(1)
	var released: InputEventKey = InputEventKey.new()
	released.keycode = key
	released.physical_keycode = key
	Input.parse_input_event(released)
	await wait_process_frames(1)


func _has_key(action: StringName, key: Key) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key_event: InputEventKey = event as InputEventKey
			if key_event.keycode == key or key_event.physical_keycode == key:
				return true
	return false


func _release_actions() -> void:
	for action: StringName in [
		&"move_up", &"move_down", &"move_left", &"move_right", &"interact", &"open_inventory"
	]:
		Input.action_release(action)
