extends GutTest
## Leitura real por teclado e regras puras: páginas não são recompensas de inventário.

const STORY: Stage01Narrative = preload("res://core/dialogue/stage_01/stage_01_script.tres")
const HUD: PackedScene = preload("res://ui/gameplay_hud.tscn")
const PLAYER: PackedScene = preload("res://entities/player/player.tscn")
const ORIGIN: StringName = &"clue_origem_saci"

var _state: Stage01State
var _journal: JournalSystem
var _items: InventorySystem
var _root: Node2D
var _hud: GameplayHUD
var _player: Player


func before_each() -> void:
	WorldState.reset()
	_state = Stage01State.new()
	_state.begin()
	_journal = JournalSystem.new(_state)
	_items = InventorySystem.new()
	_root = Node2D.new()
	add_child_autofree(_root)
	_player = PLAYER.instantiate() as Player
	_root.add_child(_player)
	_hud = HUD.instantiate() as GameplayHUD
	_root.add_child(_hud)
	_hud.bind_player(_player)


func after_each() -> void:
	if is_instance_valid(_root):
		_root.free()
	WorldState.reset()


func test_catalog_has_seven_base_pages_and_one_bonus_with_complete_source_text() -> void:
	assert_eq(JournalSystem.PAGES.size(), 8)
	var ids: Array[StringName] = []
	for page: JournalEntry in JournalSystem.PAGES:
		assert_false(page.id in ids)
		ids.append(page.id)
		assert_false(page.title.is_empty())
		assert_false(page.origin.is_empty())
		assert_eq(page.text, STORY.find_entry(page.dialogue_id).text)
		assert_eq(page.bonus, page.id == Stage01State.BONUS_CLUE)
		assert_true(page.id in Stage01State.BASE_CLUES or page.bonus)
	assert_true(_journal.find_entry(Stage01State.BONUS_CLUE).text.contains("31 de outubro"))
	assert_true(_journal.get_entries().is_empty())
	assert_true(_items.get_items().is_empty())
	assert_null(_journal.find_entry(&"unknown"))
	assert_null(_journal.make_dialogue(&"unknown"))


func test_unlock_is_new_without_marking_read_or_adding_inventory_icons() -> void:
	assert_null(_journal.make_dialogue(ORIGIN))
	assert_true(_state.unlock_clue(ORIGIN))
	assert_eq(_journal.get_entries().size(), 1)
	assert_eq(_journal.get_new_count(), 1)
	assert_false(_journal.is_read(ORIGIN))
	assert_eq(_state.pistas_saci_lidas, 0)
	assert_true(_items.get_items().is_empty())
	var copy: Array[JournalEntry] = _journal.get_entries()
	copy.clear()
	assert_eq(_journal.get_entries().size(), 1)


func test_cancel_before_last_page_does_not_count_and_reopening_starts_at_first() -> void:
	_state.unlock_clue(ORIGIN)
	var session: DialogueSession = _reading(ORIGIN)
	assert_gt(session.pages.size(), 1)
	session.reveal()
	session.advance()
	assert_eq(session.page_index, 1)
	assert_true(session.cancel())
	assert_eq(_state.pistas_saci_lidas, 0)
	assert_eq(_journal.get_new_count(), 1)
	var again: DialogueSession = _reading(ORIGIN)
	assert_eq(again.page_index, 0)
	again.reveal()
	assert_eq(_state.pistas_saci_lidas, 0)
	again.abort()


func test_final_page_requires_acknowledgement_and_rereading_is_unique() -> void:
	_state.unlock_clue(ORIGIN)
	var session: DialogueSession = _reading(ORIGIN)
	while session.page_index < session.pages.size() - 1:
		session.reveal()
		session.advance()
	session.reveal()
	assert_eq(_state.pistas_saci_lidas, 0)
	assert_true(session.active)
	session.advance()
	assert_false(session.active)
	assert_true(_journal.is_read(ORIGIN))
	assert_eq(_journal.get_new_count(), 0)
	_finish(_reading(ORIGIN))
	assert_eq(_state.pistas_saci_lidas, 1)


func test_original_dialogue_and_journal_share_the_same_read_record() -> void:
	var session: DialogueSession = DialogueSession.new(DialogueContext.new(_state, _items))
	assert_false(session.start(STORY, &"journal.origin"))
	_state.unlock_clue(ORIGIN)
	assert_true(session.start(STORY, &"journal.origin"))
	session.page_limit = 80
	_finish(session)
	assert_true(_journal.is_read(ORIGIN))
	_finish(_reading(ORIGIN))
	assert_eq(_state.pistas_saci_lidas, 1)


func test_mural_counts_only_after_all_five_texts_complete_in_any_order() -> void:
	_hub(_state)
	var session: DialogueSession = DialogueSession.new(DialogueContext.new(_state, _items))
	assert_true(session.start(STORY, &"mural.panel_1"))
	session.reveal()
	session.cancel()
	assert_true(_state.get_read_mural_panels().is_empty())
	for panel: int in [6, 4, 2, 5, 1]:
		_read_panel(panel)
		assert_eq(_state.pistas_saci_lidas, 0)
		assert_null(_journal.make_dialogue(&"clue_mural_origens"))
	_read_panel(3)
	assert_eq(_state.pistas_saci_lidas, 1)
	assert_true(_journal.is_read(&"clue_mural_origens"))
	_read_panel(1)
	_finish(_reading(&"clue_mural_origens"))
	assert_eq(_state.pistas_saci_lidas, 1)


func test_bonus_needs_seven_actual_readings_and_never_counts_as_eighth() -> void:
	_hub(_state)
	for panel: int in range(1, 6):
		_state.read_mural_panel(panel)
	for clue: StringName in Stage01State.BASE_CLUES:
		_state.unlock_clue(clue)
	assert_eq(_journal.get_new_count(), 7)
	assert_null(_journal.make_dialogue(Stage01State.BONUS_CLUE))
	for clue: StringName in Stage01State.BASE_CLUES:
		assert_false(Stage01State.BONUS_CLUE in _state.get_unlocked_clues())
		_finish(_reading(clue))
	assert_eq(_state.pistas_saci_lidas, 7)
	assert_eq(_journal.get_new_count(), 1)
	assert_eq(_journal.get_entries().size(), 8)
	_finish(_reading(Stage01State.BONUS_CLUE))
	assert_eq(_state.pistas_saci_lidas, 7)
	assert_eq(_journal.get_new_count(), 0)
	assert_eq(_state.get_read_clues().size(), 8)


func test_new_journal_instance_preserves_state_and_new_game_clears_existing_facade() -> void:
	WorldState.start_new_game()
	var shared: JournalSystem = WorldState.journal
	WorldState.stage01.unlock_clue(ORIGIN)
	var first: DialogueSession = DialogueSession.new(DialogueContext.new(WorldState.stage01, WorldState.inventory))
	assert_true(first.start(shared.make_dialogue(ORIGIN), &"journal.origin"))
	_finish(first)
	assert_true(JournalSystem.new(WorldState.stage01).is_read(ORIGIN))
	WorldState.start_new_game()
	assert_eq(WorldState.journal, shared)
	assert_true(shared.get_entries().is_empty())
	assert_eq(WorldState.stage01.pistas_saci_lidas, 0)
	assert_true(WorldState.inventory.get_items().is_empty())


func test_keyboard_empty_journal_return_and_movement_lock() -> void:
	await _tap(KEY_TAB)
	await _tap(KEY_J)
	assert_true(_inventory().journal_open)
	assert_true(_panel().visible)
	assert_false(_player.movement_enabled)
	assert_false((_panel().get_node("Info") as Panel).visible)
	assert_true((_panel().get_node("PageScroll/Pages") as VBoxContainer).get_children().is_empty())
	await _tap(KEY_E)
	assert_eq(WorldState.stage01.pistas_saci_lidas, 0)
	await _tap(KEY_ESCAPE)
	assert_false(_inventory().journal_open)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.INVENTORY)
	await _tap(KEY_TAB)
	assert_true(_player.movement_enabled)


func test_keyboard_examine_then_paginated_read_updates_new_badge_after_final_key() -> void:
	WorldState.start_new_game()
	WorldState.stage01.unlock_clue(ORIGIN)
	await _tap(KEY_TAB)
	await _tap(KEY_J)
	var panel: JournalPanel = _panel()
	assert_true((panel.get_node("PageScroll/Pages").get_child(0) as Button).text.begins_with("NOVA"))
	await _tap(KEY_E)
	await _tap(KEY_E)
	assert_eq(panel.zone, JournalPanel.Zone.EXAMINE)
	assert_true((panel.get_node("Info") as Panel).visible)
	assert_null((panel.get_node("Info/Illustration") as TextureRect).material)
	assert_eq(WorldState.stage01.pistas_saci_lidas, 0)
	await _tap(KEY_ESCAPE)
	await _tap(KEY_RIGHT)
	await _tap(KEY_ENTER)
	assert_eq(panel.zone, JournalPanel.Zone.READING)
	assert_gt(panel.reading.pages.size(), 1)
	while panel.reading.page_index < panel.reading.pages.size() - 1:
		assert_eq(WorldState.stage01.pistas_saci_lidas, 0)
		assert_true(panel.call("_fits_page", panel.reading.pages[panel.reading.page_index]))
		await _tap(KEY_ENTER)
	assert_eq(WorldState.stage01.pistas_saci_lidas, 0)
	await _tap(KEY_ENTER)
	assert_eq(WorldState.stage01.pistas_saci_lidas, 1)
	assert_false(panel.reading.active)
	assert_true((panel.get_node("PageScroll/Pages").get_child(0) as Button).text.begins_with("LIDA"))
	await _tap(KEY_TAB)
	assert_true(_player.movement_enabled)
	assert_null(panel.reading)


func test_tab_interrupt_echo_and_section_switch_do_not_mark_read() -> void:
	WorldState.start_new_game()
	WorldState.stage01.unlock_clue(ORIGIN)
	await _open_reading()
	var current: int = _panel().reading.page_index
	var echo: InputEventKey = InputEventKey.new()
	echo.keycode = KEY_E
	echo.pressed = true
	echo.echo = true
	Input.parse_input_event(echo)
	await wait_process_frames(2)
	assert_eq(_panel().reading.page_index, current)
	await _tap(KEY_J)
	assert_false(_inventory().journal_open)
	assert_null(_panel().reading)
	await _tap(KEY_J)
	await _tap(KEY_E)
	await _tap(KEY_RIGHT)
	await _tap(KEY_E)
	await _tap(KEY_TAB)
	assert_eq(WorldState.stage01.pistas_saci_lidas, 0)
	assert_eq(WorldState.journal.get_new_count(), 1)
	assert_true(_player.movement_enabled)


func test_page_navigation_and_recreated_hud_keep_unique_progress() -> void:
	WorldState.start_new_game()
	WorldState.stage01.unlock_clue(ORIGIN)
	WorldState.stage01.unlock_clue(&"clue_gorro_vermelho")
	await _tap(KEY_TAB)
	await _tap(KEY_J)
	await _tap(KEY_DOWN)
	assert_eq(_panel().selected_id, &"clue_gorro_vermelho")
	await _tap(KEY_E)
	await _tap(KEY_RIGHT)
	await _tap(KEY_E)
	while _panel().reading.active:
		await _tap(KEY_E)
	assert_eq(WorldState.stage01.pistas_saci_lidas, 1)
	_hud.free()
	_hud = HUD.instantiate() as GameplayHUD
	_root.add_child(_hud)
	_hud.bind_player(_player)
	await _tap(KEY_TAB)
	await _tap(KEY_J)
	assert_eq(_panel().get_node("PageScroll/Pages").get_child_count(), 2)
	assert_true((_panel().get_node("PageScroll/Pages").get_child(1) as Button).text.begins_with("LIDA"))
	assert_eq(WorldState.stage01.pistas_saci_lidas, 1)


func test_generic_inventory_pages_do_not_unlock_narrative_clues() -> void:
	WorldState.start_new_game()
	WorldState.inventory.add_item(load("res://core/inventory/items/stage_01/pagina_diario.tres") as ItemData)
	await _tap(KEY_TAB)
	await _tap(KEY_E)
	await _tap(KEY_RIGHT)
	await _tap(KEY_E)
	assert_eq(_inventory().focus_zone, InventoryPanel.FocusZone.DETAILS)
	assert_eq(WorldState.stage01.pistas_saci_lidas, 0)
	assert_true(WorldState.journal.get_entries().is_empty())


func test_arrows_and_enter_can_switch_sections_without_letter_shortcuts() -> void:
	await _tap(KEY_TAB)
	await _tap(KEY_UP)
	assert_true((_inventory().get_node("SectionHint") as Label).text.contains("[Mochila]"))
	await _tap(KEY_RIGHT)
	await _tap(KEY_ENTER)
	assert_true(_inventory().journal_open)
	await _tap(KEY_UP)
	assert_true((_inventory().get_node("SectionHint") as Label).text.contains("[Diário]"))
	await _tap(KEY_LEFT)
	await _tap(KEY_E)
	assert_false(_inventory().journal_open)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.INVENTORY)
	await _tap(KEY_I)
	assert_eq(_hud.mode, GameplayHUD.ModalMode.NONE)
	assert_true(_player.movement_enabled)


func test_last_base_reading_unlocks_bonus_live_and_preserves_scroll_selection() -> void:
	WorldState.start_new_game()
	_hub(WorldState.stage01)
	for panel: int in range(1, 6):
		WorldState.stage01.read_mural_panel(panel)
	for clue: StringName in Stage01State.BASE_CLUES:
		WorldState.stage01.unlock_clue(clue)
		if clue != &"clue_bambu_rachado":
			WorldState.stage01.mark_clue_read(clue)
	await _tap(KEY_TAB)
	await _tap(KEY_J)
	for index: int in range(6):
		await _tap(KEY_DOWN)
	assert_eq(_panel().selected_id, &"clue_bambu_rachado")
	assert_gt((_panel().get_node("PageScroll") as ScrollContainer).scroll_vertical, 0)
	await _tap(KEY_E)
	await _tap(KEY_RIGHT)
	await _tap(KEY_E)
	while _panel().reading.active:
		var body: RichTextLabel = _panel().get_node("Info/Body") as RichTextLabel
		assert_lte(body.get_content_height(), int(body.size.y))
		await _tap(KEY_E)
	assert_eq(_panel().selected_id, &"clue_bambu_rachado")
	assert_eq(_panel().get_node("PageScroll/Pages").get_child_count(), 8)
	assert_gt((_panel().get_node("PageScroll") as ScrollContainer).scroll_vertical, 0)
	assert_eq(WorldState.journal.get_new_count(), 1)
	await _tap(KEY_ESCAPE)
	await _tap(KEY_ESCAPE)
	await _tap(KEY_DOWN)
	assert_eq(_panel().selected_id, Stage01State.BONUS_CLUE)
	assert_true((_panel().get_node("PageScroll/Pages").get_child(7) as Button).text.begins_with("NOVA"))
	await _tap(KEY_E)
	await _tap(KEY_RIGHT)
	await _tap(KEY_E)
	while _panel().reading.active:
		await _tap(KEY_E)
	assert_eq(WorldState.stage01.pistas_saci_lidas, 7)
	assert_eq(WorldState.journal.get_new_count(), 0)


func test_reset_during_reading_and_window_shapes_leave_no_stale_page() -> void:
	WorldState.start_new_game()
	WorldState.stage01.unlock_clue(ORIGIN)
	await _open_reading()
	WorldState.start_new_game()
	assert_null(_panel().reading)
	assert_eq(_panel().zone, JournalPanel.Zone.PAGES)
	assert_false((_panel().get_node("Info") as Panel).visible)
	var window: Window = get_window()
	var previous_size: Vector2i = window.size
	var previous_override: Vector2i = window.content_scale_size
	for dimensions: Vector2i in [Vector2i(640, 360), Vector2i(360, 640), Vector2i(960, 360), Vector2i(320, 240)]:
		window.size = dimensions
		window.content_scale_size = dimensions
		await wait_process_frames(3)
		var viewport: Rect2 = _inventory().get_viewport_rect()
		assert_eq((_inventory().get_node("Background") as Control).get_global_rect(), viewport)
		for path: String in ["PageScroll", "Options", "Info", "Hint", "Progress"]:
			var control: Control = _panel().get_node(path) as Control
			assert_true(viewport.encloses(control.get_global_rect()), path + " cabe na tela " + str(dimensions))
	window.size = previous_size
	window.content_scale_size = previous_override
	await wait_process_frames(3)


func _reading(id: StringName) -> DialogueSession:
	var session: DialogueSession = DialogueSession.new(DialogueContext.new(_state, _items))
	session.page_limit = 80
	assert_true(session.start(_journal.make_dialogue(id), _journal.find_entry(id).dialogue_id))
	return session


func _finish(session: DialogueSession) -> void:
	var limit: int = 100
	while session.active and limit > 0:
		session.reveal()
		session.advance()
		limit -= 1
	assert_false(session.active)


func _read_panel(panel: int) -> void:
	var session: DialogueSession = DialogueSession.new(DialogueContext.new(_state, _items))
	assert_true(session.start(STORY, StringName("mural.panel_%d" % panel)))
	while session.active and session.entry.id == StringName("mural.panel_%d" % panel):
		session.reveal()
		session.advance()
	session.abort()


func _hub(state: Stage01State) -> void:
	for phase: StringName in Stage01State.PHASES.slice(1, 7):
		assert_true(state.advance_to(phase))


func _inventory() -> InventoryPanel:
	return _hud.get_node("Screen/Inventory") as InventoryPanel


func _panel() -> JournalPanel:
	return _hud.get_node("Screen/Inventory/Journal") as JournalPanel


func _open_reading() -> void:
	await _tap(KEY_TAB)
	await _tap(KEY_J)
	await _tap(KEY_E)
	await _tap(KEY_RIGHT)
	await _tap(KEY_E)


func _tap(key: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	await wait_process_frames(2)
	event = InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	Input.parse_input_event(event)
	await wait_process_frames(2)
